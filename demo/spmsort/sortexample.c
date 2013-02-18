#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>

#include <machine/patmos.h>
#include <machine/spm.h>

#include "sortexample.h"


Element elements[MAX_ELEMENTS];
Element alternate_storage[MAX_ELEMENTS];

unsigned _SPM *data_spm = SPM_BASE;
unsigned      *sort_this = (unsigned*) elements;


static void check_sorted(unsigned size);
static void init_memory(unsigned size);
static void run_sorts(unsigned size);

int main(void)
{
    unsigned size;

    /* Always call spm_init as a first step */
    spm_init();

    /* Use largest SPM block size for best performance */
    spm_set_block_size(BLOCK_SIZE_64_WORDS);
    assert(spm_data_is_aligned(sort_this));

    /* L1 data cache and SPM are the same size */
    printf("sortexample.c; SPM/cache size %u\n", SPM_SIZE);

    size = 512;
    run_sorts(size / 2);

    for (; size <= MAX_ELEMENTS; size *= 2) {
        run_sorts((size / 2) + (size / 4));
        run_sorts(size);
    }
    return 0;
}

static void run_sorts(unsigned size)
{
    clock_t start;

    printf("sorting with spmsort 64 word         ");
    spm_set_block_size(BLOCK_SIZE_64_WORDS);
    init_memory(size);
    start = clock();
    spmsort(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with spmsort 16 word         ");
    spm_set_block_size(BLOCK_SIZE_16_WORDS);
    init_memory(size);
    start = clock();
    spmsort(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with spmsort 4 word          ");
    spm_set_block_size(BLOCK_SIZE_4_WORDS);
    init_memory(size);
    start = clock();
    spmsort(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with Schmidt qsort           ");
    init_memory(size);
    start = clock();
    schmidt(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with Xilinx libc qsort       ");
    init_memory(size);
    start = clock();
    qsort(sort_this, size, sizeof(Element), sort_comparator);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with Bentley & McIlroy qsort ");
    init_memory(size);
    start = clock();
    bentley(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with BSD heapsort            ");
    init_memory(size);
    start = clock();
    heapsort(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with uclibc Shell sort       ");
    init_memory(size);
    start = clock();
    shellsort(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with Glibc2 mergesort        ");
    init_memory(size);
    start = clock();
    haertel(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with C++ STL introsort       ");
    init_memory(size);
    start = clock();
    introsort(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);

    printf("sorting with spmsort2 64 word        ");
    spm_set_block_size(BLOCK_SIZE_64_WORDS);
    init_memory(size);
    start = clock();
    spmsort2(sort_this, size);
    printf("%14llu %7u\n", clock() - start, size);
    check_sorted(size);


    printf("\n");
}

static void init_memory(unsigned size)
{
    int i, j, k;

    /* Initial setting */
    fflush(stdout);
    srand(size);
    assert(size <= MAX_ELEMENTS);
    j = 0x12345 + (rand() & 0xffff);

    for (i = 0; i < size; i++) {
        j += 1 + (rand() & 0xff);
        elements[i].key = j;
        k = rand();
        elements[i].payload = k;
    }

    /* Shuffle (Fisher/Yates) */
    for (i = 1; i < size; i++) {
        j = rand() % (i + 1);
        if (i != j) {
            swap_memory((char *) &elements[i], (char *) &elements[j], 
                    sizeof(Element));
        }
    }
    invalidate_data_cache();
}

static void check_sorted(unsigned size)
{   
    int i, j, k;

    invalidate_data_cache();
    srand(size);
    assert(size <= MAX_ELEMENTS);
    j = 0x12345 + (rand() & 0xffff);
    
    for (i = 0; i < size; i++) {
        j += 1 + (rand() & 0xff);
        if (elements[i].key != j) {
            asm volatile(".long 0x80000001");
            printf("not sorted; key %u is wrong\nis %u should be %u\n", 
                    i, elements[i].key, j);
            exit(1);
        }
        k = rand();
        if (elements[i].payload != k) {
            printf("not sorted; payload %u is wrong\nis %u should be %u\n",
                    i, elements[i].payload, j);
            exit(1);
        }
    }
}


