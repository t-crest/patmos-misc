#!/bin/bash -xe



SRC=./base64_mod.c
ANALYZE=b64_pton

DEMO=$(basename "${SRC}" .c)
BINDIR="./bin"
OUTDIR="./out"

mkdir -p $BINDIR $OUTDIR

patmos-clang -o "${BINDIR}/${DEMO}.elf" -mpatmos-serialize="${BINDIR}/${DEMO}.pml" "${SRC}"

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



