
SORTS=$(wildcard sorts/*.c)
SOURCES=$(wildcard *.c) $(wildcard *.h) $(SORTS)

all: buffertest sortexample

buffertest: buffertest.c sortexample.h buffer.c buffer.h
	patmos-clang -o $@ $(filter %.c,$^)

sortexample: sortexample.c sortexample.h buffer.c buffer.h $(SORTS)
	patmos-clang -o $@ -I. -Isorts $(filter %.c,$^)

clean:
	rm -f buffertest sortexample
