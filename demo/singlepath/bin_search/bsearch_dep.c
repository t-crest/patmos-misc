
#ifdef __PATMOS__
#include <machine/spm.h>
__attribute__((noinline))
int bsearch_dep(_SPM int *arr, unsigned N, int key)
#else
__attribute__((noinline))
int bsearch_dep(int arr[], unsigned N, int key)
#endif /* __PATMOS__ */
{
  unsigned lb = 0;
  unsigned ub = N - 1;

  while (lb <= ub) {
    /* unsigned shift */
    unsigned m = (lb + ub) >> 1;
    if (arr[m] < key) {
      lb = m + 1;
    } else if (arr[m] > key) {
      ub = m - 1;
    } else {
      return m;
    }
  }

  return -1;
}
