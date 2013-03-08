#!/bin/bash -xe



SRC=./base64_mod2.c
ANALYZE=b64_pton

DEMO=$(basename "${SRC}" .c)
BINDIR="./bin"
OUTDIR="./out"
GRAPHDIR="./graphs"

mkdir -p $BINDIR $OUTDIR $GRAPHDIR

#patmos-clang -Wl,-disable-inlining -o "${BINDIR}/${DEMO}.elf" -mpatmos-serialize="${BINDIR}/${DEMO}.pml" "${SRC}"
patmos-clang -O0 -Wl,-disable-inlining -o "${BINDIR}/${DEMO}.elf" -mpatmos-serialize="${BINDIR}/${DEMO}.pml" "${SRC}"

# analyze
platin bench-trace "${BINDIR}/${DEMO}.pml" --outdir ${OUTDIR} -o ${BINDIR}/${DEMO}.pml \
    --objdump-command $(which patmos-llvm-objdump) \
    --binary "${BINDIR}/${DEMO}.elf" \
    --header \
    --analysis-entry ${ANALYZE}


platin visualize -f ${ANALYZE} -O "${GRAPHDIR}" "${BINDIR}/${DEMO}.pml"

