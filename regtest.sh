# do a clean build and test of T-CREST
# this is called from regtest-init.sh
# within a newly created t-crest root named t-crest-test

# Do individual tests as test all does not work
./misc/build.sh &>> build-log.txt

# this test is not supported from build.sh
echo Running Patmos test >> result.txt
cd patmos
make test &>> ../result.txt
cd ..

# this is now the simulator test
echo Running Patmos benchmark test >> result.txt
./misc/build.sh -t patmos &>> result.txt

# Run llvm patmos target tests
echo Testing LLVM Patmos Target >> result.txt
env DEBUG_TYPE= patmos-llvm-lit llvm/test --filter="LLVM :: Patmos" -v &>> result.txt

# Build benchmark
./misc/build.sh bench &>> build-log.txt

# Run benchmark
echo Running benchmark >> result.txt
./misc/build.sh -t bench &>> result.txt

##./misc/build.sh -t gold # no tests
##./misc/build.sh -t llvm # fails always
##./misc/build.sh -t newlib # no tests
##./misc/build.sh -t compiler-rt # no tests
# RTEMS does not build on my (MS) machine - needs some more checks on dependencies
##./misc/build.sh -t rtems 
##./misc/build.sh -t rtems-test
##./misc/build.sh -t rtems-examples
##./misc/build.sh -t eclipse # this is a alias to llvm
##./misc/build.sh -t aegean # no tests
##./misc/build.sh -t poseidon # no tests
