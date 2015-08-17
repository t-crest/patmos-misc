
patmos-clang -o sqrt.nosc       -O2 -mpatmos-disable-stack-cache -mserialize=sqrt.nosc.pml   sqrt.c 
patmos-clang -o sqrt.nosc.nops  -O2 -mpatmos-preferred-subfunction-size=0   -mpatmos-disable-stack-cache -mserialize=sqrt.nosc.nops.pml   sqrt.c 
patmos-clang -o sqrt.nosc.ps512 -O2 -mpatmos-preferred-subfunction-size=512 -mpatmos-disable-stack-cache -mserialize=sqrt.nosc.ps512.pml  sqrt.c 
patmos-clang -o sqrt.nosc.ps768 -O2 -mpatmos-preferred-subfunction-size=768 -mpatmos-disable-stack-cache -mserialize=sqrt.nosc.ps768.pml  sqrt.c 

patmos-clang -o sqrt       -O2 -mserialize=sqrt.pml   sqrt.c 
patmos-clang -o sqrt.nops  -O2 -mpatmos-preferred-subfunction-size=0   -mserialize=sqrt.nops.pml   sqrt.c 
patmos-clang -o sqrt.ps512 -O2 -mpatmos-preferred-subfunction-size=512 -mserialize=sqrt.ps512.pml  sqrt.c 
patmos-clang -o sqrt.ps768 -O2 -mpatmos-preferred-subfunction-size=768 -mserialize=sqrt.ps768.pml  sqrt.c 
