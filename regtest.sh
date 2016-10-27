# do a clean build and test of T-CREST
# this is called from regtest-init.sh
# within a newly created t-crest root named t-crest-test

# Do individual tests as test all does not work
./misc/build.sh
# this test is not supported from build.sh
cd patmos
make test &> ../result.txt
cd ..
# this is now the simulator test
./misc/build.sh -t patmos >> result.txt
./misc/build.sh bench
./misc/build.sh -t bench >> result.txt
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
