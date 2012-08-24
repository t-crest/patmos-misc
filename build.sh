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

self=`readlink -f $0`
CFGFILE=`dirname $self`/build.cfg

########### user configs, overwrite in build.cfg ##############

ALLTARGETS="gold llvm clang newlib compiler-rt pasim bench"

#local_dir=`dirname $0`
#ROOT_DIR=`readlink -f $local_dir`
ROOT_DIR=$(pwd)

# Set to 'short' for llvm/clang/... directory names, 'long' for
# patmos-llvm/patmos-clang/.. or 'prefix' to use $(REPO_PREFIX)llvm/..
REPO_NAMES=short
REPO_PREFIX=

INSTALL_DIR="$ROOT_DIR/local"
BUILDDIR_SUFFIX="/build"

#LLVM_TARGETS=all
LLVM_TARGETS=Patmos
ECLIPSE_LLVM_TARGETS=Patmos

# build LLVM using configure instead of cmake
LLVM_USE_CONFIGURE=false

# Set to the name of the clang binary to use for compiling LLVM itself.
# Leave empty to use cmake defaults
CLANG_COMPILER=clang

# Build gold binutils and LLVM LTO plugin
BUILD_LTO=true

# Create symlinks instead of copying files where applicable
# (llvm, clang, gold)
INSTALL_SYMLINKS=false

# Additional arguments for cmake / configure
LLVM_CMAKE_ARGS=
LLVM_CONFIGURE_ARGS=
GOLD_ARGS=

GOLD_CFLAGS=
GOLD_CXXFLAGS=
NEWLIB_CFLAGS=

MAKEJ=
MAKE_VERBOSE=

DO_CLEAN=false
DO_UPDATE=false
DO_SHOW_CONFIGURE=false
DRYRUN=false
VERBOSE=false

#################### End of user configs #####################

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

    if [ "$repo" == "patmos" ]; then
	if [[ "$BUILDDIR_SUFFIX" =~ ^/ ]]; then
	    builddir=$repodir/simulator$BUILDDIR_SUFFIX
	else
	    builddir=$repodir$BUILDDIR_SUFFIX/simulator
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
        if [ "$DRYRUN" != "true" ]; then
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
        if [ "$DRYRUN" != "true" ]; then
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

    if [ ! -z "${!cflagsname}$CFLAGS" ]; then
	echo -n "CFLAGS='${!cflagsname} $CFLAGS'"
    fi
    if [ ! -z "${!cppflagsname}$CPPFLAGS" ]; then
	echo -n " CPPFLAGS='${!cflagsname} $CPPFLAGS'"
    fi
    if [ ! -z "${!cxxflagsname}$CXXFLAGS" ]; then
	echo -n " CXXFLAGS='${!cflagsname} $CXXFLAGS'"
    fi
}

function build_cmake() {
    repo=$1
    root=$ROOT_DIR/$(get_repo_dir $repo)
    build_call=$2
    builddir=$ROOT_DIR/$3
    rootdir=$(readlink -f $root || echo $root)
    shift 3

    # TODO pass build_flags result to cmake 

    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	echo cd $builddir
	echo cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
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
        run cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
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
    rootdir=$(readlink -f $root || echo $root)
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
  Usage: $0 [-c] [-j<n>] [-p] [-i <install_dir>] [-h] [<targets>]

    -c		Cleanup builds and rerun configure
    -j<n> 	Pass -j<n> to make
    -i <dir>	Set the install dir
    -h		Show this help
    -p		Create builddirs outside the source dirs
    -u		Update repositories
    -d		Dryrun, just show what would be executed
    -s		Show configure commands for all given targets
    -v		Show command that are executed
    -V		Make make verbosive

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

	    run ln -sf $INSTALL_DIR/lib/LLVMgold.so $builddir/lib/bfd-plugins/
	    run ln -sf $INSTALL_DIR/lib/libLTO.so   $builddir/lib/bfd-plugins/
	fi
    else
	run make $MAKE_VERBOSE $install_target
    fi
}

function build_llvm() {
    local rootdir=$1
    local builddir=$2

    run make $MAKEJ $MAKE_VERBOSE all

    if [ "$INSTALL_SYMLINKS" == "true" ]; then
	cmd="ln -sf"
    else
	# Not sure how to add a program prefix for cmake install.. so just copy what we need
	cmd="cp -afv"
    fi

    echo "Installing files .. "

    if [ "$LLVM_USE_CONFIGURE" == "true" ]; then
	builddir=$builddir/Debug+Asserts
    fi

    for file in `find $builddir/bin -type f`; do
	filename=`basename $file`
	run $cmd $file $INSTALL_DIR/bin/patmos-$filename
    done
    # symlinks have to be recreated anyway
    for file in `find $builddir/bin -type l`; do
	filename=`basename $file`
	run "ln -sf" $file $INSTALL_DIR/bin/patmos-$filename
    done

    # TODO install LLVMgold.so and libLTO.so
    if [ "$BUILD_LTO" == "true" ]; then

	run $cmd $builddir/lib/LLVMgold.so $INSTALL_DIR/lib/
	run $cmd $builddir/lib/libLTO.so   $INSTALL_DIR/lib/

	# bin is required, otherwise auto-loading of plugins does not work!
	run mkdir -p $INSTALL_DIR/bin
	run mkdir -p $INSTALL_DIR/lib/bfd-plugins

	run ln -sf ../LLVMgold.so $INSTALL_DIR/lib/bfd-plugins/
	run ln -sf ../libLTO.so   $INSTALL_DIR/lib/bfd-plugins/
    fi

}

function build_default() {
    run make $MAKEJ $MAKE_VERBOSE all
    run make $MAKE_VERBOSE install
}

function build_bench() {
    run make $MAKEJ $MAKE_VERBOSE all

    # TODO run tests, or make separate, optional target to run tests
}


function run_llvm_build() {
    local eclipse_args=
    if [ "$1"  == "eclipse" ]; then
	eclipse_args="-G 'Eclipse CDT4 - Unix Makefiles' "
    fi

    if [ "$LLVM_USE_CONFIGURE" == "true" -a "$1" != "eclipse" ]; then
	targets=$(echo $LLVM_TARGETS | tr '[:upper:]' '[:lower:]')
	build_autoconf llvm build_llvm $(get_build_dir llvm) "--disable-optimized --enable-assertions --enable-targets=$targets $LLVM_CONFIGURE_ARGS"
    else
	build_cmake llvm build_llvm $(get_build_dir llvm) "-DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DCMAKE_BUILD_TYPE=Debug $LLVM_CMAKE_ARGS $eclipse_args"
    fi
}



# one-shot config
while getopts ":chi:j:pudsvxV" opt; do
  case $opt in
    c) DO_CLEAN=true ;;
    h) usage; exit 0 ;;
    i) INSTALL_DIR="$(readlink -f $OPTARG)" ;;
    j) MAKEJ="-j$OPTARG" ;;
    p) BUILDDIR_SUBDIR=false ;;
    u) DO_UPDATE=true ;;
    d) DRYRUN=true; VERBOSE=true ;;
    s) DO_SHOW_CONFIGURE=true ;;
    v) VERBOSE=true ;;
    V) MAKE_VERBOSE="VERBOSE=1" ;;
    x) set -x ;;
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
    clang=`which $CLANG_COMPILER 2>/dev/null`
    if [ -x $clang ]; then
	LLVM_CMAKE_ARGS="$LLVM_CMAKE_ARGS -DCMAKE_C_COMPILER=$CLANG_COMPILER -DCMAKE_CXX_COMPILER=$CLANG_COMPILER++"
    fi
fi

mkdir -p "${INSTALL_DIR}"

TARGETS=${@-$ALLTARGETS}
for target in $TARGETS; do
  if [ "$DO_SHOW_CONFIGURE" ]; then
    info "Configure for '$target'"
  else
    info "Processing '"$target"'"
  fi
  case $target in
  'llvm')
    clone_update ${GITHUB_BASEURL}/patmos-llvm.git $(get_repo_dir llvm)
    if ! expr "$TARGETS" : ".*\<clang\>.*" > /dev/null; then
	run_llvm_build
    fi
    ;;
  'clang')
    clone_update ${GITHUB_BASEURL}/patmos-clang.git $(get_repo_dir llvm)/tools/clang
    # TODO optionally use configure to build LLVM, for testing purposes!
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
    build_autoconf newlib build_default $(get_build_dir newlib) --target=patmos-unknown-elf AR_FOR_TARGET=${INSTALL_DIR}/bin/$NEWLIB_AR \
        RANLIB_FOR_TARGET=${INSTALL_DIR}/bin/$NEWLIB_RANLIB LD_FOR_TARGET=${INSTALL_DIR}/bin/patmos-clang \
        CC_FOR_TARGET=${INSTALL_DIR}/bin/patmos-clang  "CFLAGS_FOR_TARGET='-ccc-host-triple patmos-unknown-elf -O2'"
    ;;
  'compiler-rt')
    clone_update ${GITHUB_BASEURL}/patmos-compiler-rt.git $(get_repo_dir compiler-rt)
    repo=$(get_repo_dir compiler-rt)
    build_cmake compiler-rt build_default $(get_build_dir compiler-rt) "-DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/$repo/cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  'patmos'|'pasim')
    clone_update https://github.com/schoeberl/patmos.git $(get_repo_dir patmos)
    build_cmake patmos/simulator build_default $(get_build_dir patmos)
    ;;
  'bench')
    clone_update ssh+git://tipca.imm.dtu.dk/home/fbrandne/repos/patmos-benchmarks $(get_repo_dir bench)
    repo=$(get_repo_dir bench)
    build_cmake bench build_bench $(get_build_dir bench) "-DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/$repo/cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  *) echo "Don't know about $target." ;;
  esac
done


