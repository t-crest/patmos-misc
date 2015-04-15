#include <stdlib.h>
#include <stdio.h>

#include <machine/rtc.h>
#include <machine/spm.h>


static const size_t MAX_SIZE = 100;


void sort(_SPM float *arr, size_t N) __attribute__((noinline));
void sort(_SPM float *arr, size_t N) {

  #pragma loopbound min 0 max 99
  for (int j = 1; j < N; j++) {
    /* invariant: sorted (a[0..j-1]) */
    float v = arr[j];

    int i = j - 1;
    #pragma loopbound min 0 max 99
    while (i >= 0 && arr[i] >= v) {
      arr[i+1] = arr[i];
      i = i - 1;
    }

    arr[i+1] = v;
  }
}

int mybsearch(_SPM float *arr, size_t N, int value) __attribute__((noinline));
int mybsearch(_SPM float *arr, size_t N, int value) {
  ssize_t lb = 0;
  ssize_t ub = N - 1;

  #pragma loopbound min 0 max 7
  while (lb <= ub) {
    ssize_t m = (lb + ub) >> 1;
    if (arr[m] < value) {
      lb = m + 1;
    } else if (arr[m] > value) {
      ub = m - 1;
    } else {
      return m;
    }
  }

  return -1;
}

int gen_and_search(int value) __attribute__((noinline));
int gen_and_search(int value) {

  _SPM float *arr = SPM_BASE;
  size_t N = rand() % (MAX_SIZE / 2) + (MAX_SIZE / 2);

  #pragma loopbound min 100 max 100
  for (size_t i = 0; i < N; i++) {
    arr[i] = rand() % N;
  }

  sort(arr, N);
  
  int pos = mybsearch(arr, N, value);

  return pos;
}

int main(int argc, char** argv) {

  srand(0);

  for (int i = 0; i < 10; i++) {
    inval_mcache();

    unsigned long long t1 = get_cpu_cycles();

    int pos = gen_and_search(i);

    unsigned long long t2 = get_cpu_cycles();

    printf("Iteration %2d: %7llu cycles, POS: %2d\n", i, t2-t1, pos);
  }
  return 0;
}
