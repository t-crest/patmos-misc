#!/bin/bash
TO_TEST=$1

if [ -z $TO_TEST ]
then
	echo "No argument"
	exit 1
fi

for i in {1..10}
do
	make clean
	make $TO_TEST -j

	pasim ${TO_TEST}_nosp.out
	NOSP=$?

	pasim ${TO_TEST}_sp.out
	SP=$?

	pasim ${TO_TEST}_sp_bundled.out
	BUNDLED=$?

	if [ "$NOSP" != "$SP" ] 
	then
		echo "Traditional not like Singlepath: $NOSP != $SP"
		exit 1
	else 
		if [ "$NOSP" != "$BUNDLED" ]
		then
			echo "Bundled wrong: $NOSP != $BUNDLED"
			exit 1
		fi
	fi
done



