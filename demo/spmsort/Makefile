
SORTS=$(wildcard sorts/*.c)
SOURCES=$(wildcard *.c) $(wildcard *.h) $(SORTS)

all: buffertest sortexample

buffertest: buffertest.c sortexample.h buffer.c buffer.h
	patmos-clang -O1 -o $@ $(filter %.c,$^)

sortexample: sortexample.c sortexample.h buffer.c buffer.h $(SORTS)
	patmos-clang -O1 -o $@ -I. -Isorts $(filter %.c,$^)

clean:
	rm -f buffertest sortexample
