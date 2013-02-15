
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <machine/spm.h>

#include "buffer.h"

#define MAX_ITEMS       (1024*128)
#define MAX_PTR         (MAX_ITEMS - 1000)


static void tester(unsigned offset,
                unsigned num_elements, 
                unsigned elem_size,
                unsigned spm_usage);
static void multibuf(unsigned spm_usage_per_job, unsigned num_tasks);


unsigned sort_this[];
unsigned *data_spm = SPM_BASE;


int main(void)
{
    unsigned i, j, esize, cycle, x = 0;
    unsigned * elem;
    SPM_BTE_Buffer bte;

    /* Always call spm_init as a first step */
    spm_init();

    printf("basic tests\n");
    tester(0, 1024, 4, 1024);
    tester(0, 1, 4, 1024);
    tester(1, 1024, 4, 1024);
    tester(0, 1, 8, 512);

    srand(1000);

    for (cycle = 0; cycle < 100; cycle++) {
        do {
            esize = 1 << (rand() % 8);
        } while (((SPM_SIZE / 2) % (esize * 4)) != 0);

        printf("%u writing test pattern, element size %u\n", cycle, esize);

        for (i = MAX_ITEMS; i < (MAX_ITEMS + (SPM_WORDS * 2)); i++) {
            sort_this[i] = 0;
        }

        elem = spm_bte_init(&bte, sort_this, 
                    data_spm, SPM_SIZE, esize * 4);
        srand(cycle + 1);
        for (i = 0; i < MAX_ITEMS; ) {
            for (j = 0; j < esize; i++, j++) {
                elem[j] = rand() + 1;
            }
            elem = spm_bte_produce(&bte);
        }
        spm_bte_finish(&bte);

        //invalidate_data_cache();

        printf("%u checking test pattern, element size %u\n", cycle, esize);

        srand(cycle + 1);
        x = 0;
        for (i = 0; i < MAX_ITEMS; i++) {
            j = rand() + 1;
            if (sort_this[i] != j) {
                printf("sort_this[%u] = %u should be %u\n",
                        i, sort_this[i], j);
                x++;
                assert(x < 10);
            }
        }
        assert(!x);

        x = 0;
        for (i = 0; i < (SPM_WORDS * 2); i++) {
            if (sort_this[i + MAX_ITEMS] != 0) {
                x = i;
            }
        }
        printf("producer overshot by %u (%u)\n", x, SPM_WORDS * 2);

        printf("%u single buffer tests\n", cycle);
        for (i = 0; i < 25; i++) {
            unsigned elem_size = 4 << (rand() % 4);
            unsigned spm_elems = SPM_SIZE / elem_size;
            unsigned total_elems;

            spm_elems /= 1 << (rand() % 4);
            if (spm_elems < 2) {
                spm_elems = 2;
            }
            total_elems = (rand() % MAX_ITEMS) + 1;
            tester((rand() % total_elems) % 256, total_elems, elem_size,
                    spm_elems * elem_size);
        }

        printf("%u multi-buffer tests\n", cycle);
        for (i = 2; i <= 16; i++) {
            multibuf(1024, i);
        }
        for (i = 2; i <= 8; i++) {
            multibuf(2048, i);
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
    assert(spm_usage <= SPM_SIZE);

    offset /= elem_words;
    offset *= elem_words;
    spm_bfe_init(&buf1, &sort_this[offset], data_spm, spm_usage, elem_size);

    for (i = offset; i < total; i += elem_words) {
        unsigned * cp = spm_bfe_consume(&buf1);

        assert((unsigned) cp >= SPM_BASE);
        assert((unsigned) (&cp[elem_words]) <= (SPM_BASE + spm_usage));

        for (j = 0; j < elem_words; j++) {
            assert(cp[j] == sort_this[i + j]);
        }
    }
    spm_wait();

    printf("ok\n");
    fflush(stdout);
}

typedef struct Task_struct {
            unsigned *      ptr;
            unsigned        remaining;
            unsigned        serial;
            SPM_BFE_Buffer  buf;
        } Task;


static void multibuf(unsigned spm_usage_per_job, unsigned num_tasks)
{
    Task *      tasks = alloca(num_tasks * sizeof(Task));
    unsigned    i, j, serial = 0;
    unsigned    check = 0;
    unsigned    job_mask;

    memset(tasks, 0, num_tasks * sizeof(Task));

    job_mask = num_tasks - 1;
    for (i = 0; i < 16; i++) {
        job_mask |= job_mask >> 1;
    }

    for (i = j = 0; i < 1000000; i++) {
        j = sort_this[i] & job_mask;
        if (j >= num_tasks) continue;

        if (tasks[j].remaining) {
            unsigned * test = spm_bfe_consume(&tasks[j].buf);
            assert(test[0] == tasks[j].ptr[0]);
            tasks[j].ptr++;
            tasks[j].remaining--;
            check++;
        } else {
            tasks[j].ptr = (unsigned *) &sort_this[rand() % MAX_PTR];
            tasks[j].remaining = rand() % (
                    &sort_this[MAX_ITEMS] - tasks[j].ptr);
            tasks[j].serial = serial;

            serial++;
            spm_bfe_init(&tasks[j].buf, tasks[j].ptr,
                    ((unsigned char *) data_spm) + (spm_usage_per_job * j),
                    spm_usage_per_job, 4);
        }
    }
    spm_wait();
    printf("%u tasks at once: %u words checked\n", num_tasks, check);
}


