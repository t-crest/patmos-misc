#!/bin/bash -e
###############################################################################
#
# Development installation script for Patmos compiler+tools
#
# The builds performed by this script are out-of-source builds.
#
# Benedikt Huber <benedikt@vmars.tuwien.ac.at>
# Daniel Prokesch <daniel@vmars.tuwien.ac.at>
# Stefan Hepp <hepp@complang.tuwien.ac.at>
#
# TODO find out whether all variables are quoted where necessary
# NB: CMake does not want it's program path quoted.
#
###############################################################################

function abspath() {
    local path=$1
    local pwd_restore="$(pwd)"

    # readlink -f does not work on OSX, so we do this manually
    cd $(dirname "$path")
    path=$(basename "$path")
    # follow chain of symlinks
    while [ -L "$path" ]; do
        path=$(readlink "$path")
        cd $(dirname "$path")
        path=$(basename "$path")
    done
    echo "$(pwd -P)/$path"
    cd "$pwd_restore"
}


OS_NAME=$(uname -s)

# physical location of this script, and the config
self=$(abspath $0)
CFGFILE=$(dirname $self)/build.cfg

# location of the patmos-chrpath script
CHRPATH=$(dirname $self)/patmos-chrpath

########### Start of user configs, overwrite in build.cfg ##############

# List of targets to build by default
ALLTARGETS="gold llvm newlib compiler-rt pasim bench"

# Root directory for all repositories
ROOT_DIR=$(pwd)

# Set to 'short' for llvm/clang/... directory names, 'long' for
# patmos-llvm/patmos-clang/.. or 'prefix' to use $(REPO_PREFIX)llvm/..
REPO_NAMES=short
REPO_PREFIX=

# Installation directory prefix
INSTALL_DIR="$ROOT_DIR/local"
# Directory suffix for directory containing generated files
BUILDDIR_SUFFIX="/build"

# Targets to support with patmos-clang
#LLVM_TARGETS=all
#LLVM_TARGETS="ARM;Mips;Patmos;X86"
LLVM_TARGETS=Patmos
ECLIPSE_LLVM_TARGETS=Patmos

# build LLVM using configure instead of cmake
LLVM_USE_CONFIGURE=false
# build LLVM using shared libraries instead of static libs
LLVM_BUILD_SHARED=true
# skip checking out clang
LLVM_OMIT_CLANG=false

# Set to the name of the clang binary to use for compiling LLVM itself.
# Leave empty to use cmake defaults
CLANG_COMPILER=clang

# Build gold binutils and LLVM LTO plugin
BUILD_LTO=true

# Build newlib, compiler-rt and benchmarks with softfloats
BUILD_SOFTFLOAT=true

# Build the Patmos Chisel emulator
BUILD_EMULATOR=true

# Create symlinks instead of copying files where applicable
# (llvm, clang, gold)
INSTALL_SYMLINKS=false

# Update rpath of binaries during installation:
# - 'remove'  Remove rpath
# - 'build'   Set install rpath at build time
# - 'true'    Update rpath to the install dir on installation
# - 'false'   Do not change rpath on installation
INSTALL_RPATH=true

# URL for the repository containing the benchmarks
#BENCH_REPO_URL="git@github.com:t-crest/patmos-benchmarks.git"
BENCH_REPO_URL=

# Set the target architecture for gold
# auto      use HOST on Linux, 'patmos-unknown-unknown-elf' otherwise
# none      do not set --target
# <target>  use <target> as target architecture
GOLD_TARGET_ARCH=auto

# Target triple for Patmos libraries and benchmarks:
# patmos-unknown-unknown-elf	Default
# patmos-unknown-rtems		Used with RTEMS
TARGET="patmos-unknown-unknown-elf"

# Additional arguments for cmake / configure
LLVM_CMAKE_ARGS=
# e.g., use ninja for building instead of make
#LLVM_CMAKE_ARGS="-G Ninja"
LLVM_CONFIGURE_ARGS=
GOLD_ARGS=
NEWLIB_ARGS=

# Build simulator in Release mode
#PASIM_ARGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo"
# Use a custom installation of Boost libraries
#PASIM_ARGS="-DBOOST_ROOT=$HOME/local/ -DBoost_NO_BOOST_CMAKE=TRUE"

# Patmos C-tools cmake options
CTOOLS_ARGS=

# Overwrite default options for pasim for make test
#BENCH_ARGS="-DPASIM_OPTIONS='-M fifo -m 4k'"

# Set path to a3, or set to empty string to disable a3
#BENCH_ARGS="${BENCH_ARGS} -DA3_EXECUTABLE="

# Additional CFLAGS, LDFLAGS 
GOLD_CFLAGS=
GOLD_CXXFLAGS=
# Enable this if gcc throws errors about narrowing conversions
#GOLD_CXXFLAGS="-Wno-narrowing"

COMPILER_RT_CFLAGS=
# Disable inline-assembly implementations in compiler-rt
#COMPILER_RT_CFLAGS="-DCRT_NO_INLINE_ASM"
BENCH_LDFLAGS=

# CFLAGS for host compiler
NEWLIB_CFLAGS=
# CFLAGS for target compiler (patmos-clang)
NEWLIB_TARGET_CFLAGS=

# Use the following FLAGS to link runtime libraries as binaries
#NEWLIB_TARGET_CFLAGS="-fpatmos-emit-obj"
#COMPILER_RT_CFLAGS="-fpatmos-emit-obj"
#BENCH_LDFLAGS="-fpatmos-lto-defaultlibs"

# Commandline option to pass to make/ctest for parallel builds
MAKEJ=-j2

# Arguments to pass to ctest
# Use "-jN" to enable parallel benchmark testing 
CTEST_ARGS=

#################### End of user configs #####################

# Internal options, set by command line
MAKE_VERBOSE=
DO_CLEAN=false
DO_UPDATE=false
DO_SHOW_CONFIGURE=false
DO_RUN_TESTS=false
DRYRUN=false
VERBOSE=false
DO_RUN_ALL=false

# user config
if [ -f $CFGFILE ]; then
  source $CFGFILE
fi


##################### Helper Functions ######################

function info() {
    echo -e "\033[32m ===== $1 ===== \033[0m" >&2
}

run() {
    if [ "$VERBOSE" == "true" ]; then
	echo "$@"
    fi
    if [ "$DRYRUN" != "true" ]; then
	eval $@
	ret=$?
	if [ $ret != 0 ]; then
	    echo "$@ failed ($ret)!"
	    return $ret
	fi
    fi
}

function install() {
    # if $src is a directory, $dst must be the target directory, not the parent directory!
    local src=$1
    local dst=$2

    if [ -f $src -a -d $dst ]; then
	dst=$dst/$(basename $src)
    fi

    run mkdir -p $(dirname $dst)

    if [ "$INSTALL_SYMLINKS" == "true" ]; then
	echo "Symlinking $src -> $dst"

	if [ -d $src ]; then
	    run rm -rf $dst
	fi
	run ln -sf $src $dst
    else
	echo "Installing $src -> $dst"

	if [ -L $dst ]; then
	    rm -f $dst
	fi
	# TODO option to use hardlinking instead
	# Maybe, if $src is a directory, make sure we remove any trash in $dst (use rsync??) .. should be optional, off by default!
	if [ "$OS_NAME" == "Linux" ]; then
	    run cp -fauT $src $dst
	else
	    if [ -e $dst ]; then
		run rm -rf $dst
	    fi
	    run cp -fR $src $dst
	fi
    fi
}

function update_rpath() {
    local repo=$1

    if [ "$INSTALL_RPATH" == "true" ]; then
	if [ -x $CHRPATH ]; then
	    run $CHRPATH -w -p $repo -i $INSTALL_DIR
	else
	    echo "** Warning: patmos-chrpath script not found, skipping setting rpath."
	fi
    fi
    if [ "$INSTALL_RPATH" == "remove" ]; then
	if [ -x $CHRPATH ]; then
	    run $CHRPATH -w -d -p $repo -i $INSTALL_DIR
	else
	    echo "** Warning: patmos-chrpath script not found, skipping setting rpath."
	fi
    fi
}

function get_repo_dir() {
    local repo=$1

    case $REPO_NAMES in
    short)
	echo $repo
	;;
    long)
	case $repo in
	patmos)	  echo "patmos" ;;
	patmos/*) echo $repo ;;
	bench)    echo "patmos-benchmarks" ;;
	*)	  echo "patmos-"$repo ;;
	esac
	;;
    prefix)
	echo $REPO_PREFIX$repo
	;;
    *)
	# TODO uhm.. make sure that this never happens by checking earlier
	echo $repo
	;;
    esac
}

function get_build_dir() {
    local repo=$1
    local repodir=$(get_repo_dir $1)
    local subdir=$2

    if [ "$repo" == "patmos" ]; then
	if [[ "$BUILDDIR_SUFFIX" =~ ^/ ]]; then
	    builddir=$repodir/$subdir$BUILDDIR_SUFFIX
	else
	    builddir=$repodir$BUILDDIR_SUFFIX/$subdir
	fi
    else
	builddir=$repodir$BUILDDIR_SUFFIX
    fi
    echo $builddir
}

function clone_update() {
    local srcurl=$1
    local target=$ROOT_DIR/$2

    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	return
    fi
    if [ ! -d "$target" ] ; then
	info "Cloning from $srcurl"
	run git clone "$srcurl" "$target"
    elif [ ${DO_UPDATE} != false ] ; then
        #TODO find a better way (e.g. stash away only on demand)
	info "Updating $1"
        run pushd "$target" ">/dev/null"
        if [ "$DRYRUN" == "true" ]; then
	    echo git stash
	else
	    ret=$(git stash)
	    # TODO is there a better way of doing this?
	    local skip_stash=false
	    if [ "$ret" == "No local changes to save" ]; then
		skip_stash=true
	    fi
	fi
        run git pull --rebase
        if [ "$DRYRUN" == "true" ]; then
	    echo git stash pop
	else
	    if [ "$skip_stash" != "true" ]; then
		git stash pop
	    fi
	fi
        run popd ">/dev/null"
    fi
}

function build_flags() {
    local repo=$1


    local cflagsname=$(echo "${repo}_CFLAGS" | tr '[a-z-/]' '[A-Z__]')
    local cppflagsname=$(echo "${repo}_CPPFLAGS" | tr '[a-z-/]' '[A-Z__]')
    local cxxflagsname=$(echo "${repo}_CXXFLAGS" | tr '[a-z-/]' '[A-Z__]')
    local ldflagsname=$(echo "${repo}_LDFLAGS" | tr '[a-z-/]' '[A-Z__]')

    if [ ! -z "${!cflagsname}$CFLAGS" ]; then
	echo -n "CFLAGS='${!cflagsname} $CFLAGS'"
    fi
    if [ ! -z "${!cppflagsname}$CPPFLAGS" ]; then
	echo -n " CPPFLAGS='${!cppflagsname} $CPPFLAGS'"
    fi
    if [ ! -z "${!cxxflagsname}$CXXFLAGS" ]; then
	echo -n " CXXFLAGS='${!cxxflagsname} $CXXFLAGS'"
    fi
    if [ ! -z "${!ldflagsname}$LDFLAGS" ]; then
	echo -n " LDFLAGS='${!ldflagsname} $LDFLAGS'"
    fi
}

function build_cmake() {
    repo=$1
    root=$ROOT_DIR/$(get_repo_dir $repo)
    build_call=$2
    builddir=$ROOT_DIR/$3
    rootdir=$(abspath $root)
    shift 3

    # TODO pass build_flags result to cmake 
    local flags=$(build_flags $repo)

    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	echo cd $builddir
	echo "$flags" cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
	return
    fi
    if [ -e $builddir -a ! -e $builddir/Makefile -a ! -e $builddir/build.ninja  ]; then
	echo "Recreating builddir after unfinished configure"
	run rm -rf $builddir
    fi
    if [ $DO_CLEAN == true -o ! -e "$builddir" ] ; then
        run rm -rf $builddir
        run mkdir -p $builddir
        run pushd $builddir ">/dev/null"
        run "$flags" cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
    else
        run pushd $builddir ">/dev/null"
    fi
    $build_call $rootdir $builddir
    run popd ">/dev/null"
}

function build_autoconf() {
    repo=$1
    root=$ROOT_DIR/$(get_repo_dir $repo)
    build_call=$2
    builddir=$ROOT_DIR/$3
    shift 3
    rootdir=$(abspath $root)
    configscript=$rootdir/configure

    # Read out GOLD_CPPFLAGS, NEWLIB_CPPFLAGS, ..
    local flags=$(build_flags $repo)

    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	echo cd $builddir
	echo "$flags" $configscript "$@" --prefix=${INSTALL_DIR}
	return
    fi
    if [ -e $builddir -a ! -e $builddir/Makefile ]; then
	echo "Recreating builddir after unfinished configure"
	run rm -rf $builddir
    fi
    if [ $DO_CLEAN == true -o ! -e "$builddir" ] ; then
        run rm -rf $builddir
        run mkdir -p $builddir
        run pushd $builddir ">/dev/null"
	run "$flags" $configscript "$@" --prefix=${INSTALL_DIR}
    else
        run pushd $builddir ">/dev/null"
    fi
    $build_call $rootdir $builddir
    run popd ">/dev/null"
}

function usage() {
  cat <<EOT
  Usage: $0 [-c] [-j<n>] [-p] [-i <install_dir>] [-h] [-a|<targets>]

    -c		Cleanup builds and rerun configure
    -j <n> 	Pass -j<n> to make
    -i <dir>	Set the install dir
    -h		Show this help
    -p		Create builddirs outside the source dirs
    -u		Update repositories
    -d		Dryrun, just show what would be executed
    -s		Show configure commands for all given targets
    -v		Show command that are executed
    -V		Make make verbosive
    -t		Run tests
    -a          Build llvm and do a clean build of newlib, compiler-rt and bench with tests.

  Available targets:
    $ALLTARGETS eclipse

  The command-line options override the user-config read from '$CFGFILE'.
EOT
}


function build_gold() {
    local rootdir=$1
    local builddir=$2

    if [ "$BUILD_LTO" == "true" ]; then
	run make $MAKEJ $MAKE_VERBOSE all-gold all-binutils
	local install_target="install-gold install-binutils"
    else
	run make $MAKEJ $MAKE_VERBOSE all-gold
	local install_target=install-gold
    fi

    if [ "$INSTALL_SYMLINKS" == "true" ]; then
	run mkdir -p $INSTALL_DIR/bin
	run ln -sf $builddir/gold/ld-new $INSTALL_DIR/bin/patmos-ld

	if [ "$BUILD_LTO" == "true" ]; then
	    run ln -sf $builddir/binutils/ar $INSTALL_DIR/bin/patmos-ar
	    run ln -sf $builddir/binutils/nm-new $INSTALL_DIR/bin/patmos-nm
	    run ln -sf $builddir/binutils/ranlib $INSTALL_DIR/bin/patmos-ranlib
	    run ln -sf $builddir/binutils/strip-new $INSTALL_DIR/bin/patmos-strip

	    # bin is required, otherwise auto-loading of plugins does not work!
	    run mkdir -p $builddir/bin
	    run mkdir -p $builddir/lib/bfd-plugins

	    run ln -sf $INSTALL_DIR/lib/LLVMgold.$LIBEXT $builddir/lib/bfd-plugins/
	    run ln -sf $INSTALL_DIR/lib/libLTO.$LIBEXT   $builddir/lib/bfd-plugins/
	fi
    else
	run make $MAKE_VERBOSE $install_target
    fi
}

function build_llvm() {
    local rootdir=$1
    local builddir=$2

    if [ -e build.ninja ] ; then
        run ninja
    else
        run make $MAKEJ $MAKE_VERBOSE all
    fi

    echo "Installing files .. "

    if [ "$LLVM_USE_CONFIGURE" == "true" ]; then
	builddir=$builddir/Debug+Asserts
    fi

    

    run mkdir -p $INSTALL_DIR/bin
    run mkdir -p $INSTALL_DIR/lib

    for file in `find $builddir/bin -type f`; do
	filename=`basename $file`

	# Not sure how to add a program prefix for cmake install.. so just copy what we need
	install $file $INSTALL_DIR/bin/patmos-$filename
    done
    # symlinks have to be recreated anyway
    for file in `find $builddir/bin -type l`; do
	filename=`basename $file`
	src=$(readlink $file)
	run ln -sf patmos-$(basename $src) $INSTALL_DIR/bin/patmos-$filename
    done

    # install all shared libraries
    for file in `find $builddir/lib -name "*.$LIBEXT"`; do
	install $file $INSTALL_DIR/lib/
    done

    # Install system headers
    install $builddir/lib/clang $INSTALL_DIR/lib/clang

    if [ "$BUILD_LTO" == "true" ]; then

	# bin is required, otherwise auto-loading of plugins does not work!
	run mkdir -p $INSTALL_DIR/bin
	run mkdir -p $INSTALL_DIR/lib/bfd-plugins

	run ln -sf ../LLVMgold.$LIBEXT $INSTALL_DIR/lib/bfd-plugins/
	run ln -sf ../libLTO.$LIBEXT   $INSTALL_DIR/lib/bfd-plugins/
    fi

    # install platin
    echo "Installing platin toolkit .. "
    run $rootdir/tools/platin/install.sh -i $INSTALL_DIR

    # Update rpaths, since we are not using cmake install
    update_rpath llvm

    if [ "$DO_RUN_TESTS" == "true" ]; then
	echo "Running tests.."
        run make check-all
    fi
}

function build_default() {
    run make $MAKEJ $MAKE_VERBOSE all
    run make $MAKE_VERBOSE install
}

function build_and_test_default() {
    run make $MAKEJ $MAKE_VERBOSE all
    run make $MAKE_VERBOSE install

    if [ "$DO_RUN_TESTS" == "true" ]; then
        run make test "ARGS='${CTEST_ARGS}'"
    fi
}

function build_bench() {
    # TODO if we do not have BUILD_SOFTFLOAT=true, then do not build softfloat benchmarks!

    run make $MAKEJ $MAKE_VERBOSE all

    if [ "$DO_RUN_TESTS" == "true" ]; then
        run make test "ARGS='${CTEST_ARGS}'"
    fi
}

function build_emulator() {
    repo=$1
    tmp=$2
    ctoolsbuild=$(get_build_dir patmos ctools)
    chiselbuild=$(get_build_dir patmos chisel)
    rootdir=$(abspath $ROOT_DIR/$repo)
    ctoolsbuilddir=$(abspath $ROOT_DIR/$ctoolsbuild)
    chiselbuilddir=$(abspath $ROOT_DIR/$chiselbuild)
    tmpdir=$(abspath $ROOT_DIR/$tmp)
    
    if [ $DO_CLEAN == true -o ! -e "$chiselbuilddir" ] ; then
        run rm -rf $chiselbuilddir
        run mkdir -p $chiselbuilddir
    fi
    if [ $DO_CLEAN == true -o ! -e "$tmpdir" ] ; then
        run rm -rf $tmpdir
        run mkdir -p $tmpdir
    fi
    
    run pushd "${rootdir}"
    run make $MAKEJ $MAKE_VERBOSE "BUILDDIR='${tmpdir}'" "CTOOLSBUILDDIR='${ctoolsbuilddir}'" "CHISELBUILDDIR='${chiselbuilddir}'" "CHISELINSTALLDIR='${tmpdir}'" "INSTALLDIR='${INSTALL_DIR}/bin'" emulator
    install "${chiselbuilddir}/emulator" "${INSTALL_DIR}/bin/patmos-emulator"
    install "${rootdir}/chisel/spm.t" "${INSTALL_DIR}/lib/ld-scripts/patmos_spm.t"
    run popd
}

function run_llvm_build() {
    local eclipse_args=
    local config_args="--with-bug-report-url='https://github.com/t-crest/patmos-llvm/issues'"
    local cmake_args="-DBUG_REPORT_URL='https://github.com/t-crest/patmos-llvm/issues'"
    if [ "$1"  == "eclipse" ]; then
	cmake_args="$cmake_args -G 'Eclipse CDT4 - Unix Makefiles' -DCMAKE_ECLIPSE_MAKE_ARGUMENTS=$MAKEJ -DCMAKE_ECLIPSE_VERSION='3.7 (Indigo)'"
    fi
    if [ "$LLVM_BUILD_SHARED" == "true" ]; then
	config_args="$config_args --enable-shared"
	cmake_args="$cmake_args -DBUILD_SHARED_LIBS=ON"
    fi

    if [ "$LLVM_USE_CONFIGURE" == "true" -a "$1" != "eclipse" ]; then
	targets=$(echo $LLVM_TARGETS | tr '[A-Z;]' '[a-z,]')
	build_autoconf llvm build_llvm $(get_build_dir llvm) "--disable-optimized --enable-assertions --enable-targets=$targets $config_args $LLVM_CONFIGURE_ARGS"
    else
	build_cmake llvm build_llvm $(get_build_dir llvm) "-DCMAKE_BUILD_TYPE=Debug -DLLVM_TARGETS_TO_BUILD='$LLVM_TARGETS' $cmake_args $LLVM_CMAKE_ARGS"
    fi
}


build_target() {
  local target=$1

  if [ "$DO_SHOW_CONFIGURE" ]; then
    info "Configure for '$target'"
  else
    info "Processing '"$target"'"
  fi
  case $target in
  'llvm')
    clone_update ${GITHUB_BASEURL}/patmos-llvm.git $(get_repo_dir llvm)
    if [ "$LLVM_OMIT_CLANG" != "true" ]; then
        clone_update ${GITHUB_BASEURL}/patmos-clang.git $(get_repo_dir llvm)/tools/clang
    fi
    run_llvm_build
    ;;
  'eclipse')
    run_llvm_build eclipse
    ;;
  'gold')
    clone_update ${GITHUB_BASEURL}/patmos-gold.git $(get_repo_dir gold)
    build_autoconf gold build_gold $(get_build_dir gold) --program-prefix=patmos- --enable-gold=yes --enable-ld=no "$GOLD_ARGS"
    ;;
  'newlib')
    clone_update ${GITHUB_BASEURL}/patmos-newlib.git $(get_repo_dir newlib)
    build_autoconf newlib build_default $(get_build_dir newlib) --target=$TARGET AR_FOR_TARGET=${INSTALL_DIR}/bin/$NEWLIB_AR \
        RANLIB_FOR_TARGET=${INSTALL_DIR}/bin/$NEWLIB_RANLIB LD_FOR_TARGET=${INSTALL_DIR}/bin/patmos-clang \
        CC_FOR_TARGET=${INSTALL_DIR}/bin/patmos-clang  "CFLAGS_FOR_TARGET='-target ${TARGET} -O2 ${NEWLIB_TARGET_CFLAGS}'" "$NEWLIB_ARGS"
    ;;
  'compiler-rt')
    clone_update ${GITHUB_BASEURL}/patmos-compiler-rt.git $(get_repo_dir compiler-rt)
    repo=$(get_repo_dir compiler-rt)
    build_cmake compiler-rt build_default $(get_build_dir compiler-rt) "-DTRIPLE=${TARGET} -DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/$repo/cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  'patmos'|'pasim')
    clone_update ${GITHUB_BASEURL}/patmos.git $(get_repo_dir patmos)
    info "Building simulator in patmos .. "
    build_cmake patmos/simulator build_and_test_default $(get_build_dir patmos simulator) "$PASIM_ARGS"
    info "Building ctools in patmos .. "
    build_cmake patmos/ctools    build_default $(get_build_dir patmos ctools) "$CTOOLS_ARGS"
    if [ "$BUILD_EMULATOR" == "false" ]; then
	info "Skipping patmos-emulator in patmos."
    else
	info "Building patmos-emulator in patmos .."
	build_emulator $(get_repo_dir patmos) $(get_build_dir patmos)/tmp
    fi
    ;;
  'bench')
    repo=$(get_repo_dir bench)
    if [ -z "$BENCH_REPO_URL" ]; then
      if [ -d $ROOT_DIR/$repo ]; then
	echo "Skipped updating of benchmark repository, BENCH_REPO_URL is not set."
      else
        echo "Benchmark repository URL is not configured, skipped. Set BENCH_REPO_URL to enable."
      fi
    else
      clone_update $BENCH_REPO_URL $(get_repo_dir bench)
    fi
    if [ -d $ROOT_DIR/$repo ]; then
      build_cmake bench build_bench $(get_build_dir bench) "-DTRIPLE=${TARGET} -DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/$repo/cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin" "$BENCH_ARGS"
    fi
    ;;
  *) echo "Don't know about $target." ;;
  esac
}



# one-shot config
while getopts ":chi:j:pudsvxVtae" opt; do
  case $opt in
    c) DO_CLEAN=true ;;
    h) usage; exit 0 ;;
    i) INSTALL_DIR="$(abspath $OPTARG)" ;;
    j) MAKEJ="-j$OPTARG" ;;
    p) BUILDDIR_SUBDIR=false ;;
    u) DO_UPDATE=true ;;
    d) DRYRUN=true; VERBOSE=true ;;
    s) DO_SHOW_CONFIGURE=true ;;
    v) VERBOSE=true ;;
    V) MAKE_VERBOSE="VERBOSE=1" ;;
    t) DO_RUN_TESTS=true ;;
    a) DO_RUN_ALL=true ;;
    x) set -x ;;
    e) # recreate build.cfg.dist
       cat build.sh | sed -n '/##* Start of user configs/,/##* End of user configs/p' | sed "$ d" | sed "/Start of user configs/d" > build.cfg.dist 
       exit
       ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))



# not config'able
GITHUB_BASEURL=https://github.com/t-crest

LIBEXT=so
if [ "$OS_NAME" == "Darwin" ]; then
    LIBEXT=dylib
fi

if [ "$GOLD_TARGET_ARCH" == "auto" ]; then
    if [ "$OS_NAME" != "Linux" ]; then
	# TODO should we use $TARGET instead here? Precise target should not matter though, as long as it is patmos.
	GOLD_ARGS="$GOLD_ARGS --target=patmos-unknown-unknown-elf"
    fi
elif [ "$GOLD_TARGET_ARCH" != "none" ]; then
    GOLD_ARGS="$GOLD_ARGS --target='$GOLD_TARGET_ARCH'"
fi

if [ "$BUILD_LTO" == "true" ]; then
    golddir=$(get_repo_dir gold)
    LLVM_CMAKE_ARGS="$LLVM_CMAKE_ARGS -DLLVM_BINUTILS_INCDIR=$ROOT_DIR/$golddir/include"
    LLVM_CONFIGURE_ARGS="$LLVM_CONFIGURE_ARGS --with-binutils-include=$ROOT_DIR/$golddir/include"
    GOLD_ARGS="$GOLD_ARGS --enable-plugins"
    NEWLIB_AR=patmos-ar
    NEWLIB_RANLIB=patmos-ranlib
else
    NEWLIB_AR=patmos-llvm-ar
    NEWLIB_RANLIB=patmos-llvm-ranlib
fi

if [ ! -z "$CLANG_COMPILER" ]; then
    clang=$(which $CLANG_COMPILER 2>/dev/null || echo -n "")
    if [ -x "$clang" ]; then
	if $clang -v 2>&1 | grep 'clang version 3.0' > /dev/null; then
	    echo "Clang version >= 3.1 required!"
	else
	    LLVM_CMAKE_ARGS="$LLVM_CMAKE_ARGS -DCMAKE_C_COMPILER=$CLANG_COMPILER -DCMAKE_CXX_COMPILER=$CLANG_COMPILER++"
	    PASIM_ARGS="$PASIM_ARGS -DCMAKE_C_COMPILER=$CLANG_COMPILER -DCMAKE_CXX_COMPILER=$CLANG_COMPILER++"
	fi
    else 
	echo "Clang $clang is not executable, igored!"
    fi
fi

if [ "$INSTALL_RPATH" == "build" ]; then
    LLVM_LDFLAGS="$LLVM_LDFLAGS -Wl,-R${INSTALL_DIR}/lib"
fi

if [ "$BUILD_SOFTFLOAT" != "true" ]; then
    NEWLIB_ARGS="--disable-newlib-io-float $NEWLIB_ARGS"
fi

mkdir -p "${INSTALL_DIR}"

if [ "$DO_RUN_ALL" == "true" ]; then
    build_target llvm
    build_target patmos
    DO_CLEAN=true
    DO_RUN_TESTS=true
    build_target compiler-rt
    build_target newlib
    build_target bench
else
    TARGETS=${@-$ALLTARGETS}
    for target in $TARGETS; do
	build_target $target
    done
fi

