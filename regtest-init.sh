# do a clean build and test of T-CREST 
export PATH=$HOME/t-crest-test/local/bin:$PATH
rm -rf $HOME/t-crest-test
mkdir $HOME/t-crest-test
cd $HOME/t-crest-test
git clone https://github.com/t-crest/patmos-misc.git misc
# rest is done in regtest
echo Testing T-CREST > result.txt
./misc/regtest.sh
RECIPIENTS=`cat $HOME/t-crest-test/misc/recipients.txt`
mail -s "[T-CREST] Build report `date` on ${HOSTNAME}" ${RECIPIENTS} < $HOME/t-crest-test/result.txt
