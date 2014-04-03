
#ifdef __PATMOS__
#include <machine/spm.h>
__attribute__((noinline))
int bsearch_ilc(_SPM int *arr, unsigned N, int key)
#else
__attribute__((noinline))
int bsearch_ilc(int arr[], unsigned N, int key)
#endif /* __PATMOS__ */
{
  int base = 0;
  int r = -1;
  int lim;

  for (lim = N; lim > 0; lim >>= 1) {
    int p = base + (lim >> 1);
    if (key > arr[p]) {
      base = p + (lim & 1);
    } else if (key == arr[p]) {
      r = p;
    }
  }

  return r;
}
