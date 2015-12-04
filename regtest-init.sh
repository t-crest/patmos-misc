# do a clean build and test of T-CREST 
export PATH=$HOME/t-crest-test/local/bin:$PATH
rm -rf $HOME/t-crest-test
mkdir $HOME/t-crest-test
cd $HOME/t-crest-test
git clone git@github.com:t-crest/patmos-misc.git misc
# rest is done in regtest
./misc/regtest.sh &> result.txt
RECIPIENTS=`cat $HOME/t-crest-test/misc/recipients.txt`
mail -s "[T-CREST] Build report `date`" ${RECIPIENTS} < $HOME/t-crest-test/result.txt
