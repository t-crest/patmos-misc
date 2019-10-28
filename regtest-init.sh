# do a clean build and test of T-CREST 
export PATH=$HOME/t-crest-test/local/bin:$PATH
rm -rf $HOME/t-crest-test
mkdir $HOME/t-crest-test
cd $HOME/t-crest-test
git clone https://github.com/t-crest/patmos-misc.git misc
# rest is done in regtest
echo Building T-CREST > build-log.txt
echo Testing T-CREST > result.txt
./misc/regtest.sh
if cat result.txt | ./llvm/build/bin/FileCheck ./misc/regtest-check.ll; then
  SUCC_MSG=SUCCESS
else
  SUCC_MSG=FAILURE
fi
zip -j ./build-log.zip ./build-log.txt
RECIPIENTS=`cat ./misc/recipients.txt`
mail -s "[T-CREST] Build report `date` on ${HOSTNAME}: $SUCC_MSG" ${RECIPIENTS} -A ./build-log.zip < ./result.txt
