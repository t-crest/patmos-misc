
SORTS=$(wildcard sorts/*.c)
SOURCES=$(wildcard *.c) $(wildcard *.h) $(SORTS)

CFLAGS=-g -Xllc -disable-lsr -Xlinker -disable-lsr -DPATMOS

all: buffertest sortexample

buffertest: buffertest.c sortexample.h buffer.c buffer.h
	patmos-clang $(CFLAGS) -o $@ $(filter %.c,$^)

sortexample: sortexample.c sortexample.h buffer.c buffer.h $(SORTS)
	patmos-clang $(CFLAGS) -o $@ -I. -Isorts $(filter %.c,$^)

clean:
	rm -f buffertest sortexample *.i *.bc *.o
