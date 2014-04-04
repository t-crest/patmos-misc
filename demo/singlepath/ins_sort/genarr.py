#!/usr/bin/env python

import sys

from random import shuffle


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print "Usage: {} nelem narrays".format(sys.argv[0])
        exit(1)

    nelem, narrays = [int(x) for x in sys.argv[1:]]

    A = range(nelem)
    print "= {"
    for i in range(narrays):
        shuffle(A)
        print "    {{{}}},".format(", ".join([str(x) for x in A]))
    print "  };"
