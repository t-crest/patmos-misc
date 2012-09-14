#!/bin/bash
#
# Rename executables in specified dir to have 'patmos-' prefix
# and recreate local links to the renamed executables
#
# Most probably you want to do that in your Patmos <install_dir>/bin
# if you did not use the build.sh script
#
# Daniel Prokesch <daniel@vmars.tuwien.ac.at>
#

DIR=${1:-.}
EXCEPT="pasim"

if [ ! -d $DIR ]; then
  echo "Error: Directory '"$DIR"' does not exist!" 1>&2
  exit 1
fi

if [[ ! $(cd $DIR ; pwd) =~ /bin$ ]]; then
  echo "Error: Directory does not end in '/bin'!" 1>&2
  exit 1
fi

# following function only works for local links to local targets within $DIR
function _sc_relink {
  local bname="${1##*/}"
  if [[ ! $bname =~ ^patmos- && ! $EXCEPT =~ $(echo "\<$bname\>") ]]; then
    echo "Relink $bname" 1>&2
    ln -s -T "patmos-$(readlink $1)" "${1%/*}/patmos-$bname"
    rm $1
  else
    echo "Skip $bname" 1>&2
  fi
}

function _sc_rename {
  local bname="${1##*/}"
  if [[ ! $bname =~ ^patmos- && ! $EXCEPT =~ $(echo "\<$bname\>") ]]; then
    echo "Rename $bname" 1>&2
    mv "$1" "${1%/*}/patmos-$bname"
  else
    echo "Skip $bname" 1>&2
  fi
}

export -f _sc_relink _sc_rename
export EXCEPT

find -P $DIR -type l -executable -exec bash -c '_sc_relink {}' \;
find -P $DIR -type f -executable -exec bash -c '_sc_rename {}' \;
