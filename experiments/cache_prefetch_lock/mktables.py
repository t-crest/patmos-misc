#!/usr/bin/env python
###############################################################################
#
# Table generator for prefetch/locking architecture.
#
# Uses the results from the trace analysis module to create the tables.
#
# Author: Daniel Prokesch <daniel@vmars.tuwien.ac.at>
#
###############################################################################

import pickle

from collections import Counter

import sys

###############################################################################

class TableCreator:
    def __init__(self, trace_analysis, tagof=lambda x: x,
                 cache_capacity_lines=1):
        self.ta = trace_analysis
        self.tagof = tagof
        self.cache_size = cache_capacity_lines
        self.cache_block_size = 0xffffffff / tagof(0xffffffff)

    def unique_blocks(self, range_start, range_end):
        """Get the memory blocks covered by the given address range.

        Returns a list of (unique) memory blocks that the range covers
        *statically*.
        """
        return range(self.tagof(range_start), self.tagof(range_end) + 1)

    def dyn_blocks(self, range_start, range_end, functions_visited = set()):
        """Return the set of distinct memory blocks referenced in execution."""
        blocks = set(self.unique_blocks(range_start, range_end))
        for call in self.ta.call_sites_range(range_start, range_end):
            if call.callee not in functions_visited:
                functions_visited.add(call.callee)
                blocks.update(
                    self.dyn_blocks(call.callee.entry,
                                    call.callee.exit,
                                    functions_visited))
        return blocks

    def num_dyn_blocks(self, range_start, range_end):
        """Return the number of distinct memory blocks referenced.

        Referenced when executing the loop. It includes all the blocks
        of functions called.
        """
        return len(self.dyn_blocks(range_start, range_end))

    def loop_size(self, loop):
        """Convenience function to determine the dynamic size of a loop."""
        return self.num_dyn_blocks(loop.head, loop.tail)

    def skip_to_next_block(self, func, addr):
        """Return an address of the memory block following addr

        Given an instruction address, return an address in the next memory
        block after the address
        """
        # An instruction starts at the start of the next block
        addr_next_block = (self.tagof(addr) + 1) * self.cache_block_size
        # Or at an offset of 4 byte.
        # In practice (once 64bit instructions are removed), we
        # could simply take the address at the beginning of the next block
        if addr_next_block not in func.cfg:
            addr_next_block += 4
            assert addr_next_block in func.cfg
        return addr_next_block


###############################################################################


class RPTCreator(TableCreator):
    def __init__(self, trace_analysis, tagof=lambda x: x,
                 cache_capacity_lines=1):
        TableCreator.__init__(self,
                              trace_analysis, tagof, cache_capacity_lines)
        self.rpt = []
        self.func_offsets = {}

        # preparatory: compute offsets for loop depths
        self.func_depth_offsets = self._compute_loop_depths()

        # 1st pass: create the "table rows"
        self._initial_fill()
        # 2nd pass to add attributes based on location in table
        self._backpatch()

    def _compute_loop_depths(self):
        cg = self.ta.call_graph()
        # compute rpo and propagate offsets in that order
        po = []
        def dfs(n, visited):
            visited.add(n)
            for succ in cg[n]:
                if succ not in visited: dfs(succ, visited)
            po.append(n)
        dfs(self.ta.functions()[0], set())
        max_offsets = {f: 0 for f in self.ta.functions()}
        for n in reversed(po):
            for succ in cg[n]:
                # maximum of current offset and new offset
                max_offsets[succ] = max(max_offsets[succ],
                                        max_offsets[n] + n.height)
        return max_offsets

    def entry_past_addr(self, addr):
        # lookup the function
        func = self.ta.get_func_at(addr)
        return next(rpt_entry
                    for rpt_entry in self.rpt[self.func_offsets[func]:]
                    if addr < rpt_entry.trigger_address)


    def _check_loop_dyn_cache_conflicts(self, loop):
        """Check if the any two memory blocks of a loop map to same line.

        Given a loop, checks if the loop is executed, any two memory blocks
        map to the same cache line, considering all visited memory blocks,
        and, for each function called, the block after the function.
        Mapping is done with block modulo self.cache_size.

        Returns True if there is a conflict.
        """
        inner_functions = set()
        blocks = self.dyn_blocks(loop.head, loop.tail, inner_functions)
        # add one block past return instruction of every inner function to
        # the set
        #print >>sys.stderr, "dynamic memory blocks of loop", blocks
        blocks.update(self.tagof(f.exit) + 1 for f in inner_functions)
        #print >>sys.stderr, "inner functions", inner_functions
        #print >>sys.stderr, "with additional function blocks added", blocks
        # map to cache lines
        cnt = Counter([b % self.cache_size for b in blocks])
        #print >>sys.stderr, "mapping to cache lines", cnt
        return any(c > 1 for c in cnt.values())

    def _initial_fill(self):
        """Initially fill the RPT.

        Rows for functions have to occur grouped to preserve the 'next index'
        requirements.
        """
        for func in self.ta.functions():
            # group of rows for func
            rpt_group = []
            # first index of the function in the rpt
            self.func_offsets[func] = len(self.rpt)
            # collect entries of interest
            for loop in func.loops():
                # Small lopp if there are no conflicts on cache lines
                if self.loop_size(loop) <= self.cache_size and \
                   not self._check_loop_dyn_cache_conflicts(loop):
                    # SMALL LOOP
                    rpt_group.append(RPT_SmallLoop(loop, func))

                else:
                    # LARGE LOOP
                    rpt_group.append(RPT_Loop(loop, func))
            for call in self.ta.call_sites_range(func.entry, func.exit):
                rpt_group.append(RPT_Call(call))
            # function exit
            # -> this implies every function has at least one entry!
            rpt_group.append(RPT_Return(func))
            # sort group by address
            rpt_group.sort(key=lambda rpt_entry: rpt_entry.trigger_address)

            # extend the global table by the rows for the function
            self.rpt.extend(rpt_group)


    def _backpatch(self):
        # build the properties and patch the addresses
        for i, rpt_entry in enumerate(self.rpt):
            rpt_entry.idx = i
            self.set_trigger_line(rpt_entry)
            rpt_entry._patch(self)

    def set_trigger_line(self, e):
        e.trigger_line = self.tagof(e.trigger_address + 4)


    def dump(self, encoded=False):
        print RPT_Entry.columns
        for e in self.rpt:
            print e if not encoded else e.str_encoded()

    def save(self, filename):
        with open(filename, "w") as f:
            pickle.dump(self.rpt, f)


    @staticmethod
    def load(filename):
        with open(filename) as f:
            return pickle.load(f)


class RPT_Entry:
    columns = "idx trig type dest it nxt count depth retdest"
    def __init__(self, trigger_address):
        self.trigger_address = trigger_address

    def _patch(self, creator):
        """Implemented by subclasses for backpatching"""
        raise Exception("Not implemented!")

    def __str__(self):
        attrs = [getattr(self, x, "-") for x in
                 ["dest", "it", "nxt", "count", "depth", "retdest"]]
        return "{} {} {} {} {} {} {} {} {} ".format(
            self.idx,
            self.trigger_line,
            self.__class__.__name__[4:], # prefetch type
            *attrs)

    def str_encoded(self):
        attrs = [getattr(self, x, "0") for x in
                 ["dest", "it", "nxt", "count", "depth", "retdest"]]
        return "{} {} {} {} {} {} {} {} {} ".format(
            self.idx,
            self.trigger_line,
            self.type_id,
            *attrs)



class RPT_Loop(RPT_Entry):
    def __init__(self, loop, func):
        self.type_id = 2 # integer type encoding
        self._loop = loop
        self._func = func
        RPT_Entry.__init__(self, loop.tail)
    def _patch(self, creator):
        self.nxt = creator.entry_past_addr(self._loop.head).idx
        self.dest = creator.tagof(self._loop.head)
        self.it = self._loop.iterations() - 1
        # max depth in call graph
        self.depth = creator.func_depth_offsets[self._func] + \
                self._func.height - self._loop.depth


class RPT_SmallLoop(RPT_Entry):
    def __init__(self, loop, func):
        self.type_id = 3 # integer type encoding
        self._loop = loop
        self._func = func
        RPT_Entry.__init__(self, loop.tail)
    def _patch(self, creator):
        # 'count' is the number of cache lines to prefetch after the loop.
        # it is the minimum of reaching the next trigger line (next table
        # index) and the number of cache lines to fill up the cache in addition
        # to the loop
        remaining = creator.cache_size - creator.loop_size(self._loop)
        gap = creator.tagof(creator.rpt[self.idx + 1].trigger_address) - \
                creator.tagof(self._loop.tail)
        self.count = min(remaining, gap)
        self.dest = creator.tagof(self._loop.head)
        #################################################################
        # if the gap is zero, switch to loop end
        if self.count == 0:
            self.type_id = 2
            self.nxt = creator.entry_past_addr(self._loop.head).idx
            self.dest = creator.tagof(self._loop.head)
            self.it = self._loop.iterations() - 1
        ################################################################
        # max depth in call graph
        self.depth = creator.func_depth_offsets[self._func] + \
                self._func.height - self._loop.depth


class RPT_Call(RPT_Entry):
    def __init__(self, call):
        self.type_id = 0 # integer type encoding
        self._call = call
        RPT_Entry.__init__(self, call.call_site)
    def _patch(self, creator):
        # destination is the memory block of the callee
        self.dest = creator.tagof(self._call.callee.entry)
        self.nxt = creator.func_offsets[self._call.callee]
        self.retdest = creator.tagof(self._call.return_address)


class RPT_Return(RPT_Entry):
    def __init__(self, of_func):
        self.type_id = 1 # integer type encoding
        RPT_Entry.__init__(self, of_func.exit)
    def _patch(self, creator):
        pass # nothing to do here


class RPT_Any(RPT_Entry):
    def __init__(self, addr):
        self.type_id = -1 # integer type encoding
        RPT_Entry.__init__(self, addr)


###############################################################################

# following code is unused for now...

class LockTableCreator(TableCreator):
    def __init__(self, trace_analysis, tagof=lambda x: x,
                 cache_capacity_lines=1):
        TableCreator.__init__(self,
                              trace_analysis, tagof, cache_capacity_lines)


        self.lt = []
        self.func_offsets = {}
        # 1st pass: create the "table rows"
        self._initial_fill()

    def _initial_fill(self):

        for func in self.ta.functions():
            # iterate over "true" loops
            for loop in func.loops():
                if self.loop_size(loop) <= self.cache_size:
                    continue
                # innermost loops with at most one child are inserted
                if len(loop.children) == 0:
                    self.lt.append((loop.tail, loop.exitnode))
                    continue
                # TODO refine the next two conditions to consider dynamic
                # block sizes instead and loops from called functions
                # loops must not have a call inside
                if len(self.ta.loop_calls(loop)) > 0: continue
                # optimization for nesting-level 1 loops: lock the inner loop
                # if it fits the cache
                if len(loop.children) == 1:
                    chld = loop.children[0]
                    if self.loop_size(chld) > self.cache_size:
                        continue
                    # search for a fitting locking window
                    lock_addr = chld.tail
                    lock_block = self.tagof(lock_addr)
                    while lock_block - self.cache_size + 1 \
                          < self.tagof(loop.head):
                        # skip forward to an address of the next cache block
                        lock_addr = self.skip_to_next_block(lock_addr, func)
                        lock_block = self.tagof(lock_addr)
                    self.lt.append((lock_addr, loop.exitnode))

    def dump(self):
        print "idx lock_addr  unlock_addr"
        for idx, (lock_addr, unlock_addr) in enumerate(self.lt):
            #print "{:3d} {:#010x} {:#010x}".format(idx, lock_addr, unlock_addr)
            print "{:3d} {:d} {:d}".format(idx, lock_addr, unlock_addr)


###############################################################################

if __name__ == "__main__":

    from traceana import TraceAnalysis, TraceGen, FunctionMap

    import argparse

    # specify argument handling
    parser = argparse.ArgumentParser()
    # options
    parser.add_argument("-s", "--size", type=int, default=16,
                        help="Size of a cache line in bytes."\
                        " (default: %(default)d)")
    parser.add_argument("-l", "--lines", type=int, default=512,
                        help="Number of cache lines. (default: %(default)d)")
    parser.add_argument("--rpt", action="store_true",
                        help="Generate RPT table.")
    parser.add_argument("--lock", action="store_true",
                        help="Generate lock table.")
    parser.add_argument("-e", "--encoded", action="store_true",
                        help="Output the tables suitable for parsing with "
                             "Bekim's scala code.")
    # positional arguments
    parser.add_argument("func_symbols",
                        help="File containing the start address of each "
                             "function; each line has the form "
                             "\"address name\" and the lines are sorted by "
                             "address.")
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "
                             "one address (hex, w/o leading 0x) per line.")
    args = parser.parse_args()


    # create analyzer and perform analysis
    TA = TraceAnalysis(FunctionMap(args.func_symbols), TraceGen(args.trace))

    tagof = lambda x: x / args.size

    if args.rpt:
        RPTC = RPTCreator(TA, tagof, args.lines)
        RPTC.dump(args.encoded)
        #RPTC.save(args.trace + ".rpt")

    if args.lock:
        LTC = LockTableCreator(TA, tagof, args.lines)
        LTC.dump()


