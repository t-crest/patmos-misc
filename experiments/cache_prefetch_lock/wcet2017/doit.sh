make clean
make XML_SIZE=1024
mkdir result_1k
mv *.txt result_1k
make clean
make XML_SIZE=2048
mkdir result_2k
mv *.txt result_2k
make clean
make XML_SIZE=4096
mkdir result_4k
mv *.txt result_4k
# make clean
# make XML_SIZE=8192
# mkdir eval_8k
# mv *.txt eval_8k
make clean
make XML_SIZE=16384
mkdir result_16k
mv *.txt result_16k
