#!/usr/bin/env python2
###############################################################################
#
# Table generator for prefetch/locking architecture.
#
# Uses the results from the trace analysis module to create the tables.
#
# Author: Daniel Prokesch <daniel@vmars.tuwien.ac.at>
#
###############################################################################

import sys

from traceana import TraceGen, FunctionMap


###############################################################################


if __name__ == '__main__':
    FM = FunctionMap(sys.argv[1])
    trace = TraceGen(sys.argv[2])
    funcnames = sys.argv[3:]

    for name in funcnames:
        if not FM.name_exists(name):
            print "Error: Function '{}' does not exist!".format(name)
            exit(1)

    state = "INITIAL"
    prev_addr = None
    caller_entry, caller_exit = None, None
    outf = None
    for addr in trace():
        if state == "INITIAL":
            if len(funcnames) == 0: break
            entry, name = FM[addr]
            if entry == addr and name in funcnames:
                # entered a function
                funcnames.remove(name) # only find it once
                outf = open(name + ".trace", "w")
                outf.write("{:08x}\n".format(addr))
                caller_entry = FM[prev_addr][0]
                caller_exit = FM.func_next(caller_entry) - 1 # hack
                state = "FUNCTION"
                print "enter {} ({:#010x})...".format(name, addr),
            prev_addr = addr
            continue
        if state == "FUNCTION":
            if caller_entry <= addr <= caller_exit:
                # we are in the caller
                outf.close()
                outf = None
                caller_entry, caller_exit = None, None
                state = "INITIAL"
                print "leave."
            else:
                # otherwise just output the trace
                outf.write("{:08x}\n".format(addr))
            prev_addr = addr
            continue

