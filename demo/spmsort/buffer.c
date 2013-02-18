
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "buffer.h"



/* Create buffer from external memory (i.e. software is consumer) */
void spm_bfe_init(SPM_BFE_Buffer * bfe,
                        const void * source,
                        _SPM void * spm_area,
                        unsigned short spm_area_size,
                        unsigned short element_size)
{
    unsigned spm_area_size_is_power_of_two = 0;
    unsigned i;
    _SPM unsigned char * area_a;
    _SPM unsigned char * area_b;

    memset(bfe, 0, sizeof(SPM_BFE_Buffer));
    assert(spm_area_size);
    assert(element_size);

    /* Rule 1: spm_area_size must be a power of two */
    for (i = 0; i < 16; i++) {
        if ((unsigned) spm_area_size == (1 << i)) {
            spm_area_size_is_power_of_two = 1;
            break;
        }
    }
    assert(spm_area_size_is_power_of_two);
    assert(spm_is_aligned((_SPM void *)(spm_area_size / 2)));

    /* Rule 2: (spm_area_size/2) must be divisible by element_size */
    assert(((spm_area_size / 2) % element_size) == 0);

    /* Placements of buffers in SPM */
    area_a = (_SPM unsigned char *) spm_area;
    area_b = &area_a[spm_area_size / 2];

    /* Ready to initialise the structure now */
    bfe->element_size = element_size;
    bfe->space_mask = spm_area_size - 1;
    bfe->fetch_size = spm_area_size / 2;
    bfe->source_ptr = (const unsigned char *) spm_data_align_floor((void *) source);
    bfe->base = area_a;
   
    /* Align check */
    assert(spm_is_aligned(area_a));
    assert(spm_is_aligned(area_b));
    assert(spm_data_is_aligned(bfe->source_ptr));

    /* Create control words for SPM operations */
    bfe->control_a = spm_get_control_word(area_a, bfe->fetch_size);
    bfe->control_b = spm_get_control_word(area_b, bfe->fetch_size);

    /* Initial fetch into areas A */
    spm_control((void *) bfe->source_ptr, bfe->control_a);

    /* First consumer (in area A) is alignment-dependent so that the source pointer
     * does not need to be correctly aligned. Fetch B as soon as the first element 
     * is consumed */
    bfe->trigger = bfe->consumer = 
            ((unsigned char *) source - (unsigned char *) bfe->source_ptr);

    bfe->source_ptr += bfe->fetch_size;
    assert(spm_data_is_aligned(bfe->source_ptr));
    assert(bfe->consumer < bfe->fetch_size);

    /* The source pointer cannot point to the middle of an element */
    assert((bfe->consumer % element_size) == 0);
    spm_wait();
}


/* Time to start another fetch (and wait for the current one
 * if it has not yet finished) */
void spm_bfe_trigger(SPM_BFE_Buffer * bfe)
{
    if (bfe->trigger < bfe->fetch_size) {
        /* Consuming area A - Fetch area B */
        bfe->trigger = bfe->fetch_size;
        spm_control((void *) bfe->source_ptr, bfe->control_b);
    } else {
        /* Consuming area B - Fetch area A */
        bfe->trigger = 0;
        spm_control((void *) bfe->source_ptr, bfe->control_a);
    }
    bfe->source_ptr += bfe->fetch_size;
}

void spm_bfe_finish(SPM_BFE_Buffer * bte)
{
    spm_wait();
}

/* Create buffer to external memory (i.e. software is producer) */
_SPM void * spm_bte_init(SPM_BTE_Buffer * bte,
                        void * target,
                        _SPM void * spm_area,
                        unsigned short spm_area_size,
                        unsigned short element_size)
{
    unsigned spm_area_size_is_power_of_two = 0;
    unsigned i;
    _SPM unsigned char * area_a;
    _SPM unsigned char * area_b;

    memset(bte, 0, sizeof(SPM_BTE_Buffer));
    assert(spm_area_size);
    assert(element_size);

    /* Rule 1: spm_area_size must be a power of two */
    for (i = 0; i < 16; i++) {
        if ((unsigned) spm_area_size == (1 << i)) {
            spm_area_size_is_power_of_two = 1;
            break;
        }
    }
    assert(spm_area_size_is_power_of_two);
    assert(spm_is_aligned((_SPM void *)(spm_area_size / 2)));

    /* Rule 2: (spm_area_size/2) must be divisible by element_size */
    assert(((spm_area_size / 2) % element_size) == 0);

    /* Placements of buffers in SPM */
    area_a = (_SPM unsigned char *) spm_area;
    area_b = &area_a[spm_area_size / 2];

    /* Ready to initialise the structure now */
    bte->element_size = element_size;
    bte->space_mask = spm_area_size - 1;
    bte->send_size = spm_area_size / 2;
    bte->target_ptr = (unsigned char *) target;
    bte->base = area_a;
   
    /* Align check - stricter for producers than for consumers */
    assert(spm_is_aligned(area_a));
    assert(spm_is_aligned(area_b));
    assert(spm_data_is_aligned(target));

    /* Create control words for SPM operations */
    bte->control_a = spm_get_control_word(area_a, bte->send_size) | FLAG_COPY_TO;
    bte->control_b = spm_get_control_word(area_b, bte->send_size) | FLAG_COPY_TO;

    /* Initially producing element 0 (area A). Send area A once complete */
    bte->producer = 0;
    bte->trigger = bte->send_size;

    return &bte->base[0];
}

/* Time to start sending data to external memory */
void spm_bte_trigger(SPM_BTE_Buffer * bte)
{
    if (bte->trigger < bte->send_size) {
        /* Data produced in area B. Send area B. */
        bte->trigger = bte->send_size;
        spm_control((void *) bte->target_ptr, bte->control_b);
    } else {
        /* Data produced in area A. Send area A. */
        bte->trigger = 0;
        spm_control((void *) bte->target_ptr, bte->control_a);
    }
    bte->target_ptr += bte->send_size;
}

void spm_bte_finish(SPM_BTE_Buffer * bte)
{
    spm_bte_trigger(bte);
    spm_wait();
}

