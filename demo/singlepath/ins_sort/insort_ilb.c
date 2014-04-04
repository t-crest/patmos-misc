
#ifdef __PATMOS__
#include <machine/spm.h>
__attribute__((noinline))
void insort_ilb(_SPM int *arr, unsigned N)
#else
__attribute__((noinline))
void insort_ilb(int arr[], unsigned N)
#endif /* __PATMOS__ */
{
  int i, j, v;
  j = 1;
  while (j < N) {
    /* invariant: sorted (a[0..j-1]) */
    v = arr[j];

    i = j - 1;
    while (i >= 0) {
      if (arr[i] < v) break;
      arr[i+1] = arr[i];
      i = i - 1;
    }

    arr[i+1] = v;
    j = j + 1;
  }
}
