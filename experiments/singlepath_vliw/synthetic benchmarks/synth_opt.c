// Loop iteration count cannot be larger, since it then won't
// fit in a short-immediate arithmetic operation.
#define ITER_COUNT 4095
// We use volatile to ensure the program isn't optimized away
static volatile int _0 = 0;

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
	int more = 1;
	#pragma loopbound min ITER_COUNT max ITER_COUNT
	for( int i = 0; more; ) {
		// We ensure no intermediate result is shared between the branches
		// so that the optimizer doesn't pull it out of the branches
		// which would stop us from bundling it.
		// E.g. (i<<_1) is only used in the true branch, while (i>>_1) is in the false branch.
		if( take_true_branch ){
			result += (i<<_1) - (i<<_2) - (i<<_3) - (i<<_4) - (i<<_5) - (i<<_6) -
				(i|_1) - (i|_2) - (i|_3) - (i|_4) - (i|_5) - (i|_6) ^
				(i-_1) ^ (i-_2) ^ (i-_3) ^ (i-_4) ^ (i-_5) ^ (i-_6) ^
				(i&_1) - (i&_2) - (i&_3);
			result += (i<<_1) + (i<<_2) + (i<<_3) + (i<<_4) + (i<<_5) + (i<<_6) +
				(i|_1) + (i|_2) + (i|_3) + (i|_4) + (i|_5) + (i|_6) &
				(i-_1) & (i-_2) & (i-_3) & (i-_4) & (i-_5) & (i-_6) &
				(i&_1) + (i&_2) + (i&_3);
				// We also calculate the increment and condition in the branches
				// to reduce the loop overhead that we can't bundle.
				i++;
				more = i<ITER_COUNT;
		} else {
			result -= (i>>_1) + (i>>_2) + (i>>_3) + (i>>_4) + (i>>_5) + (i>>_6) + 
				(i^_1) + (i^_2) + (i^_3) + (i^_4) + (i^_5) + (i^_6) & 
				(i+_1) & (i+_2) & (i+_3) & (i+_4) & (i+_5) & (i+_6) & 
				(i&_4) + (i&_5) + (i&_6);
			result -= (i>>_1) - (i>>_2) - (i>>_3) - (i>>_4) - (i>>_5) - (i>>_6) - 
				(i^_1) - (i^_2) - (i^_3) - (i^_4) - (i^_5) - (i^_6) ^ 
				(i+_1) ^ (i+_2) ^ (i+_3) ^ (i+_4) ^ (i+_5) ^ (i+_6) ^ 
				(i&_4) - (i&_5) - (i&_6);
				// different increment and conditions to ensure thay aren't shared 
				// with the other branch.
				i--;
				more = i>ITER_COUNT;
		}
	}
	// Return the result to ensure the optimizer doesn't throw it away
	return result;
}





