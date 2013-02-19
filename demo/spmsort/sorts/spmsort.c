#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <stdint.h>

#include <machine/spm.h>

#include "sortexample.h"


#define PHASE_1_ELEMS       (SPM_SIZE / sizeof(Element))

extern void spm_schmidt(_SPM void *const pbase, size_t total_elems);

static void merge(Element * dest, Element * src, 
                    unsigned total_elems, unsigned n);

void spmsort(void * const pbase, size_t total_elems)
{
    unsigned off, n, odd = 1;

    Element * base_buffer = (Element *) pbase;
    Element * src;
    Element * dest;
    Element * tmp;

    src = base_buffer;
    dest = base_buffer;

    /* How many merge steps required? */
    n = PHASE_1_ELEMS;
    while (n < total_elems) {
        n *= 2;
        odd ++;
    }
    if (!(odd & 1)) {
        dest = (Element *) alternate_storage;
    }

    /* phase 1: sort SPM-sized chunks with qsort/isort */
    for (off = 0; off < total_elems; off += PHASE_1_ELEMS) {
        n = total_elems - off;
        if (n > PHASE_1_ELEMS) {
            n = PHASE_1_ELEMS;
        }
        assert(n);

        spm_copy_from_ext(data_spm, &src[off], n * sizeof(Element));
        spm_wait();

        spm_schmidt(data_spm, n);

        spm_copy_to_ext(&dest[off], data_spm, n * sizeof(Element));
        spm_wait();
    }

    if (odd & 1) {
        assert(dest == base_buffer);
        src = (Element *) alternate_storage;
    } else {
        assert(src == base_buffer);
        assert(dest == (Element *) alternate_storage);
    }

    /* phase 2: merge */
    n = PHASE_1_ELEMS;
    while (n < total_elems) {
        tmp = src; src = dest; dest = tmp;
        merge(dest, src, total_elems, n);
        n *= 2;
    }
    assert(dest == base_buffer);
}


#define IN_A_ELEMS  ((SPM_SIZE / 4) / sizeof(Element))
#define IN_B_ELEMS  ((SPM_SIZE / 4) / sizeof(Element))
#define OUT_ELEMS   ((SPM_SIZE / 2) / sizeof(Element))

static void merge(Element * dest, Element * src, 
                    unsigned total_elems, unsigned n)
{
    unsigned off, i;
    _SPM Element * spm_A = (_SPM Element *) &data_spm[0];
    _SPM Element * spm_B = (_SPM Element *) &data_spm[SPM_WORDS / 4];
    _SPM Element * spm_out = (_SPM Element *) &data_spm[SPM_WORDS / 2];
         Element * end_all = (     Element *) &src[total_elems];
    unsigned n2 = n * 2;

    assert((n % IN_B_ELEMS) == 0);
    assert((n % IN_A_ELEMS) == 0);
    assert((n % OUT_ELEMS) == 0);

    off = 0;
    while(1) {
        Element * src_A = &src[off];
        Element * src_B = &src[off + n];
        Element * end_A = &src[off + n];
        Element * end_B = &src[off + n2];
        unsigned index_A = IN_A_ELEMS;
        unsigned index_B = IN_B_ELEMS;
        unsigned in_B_elems = IN_B_ELEMS;
        unsigned index_out = 0;

        if (src_A >= end_all) {
            /* Nothing to sort */
            break;

        } else if (end_A >= end_all) {
            /* No B area to sort here */
	    i = n;
            end_B = src_B;
        } else if (end_B > end_all) {
            /* B area is incomplete */
            i = end_B - end_all;
            end_B = end_all;
        } else {
	    /* A and B areas are complete */
	    i = 0;
	}

        /* Main merging code */
        for (; i < n2; i++) {
            if ((index_A == IN_A_ELEMS) && (src_A < end_A)) {
                spm_copy_from_ext(spm_A, src_A, 
                        IN_A_ELEMS * sizeof(Element));
                src_A += IN_A_ELEMS;
                index_A = 0;
                spm_wait();
            }
            if ((index_B == in_B_elems) && (src_B < end_B)) {
                spm_copy_from_ext(spm_B, src_B, 
                        in_B_elems * sizeof(Element));
                src_B += in_B_elems;
                index_B = 0;
                if (src_B > end_B) {
                    /* Partial B block (must be the last one) */
                    src_B -= in_B_elems;
                    in_B_elems = end_B - src_B;
                    src_B += in_B_elems;
                    assert(src_B == end_B);
                    assert(in_B_elems < IN_B_ELEMS);
                }
                spm_wait();
            }
            if (index_A == IN_A_ELEMS) {
                /* must pick B */
                spm_out[index_out] = spm_B[index_B];
                index_B++; index_out++;

            } else if (index_B == in_B_elems) {
                /* must pick A */
                spm_out[index_out] = spm_A[index_A];
                index_A++; index_out++;

            } else if (spm_sort_comparator(
                    &spm_A[index_A], &spm_B[index_B]) < 0) {
                /* select A */
                spm_out[index_out] = spm_A[index_A];
                index_A++; index_out++;

            } else {
                /* select B */
                spm_out[index_out] = spm_B[index_B];
                index_B++; index_out++;
            }
            if (index_out == OUT_ELEMS) {
                /* Write out merged data */
                spm_copy_to_ext(dest, spm_out, OUT_ELEMS * sizeof(Element));
                dest += OUT_ELEMS;
                index_out = 0;
                spm_wait();
            }
        }
        assert(index_out == 0);
        off += n2;
    }
}



