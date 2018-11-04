#include <stdio.h>

volatile int _0 = 0;
volatile int _1 = 1;
volatile int _2 = 2;
volatile int _3 = 3;

int init_func(){
	int x = _0;
	
	if(_1){
		x += _2;
	}else{
		x -= _3;
	}
	return x;
}

// Should print "2" on correct execution if the printf is enabled
int main(){
	printf("%d\n", init_func());
}








