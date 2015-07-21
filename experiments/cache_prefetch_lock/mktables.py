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



###############################################################################

class TableCreator:
    def __init__(self, trace_analysis, tagof=lambda x: x,
                 cache_capacity_lines=1):
        self.ta = trace_analysis
        self.tagof = tagof
        self.cache_size = cache_capacity_lines

        self.rpt = []
        self.func_offsets = {}
        self._initial_fill()

        # build the properties and patch the addresses
        for i, rpt_entry in enumerate(self.rpt):
            rpt_entry.idx = i
            rpt_entry.trigger_line = tagof(rpt_entry.trigger_address)
            rpt_entry._patch(self)


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

    def entry_past_addr(self, addr):
        # lookup the function
        func = self.ta.get_func_at(addr)
        return next(rpt_entry
                    for rpt_entry in self.rpt[self.func_offsets[func]:]
                    if addr < rpt_entry.trigger_address)

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
                if self.loop_size(loop) >= self.cache_size:
                    # LARGE LOOP
                    rpt_group.append(RPT_Loop(loop))
                else:
                    # SMALL LOOP
                    rpt_group.append(RPT_SmallLoop(loop))
            for call in self.ta.call_sites_range(func.entry, func.exit):
                rpt_group.append(RPT_Call(call))
            # function exit
            # -> this implies every function has at least one entry!
            rpt_group.append(RPT_Return(func))
            # sort group by address
            rpt_group.sort(key=lambda rpt_entry: rpt_entry.trigger_address)

            # extend the global table by the rows for the function
            self.rpt.extend(rpt_group)


###############################################################################



class RPT_Entry:
    columns = "idx trig type dest it nxt count retdest"
    def __init__(self, trigger_address):
        self.trigger_address = trigger_address
        self.idx = None

    def _patch(self, creator):
        """Implemented by subclasses for backpatching

        Call this after the creator's rpt has initially been filled
        """
        raise Exception("Not implemented!")

    def __str__(self):
        attrs = [getattr(self, x, "-") for x in
                 ["dest", "it", "nxt", "count", "retdest"]]
        return "{} {} {} {} {} {} {} {} ".format(
            self.idx,
            self.trigger_line,
            self.__class__.__name__[4:], # kind
            *attrs)


class RPT_Loop(RPT_Entry):
    def __init__(self, loop):
        self._loop = loop
        RPT_Entry.__init__(self, loop.tail)
    def _patch(self, creator):
        self.nxt = creator.entry_past_addr(self._loop.head).idx
        self.dest = creator.tagof(self._loop.head)
        self.it = self._loop.iterations()


class RPT_SmallLoop(RPT_Entry):
    def __init__(self, loop):
        self._loop = loop
        RPT_Entry.__init__(self, loop.tail)
    def _patch(self, creator):
        self.it = self._loop.iterations()
        # 'count' is the number of cache lines to prefetch after the loop.
        # it is the minimum of reaching the next trigger line (next table
        # index) and the number of cache lines to fill up the cache in addition
        # to the loop
        remaining = creator.cache_size - creator.loop_size(self._loop)
        gap = creator.tagof(creator.rpt[self.idx + 1].trigger_address) - \
                creator.tagof(self._loop.tail)
        self.count = min(remaining, gap)


class RPT_Call(RPT_Entry):
    def __init__(self, call):
        self._call = call
        RPT_Entry.__init__(self, call.call_site)
    def _patch(self, creator):
        # destination is the memory block of the callee
        self.dest = creator.tagof(self._call.callee.entry)
        self.nxt = creator.func_offsets[self._call.callee]
        self.retdest = creator.tagof(self._call.return_address)


class RPT_Return(RPT_Entry):
    def __init__(self, of_func):
        RPT_Entry.__init__(self, of_func.exit)
    def _patch(self, creator):
        pass # nothing to do here


class RPT_Any(RPT_Entry):
    def __init__(self, addr):
        RPT_Entry.__init__(self, addr)


###############################################################################

# following code is unused for now...



def create_lock_table(analysis, tagof=lambda x: x, cache_capacity_lines=1):
    """Create the Lock Table for the analyzed trace.

    tagof is a function to get the tag of a memory address.
    """
    call_sites = [tup[0] for tup in analysis.calls]
    block_size = 0xffffffff / tagof(0xffffffff)

    def skip_to_next_block(func, addr):
        # An instruction starts at the start of the next block
        addr_next_block = (tagof(addr) + 1) * block_size
        # Or at an offset of 4 byte.
        # In practice (once 64bit instructions are removed), we
        # could simply take the address at the beginning of the next block
        if addr_next_block not in func.cfg:
            addr_next_block += 4
            assert addr_next_block in func.cfg
        return addr_next_block

    lock_table = LT()
    for func in analysis.functions.values():
        # iterate over "true" loops
        for loop in cfg.loops():
            # TODO distinct for the small_loop prefetching type
            # only consider loops larger than the cache capacity
            if loop.dyn_num_blocks(tagof) <= cache_capacity_lines:
                continue
            # TODO refine the next two conditions to consider dynamic
            # block sizes instead and loops from called functions
            # loops must not have a call inside
            if len(loop.calls) > 0: continue
            # innermost loops with at most one child are inserted
            if len(loop.children) == 0:
                lock_table.insert(loop.tail, loop.exitnode)
                continue
            # optimization for nesting-level 1 loops: lock the inner loop
            # if it fits the cache
            if len(loop.children) == 1:
                chld = loop.children[0]
                if chld.dyn_num_blocks(tagof) > cache_capacity_lines:
                    continue
                # search for a fitting locking window
                lock_addr = chld.tail
                lock_block = tagof(lock_addr)
                while lock_block - cache_capacity_lines + 1 \
                      < tagof(loop.head):
                    # skip forward to an address of the next cache block
                    lock_addr = skip_to_next_block(lock_addr, cfg)
                    lock_block = tagof(lock_addr)
                lock_table.insert(lock_addr, loop.exitnode)
    return lock_table


###############################################################################

if __name__ == "__main__":

    from traceana import TraceAnalysis, TraceGen, FunctionMap

    import argparse

    # specify argument handling
    parser = argparse.ArgumentParser()
    # positional arguments
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "\
                             "one address (hex, w/o leading 0x) per line.")
    args = parser.parse_args()


    # create analyzer and performa analysis
    TA = TraceAnalysis(FunctionMap("funcs.txt"), TraceGen(args.trace))

    TC = TableCreator(TA, lambda x: x / 32, 4)

    print RPT_Entry.columns
    for e in TC.rpt:
        print e

