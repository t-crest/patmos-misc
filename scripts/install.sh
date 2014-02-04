#!/bin/bash
# This is a simple install.sh clone that checks for modification time before
# installing a file to prevent recompiling dependent files.

OS_NAME=$(uname -s)
MODE=
UPDATE=

function install() {
    # if $src is a directory, $dst must be the target directory, not the parent directory!
    local src=$1
    local dst=$2

    if [ -f $src -a -d $dst ]; then
        dst=$dst/$(basename $src)
    fi

    mkdir -p $(dirname $dst)

    echo "Installing $src -> $dst"

    if [ -L $dst ]; then
	rm -f $dst
    fi
    
    if [ "$OS_NAME" == "Linux" ]; then
	cp $UPDATE -faT $src $dst
    else
	if [ -e $dst ]; then
	    rm -rf $dst
	fi
	cp -fR $src $dst
    fi
    if [ ! -z $MODE ]; then
	chmod $MODE $dst
    fi
}

src=
last=

# Separate source and dest arguments
while [ "$1" != "" ]; do
    
    if [ "$1" == "-m" ]; then
	shift
	MODE=$1
    elif [ "$1" == "-u" ]; then
	UPDATE="-u"
    else
	if [ "$last" != "" ]; then
	    src="$src $last"
	fi
	last=$1
    fi

    shift
done

dst="$last"

for i in $src; do
    install $i $dst
done

