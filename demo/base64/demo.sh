#!/bin/bash -xe



SRC=./base64_mod2.c
ANALYZE=b64_pton

DEMO=$(basename "${SRC}" .c)
BINDIR="./bin"
OUTDIR="./out"
GRAPHDIR="./graphs"

mkdir -p $BINDIR $OUTDIR $GRAPHDIR

patmos-clang -O0 -Xopt -disable-inlining -o "${BINDIR}/${DEMO}.elf" -mserialize="${BINDIR}/${DEMO}.pml" "${SRC}"
patmos-llvm-objdump -d "${BINDIR}/${DEMO}.elf" > "${BINDIR}/${DEMO}.dis"

# analyze
platin wcet -i "${BINDIR}/${DEMO}.pml" --outdir ${OUTDIR} -o ${BINDIR}/${DEMO}.pml \
    --binary "${BINDIR}/${DEMO}.elf" \
    --analysis-entry ${ANALYZE} \
    --use-trace-facts


platin visualize -f ${ANALYZE} -O "${GRAPHDIR}" -i "${BINDIR}/${DEMO}.pml"

