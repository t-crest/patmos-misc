

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#ifdef __PATMOS__
#include <machine/spm.h>
#endif /* __PATMOS__ */

#include "insort.h"
#include "genperm.h"

#ifndef IS
#error "Define IS!"
#endif

#define _S(x) _S2(x)
#define _S2(x) #x


#define NUM 8

static int nfailed;

static void print_arr(const int arr[], int n)
{
  int i;
  for (i = 0; i < n; i++) {
    (void) printf("%2d ", arr[i]);
  }
  (void) putchar('\n');
}


static int checksorted(int arr[], int n)
{
  int i, x;
  x = arr[0];
  for (i = 1; i < n; i++) {
    if (arr[i] < x) return 0;
    x = arr[i];
  }
  return 1;
}



static void call_inssort(const int arr[], int n)
{
  /* local array for storing the result */
  int res[n];

#ifdef __PATMOS__
  _SPM int *B = (_SPM int *) SPM_BASE;
  spm_copy_from_ext(B, arr, n*sizeof(int));
#else /* __PATMOS__ */
  int B[n];
  (void) memcpy(B, arr, n*sizeof(int));
#endif /* __PATMOS__ */

  /* call function as defined by macro */
  IS(B, n);

#ifdef __PATMOS__
  spm_copy_to_ext(res, B, n*sizeof(int));
#else
  (void) memcpy(res, B, n*sizeof(int));
#endif /* __PATMOS__ */

  if (checksorted(res, n) == 0) {
    nfailed++;
    (void) puts(_S(IS) " wrong:");
    print_arr(arr, n);
    print_arr(res, n);
    (void) fflush(stdout);
  }
}


int main(int argc, char **argv)
{
  int A[NUM];
  int i;

  for (i = 0; i < NUM; i++) {
    A[i] = i;
  }

  genperm(A, NUM, call_inssort);

  return (nfailed != 0);
}
