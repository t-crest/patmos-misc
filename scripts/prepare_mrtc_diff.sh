#!/usr/bin/env bash

# Helper script to diff the Maelardalen benchmarks as they are available on the
# mdh.se website and part of the TACLeBench package.

MDH_URL=http://www.mrtc.mdh.se/projects/wcet/wcet_bench.zip
TACLE_URL=https://wcc-web.informatik.uni-ulm.de/TACLeBench/TACLeBench.tar.gz
CLANG_FORMAT=patmos-clang-format
DEPS="wget unzip sed $CLANG_FORMAT"

# actually don't download when dest exists
# args: url, dest
function download
{
	if [ -f $2 ]; then
		echo -e "$2 exists, not downloading"
		return
	fi

	echo -e "downloading $1 ..."
	wget $1 -O $2
    if [ $? -ne 0 ]; then
        echo -e "Error: failed to download $1"
        exit 1
    fi
}

function unpack
{
	echo -e "unpacking $1 ..."
	if [[ $1 == *.zip ]]; then
		unzip -qo $1 -d $2
	else
		tar xfz $1 -C $2
	fi
    if [ $? -ne 0 ]; then
        echo -e "Error: failed to unpack $1"
        exit 1
    fi
}

function format
{
	echo -e "formatting $1 -> $2 ..."
	$CLANG_FORMAT $1 > $2
}

# SCRIPT START
# check deps
for dep in $DEPS; do
	if ! which $dep &>/dev/null; then
		echo -e "Error: missing $dep binary (in PATH)"
		exit 1
	fi
done

download "$MDH_URL" mdh.zip
download "$TACLE_URL" tacle.tgz

mkdir -p unpack/mdh unpack/tacle
unpack mdh.zip unpack/mdh
unpack tacle.tgz unpack/tacle

mkdir -p 1.mdh 2.tacle
for i in unpack/mdh/*.c; do
	dst=`basename $i`
	case $dst in
		cnt.c)
			sed 's///' -i "$i"
			;;
	esac
	format $i 1.mdh/$dst
done

for i in unpack/tacle/TACLeBench/BENCHMARKS/SEQUENTIAL/MRTC/**/*.c; do
	dst=`basename $i`
	case $dst in
		binarysearch.c)
			dst=bs.c
			;;
		compressdata.c)
			dst=compress.c
			;;
		countnegative.c)
			sed 's///' -i "$i"
			dst=cnt.c
			;;
		fdct.c)
			# the code in the comment breaks the clang formatter
			sed 1,23d -i "$i"
			;;
		petrinet.c)
			dst=nsichneu.c
			;;
		*)
			# nothing else
			;;
	esac
	format $i 2.tacle/$dst
done
