#include <stdio.h>

__attribute__ ((noinline)) 
int measure(int n, int i, int j) {

    /*
    for (int k = 0; k < n; k++) {
	if ( i % 2 ) i /= 2;
	else i = i*3 + 1;
    }
    */

    switch (n) {
	case 0: j = 40; break;
	case 1: i = 20; j = 10; break;
	case 2: i = 30; j = 40; break;
	case 3: i = 10; break;
	case 4: i = 30; j = 12; break;
	case 5: i = 50; break;
	case 6: i = 40; break;
    }

    return i + j;
}

int main(int argc, char** argv) {
    int i = 20;
    int j = 0;
    volatile int n = 4;

    int rs = measure(n, i, j);

    printf("Result (should be 42): %d\n", rs);

    return i+j;
}

