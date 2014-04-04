#ifndef _INSORT_H_
#define _INSORT_H_


#ifdef __PATMOS__

void insort_dep(_SPM int *arr, unsigned N);

void insort_ilb(_SPM int *arr, unsigned N);

void insort_ilc(_SPM int *arr, unsigned N);

#else /* __PATMOS__ */

void insort_dep(int arr[], unsigned N);

void insort_ilb(int arr[], unsigned N);

void insort_ilc(int arr[], unsigned N);

#endif /* __PATMOS__ */


#endif /* _INSORT_H_ */
