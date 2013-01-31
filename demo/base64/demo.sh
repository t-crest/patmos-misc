#!/bin/bash -xe



SRC=./base64_mod2.c
ANALYZE=b64_pton

DEMO=$(basename "${SRC}" .c)
BINDIR="./bin"
OUTDIR="./out"
GRAPHDIR="./graphs"

mkdir -p $BINDIR $OUTDIR $GRAPHDIR

patmos-clang -O0 -Wl,-mem2reg -o "${BINDIR}/${DEMO}.elf" -mpatmos-serialize="${BINDIR}/${DEMO}.pml" "${SRC}"
#patmos-clang -Wl,-disable-inlining -o "${BINDIR}/${DEMO}.elf" -mpatmos-serialize="${BINDIR}/${DEMO}.pml" "${SRC}"

# analyze
psk bench "${BINDIR}/${DEMO}.pml" \
    --objdump-command $(which patmos-llvm-objdump) \
    --ais "${OUTDIR}/${DEMO}.ais" \
    --binary "${BINDIR}/${DEMO}.elf" \
    --report "${OUTDIR}/${DEMO}.txt" \
    --apx "${OUTDIR}/${DEMO}.apx" \
    --results "${OUTDIR}/${DEMO}.xml" \
    --header \
    --analysis-entry ${ANALYZE}


psk visualize -f ${ANALYZE} -O "${GRAPHDIR}" "${BINDIR}/${DEMO}.pml"

