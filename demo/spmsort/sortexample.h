#ifndef SORTEXAMPLE_H
#define SORTEXAMPLE_H

typedef struct Element_struct {
            int         key;
            int         payload;
        } Element;

#define BLOCK_SIZE_4_WORDS  0x20000
#define BLOCK_SIZE_8_WORDS  0x30000
#define BLOCK_SIZE_16_WORDS 0x40000 
#define BLOCK_SIZE_32_WORDS 0x50000 
#define BLOCK_SIZE_64_WORDS 0x60000 

#define SORT_BASE           0x98000000
#define ALT_STORE_BASE      0x9c000000

#define MAX_SORT_SIZE       (ALT_STORE_BASE - SORT_BASE)

#define MAX_ELEMENTS    (MAX_SORT_SIZE / sizeof(Element))

extern unsigned *data_spm;
extern unsigned *sort_this;

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

typedef struct {
            char *lo;
            char *hi;
        } stack_node;


#endif

