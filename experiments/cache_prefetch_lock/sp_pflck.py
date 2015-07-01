#!/usr/bin/env python
###############################################################################
#
# Script to preliminarily evaluate cache performance of the
# single-path prefetch and cache locking strategy developed by Bekim Cilku.
#
# Author: Daniel Prokesch <daniel@vmars.tuwien.ac.at>
#
###############################################################################

from traceana import TraceAnalysis, TraceGen, Functions, RPT, LT


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

    def lock_all(self):
        """Lock all but one cache line."""
        self.lock_offset = len(self.blocks)

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
        self.num_hits = 0
        self.num_misses = 0
        self.num_accesses = 0

    def size(self, in_blocks=False):
        retval = self.size
        if in_blocks: retval /= self.blocksize
        return retval

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

    def lock_all(self):
        for s in self.sets: s.lock_all()

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
        self.RPT = rpt
        self.LT = lt
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

    def prefetch(self, tag):
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
        if not hit:
            self.pending = (tag, self.t)

    def fetch(self, tag):
        addr = tag * self.cache.blocksize
        hit = self.cache.access(addr)
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

    def run(self, trace, enable_prefetch=False, enable_lock=False):
        cur_block = 0
        loop_registers = dict()
        for i, addr in trace():
            addr_tag = self.cache.tagof(addr)
            ### PREFETCH LOGIC
            if enable_prefetch:
                if cur_block != addr_tag:
                    # we advanced, do something
                    cur_block = addr_tag
                    # are we in a loop?
                    if cur_block in RPT:
                        # get or create entry in loop registers
                        dest, counter, size = loop_registers.setdefault(
                            cur_block, tuple(RPT[cur_block]))
                        # check if larger than cache size for prefetch
                        if size >= self.cache.size(True):
                             self.prefetch(dest) # prefetch dest
                        # check for last loop iteration
                        counter -= 1
                        if counter == 0:
                            del loop_registers[cur_block]
                            self.prefetch(cur_block + 1) # prefetch next line
                        else:
                            # update registers
                            loop_registers[cur_block] = (dest, counter, size)
                    else:
                        self.prefetch(cur_block + 1) # prefetch next line
            ### LOCK LOGIC
            if enable_lock:
                if self.LT.islock(addr): self.cache.lock_all()
                if self.LT.isunlock(addr): self.cache.unlock_all()
            ### fetch the instruction and update time ("wait" if necessary)
            self.fetch(addr_tag)

            # verbose trace output
            if self.verbose:
                print i, self.t, hex(addr)

###############################################################################
# main program entry point:
###############################################################################

if __name__ == '__main__':
    # specify argument handling
    parser = argparse.ArgumentParser()
    # positional arguments
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "\
                             "one address (hex, w/o leading 0x) per line.")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose simulation output.")
    parser.add_argument("-p", "--print-graphs", action="store_true",
                        help="Print dynamic control-flow graphs.")
    parser.add_argument("--blocksize", type=int, default=32,
                        help="Size of a cache block in bytes.")
    parser.add_argument("--sets", type=int, default=1,
                        help="Number of cache sets.")
    parser.add_argument("--assoc", type=int, default=8,
                        help="Associativity.")
    parser.add_argument("--mem-cycles", type=int, default=20,
                        help="Number of cycles required to load a cache line.")
    parser.add_argument("--disable-prefetch", action="store_true",
                        help="Disable prefetching.")
    parser.add_argument("--disable-lock", action="store_true",
                        help="Disable locking.")
    args = parser.parse_args()

    # We need the instruction address trace more than once,
    # therefore we obtain a generator function for obtaining a trace.
    # Each item is a pair of fetch cycle and instruction address.
    trace = TraceGen(args.trace)

    # instantiate the cache
    C = Cache(args.blocksize, args.sets, args.assoc)

    T = TraceAnalysis(Functions("funcs.txt"))
    T.analyze(trace)

    if args.print_graphs:
        T.write_graphs("dyncfg_")

    RPT = T.create_rp_table(C.tagof)
    LT = T.create_lock_table(C.tagof, args.sets * args.assoc)
    if args.verbose:
        T.dump(C.tagof)
        print RPT
        print LT


    Sim = Simulator(C, RPT, LT, args.mem_cycles, args.verbose)
    Sim.run(trace, not args.disable_prefetch, not args.disable_lock)
    if args.verbose:
        print Sim.stats

    print Sim.t


