
#ifdef __PATMOS__
#include <machine/spm.h>
__attribute__((noinline))
int bsearch_ilb(_SPM int *arr, unsigned N, int key)
#else
__attribute__((noinline))
int bsearch_ilb(int arr[], unsigned N, int key)
#endif /* __PATMOS__ */
{
  int base = 0;
  int lim;

  for (lim = N; lim > 0; lim >>= 1) {
    int p = base + (lim >> 1);
    if (key > arr[p]) {
      base = p + (lim & 1);
    } else if (key == arr[p]) {
      return p;
    }
  }

  return -1;
}
