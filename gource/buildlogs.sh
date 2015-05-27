#!/bin/bash
# 
# Author: Stefan Hepp <stefan@stefant.org>
#
# Run in target directory to create a merged custom-log, then run gource with
#
#   gource -s 1 --highlight-users tcrest.log.all
#
# Try --hide-roots to separate the repositories, but there seems to be a bug/unintuitive behaviour with it.
#
# TODO Add other t-crest repositories
# TODO Add caption file containing main events (reviews, major changes)
#

### Setup config

# TODO Copied from build.sh, move to common library (including defaults)

ROOT_DIR=../..
REPO_NAMES=short
REPO_PREFIX=

if [ -e ../build.cfg ]; then
  . ../build.cfg
fi


# 
# Get the source directory name for a repository, relative to the rootdir.
#
# This function expects the same arguments as get_build_dir, just that subdirectories
# are separeted by '/' instead of being passed as separate directory.
#
function get_repo_dir() {
    # name of the repository (not a directory name)
    local repo=$1

    # TODO if subdir is set to empty, we could instead make a flat hierarchy,
    #      i.e., check out patmos-rtems, patmos-rtems-examples, patmos-rtems-compiler-rt, ..
    #      Needs to be consistent with get_build_dir.
    if [ ! -z "$RTEMS_SUBDIR_PREFIX" ]; then
        case $repo in
        rtems/rtems)
            repo=rtems/${RTEMS_SUBDIR_PREFIX}
            ;;
        rtems/examples)
            repo=rtems/${RTEMS_SUBDIR_PREFIX}-examples
            ;;
        *) ;;
        esac
    fi

    case $REPO_NAMES in
    short)
        echo $repo
        ;;
    long)
        case $repo in
        patmos)   echo "patmos" ;;
        patmos/*) echo $repo ;;
        bench)    echo "patmos-benchmarks" ;;
        *)        echo "patmos-"$repo ;;
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


## Build initial logs
for repo in patmos llvm clang newlib compiler-rt gold bench misc; do
  echo "** Building log for $repo .."
  gource --output-custom-log ${repo}.log ${ROOT_DIR}/$(get_repo_dir $repo)
  sed -i -r "s#(.+)\|#\1|/${repo}#" ${repo}.log
done

## Strip initial commits
echo "** Stripping initial commits .."
mkdir -p full
for repo in llvm clang compiler-rt newlib gold bench; do
  cp -f ${repo}.log full/${repo}.log
done

awk 'BEGIN { FS="|"; } $1 > 1393009889' full/llvm.log > llvm.log
awk 'BEGIN { FS="|"; } $1 > 1337051500' full/clang.log > clang.log
awk 'BEGIN { FS="|"; } $1 > 1371083221' full/bench.log > bench.log
awk 'BEGIN { FS="|"; } $1 > 1340021667' full/newlib.log > newlib.log
awk 'BEGIN { FS="|"; } $1 > 1341407163' full/compiler-rt.log > compiler-rt.log
awk 'BEGIN { FS="|"; } $1 > 1340722550' full/gold.log > gold.log

## Merge logs
echo "** Merging logs .."
cat *.log | sort -n > tcrest.log.all

