#!/bin/bash
#################################################
#
#script for running the RTEMS testsuite
#
#################################################

cdlevel=1
partest=
simargs=("--interrupt=1")
pwd=$(pwd)
testsuites=$(pwd)/testsuites/results
log=$testsuites/testsuite-log.txt
tests=(itrontests libtests mptests psxtests samples sptests tmitrontests tmtests)
runtests=()
failtests=0
successtests=0
noexectests=0
noresulttests=0
resumeflag=0
resumetests=()

function usage() {
 cat <<EOT
 Usage: $0 [-h] [-c] [-r] [-p <pasim args>] [-t <tests>] [-l <log file>]
 
 -h				Display help contents
 -c				Clean files created during testsuite runs
 -r				Resume test execution
 -p <pasim args>		Pass additional arguments to pasim. Arguments should be passed between quotation marks
 -t <tests>			Tests to be executed (itrontests, libtests, mptests, psxtests, samples, sptests, tmitrontests, tmtests)
 -l <log file>			Override the default log file
 
EOT
}

function containsElement() {
 local e 
 for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 1; done
 return 0
}

function cleanFiles() {
	rm -rf $testsuites
}

function writeFile() {
	if [[ ! -f $1 ]]; then
		touch $1
	fi
	echo $2 >> $1
}

function testsOnResume() {	
	while read line
	do
		resumetests=( "${resumetests[@]}" $(echo "${line%%:*}"))		
	done < $1
}

function runTest() {	
	local bin=$(find $pwd/../rtems-4.10.2-build-patmos/patmos-unknown-rtems/c/pasim/testsuites -iname "$1.exe")	
	if [[ $bin ]]; then
		pasim "${simargs[@]}" $bin > $testsuites/$1-tmp.txt
		if [[ $(find -maxdepth 1 -iname "*.scn" ) ]]; then
			sed -i -e '/Cyc :/,$ d' -e 's/\r//' $testsuites/$1-tmp.txt
			diff --ignore-blank-lines $testsuites/$1-tmp.txt $1.scn > $testsuites/$1-log.txt
			if [[ -s $testsuites/$1-log.txt ]]; then
				writeFile $log "$1: Test executed: Failed!"
				echo "$(tput setaf 1)$1: Test executed: Failed!$(tput setaf 7)"
				let "failtests += 1 "
			else
				writeFile $log "$1: Test executed: Passed!"
				echo "$(tput setaf 2)$1: Test executed: Passed!$(tput setaf 7)"
				rm -rf $testsuites/$1-log.txt
				let "successtests += 1 "
			fi			
		else
			writeFile $testsuites/$2-log.txt "##### $1 #####"
			cat $testsuites/$1-tmp.txt >> $testsuites/$2-log.txt
			writeFile $testsuites/$2-log.txt "##### $1 #####"
			writeFile $log "$1: Test executed: check $2-log.txt"
			echo "$1: Test executed: check $2-log.txt"	
			let "noresulttests += 1 "
		fi
		rm -rf $testsuites/$1-tmp.txt
	elif [[ $(find -maxdepth 1 -iname "*.scn" ) ]]; then
			writeFile $log "$1: Test not executed: $1.exe file not found"
			echo "$(tput setaf 3)$1: Test not executed: $1.exe file not found$(tput setaf 7)"
			let "noexectests += 1 "
	fi
}

function recurseDirs
{
	for f in "$@"
	do
		local testflag=1
		if [[ $cdlevel == 1 ]]; then
			partest="$f"
			containsElement "$f" "${runtests[@]}"
			if [[ $? == 0 && ${#runtests[@]} -gt 0 ]]; then
				testflag=0
			fi
		fi
		if [[ -d "$f" && $testflag == 1 ]]; then			
			cd "$f"
			let "cdlevel += 1"
			containsElement "$f" "${resumetests[@]}"
			if [[ $? == 0 || ${#resumetests[@]} == 0 ]]; then
				runTest "$f" "$partest"
			fi
			recurseDirs $(ls -1)
			cd ..
			let "cdlevel -= 1"
		fi
	done
}

while getopts ":hHp:P:t:T:l:L:cCrR" opt; do	
	case "$opt" in	
	h|H) 
		usage
		exit 1
	;;
	p|P) 		
		containsElement "$OPTARG" "${simargs[@]}"		
		if [[ $? == 0 ]]; then 
			simargs=( "${simargs[@]}" "$OPTARG" )
		fi				
	;;
	t|T)
		containsElement "$OPTARG" "${tests[@]}"		
		if [[ $? == 1 ]]; then
			runtests=( "${runtests[@]}" "$OPTARG" )
		else
			echo "Invalid test: $OPTARG"
			usage
			exit 1
		fi
	;;
	l|L)
		log=$testsuites/"$OPTARG"
	;;
	c|C)
		cleanFiles
		exit 1
	;;
	r|R)
		resumeflag=1
		testsOnResume $log		
	;;
	\?) 		
		echo "Invalid option: -$OPTARG"
		usage
		exit 1
	;;
	:)
		echo "Option -$OPTARG requires an argument"
		usage
		exit 1
	;;
	esac	
done

if [[ ! -d testsuites ]]; then
	echo "Invalid dir. Go to RTEMS source dir."
	exit 1
fi

cd testsuites
if [[ $resumeflag == 0 ]]; then
	cleanFiles
	mkdir $testsuites
fi
recurseDirs $(ls -1)

let " totaltests = successtests + failtests + noexectests + noresulttests"
successper=0
failper=0
noexecper=0
noresultper=0
if [[ $totaltests != 0 ]]; then
	let " successper = successtests / totaltests * 100"
	let " failper = failtests / totaltests * 100"
	let " noexecper = noexectests / totaltests * 100"
	let " noresultper = noresulttests / totaltests * 100"
fi
writeFile $log ""
writeFile $log "---------- Results ----------"
writeFile $log "Successful tests: $successtests ($successper%)"
writeFile $log "Failed tests: $failtests ($failper%)"
writeFile $log "Not executed tests: $noexectests ($noexecper%)"
writeFile $log "No result tests: $noresulttests ($noresultper%)"
