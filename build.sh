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

function info() {
    echo -e "\033[32m ===== $1 ===== \033[0m" >&2
}

run() {
    if [ "$DRYRUN" != "true" ]; then
	eval $@
	ret=$?
	if [ $ret != 0 ]; then
	    echo "$@ failed ($ret)!"
	    return $ret
	fi
    elif [ "$VERBOSE" == "true" ]; then
	echo "$@"
    fi
}

function clone_update() {
    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	return
    fi
    if [ ! -d "$2" ] ; then
	info "Cloning from $1"
	run git clone "$1" "$ROOT_DIR/$2"
    elif [ ${DO_UPDATE} != false ] ; then
        #TODO find a better way (e.g. stash away only on demand)
	info "Updating $2"
        pushd "$ROOT_DIR/$2" > /dev/null
        run git stash
        run git pull --rebase
        run git stash pop
        popd > /dev/null
    fi
}

function build_cmake() {
    root=$ROOT_DIR/$1
    build_call=$2
    builddir=$ROOT_DIR/$3
    rootdir=$(readlink -f $root)
    shift 3
    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	echo cd $builddir
	echo cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
	return
    fi
    if [ ! -e $builddir/Makefile ]; then
	echo "Recreating builddir after unfinished configure"
	run rm -rf $builddir
    fi
    if [ $DO_CLEAN == true -o ! -e "$builddir" ] ; then
        run rm -rf $builddir
        run mkdir -p $builddir
        run pushd $builddir > /dev/null
        run cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
	# TODO check if configure was sucessful
    else
        run pushd $builddir > /dev/null
    fi
    $build_call $rootdir $builddir
    run popd > /dev/null
}

function build_autoconf() {
    root=$ROOT_DIR/$1
    build_call=$2
    builddir=$ROOT_DIR/$3
    shift 3
    rootdir=$(readlink -f $root)
    configscript=$rootdir/configure
    if [ "$DO_SHOW_CONFIGURE" == "true" ]; then
	echo cd $builddir
	echo $configscript "$@" --prefix=${INSTALL_DIR}
	return
    fi
    if [ ! -e $builddir/Makefile ]; then
	echo "Recreating builddir after unfinished configure"
	run rm -rf $builddir
    fi
    if [ $DO_CLEAN == true -o ! -e "$builddir" ] ; then
        run rm -rf $builddir
        run mkdir -p $builddir
        run pushd $builddir > /dev/null
	run $configscript "$@" --prefix=${INSTALL_DIR}
	# TODO check if configure was sucessful
    else
        run pushd $builddir > /dev/null
    fi
    $build_call $rootdir $builddir
    run popd > /dev/null
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

  Available targets:
    $ALLTARGETS eclipse

  The command-line options override the user-config read from '$CFGFILE'.
EOT
}


function build_gold() {
    local rootdir=$1
    local builddir=$2

    if [ "$BUILD_LTO" == "true" ]; then
	run make $MAKEJ all || exit 1
	local install_target=install
    else
	run make $MAKEJ all-gold || exit 1
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
	fi
    else 
	run make $install_target || exit 1
    fi
}

function build_llvm() {
    local rootdir=$1
    local builddir=$2
    
    run make $MAKEJ all || exit 1

    if [ "$INSTALL_SYMLINKS" ]; then
	cmd="ln -sf"
	gold_installdir=$INSTALL_DIR/
    else
	# Not sure how to add a program prefix for cmake install.. so just copy what we need
	cmd="cp -afv"
	gold_installdir=$INSTALL_DIR/
    fi

    echo "Installing files .. "

    for file in `find $builddir/bin -type f -o -type l`; do
	filename=`basename $file`
	run rm -rf $INSTALL_DIR/bin/patmos-$filename
	run $cmd $file $INSTALL_DIR/bin/patmos-$filename
    done

    # TODO install LLVMgold.so and libLTO.so
    if [ "$BUILD_LTO" == "true" ]; then
		
	# bin is required, otherwise auto-loading of plugins does not work!
	run mkdir -p $gold_installdir/bin
	run mkdir -p $gold_installdir/lib/bfd-plugins

	run $cmd $builddir/lib/LLVMgold.so $INSTALL_DIR/lib/
	run $cmd $builddir/lib/libLTO.so   $INSTALL_DIR/lib/

	run ln -sf $INSTALL_DIR/lib/LLVMgold.so $gold_installdir/lib/bfd-plugins/
	run ln -sf $INSTALL_DIR/lib/libLTO.so   $gold_installdir/lib/bfd-plugins/
    fi

}

function build_default() {
    run make $MAKEJ all || exit 1
    run make install || exit 1
}

function build_bench() {
    run make $MAKEJ all || exit 1

    # TODO run tests, or make separate, optional target to run tests
}


ALLTARGETS="gold llvm clang newlib compiler-rt pasim bench"
CFGFILE=build.cfg

########### user configs, overwrite in build.cfg ##############

#local_dir=`dirname $0` 
#ROOT_DIR=`readlink -f $local_dir`
ROOT_DIR=$(pwd)

INSTALL_DIR="$ROOT_DIR/local"
BUILDDIR_SUFFIX="/build"

#LLVM_TARGETS=all
LLVM_TARGETS=Patmos
ECLIPSE_LLVM_TARGETS=Patmos

# Set to the name of the clang binary to use for compiling LLVM
# or leave empty to use cmake defaults
CLANG_COMPILER=clang

# Build gold binutils and LLVM LTO plugin
BUILD_LTO=true

# Create symlinks instead of copying files where applicable
# (llvm, clang, gold)
INSTALL_SYMLINKS=false

# Additional arguments for cmake / configure
LLVM_CMAKE_ARGS=
GOLD_ARGS=

MAKEJ= 

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


# one-shot config
while getopts ":chi:j:puds" opt; do
  case $opt in
    c) DO_CLEAN=true ;;
    h) usage; exit 0 ;;
    i) INSTALL_DIR="$(readlink -f $OPTARG)" ;;
    j) MAKEJ="-j$OPTARG" ;;
    p) BUILDDIR_SUBDIR=false ;;
    u) DO_UPDATE=true ;;
    d) DRYRUN=true; VERBOSE=true ;;
    s) DO_SHOW_CONFIGURE=true ;;
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
    LLVM_CMAKE_ARGS="$LLVM_CMAKE_ARGS -DLLVM_BINUTILS_INCDIR=$ROOT_DIR/gold/include"
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
    clone_update ${GITHUB_BASEURL}/patmos-llvm.git llvm
    if ! expr "$TARGETS" : ".*\<clang\>.*" > /dev/null; then
      build_cmake llvm build_llvm llvm$BUILDDIR_SUFFIX "-DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DCMAKE_BUILD_TYPE=Debug $LLVM_CMAKE_ARGS"
    fi
    ;;
  'clang')
    clone_update ${GITHUB_BASEURL}/patmos-clang.git llvm/tools/clang
    # TODO optionally use configure to build LLVM, for testing purposes!
    build_cmake llvm build_llvm llvm$BUILDDIR_SUFFIX "-DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DCMAKE_BUILD_TYPE=Debug $LLVM_CMAKE_ARGS"
    ;;
  'eclipse')
    # TODO add options to use Eclipse generator, ensure g++ is used to compile
    build_cmake llvm build_llvm llvm-eclipse$BUILDDIR_SUFFIX "-DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DCMAKE_BUILD_TYPE=Debug $LLVM_CMAKE_ARGS"
    ;;
  'gold')
    clone_update ${GITHUB_BASEURL}/patmos-gold.git gold
    build_autoconf gold build_gold gold$BUILDDIR_SUFFIX --program-prefix=patmos- --enable-gold=yes --enable-ld=no $GOLD_ARGS
    ;;
  'newlib')
    clone_update ${GITHUB_BASEURL}/patmos-newlib.git newlib
    build_autoconf newlib build_default newlib$BUILDDIR_SUFFIX --target=patmos-unknown-elf AR_FOR_TARGET=${INSTALL_DIR}/bin/$NEWLIB_AR \
        RANLIB_FOR_TARGET=${INSTALL_DIR}/bin/$NEWLIB_RANLIB LD_FOR_TARGET=${INSTALL_DIR}/bin/llvm-ld \
        CC_FOR_TARGET=${INSTALL_DIR}/bin/clang  "CFLAGS_FOR_TARGET='-ccc-host-triple patmos-unknown-elf -O2'"
    ;;
  'compiler-rt')
    clone_update ${GITHUB_BASEURL}/patmos-compiler-rt.git compiler-rt
    build_cmake compiler-rt build_default compiler-rt$BUILDDIR_SUFFIX "-DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/compiler-rt/cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  'pasim')
    clone_update https://github.com/schoeberl/patmos.git patmos
    if expr "$BUILDDIR_SUFFIX" : "/" > /dev/null; then
	builddir=patmos$BUILDDIR_SUFFIX/simulator
    else
	builddir=patmos/simulator$BUILDDIR_SUFFIX
    fi
    build_cmake patmos/simulator build_default $builddir
    ;;
  'bench')
    clone_update ssh+git://tipca.imm.dtu.dk/home/fbrandne/repos/patmos-benchmarks bench
    build_cmake bench build_bench bench$BUILDDIR_SUFFIX "-DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/bench/cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  *) echo "Don't know about $target." ;;
  esac
done


