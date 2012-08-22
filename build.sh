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


function clone_update() {
    if [ ! -d "$2" ] ; then
	info "Cloning from $1"
	git clone "$1" "$2"
    elif [ ${DO_UPDATE} != false ] ; then
        #TODO find a better way (e.g. stash away only on demand)
	info "Updating $2"
        pushd "$2" > /dev/null
        git stash
        git pull --rebase
        git stash pop
        popd > /dev/null
    fi
}

function build_cmake() {
    root=$1
    builddir="${root}${BUILDDIR_SUFFIX}"
    rootdir=$(readlink -f $root)
    shift
    if [ $DO_CLEAN == true -o ! -e "$builddir" ] ; then
        rm -rf $builddir
        mkdir -p $builddir
        pushd $builddir > /dev/null
        cmake $@ -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} $rootdir
    else
        pushd $builddir > /dev/null
    fi
    make $MAKEJ && make install
    popd > /dev/null
}

function build_autoconf() {
    root=$1
    targets="$2"
    shift 2
    builddir="${root}${BUILDDIR_SUFFIX}"
    configscript=$(readlink -f $root/configure)
    clean_dir $builddir
    pushd $builddir > /dev/null
    if [ $DO_CLEAN == true ] ; then
	$configscript "$@" --prefix=${INSTALL_DIR}
    fi
    make $targets
    popd > /dev/null
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

  Available targets:
    $ALLTARGETS

  The command-line options override the user-config read from '$CFGFILE'.
EOT
}

ALLTARGETS="gold llvm clang newlib compiler-rt pasim bench"
CFGFILE=build.cfg

# default config
INSTALL_DIR="$(pwd)/local"
BUILDDIR_SUFFIX="/build"
MAKEJ= # only for cmake'd builds (newlib's make is not happy with -j)
DO_CLEAN=false
DO_UPDATE=false
# not yet
LLVM_TARGETS=Patmos




# user config
if [ -f $CFGFILE ]; then
  source $CFGFILE
fi


# one-shot config
while getopts ":chi:j:pu" opt; do
  case $opt in
    c) DO_CLEAN=true ;;
    h) usage; exit 0 ;;
    i) INSTALL_DIR="$(readlink -f $OPTARG)" ;;
    j) MAKEJ="-j$OPTARG" ;;
    p) BUILDDIR_SUFFIX="-build" ;;
    u) DO_UPDATE=true ;;
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

mkdir -p "${INSTALL_DIR}"

TARGETS=${@-$ALLTARGETS}
for target in $TARGETS; do
  info "Processing '"$target"'"
  case $target in
  'llvm')
    clone_update ${GITHUB_BASEURL}/patmos-llvm.git llvm
    if ! expr "$TARGETS" : ".*\<clang\>.*" > /dev/null; then
      build_cmake llvm "-DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DCMAKE_BUILD_TYPE=Debug"
    fi
    ;;
  'clang')
    clone_update ${GITHUB_BASEURL}/patmos-clang.git llvm/tools/clang
    build_cmake llvm "-DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DCMAKE_BUILD_TYPE=Debug"
    ;;
  'gold')
    clone_update ${GITHUB_BASEURL}/patmos-gold.git gold
    build_autoconf gold "all-gold install-gold" --program-prefix=patmos- --enable-gold=yes --enable-ld=no -enable-plugins
    ;;
  'newlib')
    clone_update ${GITHUB_BASEURL}/patmos-newlib.git newlib
    build_autoconf newlib "all install" --target=patmos-unknown-elf AR_FOR_TARGET=${INSTALL_DIR}/bin/llvm-ar \
        RANLIB_FOR_TARGET=${INSTALL_DIR}/bin/llvm-ranlib LD_FOR_TARGET=${INSTALL_DIR}/bin/llvm-ld \
        CC_FOR_TARGET=${INSTALL_DIR}/bin/clang  CFLAGS_FOR_TARGET='-ccc-host-triple patmos-unknown-elf -O2'
    ;;
  'compiler-rt')
    clone_update ${GITHUB_BASEURL}/patmos-compiler-rt.git compiler-rt
    build_cmake compiler-rt "-DCMAKE_TOOLCHAIN_FILE=../cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  'pasim')
    clone_update https://github.com/schoeberl/patmos.git patmos
    build_cmake patmos/simulator
    ;;
  'bench')
    clone_update ssh+git://tipca/home/fbrandne/repos/patmos-benchmarks bench
    build_cmake bench "-DCMAKE_TOOLCHAIN_FILE=../cmake/patmos-clang-toolchain.cmake -DCMAKE_PROGRAM_PATH=${INSTALL_DIR}/bin"
    ;;
  *) echo "Don't know about $target." ;;
  esac
done


