

#include <stdio.h>
#include <stdlib.h>


#ifdef __PATMOS__
#include <machine/spm.h>
#endif /* __PATMOS__ */

#include "bsearch.h"

#ifndef BS
#error "Define BS!"
#endif

#define _S(x) _S2(x)
#define _S2(x) #x

#define bsearch(arr, N, key) \
  do { \
    int pos;\
    (void) printf(_S(BS) " (key = %2d)", key); \
    (void) fflush(stdout); \
    pos = BS(arr, N, key); \
    (void) printf(" -> pos = %d\n", pos); \
    (void) fflush(stdout); \
  } while (0)


#define NUM 10

int A[NUM] = {0, 10, 20, 30, 40, 50, 60, 70, 80, 90};

static void print_arr(int arr[])
{
  int i;
  for (i = 0; i < NUM; i++) {
    (void) printf("%2d ", arr[i]);
  }
  (void) putchar('\n');
}



int main(int argc, char **argv)
{
  int i, k;

  print_arr(A);

#ifdef __PATMOS__
  _SPM int *B = (_SPM int *) SPM_BASE;
  spm_copy_from_ext(B, A, sizeof A);
#else /* __PATMOS__ */
  int *B = A;
#endif /* __PATMOS__ */

  for (i = 0; i < NUM; i++) {
    bsearch(B, NUM, 10*i);
  }


  return 0;
}
