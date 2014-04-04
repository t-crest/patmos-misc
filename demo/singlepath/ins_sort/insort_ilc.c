
#ifdef __PATMOS__
#include <machine/spm.h>
__attribute__((noinline))
void insort_ilc(_SPM int *arr, unsigned N)
#else
__attribute__((noinline))
void insort_ilc(int arr[], unsigned N)
#endif /* __PATMOS__ */
{
  int i, j, v;
  j = 1;
  while (j < N) {
    /* invariant: sorted (a[0..j-1]) */
    v = arr[j];

    {
      int cnt, finished = 0;
      i = j - 1;
      for (cnt = 0; cnt < j; cnt++) {
        if (arr[i] < v) finished = 1;
        if (!finished) {
          arr[i+1] = arr[i];
          i--;
        }
      }
    }

    arr[i+1] = v;
    j = j + 1;
  }
}
