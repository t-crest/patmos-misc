# do a clean build and test of T-CREST
# this is called from regtest-init.sh
./misc/build.sh
# this test is not supported from build.sh
cd patmos
make test
# first do a bench build
./misc/build.sh bench
./misc/build.sh -t bench
./misc/build.sh -t
