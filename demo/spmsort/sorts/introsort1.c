#include <assert.h>
/* Provide Declarations */
#include <stdarg.h>
#include <setjmp.h>
/* get a declaration for alloca */
#if defined(__CYGWIN__) || defined(__MINGW32__)
#define  alloca(x) __builtin_alloca((x))
#define _alloca(x) __builtin_alloca((x))
#elif defined(__APPLE__)
extern void *__builtin_alloca(unsigned long);
#define alloca(x) __builtin_alloca(x)
#define longjmp _longjmp
#define setjmp _setjmp
#elif defined(__sun__)
#if defined(__sparcv9)
extern void *__builtin_alloca(unsigned long);
#else
extern void *__builtin_alloca(unsigned int);
#endif
#define alloca(x) __builtin_alloca(x)
#elif defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__) || defined(__DragonFly__) || defined(__arm__)
#define alloca(x) __builtin_alloca(x)
#elif defined(_MSC_VER)
#define inline _inline
#define alloca(x) _alloca(x)
#else
#include <alloca.h>
#endif

#ifndef __GNUC__  /* Can only support "linkonce" vars with GCC */
#define __attribute__(X)
#endif

#if defined(__GNUC__) && defined(__APPLE_CC__)
#define __EXTERNAL_WEAK__ __attribute__((weak_import))
#elif defined(__GNUC__)
#define __EXTERNAL_WEAK__ __attribute__((weak))
#else
#define __EXTERNAL_WEAK__
#endif

#if defined(__GNUC__) && defined(__APPLE_CC__)
#define __ATTRIBUTE_WEAK__
#elif defined(__GNUC__)
#define __ATTRIBUTE_WEAK__ __attribute__((weak))
#else
#define __ATTRIBUTE_WEAK__
#endif

#if defined(__GNUC__)
#define __HIDDEN__ __attribute__((visibility("hidden")))
#endif

#ifdef __GNUC__
#define LLVM_NAN(NanStr)   __builtin_nan(NanStr)   /* Double */
#define LLVM_NANF(NanStr)  __builtin_nanf(NanStr)  /* Float */
#define LLVM_NANS(NanStr)  __builtin_nans(NanStr)  /* Double */
#define LLVM_NANSF(NanStr) __builtin_nansf(NanStr) /* Float */
#define LLVM_INF           __builtin_inf()         /* Double */
#define LLVM_INFF          __builtin_inff()        /* Float */
#define LLVM_PREFETCH(addr,rw,locality) __builtin_prefetch(addr,rw,locality)
#define __ATTRIBUTE_CTOR__ __attribute__((constructor))
#define __ATTRIBUTE_DTOR__ __attribute__((destructor))
#define LLVM_ASM           __asm__
#else
#define LLVM_NAN(NanStr)   ((double)0.0)           /* Double */
#define LLVM_NANF(NanStr)  0.0F                    /* Float */
#define LLVM_NANS(NanStr)  ((double)0.0)           /* Double */
#define LLVM_NANSF(NanStr) 0.0F                    /* Float */
#define LLVM_INF           ((double)0.0)           /* Double */
#define LLVM_INFF          0.0F                    /* Float */
#define LLVM_PREFETCH(addr,rw,locality)            /* PREFETCH */
#define __ATTRIBUTE_CTOR__
#define __ATTRIBUTE_DTOR__
#define LLVM_ASM(X)
#endif

#if __GNUC__ < 4 /* Old GCC's, or compilers not GCC */ 
#define __builtin_stack_save() 0   /* not implemented */
#define __builtin_stack_restore(X) /* noop */
#endif

#if __GNUC__ && __LP64__ /* 128-bit integer types */
typedef int __attribute__((mode(TI))) llvmInt128;
typedef unsigned __attribute__((mode(TI))) llvmUInt128;
#endif

#define CODE_FOR_MAIN() /* Any target-specific code for main()*/

#ifndef __cplusplus
typedef unsigned char bool;
#endif


/* Support for floating point constants */
typedef unsigned long long ConstantDoubleTy;
typedef unsigned int        ConstantFloatTy;
typedef struct { unsigned long long f1; unsigned short f2; unsigned short pad[3]; } ConstantFP80Ty;
typedef struct { unsigned long long f1; unsigned long long f2; } ConstantFP128Ty;


/* Global Declarations */
/* Helper union for bitcasts */
typedef union {
  unsigned int Int32;
  unsigned long long Int64;
  float Float;
  double Double;
} llvmBitCastUnion;
/* Structure forward decls */
struct l_struct_2E__2E_0_2E__10;
struct l_struct_2E__2E_1__pthread_mutex_s;
struct l_struct_2E_Element;
struct l_struct_2E_pthread_attr_t;
struct l_struct_2E_pthread_mutex_t;
struct l_unnamed0;

/* Typedefs */
typedef struct l_struct_2E__2E_0_2E__10 l_struct_2E__2E_0_2E__10;
typedef struct l_struct_2E__2E_1__pthread_mutex_s l_struct_2E__2E_1__pthread_mutex_s;
typedef struct l_struct_2E_Element l_struct_2E_Element;
typedef struct l_struct_2E_pthread_attr_t l_struct_2E_pthread_attr_t;
typedef struct l_struct_2E_pthread_mutex_t l_struct_2E_pthread_mutex_t;
typedef struct l_unnamed0 l_unnamed0;

/* Structure contents */
struct l_struct_2E__2E_0_2E__10 {
  unsigned int field0;
};

struct l_struct_2E__2E_1__pthread_mutex_s {
  unsigned int field0;
  unsigned int field1;
  unsigned int field2;
  unsigned int field3;
  unsigned int field4;
  struct l_struct_2E__2E_0_2E__10 field5;
};

struct l_struct_2E_Element {
  unsigned int field0;
  unsigned int field1;
};

struct l_unnamed0 { unsigned char array[32]; };

struct l_struct_2E_pthread_attr_t {
  unsigned int field0;
  struct l_unnamed0 field1;
};

struct l_struct_2E_pthread_mutex_t {
  struct l_struct_2E__2E_1__pthread_mutex_s field0;
};


/* Function Declarations */
double fmod(double, double);
float fmodf(float, float);
long double fmodl(long double, long double);
unsigned char _ZltRK14Element_structS1_(struct l_struct_2E_Element *llvm_cbe_elem1, struct l_struct_2E_Element *llvm_cbe_elem2);
void _ZSt9make_heapIP14Element_structEvT_S2_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last) __ATTRIBUTE_WEAK__;
void _ZSt10__pop_heapIP14Element_structS0_EvT_S2_S2_T0_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last, struct l_struct_2E_Element *llvm_cbe___result, unsigned int llvm_cbe___value_2e_0, unsigned int llvm_cbe___value_2e_1) __ATTRIBUTE_WEAK__;
void _ZSt16__introsort_loopIP14Element_structiEvT_S2_T0_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last, unsigned int llvm_cbe___depth_limit) __ATTRIBUTE_WEAK__;
void _ZSt16__insertion_sortIP14Element_structEvT_S2_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last) __ATTRIBUTE_WEAK__;
void _ZSt22__final_insertion_sortIP14Element_structEvT_S2_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last) __ATTRIBUTE_WEAK__;
void introsort(struct l_struct_2E_Element *llvm_cbe_bot, unsigned int llvm_cbe_total_elems);
extern unsigned int pthread_once(unsigned int *, void  (*) (void)) __EXTERNAL_WEAK__;
extern unsigned char *pthread_getspecific(unsigned int ) __EXTERNAL_WEAK__;
extern unsigned int pthread_setspecific(unsigned int , unsigned char *) __EXTERNAL_WEAK__;
extern unsigned int pthread_create(unsigned int *, struct l_struct_2E_pthread_attr_t *, unsigned char * (*) (unsigned char *), unsigned char *) __EXTERNAL_WEAK__;
extern unsigned int pthread_cancel(unsigned int ) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutex_lock(struct l_struct_2E_pthread_mutex_t *) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutex_trylock(struct l_struct_2E_pthread_mutex_t *) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutex_unlock(struct l_struct_2E_pthread_mutex_t *) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutex_init(struct l_struct_2E_pthread_mutex_t *, struct l_struct_2E__2E_0_2E__10 *) __EXTERNAL_WEAK__;
extern unsigned int pthread_key_create(unsigned int *, void  (*) (unsigned char *)) __EXTERNAL_WEAK__;
extern unsigned int pthread_key_delete(unsigned int ) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutexattr_init(struct l_struct_2E__2E_0_2E__10 *) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutexattr_settype(struct l_struct_2E__2E_0_2E__10 *, unsigned int ) __EXTERNAL_WEAK__;
extern unsigned int pthread_mutexattr_destroy(struct l_struct_2E__2E_0_2E__10 *) __EXTERNAL_WEAK__;
void free(unsigned char *);
void abort(void);


/* Function Bodies */
static inline int llvm_fcmp_ord(double X, double Y) { return X == X && Y == Y; }
static inline int llvm_fcmp_uno(double X, double Y) { return X != X || Y != Y; }
static inline int llvm_fcmp_ueq(double X, double Y) { return X == Y || llvm_fcmp_uno(X, Y); }
static inline int llvm_fcmp_une(double X, double Y) { return X != Y; }
static inline int llvm_fcmp_ult(double X, double Y) { return X <  Y || llvm_fcmp_uno(X, Y); }
static inline int llvm_fcmp_ugt(double X, double Y) { return X >  Y || llvm_fcmp_uno(X, Y); }
static inline int llvm_fcmp_ule(double X, double Y) { return X <= Y || llvm_fcmp_uno(X, Y); }
static inline int llvm_fcmp_uge(double X, double Y) { return X >= Y || llvm_fcmp_uno(X, Y); }
static inline int llvm_fcmp_oeq(double X, double Y) { return X == Y ; }
static inline int llvm_fcmp_one(double X, double Y) { return X != Y && llvm_fcmp_ord(X, Y); }
static inline int llvm_fcmp_olt(double X, double Y) { return X <  Y ; }
static inline int llvm_fcmp_ogt(double X, double Y) { return X >  Y ; }
static inline int llvm_fcmp_ole(double X, double Y) { return X <= Y ; }
static inline int llvm_fcmp_oge(double X, double Y) { return X >= Y ; }

unsigned char _ZltRK14Element_structS1_(struct l_struct_2E_Element *llvm_cbe_elem1, struct l_struct_2E_Element *llvm_cbe_elem2) {
  unsigned int llvm_cbe_tmp__1;
  unsigned int llvm_cbe_tmp__2;

  llvm_cbe_tmp__1 = *((&llvm_cbe_elem1->field0));
  llvm_cbe_tmp__2 = *((&llvm_cbe_elem2->field0));
  return (((unsigned char )(bool )(((signed int )llvm_cbe_tmp__1) < ((signed int )llvm_cbe_tmp__2))));
}


void _ZSt9make_heapIP14Element_structEvT_S2_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last) {
  unsigned int llvm_cbe_tmp__3;
  unsigned int llvm_cbe_tmp__4;
  unsigned int llvm_cbe_tmp__5;
  unsigned int llvm_cbe_tmp10;
  unsigned int llvm_cbe_tmp12;
  unsigned int llvm_cbe_indvar;
  unsigned int llvm_cbe_indvar__PHI_TEMPORARY;
  unsigned int llvm_cbe___parent_2e_0;
  unsigned int llvm_cbe_tmp9;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in13_2e_i;
  unsigned int llvm_cbe___secondChild_2e_115_2e_i;
  unsigned int llvm_cbe_tmp__6;
  unsigned int llvm_cbe_tmp__7;
  unsigned int llvm_cbe___secondChild_2e_116_2e_i;
  unsigned int llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in14_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___holeIndex_addr_2e_011_2e_i;
  unsigned int llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__8;
  unsigned int llvm_cbe_tmp__9;
  unsigned int llvm_cbe_tmp__10;
  unsigned int llvm_cbe___secondChild_2e_1_2e__2e_i;
  unsigned int llvm_cbe_tmp__11;
  unsigned int llvm_cbe_tmp__12;
  unsigned int llvm_cbe_phitmp_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__13;
  unsigned int llvm_cbe_tmp__14;
  unsigned int llvm_cbe_tmp__15;
  unsigned int llvm_cbe_tmp__16;
  unsigned int llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i;
  unsigned int llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___parent_2e_0_2e_i_2e_i;
  unsigned int llvm_cbe_tmp__17;
  unsigned int llvm_cbe_indvar_2e_next;

  assert(0);
  llvm_cbe_tmp__3 = ((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___last))) - ((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___first)))));
  if ((((signed int )llvm_cbe_tmp__3) > ((signed int )15u))) {
    goto llvm_cbe_bb;
  } else {
    goto llvm_cbe_return;
  }

llvm_cbe_bb:
  llvm_cbe_tmp__4 = ((signed int )(((signed int )llvm_cbe_tmp__3) >> ((signed int )3u)));
  llvm_cbe_tmp__5 = ((signed int )(((signed int )(((unsigned int )(((unsigned int )llvm_cbe_tmp__4) + ((unsigned int )4294967294u))))) / ((signed int )2u)));
  llvm_cbe_tmp10 = llvm_cbe_tmp__5 << 1u;
  llvm_cbe_tmp12 = ((unsigned int )(((unsigned int )llvm_cbe_tmp10) + ((unsigned int )2u)));
  llvm_cbe_indvar__PHI_TEMPORARY = 0u;   /* for PHI node */
  goto llvm_cbe_bb1;

  do {     /* Syntactic loop 'bb1' to make GCC happy */
llvm_cbe_bb1:
  llvm_cbe_indvar = llvm_cbe_indvar__PHI_TEMPORARY;
  llvm_cbe___parent_2e_0 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__5) - ((unsigned int )llvm_cbe_indvar)));
  llvm_cbe_tmp9 = ((unsigned int )(((unsigned int )llvm_cbe_indvar) * ((unsigned int )4294967294u)));
  llvm_cbe___secondChild_2e_1_2e_in13_2e_i = ((unsigned int )(((unsigned int )llvm_cbe_tmp9) + ((unsigned int )llvm_cbe_tmp10)));
  llvm_cbe___secondChild_2e_115_2e_i = ((unsigned int )(((unsigned int )llvm_cbe_tmp9) + ((unsigned int )llvm_cbe_tmp12)));
  llvm_cbe_tmp__6 = *((&llvm_cbe___first[((signed int )llvm_cbe___parent_2e_0)].field0));
  llvm_cbe_tmp__7 = *((&llvm_cbe___first[((signed int )llvm_cbe___parent_2e_0)].field1));
  if ((((signed int )llvm_cbe___secondChild_2e_115_2e_i) < ((signed int )llvm_cbe_tmp__4))) {
    llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_115_2e_i;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_in13_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY = llvm_cbe___parent_2e_0;   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  } else {
    llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_115_2e_i;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_in13_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___parent_2e_0;   /* for PHI node */
    goto llvm_cbe_bb4_2e_i;
  }

llvm_cbe_bb4:
  llvm_cbe_indvar_2e_next = ((unsigned int )(((unsigned int )llvm_cbe_indvar) + ((unsigned int )1u)));
  llvm_cbe_indvar__PHI_TEMPORARY = llvm_cbe_indvar_2e_next;   /* for PHI node */
  goto llvm_cbe_bb1;

llvm_cbe__ZSt13__adjust_heapIP14Element_structiS0_EvT_T0_S3_T1__2e_exit:
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field0)) = llvm_cbe_tmp__6;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field1)) = llvm_cbe_tmp__7;
  if (llvm_cbe_tmp__5 == llvm_cbe_indvar) {
    goto llvm_cbe_return;
  } else {
    goto llvm_cbe_bb4;
  }

  do {     /* Syntactic loop 'bb1.i.i' to make GCC happy */
llvm_cbe_bb1_2e_i_2e_i:
  llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i = llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i = llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe___parent_2e_0_2e_i_2e_i = ((signed int )(((signed int )(((unsigned int )(((unsigned int )llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i) + ((unsigned int )4294967295u))))) / ((signed int )2u)));
  if ((((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i) > ((signed int )llvm_cbe___parent_2e_0))) {
    goto llvm_cbe_bb2_2e_i_2e_i;
  } else {
    goto llvm_cbe__ZSt13__adjust_heapIP14Element_structiS0_EvT_T0_S3_T1__2e_exit;
  }

llvm_cbe_bb_2e_i_2e_i:
  llvm_cbe_tmp__16 = *((&llvm_cbe___first[((signed int )llvm_cbe___parent_2e_0_2e_i_2e_i)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field0)) = llvm_cbe_tmp__17;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field1)) = llvm_cbe_tmp__16;
  llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___parent_2e_0_2e_i_2e_i;   /* for PHI node */
  llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___parent_2e_0_2e_i_2e_i;   /* for PHI node */
  goto llvm_cbe_bb1_2e_i_2e_i;

llvm_cbe_bb2_2e_i_2e_i:
  llvm_cbe_tmp__17 = *((&llvm_cbe___first[((signed int )llvm_cbe___parent_2e_0_2e_i_2e_i)].field0));
  if ((((signed int )llvm_cbe_tmp__17) < ((signed int )llvm_cbe_tmp__6))) {
    goto llvm_cbe_bb_2e_i_2e_i;
  } else {
    goto llvm_cbe__ZSt13__adjust_heapIP14Element_structiS0_EvT_T0_S3_T1__2e_exit;
  }

  } while (1); /* end of syntactic loop 'bb1.i.i' */
llvm_cbe_bb4_2e_i:
  llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i = llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY;
  llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i = llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY;
  llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i = llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  if (llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i == llvm_cbe_tmp__4) {
    goto llvm_cbe_bb5_2e_i;
  } else {
    llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i;   /* for PHI node */
    goto llvm_cbe_bb1_2e_i_2e_i;
  }

  do {     /* Syntactic loop 'bb.i' to make GCC happy */
llvm_cbe_bb_2e_i:
  llvm_cbe___secondChild_2e_116_2e_i = llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY;
  llvm_cbe___secondChild_2e_1_2e_in14_2e_i = llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY;
  llvm_cbe___holeIndex_addr_2e_011_2e_i = llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp__8 = llvm_cbe___secondChild_2e_1_2e_in14_2e_i | 1u;
  llvm_cbe_tmp__9 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_116_2e_i)].field0));
  llvm_cbe_tmp__10 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp__8)].field0));
  llvm_cbe___secondChild_2e_1_2e__2e_i = (((((signed int )llvm_cbe_tmp__9) < ((signed int )llvm_cbe_tmp__10))) ? (llvm_cbe_tmp__8) : (llvm_cbe___secondChild_2e_116_2e_i));
  llvm_cbe_tmp__11 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_1_2e__2e_i)].field0));
  llvm_cbe_tmp__12 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_1_2e__2e_i)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_011_2e_i)].field0)) = llvm_cbe_tmp__11;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_011_2e_i)].field1)) = llvm_cbe_tmp__12;
  llvm_cbe_phitmp_2e_i = llvm_cbe___secondChild_2e_1_2e__2e_i << 1u;
  llvm_cbe___secondChild_2e_1_2e_i = ((unsigned int )(((unsigned int )llvm_cbe_phitmp_2e_i) + ((unsigned int )2u)));
  if ((((signed int )llvm_cbe___secondChild_2e_1_2e_i) < ((signed int )llvm_cbe_tmp__4))) {
    llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_i;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY = llvm_cbe_phitmp_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e__2e_i;   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  } else {
    llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_i;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe_phitmp_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e__2e_i;   /* for PHI node */
    goto llvm_cbe_bb4_2e_i;
  }

  } while (1); /* end of syntactic loop 'bb.i' */
llvm_cbe_bb5_2e_i:
  llvm_cbe_tmp__13 = llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i | 1u;
  llvm_cbe_tmp__14 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp__13)].field0));
  llvm_cbe_tmp__15 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp__13)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i)].field0)) = llvm_cbe_tmp__14;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i)].field1)) = llvm_cbe_tmp__15;
  llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe_tmp__13;   /* for PHI node */
  llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe_tmp__13;   /* for PHI node */
  goto llvm_cbe_bb1_2e_i_2e_i;

  } while (1); /* end of syntactic loop 'bb1' */
llvm_cbe_return:
  return;
}


void _ZSt10__pop_heapIP14Element_structS0_EvT_S2_S2_T0_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last, struct l_struct_2E_Element *llvm_cbe___result, unsigned int llvm_cbe___value_2e_0, unsigned int llvm_cbe___value_2e_1) {
  unsigned int llvm_cbe_tmp__18;
  unsigned int llvm_cbe_tmp__19;
  unsigned int llvm_cbe_tmp__20;
  unsigned int llvm_cbe___secondChild_2e_116_2e_i;
  unsigned int llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in14_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___holeIndex_addr_2e_011_2e_i;
  unsigned int llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__21;
  unsigned int llvm_cbe_tmp__22;
  unsigned int llvm_cbe_tmp__23;
  unsigned int llvm_cbe___secondChild_2e_1_2e__2e_i;
  unsigned int llvm_cbe_tmp__24;
  unsigned int llvm_cbe_tmp__25;
  unsigned int llvm_cbe_phitmp_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_i;
  unsigned int llvm_cbe_phitmp;
  unsigned int llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i;
  unsigned int llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__26;
  unsigned int llvm_cbe_tmp__27;
  unsigned int llvm_cbe_tmp__28;
  unsigned int llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i;
  unsigned int llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i;
  unsigned int llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe___parent_2e_0_2e_i_2e_i;
  unsigned int llvm_cbe_tmp__29;

  llvm_cbe_tmp__18 = *((&llvm_cbe___first->field0));
  llvm_cbe_tmp__19 = *((&llvm_cbe___first->field1));
  *((&llvm_cbe___result->field0)) = llvm_cbe_tmp__18;
  *((&llvm_cbe___result->field1)) = llvm_cbe_tmp__19;
  llvm_cbe_tmp__20 = ((signed int )(((signed int )(((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___last))) - ((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___first))))))) >> ((signed int )3u)));
  if ((((signed int )llvm_cbe_tmp__20) > ((signed int )2u))) {
    llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY = 2u;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  } else {
    llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY = 2u;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY = 1u;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb4_2e_i;
  }

  do {     /* Syntactic loop 'bb.i' to make GCC happy */
llvm_cbe_bb_2e_i:
  llvm_cbe___secondChild_2e_116_2e_i = llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY;
  llvm_cbe___secondChild_2e_1_2e_in14_2e_i = llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY;
  llvm_cbe___holeIndex_addr_2e_011_2e_i = llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp__21 = llvm_cbe___secondChild_2e_1_2e_in14_2e_i | 1u;
  llvm_cbe_tmp__22 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_116_2e_i)].field0));
  llvm_cbe_tmp__23 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp__21)].field0));
  llvm_cbe___secondChild_2e_1_2e__2e_i = (((((signed int )llvm_cbe_tmp__22) < ((signed int )llvm_cbe_tmp__23))) ? (llvm_cbe_tmp__21) : (llvm_cbe___secondChild_2e_116_2e_i));
  llvm_cbe_tmp__24 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_1_2e__2e_i)].field0));
  llvm_cbe_tmp__25 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_1_2e__2e_i)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_011_2e_i)].field0)) = llvm_cbe_tmp__24;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_011_2e_i)].field1)) = llvm_cbe_tmp__25;
  llvm_cbe_phitmp_2e_i = llvm_cbe___secondChild_2e_1_2e__2e_i << 1u;
  llvm_cbe___secondChild_2e_1_2e_i = ((unsigned int )(((unsigned int )llvm_cbe_phitmp_2e_i) + ((unsigned int )2u)));
  if ((((signed int )llvm_cbe___secondChild_2e_1_2e_i) < ((signed int )llvm_cbe_tmp__20))) {
    llvm_cbe___secondChild_2e_116_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_i;   /* for PHI node */
    llvm_cbe___secondChild_2e_1_2e_in14_2e_i__PHI_TEMPORARY = llvm_cbe_phitmp_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_011_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e__2e_i;   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  } else {
    goto llvm_cbe_bb4_2e_i_2e_loopexit;
  }

  } while (1); /* end of syntactic loop 'bb.i' */
llvm_cbe_bb4_2e_i_2e_loopexit:
  llvm_cbe_phitmp = llvm_cbe_phitmp_2e_i | 1u;
  llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_i;   /* for PHI node */
  llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe_phitmp;   /* for PHI node */
  llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e__2e_i;   /* for PHI node */
  goto llvm_cbe_bb4_2e_i;

llvm_cbe_bb4_2e_i:
  llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i = llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i__PHI_TEMPORARY;
  llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i = llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i__PHI_TEMPORARY;
  llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i = llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  if (llvm_cbe___secondChild_2e_1_2e_lcssa_2e_i == llvm_cbe_tmp__20) {
    goto llvm_cbe_bb5_2e_i;
  } else {
    llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i;   /* for PHI node */
    llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i;   /* for PHI node */
    goto llvm_cbe_bb1_2e_i_2e_i;
  }

llvm_cbe_bb5_2e_i:
  llvm_cbe_tmp__26 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i)].field0));
  llvm_cbe_tmp__27 = *((&llvm_cbe___first[((signed int )llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i)].field0)) = llvm_cbe_tmp__26;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_lcssa_2e_i)].field1)) = llvm_cbe_tmp__27;
  llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i;   /* for PHI node */
  llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___secondChild_2e_1_2e_in_2e_lcssa_2e_i;   /* for PHI node */
  goto llvm_cbe_bb1_2e_i_2e_i;

  do {     /* Syntactic loop 'bb1.i.i' to make GCC happy */
llvm_cbe_bb1_2e_i_2e_i:
  llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i = llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i = llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe___parent_2e_0_2e_i_2e_i = ((signed int )(((signed int )(((unsigned int )(((unsigned int )llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i) + ((unsigned int )4294967295u))))) / ((signed int )2u)));
  if ((((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i) > ((signed int )0u))) {
    goto llvm_cbe_bb2_2e_i_2e_i;
  } else {
    goto llvm_cbe__ZSt13__adjust_heapIP14Element_structiS0_EvT_T0_S3_T1__2e_exit;
  }

llvm_cbe_bb_2e_i_2e_i:
  llvm_cbe_tmp__28 = *((&llvm_cbe___first[((signed int )llvm_cbe___parent_2e_0_2e_i_2e_i)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field0)) = llvm_cbe_tmp__29;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field1)) = llvm_cbe_tmp__28;
  llvm_cbe___parent_2e_0_2e_in_2e_in_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___parent_2e_0_2e_i_2e_i;   /* for PHI node */
  llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe___parent_2e_0_2e_i_2e_i;   /* for PHI node */
  goto llvm_cbe_bb1_2e_i_2e_i;

llvm_cbe_bb2_2e_i_2e_i:
  llvm_cbe_tmp__29 = *((&llvm_cbe___first[((signed int )llvm_cbe___parent_2e_0_2e_i_2e_i)].field0));
  if ((((signed int )llvm_cbe_tmp__29) < ((signed int )llvm_cbe___value_2e_0))) {
    goto llvm_cbe_bb_2e_i_2e_i;
  } else {
    goto llvm_cbe__ZSt13__adjust_heapIP14Element_structiS0_EvT_T0_S3_T1__2e_exit;
  }

  } while (1); /* end of syntactic loop 'bb1.i.i' */
llvm_cbe__ZSt13__adjust_heapIP14Element_structiS0_EvT_T0_S3_T1__2e_exit:
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field0)) = llvm_cbe___value_2e_0;
  *((&llvm_cbe___first[((signed int )llvm_cbe___holeIndex_addr_2e_0_2e_i_2e_i)].field1)) = llvm_cbe___value_2e_1;
  return;
}


void _ZSt16__introsort_loopIP14Element_structiEvT_S2_T0_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last, unsigned int llvm_cbe___depth_limit) {
  unsigned int llvm_cbe_tmp__30;
  unsigned int *llvm_cbe_tmp__31;
  unsigned int llvm_cbe_tmp24;
  unsigned int llvm_cbe_indvar_2e_i1_2e_i;
  unsigned int llvm_cbe_indvar_2e_i1_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp12;
  struct l_struct_2E_Element *llvm_cbe_scevgep_2e_i3_2e_i;
  unsigned int llvm_cbe_tmp__32;
  unsigned int llvm_cbe_tmp__33;
  struct l_struct_2E_Element *llvm_cbe_tmp__34;
  unsigned int llvm_cbe_tmp__35;
  struct l_struct_2E_Element *llvm_cbe_tmp__36;
  unsigned int llvm_cbe_tmp__37;
  unsigned int llvm_cbe_tmp__38;
  unsigned int llvm_cbe_tmp__39;
  struct l_struct_2E_Element *llvm_cbe_retval_2e_i;
  struct l_struct_2E_Element *llvm_cbe_retval16_2e_i;
  struct l_struct_2E_Element *llvm_cbe_tmp__40;
  struct l_struct_2E_Element *llvm_cbe_tmp__40__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__41;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_0_2e_ph_2e_i;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY;
  struct l_struct_2E_Element *llvm_cbe___first_addr_2e_0_2e_ph_2e_i;
  struct l_struct_2E_Element *llvm_cbe___first_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__42;
  unsigned int llvm_cbe_indvar16_2e_i;
  unsigned int llvm_cbe_indvar16_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp15;
  struct l_struct_2E_Element *llvm_cbe_scevgep_2e_i9;
  unsigned int llvm_cbe_tmp__43;
  struct l_struct_2E_Element *llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i;
  struct l_struct_2E_Element *llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_indvar_2e_i;
  unsigned int llvm_cbe_indvar_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp14_2e_i;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_1_2e_i;
  unsigned int *llvm_cbe_scevgep15_2e_i;
  unsigned int llvm_cbe_tmp__44;
  unsigned int *llvm_cbe_tmp__45;
  unsigned int llvm_cbe_tmp__46;
  unsigned int *llvm_cbe_tmp__47;
  unsigned int llvm_cbe_tmp__48;
  unsigned int *llvm_cbe_tmp__49;
  unsigned int llvm_cbe_tmp__50;
  struct l_struct_2E_Element *llvm_cbe_tmp__51;
  unsigned int llvm_cbe_indvar_2e_next;
  unsigned int llvm_cbe_indvar;
  unsigned int llvm_cbe_indvar__PHI_TEMPORARY;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_0;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_0__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp25;
  unsigned int llvm_cbe_tmp__52;

  llvm_cbe_tmp__30 = ((unsigned int )(unsigned long)llvm_cbe___first);
  llvm_cbe_tmp__31 = (&llvm_cbe___first->field0);
  llvm_cbe_tmp24 = ((unsigned int )(((unsigned int )llvm_cbe___depth_limit) + ((unsigned int )4294967295u)));
  llvm_cbe_indvar__PHI_TEMPORARY = 0u;   /* for PHI node */
  llvm_cbe___last_addr_2e_0__PHI_TEMPORARY = llvm_cbe___last;   /* for PHI node */
  goto llvm_cbe_bb5;

llvm_cbe__ZSt13__heap_selectIP14Element_structEvT_S2_S2__2e_exit_2e_i:
   /*tail*/ _ZSt9make_heapIP14Element_structEvT_S2_(llvm_cbe___first, llvm_cbe___last_addr_2e_0);
  if ((((signed int )llvm_cbe_tmp__52) > ((signed int )15u))) {
    llvm_cbe_indvar_2e_i1_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i4_2e_i;
  } else {
    goto llvm_cbe__ZSt12partial_sortIP14Element_structEvT_S2_S2__2e_exit;
  }

  do {     /* Syntactic loop 'bb.i4.i' to make GCC happy */
llvm_cbe_bb_2e_i4_2e_i:
  llvm_cbe_indvar_2e_i1_2e_i = llvm_cbe_indvar_2e_i1_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp12 = llvm_cbe_indvar_2e_i1_2e_i ^ 4294967295u;
  llvm_cbe_scevgep_2e_i3_2e_i = (&llvm_cbe___last_addr_2e_0[((signed int )llvm_cbe_tmp12)]);
  llvm_cbe_tmp__32 = *((&llvm_cbe___last_addr_2e_0[((signed int )llvm_cbe_tmp12)].field0));
  llvm_cbe_tmp__33 = *((&((&llvm_cbe___last_addr_2e_0[((signed int )(-(llvm_cbe_indvar_2e_i1_2e_i)))].field0))[((signed int )4294967295u)]));
   /*tail*/ _ZSt10__pop_heapIP14Element_structS0_EvT_S2_S2_T0_(llvm_cbe___first, llvm_cbe_scevgep_2e_i3_2e_i, llvm_cbe_scevgep_2e_i3_2e_i, llvm_cbe_tmp__32, llvm_cbe_tmp__33);
  if ((((signed int )(((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe_scevgep_2e_i3_2e_i))) - ((unsigned int )llvm_cbe_tmp__30))))) > ((signed int )15u))) {
    llvm_cbe_indvar_2e_i1_2e_i__PHI_TEMPORARY = (((unsigned int )(((unsigned int )llvm_cbe_indvar_2e_i1_2e_i) + ((unsigned int )1u))));   /* for PHI node */
    goto llvm_cbe_bb_2e_i4_2e_i;
  } else {
    goto llvm_cbe__ZSt12partial_sortIP14Element_structEvT_S2_S2__2e_exit;
  }

  } while (1); /* end of syntactic loop 'bb.i4.i' */
llvm_cbe__ZSt12partial_sortIP14Element_structEvT_S2_S2__2e_exit:
  return;
  do {     /* Syntactic loop 'bb5' to make GCC happy */
llvm_cbe_bb5:
  llvm_cbe_indvar = llvm_cbe_indvar__PHI_TEMPORARY;
  llvm_cbe___last_addr_2e_0 = llvm_cbe___last_addr_2e_0__PHI_TEMPORARY;
  llvm_cbe_tmp25 = ((unsigned int )(((unsigned int )llvm_cbe_tmp24) - ((unsigned int )llvm_cbe_indvar)));
  llvm_cbe_tmp__52 = ((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___last_addr_2e_0))) - ((unsigned int )llvm_cbe_tmp__30)));
  if ((((signed int )llvm_cbe_tmp__52) > ((signed int )135u))) {
    goto llvm_cbe_bb;
  } else {
    goto llvm_cbe_return;
  }

llvm_cbe__ZSt21__unguarded_partitionIP14Element_structS0_ET_S2_S2_T0__2e_exit:
   /*tail*/ _ZSt16__introsort_loopIP14Element_structiEvT_S2_T0_(llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i, llvm_cbe___last_addr_2e_0, llvm_cbe_tmp25);
  llvm_cbe_indvar_2e_next = ((unsigned int )(((unsigned int )llvm_cbe_indvar) + ((unsigned int )1u)));
  llvm_cbe_indvar__PHI_TEMPORARY = llvm_cbe_indvar_2e_next;   /* for PHI node */
  llvm_cbe___last_addr_2e_0__PHI_TEMPORARY = llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i;   /* for PHI node */
  goto llvm_cbe_bb5;

  do {     /* Syntactic loop 'bb2.outer.i' to make GCC happy */
llvm_cbe_bb2_2e_outer_2e_i:
  llvm_cbe___last_addr_2e_0_2e_ph_2e_i = llvm_cbe___last_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY;
  llvm_cbe___first_addr_2e_0_2e_ph_2e_i = llvm_cbe___first_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp__42 = *((&llvm_cbe___first_addr_2e_0_2e_ph_2e_i->field0));
  if ((((signed int )llvm_cbe_tmp__42) < ((signed int )llvm_cbe_tmp__41))) {
    llvm_cbe_indvar16_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb1_2e_i;
  } else {
    llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___first_addr_2e_0_2e_ph_2e_i;   /* for PHI node */
    goto llvm_cbe_bb5_2e_preheader_2e_i;
  }

llvm_cbe_bb9_2e_i:
  llvm_cbe_tmp__45 = (&llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i->field0);
  llvm_cbe_tmp__46 = *llvm_cbe_tmp__45;
  llvm_cbe_tmp__47 = (&llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i->field1);
  llvm_cbe_tmp__48 = *llvm_cbe_tmp__47;
  llvm_cbe_tmp__49 = (&llvm_cbe___last_addr_2e_0_2e_ph_2e_i[((signed int )llvm_cbe_tmp14_2e_i)].field1);
  llvm_cbe_tmp__50 = *llvm_cbe_tmp__49;
  *llvm_cbe_tmp__45 = llvm_cbe_tmp__44;
  *llvm_cbe_tmp__47 = llvm_cbe_tmp__50;
  *llvm_cbe_scevgep15_2e_i = llvm_cbe_tmp__46;
  *llvm_cbe_tmp__49 = llvm_cbe_tmp__48;
  llvm_cbe_tmp__51 = (&llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i[((signed int )1u)]);
  llvm_cbe___last_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY = llvm_cbe___last_addr_2e_1_2e_i;   /* for PHI node */
  llvm_cbe___first_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY = llvm_cbe_tmp__51;   /* for PHI node */
  goto llvm_cbe_bb2_2e_outer_2e_i;

llvm_cbe_bb7_2e_i10:
  if ((((unsigned int )llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i) < ((unsigned int )llvm_cbe___last_addr_2e_1_2e_i))) {
    goto llvm_cbe_bb9_2e_i;
  } else {
    goto llvm_cbe__ZSt21__unguarded_partitionIP14Element_structS0_ET_S2_S2_T0__2e_exit;
  }

  do {     /* Syntactic loop 'bb5.i' to make GCC happy */
llvm_cbe_bb5_2e_i:
  llvm_cbe_indvar_2e_i = llvm_cbe_indvar_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp14_2e_i = llvm_cbe_indvar_2e_i ^ 4294967295u;
  llvm_cbe___last_addr_2e_1_2e_i = (&llvm_cbe___last_addr_2e_0_2e_ph_2e_i[((signed int )llvm_cbe_tmp14_2e_i)]);
  llvm_cbe_scevgep15_2e_i = (&llvm_cbe___last_addr_2e_0_2e_ph_2e_i[((signed int )llvm_cbe_tmp14_2e_i)].field0);
  llvm_cbe_tmp__44 = *llvm_cbe_scevgep15_2e_i;
  if ((((signed int )llvm_cbe_tmp__44) > ((signed int )llvm_cbe_tmp__41))) {
    llvm_cbe_indvar_2e_i__PHI_TEMPORARY = (((unsigned int )(((unsigned int )llvm_cbe_indvar_2e_i) + ((unsigned int )1u))));   /* for PHI node */
    goto llvm_cbe_bb5_2e_i;
  } else {
    goto llvm_cbe_bb7_2e_i10;
  }

  } while (1); /* end of syntactic loop 'bb5.i' */
llvm_cbe_bb5_2e_preheader_2e_i:
  llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i = llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  llvm_cbe_indvar_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
  goto llvm_cbe_bb5_2e_i;

  do {     /* Syntactic loop 'bb1.i' to make GCC happy */
llvm_cbe_bb1_2e_i:
  llvm_cbe_indvar16_2e_i = llvm_cbe_indvar16_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp15 = ((unsigned int )(((unsigned int )llvm_cbe_indvar16_2e_i) + ((unsigned int )1u)));
  llvm_cbe_scevgep_2e_i9 = (&llvm_cbe___first_addr_2e_0_2e_ph_2e_i[((signed int )llvm_cbe_tmp15)]);
  llvm_cbe_tmp__43 = *((&llvm_cbe___first_addr_2e_0_2e_ph_2e_i[((signed int )llvm_cbe_tmp15)].field0));
  if ((((signed int )llvm_cbe_tmp__43) < ((signed int )llvm_cbe_tmp__41))) {
    llvm_cbe_indvar16_2e_i__PHI_TEMPORARY = llvm_cbe_tmp15;   /* for PHI node */
    goto llvm_cbe_bb1_2e_i;
  } else {
    llvm_cbe___first_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe_scevgep_2e_i9;   /* for PHI node */
    goto llvm_cbe_bb5_2e_preheader_2e_i;
  }

  } while (1); /* end of syntactic loop 'bb1.i' */
  } while (1); /* end of syntactic loop 'bb2.outer.i' */
llvm_cbe__ZSt8__medianI14Element_structERKT_S3_S3_S3__2e_exit:
  llvm_cbe_tmp__40 = llvm_cbe_tmp__40__PHI_TEMPORARY;
  llvm_cbe_tmp__41 = *((&llvm_cbe_tmp__40->field0));
  llvm_cbe___last_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY = llvm_cbe___last_addr_2e_0;   /* for PHI node */
  llvm_cbe___first_addr_2e_0_2e_ph_2e_i__PHI_TEMPORARY = llvm_cbe___first;   /* for PHI node */
  goto llvm_cbe_bb2_2e_outer_2e_i;

llvm_cbe_bb_2e_i:
  if ((((signed int )llvm_cbe_tmp__38) < ((signed int )llvm_cbe_tmp__39))) {
    llvm_cbe_tmp__40__PHI_TEMPORARY = llvm_cbe_tmp__36;   /* for PHI node */
    goto llvm_cbe__ZSt8__medianI14Element_structERKT_S3_S3_S3__2e_exit;
  } else {
    goto llvm_cbe_bb3_2e_i;
  }

llvm_cbe_bb2:
  llvm_cbe_tmp__34 = (&llvm_cbe___last_addr_2e_0[((signed int )4294967295u)]);
  llvm_cbe_tmp__35 = ((signed int )(((signed int )llvm_cbe_tmp__52) / ((signed int )16u)));
  llvm_cbe_tmp__36 = (&llvm_cbe___first[((signed int )llvm_cbe_tmp__35)]);
  llvm_cbe_tmp__37 = *llvm_cbe_tmp__31;
  llvm_cbe_tmp__38 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp__35)].field0));
  llvm_cbe_tmp__39 = *((&llvm_cbe___last_addr_2e_0[((signed int )4294967295u)].field0));
  if ((((signed int )llvm_cbe_tmp__37) < ((signed int )llvm_cbe_tmp__38))) {
    goto llvm_cbe_bb_2e_i;
  } else {
    goto llvm_cbe_bb7_2e_i;
  }

llvm_cbe_bb:
  if (llvm_cbe_indvar == llvm_cbe___depth_limit) {
    goto llvm_cbe__ZSt13__heap_selectIP14Element_structEvT_S2_S2__2e_exit_2e_i;
  } else {
    goto llvm_cbe_bb2;
  }

llvm_cbe_bb3_2e_i:
  llvm_cbe_retval_2e_i = (((((signed int )llvm_cbe_tmp__37) < ((signed int )llvm_cbe_tmp__39))) ? (llvm_cbe_tmp__34) : (llvm_cbe___first));
  llvm_cbe_tmp__40__PHI_TEMPORARY = llvm_cbe_retval_2e_i;   /* for PHI node */
  goto llvm_cbe__ZSt8__medianI14Element_structERKT_S3_S3_S3__2e_exit;

llvm_cbe_bb7_2e_i:
  if ((((signed int )llvm_cbe_tmp__37) < ((signed int )llvm_cbe_tmp__39))) {
    llvm_cbe_tmp__40__PHI_TEMPORARY = llvm_cbe___first;   /* for PHI node */
    goto llvm_cbe__ZSt8__medianI14Element_structERKT_S3_S3_S3__2e_exit;
  } else {
    goto llvm_cbe_bb10_2e_i;
  }

llvm_cbe_bb10_2e_i:
  llvm_cbe_retval16_2e_i = (((((signed int )llvm_cbe_tmp__38) < ((signed int )llvm_cbe_tmp__39))) ? (llvm_cbe_tmp__34) : (llvm_cbe_tmp__36));
  llvm_cbe_tmp__40__PHI_TEMPORARY = llvm_cbe_retval16_2e_i;   /* for PHI node */
  goto llvm_cbe__ZSt8__medianI14Element_structERKT_S3_S3_S3__2e_exit;

  } while (1); /* end of syntactic loop 'bb5' */
llvm_cbe_return:
  return;
}


void _ZSt16__insertion_sortIP14Element_structEvT_S2_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last) {
  unsigned int *llvm_cbe_tmp__53;
  unsigned int llvm_cbe_tmp__54;
  unsigned int *llvm_cbe_tmp__55;
  unsigned int llvm_cbe_tmp__56;
  unsigned int llvm_cbe_tmp__56__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp22;
  unsigned int llvm_cbe_tmp29;
  struct l_struct_2E_Element *llvm_cbe___i_2e_0;
  struct l_struct_2E_Element *llvm_cbe___i_2e_019;
  unsigned int llvm_cbe_tmp__57;
  unsigned int llvm_cbe_tmp__58;
  unsigned int llvm_cbe_tmp__59;
  unsigned int llvm_cbe_tmp__60;
  unsigned int llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i;
  unsigned int llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp20;
  unsigned int llvm_cbe_tmp23;
  unsigned int llvm_cbe_tmp__61;
  unsigned int llvm_cbe_tmp__62;
  unsigned int llvm_cbe_indvar_2e_next_2e_i_2e_i_2e_i_2e_i;
  unsigned int llvm_cbe_tmp__63;
  unsigned int llvm_cbe_indvar_2e_i;
  unsigned int llvm_cbe_indvar_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp33;
  struct l_struct_2E_Element *llvm_cbe___next_2e_06_2e_i;
  unsigned int llvm_cbe_tmp37;
  unsigned int llvm_cbe_tmp__64;
  unsigned int llvm_cbe_tmp__65;
  unsigned int llvm_cbe_tmp__66;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i;
  struct l_struct_2E_Element *llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;

  if (llvm_cbe___first == llvm_cbe___last) {
    goto llvm_cbe_return;
  } else {
    goto llvm_cbe_bb7_2e_preheader;
  }

llvm_cbe_bb7_2e_preheader:
  if ((((&llvm_cbe___first[((signed int )1u)])) == llvm_cbe___last)) {
    goto llvm_cbe_return;
  } else {
    goto llvm_cbe_bb_2e_nph;
  }

llvm_cbe_bb_2e_nph:
  llvm_cbe_tmp__53 = (&llvm_cbe___first->field0);
  llvm_cbe_tmp__54 = ((unsigned int )(unsigned long)llvm_cbe___first);
  llvm_cbe_tmp__55 = (&llvm_cbe___first->field1);
  llvm_cbe_tmp__56__PHI_TEMPORARY = 0u;   /* for PHI node */
  goto llvm_cbe_bb1;

  do {     /* Syntactic loop 'bb1' to make GCC happy */
llvm_cbe_bb1:
  llvm_cbe_tmp__56 = llvm_cbe_tmp__56__PHI_TEMPORARY;
  llvm_cbe_tmp22 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__56) + ((unsigned int )1u)));
  llvm_cbe_tmp29 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__56) + ((unsigned int )4294967295u)));
  llvm_cbe___i_2e_0 = (&llvm_cbe___first[((signed int )(((unsigned int )(((unsigned int )llvm_cbe_tmp__56) + ((unsigned int )2u)))))]);
  llvm_cbe___i_2e_019 = (&llvm_cbe___first[((signed int )llvm_cbe_tmp22)]);
  llvm_cbe_tmp__57 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp22)].field0));
  llvm_cbe_tmp__58 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp22)].field1));
  llvm_cbe_tmp__59 = *llvm_cbe_tmp__53;
  if ((((signed int )llvm_cbe_tmp__57) < ((signed int )llvm_cbe_tmp__59))) {
    goto llvm_cbe_bb2;
  } else {
    goto llvm_cbe_bb3;
  }

llvm_cbe_bb7_2e_backedge:
  if (llvm_cbe___i_2e_0 == llvm_cbe___last) {
    goto llvm_cbe_return;
  } else {
    llvm_cbe_tmp__56__PHI_TEMPORARY = llvm_cbe_tmp22;   /* for PHI node */
    goto llvm_cbe_bb1;
  }

llvm_cbe__ZSt13copy_backwardIP14Element_structS1_ET0_T_S3_S2__2e_exit:
  *llvm_cbe_tmp__53 = llvm_cbe_tmp__57;
  *llvm_cbe_tmp__55 = llvm_cbe_tmp__58;
  goto llvm_cbe_bb7_2e_backedge;

llvm_cbe_bb2:
  llvm_cbe_tmp__60 = ((signed int )(((signed int )(((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___i_2e_019))) - ((unsigned int )llvm_cbe_tmp__54))))) >> ((signed int )3u)));
  if ((((signed int )llvm_cbe_tmp__60) > ((signed int )0u))) {
    llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i_2e_i_2e_i_2e_i;
  } else {
    goto llvm_cbe__ZSt13copy_backwardIP14Element_structS1_ET0_T_S3_S2__2e_exit;
  }

  do {     /* Syntactic loop 'bb.i.i.i.i' to make GCC happy */
llvm_cbe_bb_2e_i_2e_i_2e_i_2e_i:
  llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i = llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp20 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__56) - ((unsigned int )llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i)));
  llvm_cbe_tmp23 = ((unsigned int )(((unsigned int )llvm_cbe_tmp22) - ((unsigned int )llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i)));
  llvm_cbe_tmp__61 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp20)].field0));
  llvm_cbe_tmp__62 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp20)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe_tmp23)].field0)) = llvm_cbe_tmp__61;
  *((&llvm_cbe___first[((signed int )llvm_cbe_tmp23)].field1)) = llvm_cbe_tmp__62;
  llvm_cbe_indvar_2e_next_2e_i_2e_i_2e_i_2e_i = ((unsigned int )(((unsigned int )llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i) + ((unsigned int )1u)));
  if (llvm_cbe_indvar_2e_next_2e_i_2e_i_2e_i_2e_i == llvm_cbe_tmp__60) {
    goto llvm_cbe__ZSt13copy_backwardIP14Element_structS1_ET0_T_S3_S2__2e_exit;
  } else {
    llvm_cbe_indvar_2e_i_2e_i_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe_indvar_2e_next_2e_i_2e_i_2e_i_2e_i;   /* for PHI node */
    goto llvm_cbe_bb_2e_i_2e_i_2e_i_2e_i;
  }

  } while (1); /* end of syntactic loop 'bb.i.i.i.i' */
llvm_cbe__ZSt25__unguarded_linear_insertIP14Element_structS0_EvT_T0__2e_exit:
  llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i = llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY;
  *((&llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i->field0)) = llvm_cbe_tmp__57;
  *((&llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i->field1)) = llvm_cbe_tmp__58;
  goto llvm_cbe_bb7_2e_backedge;

llvm_cbe_bb3:
  llvm_cbe_tmp__63 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp__56)].field0));
  if ((((signed int )llvm_cbe_tmp__63) > ((signed int )llvm_cbe_tmp__57))) {
    llvm_cbe_indvar_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  } else {
    llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___i_2e_019;   /* for PHI node */
    goto llvm_cbe__ZSt25__unguarded_linear_insertIP14Element_structS0_EvT_T0__2e_exit;
  }

  do {     /* Syntactic loop 'bb.i' to make GCC happy */
llvm_cbe_bb_2e_i:
  llvm_cbe_indvar_2e_i = llvm_cbe_indvar_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp33 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__56) - ((unsigned int )llvm_cbe_indvar_2e_i)));
  llvm_cbe___next_2e_06_2e_i = (&llvm_cbe___first[((signed int )llvm_cbe_tmp33)]);
  llvm_cbe_tmp37 = ((unsigned int )(((unsigned int )llvm_cbe_tmp22) - ((unsigned int )llvm_cbe_indvar_2e_i)));
  llvm_cbe_tmp__64 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp33)].field0));
  llvm_cbe_tmp__65 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp33)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe_tmp37)].field0)) = llvm_cbe_tmp__64;
  *((&llvm_cbe___first[((signed int )llvm_cbe_tmp37)].field1)) = llvm_cbe_tmp__65;
  llvm_cbe_tmp__66 = *((&llvm_cbe___first[((signed int )(((unsigned int )(((unsigned int )llvm_cbe_tmp29) - ((unsigned int )llvm_cbe_indvar_2e_i)))))].field0));
  if ((((signed int )llvm_cbe_tmp__66) > ((signed int )llvm_cbe_tmp__57))) {
    llvm_cbe_indvar_2e_i__PHI_TEMPORARY = (((unsigned int )(((unsigned int )llvm_cbe_indvar_2e_i) + ((unsigned int )1u))));   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  } else {
    llvm_cbe___last_addr_2e_0_2e_lcssa_2e_i__PHI_TEMPORARY = llvm_cbe___next_2e_06_2e_i;   /* for PHI node */
    goto llvm_cbe__ZSt25__unguarded_linear_insertIP14Element_structS0_EvT_T0__2e_exit;
  }

  } while (1); /* end of syntactic loop 'bb.i' */
  } while (1); /* end of syntactic loop 'bb1' */
llvm_cbe_return:
  return;
}


void _ZSt22__final_insertion_sortIP14Element_structEvT_S2_(struct l_struct_2E_Element *llvm_cbe___first, struct l_struct_2E_Element *llvm_cbe___last) {
  struct l_struct_2E_Element *llvm_cbe_tmp__67;
  unsigned int llvm_cbe_tmp__68;
  unsigned int llvm_cbe_tmp__68__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp22;
  unsigned int llvm_cbe_tmp18;
  unsigned int llvm_cbe_tmp15;
  unsigned int llvm_cbe_tmp13;
  struct l_struct_2E_Element *llvm_cbe_scevgep26_2e_i;
  unsigned int llvm_cbe_tmp__69;
  unsigned int llvm_cbe_tmp__70;
  unsigned int llvm_cbe_tmp__71;
  unsigned int llvm_cbe_indvar_2e_i_2e_i;
  unsigned int llvm_cbe_indvar_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp9_2e_i;
  unsigned int llvm_cbe_tmp16;
  unsigned int llvm_cbe_tmp23;
  unsigned int llvm_cbe_tmp__72;
  unsigned int llvm_cbe_tmp__73;
  unsigned int llvm_cbe_tmp__74;
  unsigned int llvm_cbe__2e_pn_2e_i;
  unsigned int llvm_cbe__2e_pn_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe__2e_sum7;

  if ((((signed int )(((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___last))) - ((unsigned int )(((unsigned int )(unsigned long)llvm_cbe___first))))))) > ((signed int )135u))) {
    goto llvm_cbe_bb;
  } else {
    goto llvm_cbe_bb1;
  }

llvm_cbe_bb:
  llvm_cbe_tmp__67 = (&llvm_cbe___first[((signed int )16u)]);
   /*tail*/ _ZSt16__insertion_sortIP14Element_structEvT_S2_(llvm_cbe___first, llvm_cbe_tmp__67);
  if (llvm_cbe_tmp__67 == llvm_cbe___last) {
    goto llvm_cbe__ZSt26__unguarded_insertion_sortIP14Element_structEvT_S2__2e_exit;
  } else {
    llvm_cbe_tmp__68__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  }

  do {     /* Syntactic loop 'bb.i' to make GCC happy */
llvm_cbe_bb_2e_i:
  llvm_cbe_tmp__68 = llvm_cbe_tmp__68__PHI_TEMPORARY;
  llvm_cbe_tmp22 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__68) + ((unsigned int )16u)));
  llvm_cbe_tmp18 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__68) + ((unsigned int )14u)));
  llvm_cbe_tmp15 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__68) + ((unsigned int )15u)));
  llvm_cbe_tmp13 = ((unsigned int )(((unsigned int )llvm_cbe_tmp__68) + ((unsigned int )4294967295u)));
  llvm_cbe_scevgep26_2e_i = (&llvm_cbe___first[((signed int )(((unsigned int )(((unsigned int )llvm_cbe_tmp__68) + ((unsigned int )17u)))))]);
  llvm_cbe_tmp__69 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp22)].field0));
  llvm_cbe_tmp__70 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp22)].field1));
  llvm_cbe_tmp__71 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp15)].field0));
  if ((((signed int )llvm_cbe_tmp__71) > ((signed int )llvm_cbe_tmp__69))) {
    llvm_cbe_indvar_2e_i_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i_2e_i;
  } else {
    llvm_cbe__2e_pn_2e_i__PHI_TEMPORARY = llvm_cbe_tmp__68;   /* for PHI node */
    goto llvm_cbe__ZSt25__unguarded_linear_insertIP14Element_structS0_EvT_T0__2e_exit_2e_i;
  }

llvm_cbe__ZSt25__unguarded_linear_insertIP14Element_structS0_EvT_T0__2e_exit_2e_i:
  llvm_cbe__2e_pn_2e_i = llvm_cbe__2e_pn_2e_i__PHI_TEMPORARY;
  llvm_cbe__2e_sum7 = ((unsigned int )(((unsigned int )llvm_cbe__2e_pn_2e_i) + ((unsigned int )16u)));
  *((&llvm_cbe___first[((signed int )llvm_cbe__2e_sum7)].field0)) = llvm_cbe_tmp__69;
  *((&llvm_cbe___first[((signed int )llvm_cbe__2e_sum7)].field1)) = llvm_cbe_tmp__70;
  if (llvm_cbe_scevgep26_2e_i == llvm_cbe___last) {
    goto llvm_cbe__ZSt26__unguarded_insertion_sortIP14Element_structEvT_S2__2e_exit;
  } else {
    llvm_cbe_tmp__68__PHI_TEMPORARY = (((unsigned int )(((unsigned int )llvm_cbe_tmp__68) + ((unsigned int )1u))));   /* for PHI node */
    goto llvm_cbe_bb_2e_i;
  }

  do {     /* Syntactic loop 'bb.i.i' to make GCC happy */
llvm_cbe_bb_2e_i_2e_i:
  llvm_cbe_indvar_2e_i_2e_i = llvm_cbe_indvar_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp9_2e_i = ((unsigned int )(((unsigned int )llvm_cbe_tmp13) - ((unsigned int )llvm_cbe_indvar_2e_i_2e_i)));
  llvm_cbe_tmp16 = ((unsigned int )(((unsigned int )llvm_cbe_tmp15) - ((unsigned int )llvm_cbe_indvar_2e_i_2e_i)));
  llvm_cbe_tmp23 = ((unsigned int )(((unsigned int )llvm_cbe_tmp22) - ((unsigned int )llvm_cbe_indvar_2e_i_2e_i)));
  llvm_cbe_tmp__72 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp16)].field0));
  llvm_cbe_tmp__73 = *((&llvm_cbe___first[((signed int )llvm_cbe_tmp16)].field1));
  *((&llvm_cbe___first[((signed int )llvm_cbe_tmp23)].field0)) = llvm_cbe_tmp__72;
  *((&llvm_cbe___first[((signed int )llvm_cbe_tmp23)].field1)) = llvm_cbe_tmp__73;
  llvm_cbe_tmp__74 = *((&llvm_cbe___first[((signed int )(((unsigned int )(((unsigned int )llvm_cbe_tmp18) - ((unsigned int )llvm_cbe_indvar_2e_i_2e_i)))))].field0));
  if ((((signed int )llvm_cbe_tmp__74) > ((signed int )llvm_cbe_tmp__69))) {
    llvm_cbe_indvar_2e_i_2e_i__PHI_TEMPORARY = (((unsigned int )(((unsigned int )llvm_cbe_indvar_2e_i_2e_i) + ((unsigned int )1u))));   /* for PHI node */
    goto llvm_cbe_bb_2e_i_2e_i;
  } else {
    llvm_cbe__2e_pn_2e_i__PHI_TEMPORARY = llvm_cbe_tmp9_2e_i;   /* for PHI node */
    goto llvm_cbe__ZSt25__unguarded_linear_insertIP14Element_structS0_EvT_T0__2e_exit_2e_i;
  }

  } while (1); /* end of syntactic loop 'bb.i.i' */
  } while (1); /* end of syntactic loop 'bb.i' */
llvm_cbe__ZSt26__unguarded_insertion_sortIP14Element_structEvT_S2__2e_exit:
  return;
llvm_cbe_bb1:
   /*tail*/ _ZSt16__insertion_sortIP14Element_structEvT_S2_(llvm_cbe___first, llvm_cbe___last);
  return;
}


void introsort(struct l_struct_2E_Element *llvm_cbe_bot, unsigned int llvm_cbe_total_elems) {
  struct l_struct_2E_Element *llvm_cbe_tmp__75;
  unsigned int llvm_cbe_tmp__76;
  unsigned int llvm_cbe___n_addr_2e_05_2e_i_2e_i;
  unsigned int llvm_cbe___n_addr_2e_05_2e_i_2e_i__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__77;
  unsigned int llvm_cbe_tmp__77__PHI_TEMPORARY;
  unsigned int llvm_cbe_tmp__78;
  unsigned int llvm_cbe_phitmp_2e_i;
  unsigned int llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i;
  unsigned int llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i__PHI_TEMPORARY;

  llvm_cbe_tmp__75 = (&llvm_cbe_bot[((signed int )llvm_cbe_total_elems)]);
  if (llvm_cbe_total_elems == 0u) {
    goto llvm_cbe__ZSt4sortIP14Element_structEvT_S2__2e_exit;
  } else {
    goto llvm_cbe_bb_2e_i;
  }

llvm_cbe_bb_2e_i:
  llvm_cbe_tmp__76 = ((signed int )(((signed int )(((unsigned int )(((unsigned int )(((unsigned int )(unsigned long)llvm_cbe_tmp__75))) - ((unsigned int )(((unsigned int )(unsigned long)llvm_cbe_bot))))))) >> ((signed int )3u)));
  if (llvm_cbe_tmp__76 == 1u) {
    llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe__ZSt4__lgIiET_S0__2e_exit_2e_i;
  } else {
    llvm_cbe___n_addr_2e_05_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe_tmp__76;   /* for PHI node */
    llvm_cbe_tmp__77__PHI_TEMPORARY = 0u;   /* for PHI node */
    goto llvm_cbe_bb_2e_i_2e_i;
  }

  do {     /* Syntactic loop 'bb.i.i' to make GCC happy */
llvm_cbe_bb_2e_i_2e_i:
  llvm_cbe___n_addr_2e_05_2e_i_2e_i = llvm_cbe___n_addr_2e_05_2e_i_2e_i__PHI_TEMPORARY;
  llvm_cbe_tmp__77 = llvm_cbe_tmp__77__PHI_TEMPORARY;
  llvm_cbe_tmp__78 = ((signed int )(((signed int )llvm_cbe___n_addr_2e_05_2e_i_2e_i) >> ((signed int )1u)));
  if (llvm_cbe_tmp__78 == 1u) {
    goto llvm_cbe__ZSt4__lgIiET_S0__2e_exit_2e_loopexit_2e_i;
  } else {
    llvm_cbe___n_addr_2e_05_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe_tmp__78;   /* for PHI node */
    llvm_cbe_tmp__77__PHI_TEMPORARY = (((unsigned int )(((unsigned int )llvm_cbe_tmp__77) + ((unsigned int )1u))));   /* for PHI node */
    goto llvm_cbe_bb_2e_i_2e_i;
  }

  } while (1); /* end of syntactic loop 'bb.i.i' */
llvm_cbe__ZSt4__lgIiET_S0__2e_exit_2e_loopexit_2e_i:
  llvm_cbe_phitmp_2e_i = ((unsigned int )(((unsigned int )(llvm_cbe_tmp__77 << 1u)) + ((unsigned int )2u)));
  llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i__PHI_TEMPORARY = llvm_cbe_phitmp_2e_i;   /* for PHI node */
  goto llvm_cbe__ZSt4__lgIiET_S0__2e_exit_2e_i;

llvm_cbe__ZSt4__lgIiET_S0__2e_exit_2e_i:
  llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i = llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i__PHI_TEMPORARY;
   /*tail*/ _ZSt16__introsort_loopIP14Element_structiEvT_S2_T0_(llvm_cbe_bot, llvm_cbe_tmp__75, llvm_cbe___k_2e_0_2e_lcssa_2e_i_2e_i);
   /*tail*/ _ZSt22__final_insertion_sortIP14Element_structEvT_S2_(llvm_cbe_bot, llvm_cbe_tmp__75);
  return;
llvm_cbe__ZSt4sortIP14Element_structEvT_S2__2e_exit:
  return;
}

