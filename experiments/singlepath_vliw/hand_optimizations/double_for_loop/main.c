#include <stdio.h>

volatile int _0 = 0;
volatile int _1 = 1;
volatile int _2 = 2;
volatile int _3 = 3;

int init_func(){
	int x = _0;
	if(_1){
		for(int i = 0; i<100; i++){
			x += i + _2;
		}
	}else{
		for(int i = 0; i<300; i++){
			x += i - _3;
		}
	}
	return x;
}

// Should print "5150" on correct execution
int main(){
	printf("%d\n", init_func());
}








