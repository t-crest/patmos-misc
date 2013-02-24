
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#ifdef PATMOS
#include <machine/patmos.h>
#include <machine/spm.h>
#endif

#include "sortexample.h"
#include "buffer.h"

#define MAX_TEST_SIZE   5000000
#define MAX_ITEMS       10000
#define MAX_TASKS       16


static void tester(unsigned offset,
                unsigned num_elements, 
                unsigned elem_size,
                unsigned spm_usage);
static void multibuf(unsigned max_spm_usage_per_job, 
                unsigned num_tasks,
                unsigned run_limit);
static void spm_size_test(void);
static void mysrand(unsigned x);
static unsigned myrand(void);


#ifdef PATMOS
_SPM unsigned *data_spm;
unsigned off_chip[MAX_TEST_SIZE];
#define DATA_SPM_BASE SPM_BASE
#define DATA_SPM_SIZE SPM_SIZE
#define DATA_SPM_WORDS SPM_WORDS
#else
#define _SPM
#define off_chip  ((unsigned *) sort_this)
#endif




int main(void)
{
    unsigned i, j, esize, cycle, x = 0;
    _SPM unsigned * elem;
    SPM_BTE_Buffer bte;
    const unsigned check = 0xbeef0000;
    unsigned run_limit = 1000;

#ifdef PATMOS
    data_spm = SPM_BASE;
#endif

    /* Always call spm_init as a first step */
    spm_init();

    printf("SPM location 0x%x\n", (unsigned) DATA_SPM_BASE);
    printf("off_chip location 0x%x size %u words\n", 
                (unsigned) off_chip, MAX_TEST_SIZE);
    printf("Expected SPM size: %u words, %u bytes\n", 
                DATA_SPM_WORDS, DATA_SPM_SIZE);
    spm_size_test();

    printf("basic tests\n");
    tester(0, 1024, 4, 1024);
    tester(0, 1, 4, 1024);
    tester(1, 1024, 4, 1024);
    tester(0, 1, 8, 512);

    mysrand(1000);

    for (cycle = 0; cycle < 100; cycle++) {
        do {
            esize = 1 << (myrand() % 8);
        } while (((DATA_SPM_SIZE / 2) % (esize * 4)) != 0);

        printf("%u writing test pattern, element size %u\n", cycle, esize);

        for (i = MAX_ITEMS; i < (MAX_ITEMS + (DATA_SPM_WORDS * 2)); i++) {
            off_chip[i] = check | i;
        }

        elem = spm_bte_init(&bte, off_chip, 
                    data_spm, DATA_SPM_SIZE, esize * 4);
        mysrand(cycle + 1);
        for (i = 0; i < MAX_ITEMS; ) {
            for (j = 0; j < esize; i++, j++) {
                elem[j] = (cycle == 0) ? i : (myrand() + 1);
            }
            elem = spm_bte_produce(&bte);
        }
        spm_bte_finish(&bte);

        invalidate_data_cache();

        printf("%u checking test pattern, element size %u\n", cycle, esize);

        mysrand(cycle + 1);
        x = 0;
        for (i = 0; i < MAX_ITEMS; i++) {
            j = (cycle == 0) ? i : (myrand() + 1);
            if (off_chip[i] != j) {
                printf("off_chip[%08x] = %08x should be %08x\n",
                        i, off_chip[i], j);
                x++;
                assert(x < 10);
            }
        }
        assert(!x);

        x = 0;
        for (i = 0; i < (DATA_SPM_WORDS * 2); i++) {
            if (off_chip[i + MAX_ITEMS] != (check | i)) {
                x = i;
            }
        }
        printf("producer overshot by %u (%u)\n", x, DATA_SPM_WORDS * 2);

        printf("%u single buffer tests\n", cycle);
        mysrand(cycle + 0x2000);
        for (i = 0; (i < (3 + cycle)) && (i < 25); i++) {
            unsigned elem_size = 4 << (myrand() % 4);
            unsigned spm_elems = DATA_SPM_SIZE / elem_size;
            unsigned total_elems;

            spm_elems /= 1 << (myrand() % 4);
            if (spm_elems < 2) {
                spm_elems = 2;
            }
            total_elems = (myrand() % MAX_ITEMS) + 1;
            tester((myrand() % total_elems) % 256, total_elems, elem_size,
                    spm_elems * elem_size);
        }

        mysrand(cycle + 0x1000);
        printf("%u multi-buffer tests, myrand %04x\n", 
                        cycle, myrand() & 0xffff);
        multibuf(myrand(), 2 + (myrand() % 15), run_limit);
        for (i = 2; i <= 16; i++) {
            multibuf(1024, i, run_limit);
        }

        multibuf(myrand(), 2 + (myrand() % 15), run_limit);
        for (i = 2; i <= 8; i++) {
            multibuf(2048, i, run_limit);
        }
        run_limit *= 10;
        if (run_limit > MAX_TEST_SIZE) {
            run_limit = MAX_TEST_SIZE;
        }
    }
    return 0;
}

static void tester(unsigned offset,
                unsigned num_elements, 
                unsigned elem_size,
                unsigned spm_usage)
{
    unsigned i, j;
    unsigned total = elem_size * num_elements;
    unsigned elem_words = elem_size / 4;
    SPM_BFE_Buffer buf1;

    printf("tester(%u, %u, %u, %u) ", 
                offset, num_elements, elem_size, spm_usage);
    fflush(stdout);

    assert(elem_words >= 1);
    assert((elem_words * 4) == elem_size);
    assert(spm_usage >= (elem_size * 2));
    assert(spm_usage <= DATA_SPM_SIZE);

    offset /= elem_words;
    offset *= elem_words;
    spm_bfe_init(&buf1, &off_chip[offset], data_spm, spm_usage, elem_size);

    for (i = offset; i < total; i += elem_words) {
        _SPM unsigned * cp = spm_bfe_consume(&buf1);

        assert((unsigned) cp >= DATA_SPM_BASE);
        assert((unsigned) (&cp[elem_words]) <= (DATA_SPM_BASE + spm_usage));

        for (j = 0; j < elem_words; j++) {
            assert(cp[j] == off_chip[i + j]);
        }
    }
    spm_wait();

    printf("ok\n");
    fflush(stdout);
}

typedef struct Task_struct {
            unsigned *      ptr;
            unsigned        remaining;
            SPM_BFE_Buffer  buf;
        } Task;



static void multibuf(unsigned max_spm_usage_per_job, 
                unsigned num_tasks, unsigned run_limit)
{
    Task *      tasks = alloca(num_tasks * sizeof(Task));
    //Task        tasks[MAX_TASKS];
    unsigned    i, j, fetches = 0;
    unsigned    job_mask;
    unsigned    spm_usage_per_job;

    assert(num_tasks <= MAX_TASKS);
    assert(num_tasks > 1);
    memset(tasks, 0, num_tasks * sizeof(Task));

    // get a sensible spm_usage_per_job based on SPM size
    // spm_usage_per_job must be a multiple of (1 << spm_block_shift)
    // spm_usage_per_job must be a power of 2
    // spm_usage_per_job * num_tasks must fit within the SPM
    i = 16;
    do {
        i --;
        spm_usage_per_job = 1 << i;
    } while (i && ((spm_usage_per_job * num_tasks) > DATA_SPM_SIZE));

    // sanity checks
    assert((spm_usage_per_job * num_tasks) <= DATA_SPM_SIZE);   // fits SPM?
    assert((spm_usage_per_job % (1 << spm_block_shift)) == 0);  // multiple?
    assert(spm_usage_per_job != 0);                             // not zero?
    // aligned?
    assert(spm_is_aligned((const _SPM void *) spm_usage_per_job));
    assert(spm_is_aligned((const _SPM void *) (spm_usage_per_job / 2)));

    job_mask = num_tasks - 1;
    for (i = 0; i < 16; i++) {
        job_mask |= job_mask >> 1;
    }

    for (i = j = 0; i < run_limit; i++) {
        _SPM unsigned * test;

        do {
            j = myrand() & job_mask;
        } while (j >= num_tasks);

        if (!tasks[j].remaining) {
            tasks[j].ptr = (unsigned *) &off_chip[myrand() % 
                            (MAX_TEST_SIZE - (DATA_SPM_WORDS * 2))];
            tasks[j].remaining = myrand() % (
                    &off_chip[MAX_TEST_SIZE] - tasks[j].ptr);

            fetches++;
            spm_bfe_init(&tasks[j].buf, tasks[j].ptr,
                    ((_SPM unsigned char *) data_spm) + (spm_usage_per_job * j),
                    spm_usage_per_job, 4);
        }
        test = spm_bfe_consume(&tasks[j].buf);
        assert(test[0] == tasks[j].ptr[0]);
        tasks[j].ptr++;
        tasks[j].remaining--;
    }
    spm_wait();
    printf("%u tasks at once, %u fetches, %u reads, %u per job, myrand %04x\n", 
                num_tasks, fetches, run_limit, 
                spm_usage_per_job, myrand() & 0xffff);
}

static void spm_size_test(void)
{
#ifndef PATMOS
    /* Cannot check the size on Patmos because the SPM is not overmapped */
    unsigned i, j;
    const unsigned oversize = 256;
    const unsigned DBF = 0xdeadbeef;

    assert(DATA_SPM_SIZE == (DATA_SPM_WORDS * 4));
    for (i = 0; i < (oversize * DATA_SPM_WORDS); i++) {
        data_spm[i] = i;
    }
    for (i = 0; i < (oversize * DATA_SPM_WORDS); i++) {
        j = data_spm[i];
        if (j == DBF) {
            printf("SPM size is actually %u words\n", i);
            assert(i == DATA_SPM_WORDS);
            break;
        } 
        assert(j == i);
    }
    assert(i == DATA_SPM_WORDS);

    for (; i < (oversize * DATA_SPM_WORDS); i++) {
        assert(data_spm[i] == DBF);
    }
    for (i = 0; i < DATA_SPM_WORDS; i++) {
        assert(data_spm[i] == i);
    }
    for (; i < (oversize * DATA_SPM_WORDS); i++) {
        data_spm[i] = ~i;
    }
    for (i = 0; i < DATA_SPM_WORDS; i++) {
        assert(data_spm[i] == i);
    }
    for (; i < (oversize * DATA_SPM_WORDS); i++) {
        assert(data_spm[i] == DBF);
    }
    mysrand(2);
    for (i = 0; i < (oversize * DATA_SPM_WORDS); i++) {
        data_spm[i] = myrand();
    }
    mysrand(2);
    for (i = 0; i < DATA_SPM_WORDS; i++) {
        j = data_spm[i];
        j ^= myrand();
        assert(j == 0);
    }
    for (; i < (oversize * DATA_SPM_WORDS); i++) {
        assert(data_spm[i] == DBF);
    }
#endif
}

static unsigned random_state = 1;

static void mysrand(unsigned x)
{
    random_state = x;
}

static unsigned myrand(void)
{
    random_state = ((random_state & 0xffff) * 36969) +
                    (random_state >> 16);
    return random_state;
}
