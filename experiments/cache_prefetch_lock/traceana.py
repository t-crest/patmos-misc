#!/usr/bin/env python
###############################################################################
#
# Trace analysis module.
#
# Analyze an instruction trace of a single-path program.
#
# Author: Daniel Prokesch <daniel@vmars.tuwien.ac.at>
#
###############################################################################


from bisect import bisect
from subprocess import call # call dot to generate .png out of .dot files

###############################################################################

class Loop:
    def __init__(self, backedge, count, exitnode):
        self.tail, self.head = backedge
        self.depth = 0
        self.count = count
        self.parent = None
        self.exitnode = exitnode
        self.children = []
        self._iterations = None # computed lazily

    def __str__(self):
        if self.depth > 0:
            return "h:{:#010x} t:{:#010x} e:{:#010x} d:{} it:{}".format(
                self.head, self.tail, self.exitnode, self.depth, self.iterations())
        else:
            return "h:{:#010x} #calls:{}".format(self.head, self.iterations())

    def iterations(self):
        if self._iterations == None:
            it = self.count
            par = self.parent
            while par:
                it /= par.iterations()
                par = par.parent
            self._iterations = it + 1
        return self._iterations

    def is_innermost(self):
        return len(self.children) == 0

    def contains(self, other):
        """Return true if the other loop is contained in this loop."""
        return other.head > self.head and other.tail < self.tail


###############################################################################



class TraceCFG:
    def __init__(self, entry):
        self.addresses = {}
        self.entry = entry
        self.prev  = entry
        self.count = 0
        self._loop_tree = None

    def advance(self, address):
        if address == self.entry:
            # fresh entry to function, prevent backedge
            self.prev = self.entry
            self.count += 1
        # entry for current address
        # successors is a dictionary, with a counter for each successor
        self.addresses.setdefault(address, {})
        # no self loop
        if address != self.prev:
            succs = self.addresses[self.prev]
            succs.setdefault(address, 0)
            succs[address] += 1
            self.prev = address

    def edge_count(u, v):
        if u in self.addresses:
            return self.addresses[u].get(v, 0)
        return 0

    def _backedges(self):
        """DFS determining backedges."""
        visited = set()
        finished = set()
        be = []
        def dfs(v):
          visited.add(v)
          for w in self.addresses[v]:
              if w in visited and w not in finished:
                  be.append(((v, w), self.addresses[v][w]))
              if w not in visited: dfs(w)
          finished.add(v)
        dfs(self.entry)
        return be

    def loop_tree(self):
        """Construct the loop tree lazily and return the root."""
        if self._loop_tree == None:
            be = sorted(self._backedges(), key=lambda x: x[0][1])
            root = last = Loop((0xffffffff, self.entry), self.count - 1, None)
            for edge, cnt in be:
                assert len(self.addresses[edge[0]]) == 2
                exitnode = (set(self.addresses[edge[0]]) - {edge[1]}).pop()
                new = Loop(edge, cnt, exitnode)
                par = last
                while True:
                    if par.contains(new):
                        new.parent = par
                        par.children.append(new)
                        break
                    par = par.parent
                new.depth = par.depth + 1
                last = new
            self._loop_tree = root
        return self._loop_tree

    def loops(self):
        root = self.loop_tree()
        loops = []
        # preorder traversal of the loop_tree
        def traverse(node):
            # start appending with the children, this will skip the root node
            for child in node.children:
                loops.append(child)
                traverse(child)
        # start at top
        traverse(root)
        return loops


    def __str__(self):
        return '\n'.join("{}: {}".format(*pair)
                         for pair in self.addresses.iteritems())

    def write_graph(self, fname):
        with open(fname + ".dot", "w") as f:
            f.write('digraph TraceCFG {\n'\
                    '  graph[label="Dynamic CFG from trace", '\
                             'ranksep=0.25, fontname="sans-serif"];\n'\
                    '  edge [fontname="sans-serif"];\n'\
                    '  node [shape=rectangle, '\
                             'fontname="sans-serif"];\n')
            # print blocks in dfs-order
            visited = set()
            def dfs(prev, addr):
                if addr not in visited:
                    label = "{0:#08x}".format(addr) \
                            if type(addr) == type(0xffffffff) else addr
                    f.write('  {} [label="{}"];\n'.format(addr, label))
                if prev:
                    f.write('  {} -> {} [label="{}"];\n'.format(
                        prev, addr, self.addresses[prev][addr]))
                if addr in visited: return
                visited.add(addr)
                if addr in self.addresses:
                    for succ in self.addresses[addr]: dfs(addr, succ)
            dfs(None, self.entry)
            f.write('}\n')
        assert(f.closed)
        call(["/usr/bin/dot", "-Tpng", "-o", fname + ".png", fname + ".dot"])



###############################################################################

class RPT:
    def __init__(self, tagof=lambda x: x):
        self.tagof = tagof
        self.entries = dict()

    def __getitem__(self, item):
        # item as address
        mb = self.tagof(item)
        return self.entries.get(mb, None)

    def __contains__(self, item):
        return self.tagof(item) in self.entries

    def insert(self, trigger, dest, count):
        trigger_line = self.tagof(trigger)
        dest_line = self.tagof(dest)
        assert trigger_line not in self.entries
        self.entries[trigger_line] = (dest_line, count,
                                      trigger_line - dest_line + 1)

    def __str__(self):
        lines = []
        lines.append("  {:>8s}  {:>8s}  {:>8s}  {:>8s}".format(
            "trig", "dest", "count", "size"))
        lines.append("="*40)
        for trig, val in sorted(self.entries.iteritems()):
            lines.append("  {:8d}  {:8d}  {:8d}  {:8d}".format(trig, *val))
        return "\n".join(lines)

class LT:
    def __init__(self):
        self.lock = set()
        self.unlock = set()
        self.pairs = set()

    def __contains__(self, item):
        return item in (self.lock | self.unlock)

    def insert(self, lockaddr, unlockaddr):
        self.lock.add(lockaddr)
        self.unlock.add(unlockaddr)
        self.pairs.add((lockaddr, unlockaddr))

    def islock(self, addr):
        return addr in self.lock

    def isunlock(self, addr):
        return addr in self.unlock

    def __str__(self):
        lines = []
        lines.append("  {:>10s}  {:>10s}".format("lock", "unlock"))
        lines.append("="*24)
        for lock, unlock in sorted(self.pairs):
            lines.append("  {:#10x}  {:#10x}".format(lock, unlock))
        return "\n".join(lines)


###############################################################################


class TraceAnalysis:
    def __init__(self, functions):
        self.functions = functions
        self.func_stack = [(None, None)]
        self.cfgs = {}
        self.prev = None
        self.call_edge_stack = []
        self.call_ret = {}

    def advance(self, addr):
        cur_func = self.functions[addr]
        dyncfg = self.cfgs.setdefault(cur_func, TraceCFG(addr))
        # advance the cfg for the given function
        dyncfg.advance(addr)
        # handle call/return edges
        if addr == cur_func[0]: #entry
            self.func_stack.append(cur_func)
            # push call edge
            self.call_edge_stack.append((self.prev, addr))
        elif cur_func != self.func_stack[-1]:
            self.func_stack.pop()
            # addr is the return address
            call_edge = self.call_edge_stack.pop()
            # record tuple (callsite, retaddr, func)
            tup = (call_edge[0], addr, call_edge[1])
            count = self.call_ret.get(tup, 0)
            self.call_ret[tup] = count + 1
        # remember last address
        self.prev = addr

    def analyze(self, trace):
        """Analyze a given trace.

        trace is a generator function for the instruction address trace.
        """
        for cyc, addr in trace():
            #addrs = [addr, addr+4]
            #for a in addrs: self.advance(a)
            self.advance(addr)

    def write_graphs(self, prefix=""):
        for func, cfg in self.cfgs.iteritems():
            cfg.write_graph(prefix + func[1])

    def dump(self, tagof=lambda x: x):
        call_sites = [tup[0] for tup in self.call_ret.keys()]
        def dump_loop(loop):
            print "    "*loop.depth, str(loop), "has_call=",\
                any([loop.head <= site <= loop.tail for site in call_sites])
            for child in loop.children:
                dump_loop(child)
        for func, cfg in self.cfgs.iteritems():
            print "# {}:".format(func[1])
            dump_loop(cfg.loop_tree())
        print "# call_site/return_adddress (count) [caller -> callee]"
        call_list = sorted(self.call_ret.iteritems(), key=lambda x: x[1],
                           reverse=True)
        for (callsite, retaddr, func), count in call_list:
            print "{:#010x}/{:#010x} ({}) [{} -> {}]".format(
                callsite, retaddr, count,
                *[self.functions[e][1] for e in [callsite, func]])


    def create_rp_table(self, tagof=lambda x: x):
        """Create the Reference Prediction Table (RPT) for the analyzed trace.

        tagof is a function to get the tag of a memory address.
        """
        rpt = RPT(tagof)
        for func, cfg in self.cfgs.iteritems():
            for loop in cfg.loops():
                rpt.insert(loop.tail, loop.head, loop.iterations())
        return rpt


    def create_lock_table(self, tagof=lambda x: x, cache_capacity_lines=1):
        """Create the Lock Table for the analyzed trace.

        tagof is a function to get the tag of a memory address.
        """
        call_sites = [tup[0] for tup in self.call_ret.keys()]
        block_size = 0xffffffff / tagof(0xffffffff)

        def loop_has_call(loop):
            return any([loop.head <= site <= loop.tail for site in call_sites])

        def loop_size_blocks(loop):
            return tagof(loop.tail) - tagof(loop.head) + 1

        def skip_to_next_block(addr, cfg):
            # An instruction starts at the start of the next block
            addr_next_block = (tagof(addr) + 1) * block_size
            # Or at an offset of 4 byte.
            # In practice (once 64bit instructions are removed), we
            # could simply take the address at the beginning of the next block
            if addr_next_block not in cfg.addresses:
                addr_next_block += 4
                assert addr_next_block in cfg.addresses
            return addr_next_block

        lock_table = LT()
        for func, cfg in self.cfgs.iteritems():
            # iterate over "true" loops
            for loop in cfg.loops():
                # only consider loops larger than the cache capacity
                if loop_size_blocks(loop) <= cache_capacity_lines: continue
                # loops must not have a call inside
                if loop_has_call(loop): continue
                # innermost loops with at most one child are inserted
                if loop.is_innermost():
                    lock_table.insert(loop.tail, loop.exitnode)
                    continue
                # optimization for nesting-level 1 loops: lock the inner loop
                # if it fits the cache
                if len(loop.children) == 1:
                    chld = loop.children[0]
                    if loop_size_blocks(chld) > cache_capacity_lines:
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

class Functions:
    """Class to lookup the function an instruction address belongs to."""
    def __init__(self, fname):
        self.entries = []
        self.names = []
        with open(fname, "r") as f:
            for line in f:
                addr, name = line.split(" ")
                self.entries.append(int(addr, 16))
                self.names.append(name.rstrip())

    def __getitem__(self, addr):
        i = bisect(self.entries, addr)
        if i > 0:
            return self.entries[i-1], self.names[i-1]
        else:
            return None, None


###############################################################################

def TraceGen(tracefile):
    """Trace Generator, given an address trace file (1 address/line).

    Each item yielded by the generator is a pair of fetch cycle and
    instruction address.
    """
    def trace():
        with open(tracefile, 'r') as ftrace:
            for cnt, x in enumerate(ftrace):
                yield (cnt, int(x, 16))
    # return the generator function (closure)
    return trace


##############################################################################

if __name__ == "__main__":
    import argparse
    # specify argument handling
    parser = argparse.ArgumentParser()
    # positional arguments
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "\
                             "one address (hex, w/o leading 0x) per line.")
    parser.add_argument("-p", "--print-graphs", action="store_true",
                        help="Print dynamic control-flow graphs.")
    args = parser.parse_args()

    tagof = lambda x: x / 32

    # create analyzer and performa analysis
    T = TraceAnalysis(Functions("funcs.txt"))
    T.analyze(TraceGen(args.trace))
    T.dump()

    RPT = T.create_rp_table(tagof)
    print RPT

    LT = T.create_lock_table(tagof, 4)
    print LT


    if args.print_graphs:
        T.write_graphs("dyncfg_")
