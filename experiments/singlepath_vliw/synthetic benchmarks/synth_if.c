#define ITER_COUNT 4095
// We use volatile to ensure the program isn't optimized away
static volatile int _0 = 1;

int main() {
	// Load values before the loop to ensure no load instruction
	// are in the loop.
	int take_true_branch = _0;
	// We don't care about the actual result of the calculation,
	// so we just load the same value. 
	// Optimizer will think they are different values.
	int _1 = _0;
	int _2 = _0;
	int _3 = _0;
	int _4 = _0;
	int _5 = _0;
	int _6 = _0;
	int result = 0;
	#pragma loopbound min ITER_COUNT max ITER_COUNT
	for (int i = 0; i<ITER_COUNT; i++) {
		if( i >> take_true_branch ){
			if ( i & _1 ) {
				result += (i<<_1) - (i<<_2) - (i<<_3) -
					(i|_1) - (i|_2) - (i|_3) ^
					(i-_1) ^ (i-_2) ^ (i-_3) ^ (i&_2);
			} else {
				result -= (i<<_4) - (i<<_5) - (i<<_6) -
					(i|_4) - (i|_5) - (i|_6) ^
					(i-_4) ^ (i-_5) ^ (i-_6) ^ (i&_3);
			}
		} else {
			result -= (i>>_1) + (i>>_2) + (i>>_3) + (i>>_4) + (i>>_5) + (i>>_6) + 
				(i^_1) + (i^_2) + (i^_3) + (i^_4) + (i^_5) + (i^_6) & 
				(i+_1) & (i+_2) & (i+_3) & (i+_4) & (i+_5) & (i+_6) &
				(i&_4) + (i&_5) + (i&_6);
		}
	}
	// Return the result to ensure the optimizer doesn't throw it away
	return result;
}





