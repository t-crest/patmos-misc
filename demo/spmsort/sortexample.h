#ifndef SORTEXAMPLE_H
#define SORTEXAMPLE_H

#include <stdio.h>
#include <string.h>

#include <machine/spm.h>

typedef struct Element_struct {
            int         key;
            int         payload;
        } Element;

#define BLOCK_SIZE_4_WORDS  0x200
#define BLOCK_SIZE_8_WORDS  0x300
#define BLOCK_SIZE_16_WORDS 0x400 
#define BLOCK_SIZE_32_WORDS 0x500 
#define BLOCK_SIZE_64_WORDS 0x600 

#define MAX_SORT_SIZE       0x80000

#define MAX_ELEMENTS    (MAX_SORT_SIZE / sizeof(Element))

extern _SPM unsigned *data_spm;
extern      unsigned *sort_this;

extern Element elements[];
extern Element alternate_storage[];

extern void haertel(void *base, size_t nmemb);
extern void schmidt(void *base, size_t nmemb);
extern void heapsort(void *base, size_t nmemb);
extern void introsort(void *base, size_t nmemb);
extern void shellsort(void *base, size_t nmemb);
extern void bentley(void *base, size_t nmemb);
extern void spmsort(void *base, size_t nmemb);
extern void spmsort2(void *base, size_t nmemb);



#define FLAG_COPY_TO (1<<30)

typedef long long unsigned control_t;

static inline control_t spm_get_control_word(const _SPM void * spm_ptr, unsigned size)
{
    unsigned d = (unsigned) spm_ptr;

#ifdef CHECK_SPM
    assert(spm_is_aligned(spm_ptr));
    assert(spm_is_aligned((void *) size));
    assert(SPM_BASE <= (unsigned) spm_ptr);
    assert((unsigned) spm_ptr <= SPM_HIGH);
#endif
    return ((control_t)d << 32) | (size);
}

static inline void spm_control(void * src, control_t ctrl)
{
    _SPM void *dst =  (_SPM void*) (ctrl >> 32);
    size_t n  = (size_t) (ctrl & 0x0FFFFFFF);
    if (ctrl & FLAG_COPY_TO) {
	spm_copy_to_ext(src, dst, n);
    } else {
	spm_copy_from_ext(dst, src, n);
    }
}


static inline int sort_comparator(const void *elem1, const void *elem2)
{
    int k1 = ((Element *) elem1)->key;
    int k2 = ((Element *) elem2)->key;
    return k1 - k2;
}

static inline void swap_memory(char *a, char *b, size_t size)
{
    Element * a1 = (Element *) a;
    Element * b1 = (Element *) b;

    size /= sizeof(Element);
    while(size) {
        Element tmp0 = a1[0];
        a1[0] = b1[0];
        b1[0] = tmp0;
        a1 ++;
        size --;
    }
}

static inline int spm_sort_comparator(_SPM const void *elem1, _SPM const void *elem2)
{
    int k1 = ((_SPM Element *) elem1)->key;
    int k2 = ((_SPM Element *) elem2)->key;
    return k1 - k2;
}

static inline void spm_swap_memory(_SPM char *a, _SPM char *b, size_t size)
{
    _SPM Element * a1 = (_SPM Element *) a;
    _SPM Element * b1 = (_SPM Element *) b;

    size /= sizeof(Element);
    while(size) {
        Element tmp0 = a1[0];
        a1[0] = b1[0];
        b1[0] = tmp0;
        a1 ++;
        size --;
    }
}


typedef struct {
            char *lo;
            char *hi;
        } stack_node;

typedef struct {
            _SPM char *lo;
            _SPM char *hi;
        } spm_stack_node;


#endif

