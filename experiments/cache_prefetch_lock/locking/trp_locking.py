#!/usr/bin/env python
###############################################################################
#
# Script to preliminarily evaluate cache performance of the
# single-path cache locking strategy developed by Bekim Cilku.
#
# Author: Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import re
import string
import argparse

from subprocess import call # call dot to generate .png out of .dot files


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

    def lock(self, tag):
        if self.lock_offset >= len(self.blocks):
            raise Exception("Lock limit reached")
        if tag in self.blocks[0:self.lock_offset]:
            # it is already locked
            # we do not need to do anything but report hit
            return True
        hit = self.update(tag)
        self.lock_offset += 1
        return hit

    def get_num_locked(self):
        return self.lock_offset

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
        self.num_hits = 0
        self.num_misses = 0
        self.num_accesses = 0

    def tagof(self, addr):
        """Get the tag of a specified address."""
        return (addr // self.blocksize)

    def setof(self, tag):
        return self.sets[tag % len(self.sets)]

    def access(self, addr, lock=False):
        self.num_accesses += 1
        tag = self.tagof(addr)
        cset = self.setof(tag)
        hit = cset.update(tag) if not lock else cset.lock(tag)
        if hit:
            self.num_hits += 1
        else:
            self.num_misses += 1
        return hit

    def get_num_locked(self):
        return sum([s.get_num_locked() for s in self.sets])

    def __str__(self):
        return "\n".join(["{}: {}".format(i, s)
                          for i, s in enumerate(self.sets)])


###############################################################################


class MemoryBlock:
    def __init__(self, tag, trace):
        self.tag = tag
        self.trace = trace
        self.last_accessed = -1
        self.cnt = 0
        self.tcs = None
        self.trp = {}
        self.succs = {}

    def edgeto(self, other):
        if self != other:
            cnt = self.succs.setdefault(other, 0)
            self.succs[other] = cnt + 1

    def access(self, cyc):
        self.trace.connect(self)
        self.cnt += 1
        self.last_accessed = cyc
        if self.tcs != None and len(self.tcs) < self.trace.cache_assoc:
            tcs = frozenset(self.tcs)
            self.trp.setdefault(tcs, 0)
            self.trp[tcs] += 1
        self.tcs = set()

    def num_hits(self, locked):
        if self in locked:
            return self.cnt
        else:
            return sum(f for s, f in self.trp.iteritems()
                       if len(locked) + len(s) < self.trace.cache_assoc)

    def num_misses(self, locked):
        return self.cnt - self.num_hits(locked)

    def __str__(self):
        setfmt = lambda s: "{{{}}}".format(", ".join(str(e) for e in s))
        tcsfmt = lambda tcs, f: "<{},{}>".format(setfmt(tcs),f)
        trp = ", ".join([tcsfmt(s, f) for (s,f) in self.trp.items()])
        template = "{:6d}: {:6d}  {:6d}  {:6d}  {:6d}  {}"
        return template.format(self.tag, self.cnt, self.num_misses({}),
                               self.num_hits({}), self.last_accessed, trp)

        #succs = ",".join(["{}({})".format(b.tag, cnt)
        #                  for b, cnt in self.succs.iteritems()])
        #return "{} ({}/{}) ->[{}]".format(self.tag, self.num_misses,
        #                                  self.num_hits, succs)


class Trace:
    def __init__(self, num, cache_assoc):
        self.num = num
        self.subtraces = [Subtrace(cache_assoc) for i in range(num)]

    def __iter__(self):
        return self.subtraces.__iter__()

    def __getitem__(self, key):
        return self.subtraces[key]

    def access(self, tag, cyc):
        self.subtrace_of(tag).access(tag, cyc)

    def subtrace_of(self, tag):
        return self.subtraces[tag % self.num]

    def num_hits(self, locked=frozenset()):
        return sum(t.num_hits(frozenset(m for m in locked
                              if (m.tag % t.cache_assoc) == i))
                   for i, t in enumerate(self.subtraces))

    def num_misses(self, locked=frozenset()):
        return sum(t.num_misses(frozenset(m for m in locked
                                if (m.tag % t.cache_assoc) == i))
                   for i, t in enumerate(self.subtraces))

    def num_accesses(self):
        return sum(t.num_accesses() for t in self.subtraces)

    def locking_optimal(self):
        solution = []
        for t in self.subtraces:
            solution.extend(t.locking_optimal())
        return solution

    def locking_heuristic(self):
        solution = set()
        for t in self.subtraces:
            solution |= t.locking_heuristic()
        return frozenset(solution)

    def write_graphs(self, fname):
        for i, t in enumerate(self.subtraces):
            t.write_graph("{}_{}".format(fname, i))

    def __str__(self):
            return "\n".join("Subtrace #{}:\n{}".format(i, t)
                             for i, t in enumerate(self.subtraces))


class Subtrace:
    def __init__(self, cache_assoc):
        self.blocks = {}
        self.cache_assoc = cache_assoc
        self.entry = None
        self.prev  = None
        self.locked = set()

    def get_block(self, tag):
        b = self.blocks.setdefault(tag, MemoryBlock(tag, self))
        if not self.entry: self.entry = b
        return b

    def access(self, tag, cyc):
        # commit for tag
        self.get_block(tag).access(cyc)
        # update tcs in other memory blocks
        for mo in self.blocks.itervalues():
            if tag != mo.tag:
                mo.tcs.add(tag)

    def connect(self, block):
        if self.prev and self.prev != block:
            self.prev.edgeto(block)
        self.prev = block

    def num_hits(self, locked=frozenset()):
        assert locked <= set(self.blocks.values())
        return sum(m.num_hits(locked) for m in self.blocks.itervalues())

    def num_misses(self, locked=frozenset()):
        assert locked <= set(self.blocks.values())
        return sum(m.num_misses(locked) for m in self.blocks.itervalues())

    def num_accesses(self):
        return sum(m.cnt for m in self.blocks.itervalues())

    def __str__(self):
        return '\n'.join(str(m) for m in self.blocks.itervalues())

    def write_graph(self, fname):
        with open(fname + ".dot", "w") as f:
            f.write('digraph MemoryBlocks {\n'\
                    '  graph[label="Mem block access graph", '\
                             'ranksep=0.25, fontname="sans-serif"];\n'\
                    '  edge [fontname="sans-serif"];\n'\
                    '  node [shape=rectangle, '\
                             'fontname="sans-serif"];\n')
            # print blocks in dfs-order
            visited = set()
            def dfs(prev, b):
                if b not in visited:
                    f.write('  T{0} [label="T{0}\\n<{1:d}/{2:d}>"];\n'
                        .format(b.tag, b.num_misses, b.num_hits))
                if prev:
                    f.write('  T{} -> T{} [label="{:d}"];\n'
                            .format(prev.tag, b.tag, prev.succs[b]))
                if b in visited: return
                visited.add(b)
                for succ in b.succs: dfs(b, succ)
            dfs(None, self.entry)
            f.write('}\n')
        assert(f.closed)
        call(["/usr/bin/dot", "-Tpng", "-o", fname + ".png", fname + ".dot"])

    def locking_optimal(self):
        solver = OptimalSolver(self)
        res = solver.solve()
        print "===="
        print "SOLUTION:", [m.tag for m in res], solver.maxhit, "hits"
        return res

    def locking_heuristic(self):
        locked = set()
        flag = True
        current_hit = self.num_hits(locked)
        while flag:
            benefit = 0
            for m in frozenset(self.blocks.values()) - locked:
                new_hit = self.num_hits(locked | {m})
                if new_hit - current_hit > benefit:
                    benefit = new_hit - current_hit
                    mx = m
            if benefit > 0:
                locked.add(mx)
            else:
                flag = False
            if len(locked) == self.cache_assoc:
                flag = False

        print "===="
        print "HEURISTIC:", [m.tag for m in locked], \
                self.num_hits(locked), "hits"
        return locked


class OptimalSolver:
    def __init__(self, trace):
        self.trace = trace
        self.cache_assoc = trace.cache_assoc
        self.Mi = frozenset(trace.blocks.values())

    def _search(self, M, locked):
        if len(locked) == self.cache_assoc or len(M) == 0:
            newhit = self.trace.num_hits(locked)
            if newhit > self.maxhit:
                self.optimal_soln = frozenset(locked)
                self.maxhit = newhit
            return
        # lock any memory block
        m = M.pop()
        locked.add(m)
        curhit = sum(mp.num_hits(locked) for mp in (self.Mi - M))
        # Mp is set of memory blocks from M with maximum access cnt
        # (of size of remaining lines to lock)
        Mp = sorted(M, key=lambda x: x.cnt,
                    reverse=True)[0:(self.cache_assoc - len(locked))]
        bound = sum(mp.cnt for mp in Mp)
        Mpp = set()
        while len(Mp) + len(Mpp) < len(M):
            mp = max(M - Mpp, key = lambda x: x.num_hits(locked))
            bound += mp.num_hits(locked)
            Mpp.add(mp)
        bound = min(bound, sum(mp.cnt for mp in M))
        if curhit + bound > self.maxhit:
            # branching decision for m
            self._search(set(M), set(locked))
        self._search(set(M), set(locked - {m}))

    def solve(self, maxhit=None):
        self.maxhit = self.trace.num_hits() if not maxhit else maxhit
        self.optimal_soln = frozenset()
        self._search(set(self.Mi), set())
        return self.optimal_soln



###############################################################################


def simulate(trace, TRP=None):
    """Main cache simulation function.

    trace is a generator function for the instruction address trace.
    """

    for cyc, addr in trace():
        # As instructions of Patmos are aligned at 32 bit but can be 64 bit in
        # size, an instruction may span across two cache-lines.
        # We fetch both possible cache-lines for correctness.
        addrs = [addr, addr+4]

        # simulate cache
        for a in addrs: C.access(a)

        tags = [C.tagof(a) for a in addrs]

        if TRP:
            for t in tags:
                TRP.access(t, cyc)

        # verbose trace output
        if args.verbose:
            print cyc, hex(addr), tags
            print C
            print "==="

    # End of main simulation loop
    return cyc



###############################################################################
# main program entry point:
###############################################################################

if __name__=='__main__':
    # specify argument handling
    parser = argparse.ArgumentParser()
    # positional arguments
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "\
                             "one address (hex, w/o leading 0x) per line.")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose simulation output.")
    parser.add_argument("-p", "--print-graphs", action="store_true",
                        help="Print memory block access graphs.")
    parser.add_argument("--blocksize", type=int, default=64,
                        help="Size of a cache block.")
    parser.add_argument("--sets", type=int, default=2,
                        help="Number of cache sets.")
    parser.add_argument("--assoc", type=int, default=4,
                        help="Associativity.")
    parser.add_argument("--miss-costs", type=int, default=10,
                        help="Associativity.")
    args = parser.parse_args()

    # miss cycles for a cache block
    miss_cycles = 10

    # We need the instruction address trace more than once,
    # therefore we define a generator function for obtaining a trace.
    # Each item is a pair of fetch cycle and instruction address.
    def trace():
        with open(args.trace, 'r') as ftrace:
            for cyc, x in enumerate(ftrace):
                yield (cyc, int(x, 16))
        pass


    C = Cache(args.blocksize, args.sets, args.assoc)

    T = Trace(args.sets, args.assoc)

    tags_to_lock = []#[10820, 10821, 10822, 10823]
    for t in tags_to_lock:
        C.access(t * C.blocksize, lock=True)

    # Call the main simulation function.
    cyc = simulate(trace, T)

    print "Number of instructions:", cyc
    print "Cache: {} accesses, {} misses / {} hits".format(C.num_accesses,
                                                           C.num_misses,
                                                           C.num_hits)
    print "Total execution time:", cyc + C.num_misses*args.miss_costs

    print T
    print "Trace: {} accesses, {} misses / {} hits".format(T.num_accesses(),
                                                           T.num_misses(),
                                                           T.num_hits())
    if args.print_graphs: T.write_graphs("graph")

    C = Cache(args.blocksize, args.sets, args.assoc)
    heur = T.locking_heuristic()
    print [m.tag for m in heur]
    print "Trace: {} accesses, {} misses / {} hits".format(T.num_accesses(),
                                                           T.num_misses(heur),
                                                           T.num_hits(heur))
    sol = T.locking_optimal()
    print [m.tag for m in sol]
    for t in sol:
        C.access(t.tag * C.blocksize, lock=True)
    cyc = simulate(trace)

    print "Number of instructions:", cyc
    print "Cache: {} accesses, {} misses / {} hits".format(C.num_accesses,
                                                           C.num_misses,
                                                           C.num_hits)

