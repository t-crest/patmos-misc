#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <stdint.h>

#include <machine/spm.h>

#include "sortexample.h"
#include "buffer.h"


#define PHASE_1_ELEMS       (SPM_SIZE / sizeof(Element))

extern void spm_schmidt(_SPM void *const pbase, size_t total_elems);

static void merge(Element * dest, Element * src, 
                    unsigned total_elems, unsigned n);

void spmsort2(void * const pbase, size_t total_elems)
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


#define IN_A_SIZE   (SPM_SIZE / 4)
#define IN_B_SIZE   (SPM_SIZE / 4)
#define OUT_SIZE    (SPM_SIZE / 2)

static void merge(Element * dest, Element * src, 
                    unsigned total_elems, unsigned n)
{
    unsigned        off, i;
    SPM_BFE_Buffer  buf_A;
    SPM_BFE_Buffer  buf_B;
    SPM_BTE_Buffer  buf_out;
    _SPM Element * spm_A = (_SPM Element *) &data_spm[0];
    _SPM Element * spm_B = (_SPM Element *) &data_spm[IN_A_SIZE / 4];
    _SPM Element * spm_out = (_SPM Element *) &data_spm[(IN_A_SIZE + IN_B_SIZE) / 4];
         Element * end_all = (     Element *) &src[total_elems];
    _SPM Element * out;
    unsigned n2 = n * 2;

    out = spm_bte_init(&buf_out, dest, spm_out, OUT_SIZE, sizeof(Element));

    off = 0;
    while(1) {
        Element * src_A = &src[off];
        Element * src_B = &src[off + n];
        Element * end_A = &src[off + n];
        Element * end_B = &src[off + n2];
        _SPM Element * A_elem;
        _SPM Element * B_elem;
        unsigned A_count = n;
        unsigned B_count = n;

        if (src_A >= end_all) {
            /* Nothing to sort */
            break;

        } else if (end_A >= end_all) {
            /* A area is incomplete */
            /* No B area to sort here */
            B_count = 0;
            A_count = end_all - src_A;
            
        } else if (end_B > end_all) {
            /* B area is incomplete */
            end_B = end_all;
            B_count = end_all - src_B;
            assert (B_count);
            assert (B_count <= n);
        }

        off += A_count + B_count;
        assert (A_count);
        assert (A_count <= n);

        spm_bfe_init(&buf_A, src_A, spm_A, 
                            IN_A_SIZE, sizeof(Element));
        A_elem = spm_bfe_consume(&buf_A);

        if (B_count) {
            /* Merge required as A_count and B_count are non-zero */
            spm_bfe_init(&buf_B, src_B, spm_B, 
                            IN_B_SIZE, sizeof(Element));
            B_elem = spm_bfe_consume(&buf_B);

            while(A_count && B_count) {
                if (spm_sort_comparator(A_elem, B_elem) < 0) {
                    /* select A */
                    out[0] = A_elem[0];
                    A_count--;
                    A_elem = spm_bfe_consume(&buf_A);
                } else {
                    /* select B */
                    out[0] = B_elem[0];
                    B_count--;
                    B_elem = spm_bfe_consume(&buf_B);
                }
                out = spm_bte_produce(&buf_out);
            }
            /* Final fill from B? */
            while (B_count) {
                out[0] = B_elem[0];
                B_count--;
                out = spm_bte_produce(&buf_out);
                B_elem = spm_bfe_consume(&buf_B);
            }
        }

        /* Final fill from A? */
        while (A_count) {
            out[0] = A_elem[0];
            A_count--;
            out = spm_bte_produce(&buf_out);
            A_elem = spm_bfe_consume(&buf_A);
        }
    }
    spm_bte_finish(&buf_out);
}



