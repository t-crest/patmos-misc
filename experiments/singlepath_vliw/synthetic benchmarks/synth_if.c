// We use volatile to ensure the program isn't optimized away
static volatile int _0 = 1;

int main() {
	// Load values before the loop to ensure no load instruction
	// are in the loop.
	int take_true_branch = _0;
	// We don't care about the actual result of the calculation,
	// so we just load the same value. 
	// Optimizer will think they are different values.
	int i = _0;
	int _1 = _0;
	int _2 = _0;
	int _3 = _0;
	int _4 = _0;
	int _5 = _0;
	int _6 = _0;
	int result = 0;
	if( take_true_branch ){
		if (_1 + _2 + _3 + _4 + _5 + _6) {
			result += (i<<_1) - (i<<_2) - (i<<_3) - (i<<_4) - (i<<_5) - (i<<_6) -
				(i|_1) - (i|_2) - (i|_3) - (i|_4) - (i|_5) - (i|_6) ^
				(i-_1) ^ (i-_2) ^ (i-_3) ^ (i-_4) ^ (i-_5) ^ (i-_6) ^
				(i&_1) - (i&_2) - (i&_3);
		} else {
			result += (i<<_1) + (i<<_2) + (i<<_3) + (i<<_4) + (i<<_5) + (i<<_6) +
				(i|_1) + (i|_2) + (i|_3) + (i|_4) + (i|_5) + (i|_6) &
				(i-_1) & (i-_2) & (i-_3) & (i-_4) & (i-_5) & (i-_6) &
				(i&_1) + (i&_2) + (i&_3);
		}
	} else {
		if (_1 - _2 - _3 - _4 - _5 - _6) {
			result -= (i>>_1) + (i>>_2) + (i>>_3) + (i>>_4) + (i>>_5) + (i>>_6) + 
				(i^_1) + (i^_2) + (i^_3) + (i^_4) + (i^_5) + (i^_6) & 
				(i+_1) & (i+_2) & (i+_3) & (i+_4) & (i+_5) & (i+_6) & 
				(i&_4) + (i&_5) + (i&_6);
		} else {
			result -= (i>>_1) - (i>>_2) - (i>>_3) - (i>>_4) - (i>>_5) - (i>>_6) - 
				(i^_1) - (i^_2) - (i^_3) - (i^_4) - (i^_5) - (i^_6) ^ 
				(i+_1) ^ (i+_2) ^ (i+_3) ^ (i+_4) ^ (i+_5) ^ (i+_6) ^ 
				(i&_4) - (i&_5) - (i&_6);
		}
	}
	// Return the result to ensure the optimizer doesn't throw it away
	return result;
}





