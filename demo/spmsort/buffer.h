#ifndef BUFFER_H
#define BUFFER_H


#include <machine/spm.h>

#include "sortexample.h"


typedef struct SPM_BFE_Buffer_struct {
            unsigned short  element_size, consumer;
            unsigned short  space_mask, trigger, fetch_size;
            control_t       control_a, control_b;
            _SPM  unsigned char * base;
            const unsigned char * source_ptr;
        } SPM_BFE_Buffer;

typedef struct SPM_BTE_Buffer_struct {
            unsigned short  element_size, producer;
            unsigned short  space_mask, trigger, send_size;
            control_t       control_a, control_b;
            _SPM unsigned char * base;
            unsigned char * target_ptr;
        } SPM_BTE_Buffer;

/* BFE = Buffer From External Memory (Consumer) */
void spm_bfe_init(SPM_BFE_Buffer * bfe,
                        const void * source,
                        _SPM void * spm_area,
                        unsigned short spm_area_size,
                        unsigned short element_size);

/* Call when finished with a BFE buffer */
void spm_bfe_finish(SPM_BFE_Buffer * bfe);

/* BTE = Buffer To External Memory (Producer) */
_SPM void * spm_bte_init(SPM_BTE_Buffer * bte,
                        void * target,
                        _SPM void * spm_area,
                        unsigned short spm_area_size,
                        unsigned short element_size);

/* Call when finished with a BTE buffer */
void spm_bte_finish(SPM_BTE_Buffer * bte);

/* Internal buffering functions */
void spm_bfe_trigger(SPM_BFE_Buffer * bfe);
void spm_bte_trigger(SPM_BTE_Buffer * bfe);

/* Return a pointer to the next available element.
 * Element is guaranteed to be in SPM and ready for use. */
static inline _SPM void * spm_bfe_consume(SPM_BFE_Buffer * bfe)
{
    unsigned c = bfe->consumer;
    _SPM void * ptr = &bfe->base[c];

    if (c == bfe->trigger) {
        /* Time to start another fetch (and wait for the current one
         * if it has not yet finished) */
        spm_bfe_trigger(bfe);
    }
    bfe->consumer = (c + bfe->element_size) & bfe->space_mask;
    return ptr;
}

/* Element is finished; return a pointer for the next element */
static inline _SPM void * spm_bte_produce(SPM_BTE_Buffer * bte)
{
    unsigned p = bte->producer;

    bte->producer = p = (p + bte->element_size) & bte->space_mask;
    if (p == bte->trigger) {
        /* Time to start sending data to external memory */
        spm_bte_trigger(bte);
    }
    return &bte->base[p];
}


#endif


