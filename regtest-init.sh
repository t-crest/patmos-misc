echo Building T-CREST > build-log.txt
echo Testing T-CREST > result.txt
./misc/regtest.sh
if cat result.txt | ./llvm/build/bin/FileCheck ./misc/regtest-check.ll; then
  echo "Regression test success."
  exit 0
else
  echo "Regression test failure."
  exit 1
fi
