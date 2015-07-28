#!/usr/bin/env python
###############################################################################
#
# Script to preliminarily evaluate cache performance of the
# single-path prefetch and cache locking strategy developed by Bekim Cilku.
#
# Author: Daniel Prokesch <daniel@vmars.tuwien.ac.at>
#
###############################################################################

from traceana import TraceGen
from mktables import *


import argparse




###############################################################################


class CacheSetLockable:
    def __init__(self, associativity=4):
        self.blocks = associativity * [None]
        self.lock_offset = 0

    def contains(self, tag):
        return tag in self.blocks

    def update(self, tag):
        """Like LRU update, just start at lock_offset position."""
        if tag in self.blocks:
            # Move tag to the front
            idx = self.blocks.index(tag)
            if idx > self.lock_offset:
                self.blocks.insert(self.lock_offset, self.blocks.pop(idx))
            else:
                pass # it is a locked line and stays where it is
            return True
        else:
            if self.lock_offset < len(self.blocks):
                # Insert at the front and throw away the last element
                self.blocks.insert(self.lock_offset, tag)
                self.blocks.pop()
            return False

    def lockn(self, n):
        """Lock n cache lines.

        n must be smaller than the total number of cache lines.
        The most recent (youngest) lines are locked.
        """
        assert n < len(self.blocks)
        self.lock_offset = n

    def unlock_all(self):
        """Unlock all cache lines."""
        self.lock_offset = 0


    def __str__(self):
        tagstr = lambda tag: str(tag) if tag else "-"
        locked = self.blocks[0:self.lock_offset]
        unlocked = self.blocks[self.lock_offset:]
        return "[" + "|".join([tagstr(t) for t in locked]) + \
               "||"+ "|".join([tagstr(t) for t in unlocked]) + "]"



class Cache:
    """
    The fully associative LRU cache model used for this evaluation.

    Fields:
    blocksize     ... block size in bytes, a multiple of 2, e.g. 64
    sets          ... number of cache sets
    associativity ... number of cache lines in a set
    """

    def __init__(self, blocksize, sets, associativity=4):
        self.blocksize = blocksize
        self.sets = [CacheSetLockable(associativity) for i in range(sets)]
        self.size = blocksize * sets * associativity
        self.associativity = associativity
        self.num_hits = 0
        self.num_misses = 0
        self.num_accesses = 0

    def size_blocks(self):
        return self.size / self.blocksize

    def tagof(self, addr):
        """Get the tag of a specified address."""
        return (addr // self.blocksize)

    def setof(self, tag):
        return self.sets[tag % len(self.sets)]

    def access(self, addr):
        self.num_accesses += 1
        tag = self.tagof(addr)
        cset = self.setof(tag)
        hit = cset.update(tag)
        if hit:
            self.num_hits += 1
        else:
            self.num_misses += 1
        return hit

    def lockn(self, n):
        for s in self.sets: s.lockn(n)

    def unlock_all(self):
        for s in self.sets: s.unlock_all()

    def __str__(self):
        return "\n".join(["{}: {}".format(i, s)
                          for i, s in enumerate(self.sets)])




###############################################################################



class Simulator:
    """Main simulator of the single-path prefetch+locking approach."""
    def __init__(self, cache, rpt, lt, memlatency, verbose=False):
        self.t = 0  # simulation time
        self.cache = cache
        self.stack = []
        self.RPT = rpt
        self.rptp = 0 # pointer into the rpt
        self.LT = lt
        self.ltp = 0 # pointer into the lt
        self.memlatency = memlatency
        self.verbose = verbose
        # internal state
        self.pending = None # store (tag, start_time)
        # stats
        self.stats = {
            "prefetch_conflicts" : 0,
            "prefetch_waittime"  : 0,
            "cnt_pf_miss"        : 0,
            "cnt_miss"           : 0,
        }

    def _prefetch(self, tag):
        # check if there is a pending request.
        # if yes, we have to wait until it is finished
        if self.pending:
            self.stats["prefetch_conflicts"] += 1
            ptag, pstart = self.pending
            pend = pstart + self.memlatency
            assert pend > self.t
            self.stats["prefetch_waittime"] += pend - self.t
            self.t = pend # wait
        addr = tag * self.cache.blocksize
        hit = self.cache.access(addr)
        print "prefetch request", tag, self.t
        if not hit:
            self.pending = (tag, self.t)
            print "add pending", self.pending

    def _fetch(self, tag):
        addr = tag * self.cache.blocksize
        hit = self.cache.access(addr)
        print "fetch request", tag, self.t
        if self.pending:
            ptag, pstart = self.pending
            pend = pstart + self.memlatency
        if hit:
            # check if it is a still pending prefetch
            if self.pending and tag == ptag:
                if pend > self.t:
                    self.stats["cnt_pf_miss"] += 1
                    self.stats["prefetch_waittime"] += pend - self.t
                    self.t = pend # wait
        else:
            # regular cache access
            self.stats["cnt_miss"] += 1
            self.t += self.memlatency
        # nothing pending anymore
        if self.pending and pend <= self.t:
            self.pending = None
        self.t += 1 # instruction

    def _process_rpt(self, rpte):
        if   type(rpt) is RPT_Loop:
            # push loop counter onto stack
            pass
        elif type(rpt) is RPT_SmallLoop:
            pass
        elif type(rpt) is RPT_Call:
            pass
        elif type(rpt) is RPT_Return:
            pass
        elif type(rpt) is RPT_Any:
            pass
        # get or create entry in loop registers
        dest, counter, size = self.loop_registers.setdefault(
            cur_block, tuple(RPT[cur_block]))
        # check for last loop iteration
        counter -= 1
        if counter > 0:
            # update registers
            self.loop_registers[cur_block] = (dest, counter, size)
            # check if larger than cache size for prefetch
            if size >= self.cache.size_blocks():
                 self._prefetch(dest) # prefetch dest
        else:
            # this was the last iteration, so we remove the
            # registers for this loop and prefetch the line
            # after the loop
            del self.loop_registers[cur_block]
            self._prefetch(cur_block + 1) # prefetch next line

    def run(self, trace):
        cur_block = 0
        self.loop_registers = dict()
        for i, addr in enumerate(trace()):
            addr_tag = self.cache.tagof(addr)

            ### fetch the instruction and update time ("wait" if necessary)
            self._fetch(addr_tag)

            ### PREFETCH LOGIC
            if cur_block != addr_tag:
                # we advanced, do something
                cur_block = addr_tag
                # the current RPT entry
                rpte = self.RPT[self.rptp]
                # are we in a trigger line?
                if cur_block == rpte.trigger_line:
                    # process depending on type
                    self._process_rpt(rpte)
                else:
                    self._prefetch(cur_block + 1) # prefetch next line
            ### LOCK LOGIC
            if addr in zip(*self.LT)[0]:
                self.cache.lockn(self.cache.associativity - 2)
            if addr in zip(*self.LT)[1]:
                self.cache.unlock_all()

            # verbose trace output
            if self.verbose:
                print i, hex(addr), str(self)#, str(self.stats)

    def __str__(self):
        """Return a textual representation of the hardware state."""
        s = [
                # simulation time
                ("time", self.t),
                # cache content
                ("cache", self.cache),
                # pending prefetch
                ("pending", self.pending),
                # loop registers
                ("loops", self.loop_registers),
        ]
        return ", ".join("{}: {}".format(*pair) for pair in s)

###############################################################################
# main program entry point:
###############################################################################

if __name__ == '__main__':
    # specify argument handling
    parser = argparse.ArgumentParser()
    # positional arguments
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "
                             "one address (hex, w/o leading 0x) per line.")
    # options
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose simulation output.")
    parser.add_argument("--rpt", type=str,
                        help="Reference Prediction Table.")
    parser.add_argument("--size", type=int, default=16,
                        help="Size of a cache line in bytes."\
                        " (default: %(default)d)")
    parser.add_argument("--sets", type=int, default=1,
                        help="Number of cache sets. (default: %(default)d)")
    parser.add_argument("--assoc", type=int, default=4,
                        help="Associativity. (default: %(default)d)")
    parser.add_argument("--mem-cycles", type=int, default=20,
                        help="Number of cycles required to load a cache line."\
                        " (default: %(default)d)")
    args = parser.parse_args()

    # We need the instruction address trace more than once,
    # therefore we obtain a generator function for obtaining a trace.
    # Each item is a pair of fetch cycle and instruction address.
    trace = TraceGen(args.trace)

    # instantiate the cache
    C = Cache(args.size, args.sets, args.assoc)
    print "Cache size in blocks:", C.size_blocks()

    rpt = RPTCreator.load(args.rpt) if args.rpt else [(0,)] # empty table

    for e in rpt:
        print e

    Sim = Simulator(C, rpt,
                    [(0,0)], # empty lock table
                    args.mem_cycles,
                    args.verbose)
    Sim.run(trace)
    if args.verbose:
        print Sim.stats

    print Sim.t


