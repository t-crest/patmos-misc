#ifndef _BSEARCH_H_
#define _BSEARCH_H_


#ifdef __PATMOS__

int bsearch_dep(_SPM int *arr, unsigned N, int key);

int bsearch_ilb(_SPM int *arr, unsigned N, int key);

int bsearch_ilc(_SPM int *arr, unsigned N, int key);

#else /* __PATMOS__ */

int bsearch_dep(int arr[], unsigned N, int key);

int bsearch_ilb(int arr[], unsigned N, int key);

int bsearch_ilc(int arr[], unsigned N, int key);

#endif /* __PATMOS__ */


#endif /* _BSEARCH_H_ */
