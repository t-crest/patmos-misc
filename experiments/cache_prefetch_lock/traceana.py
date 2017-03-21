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
                self.head, self.tail, self.exitnode, self.depth,
                self.iterations())
        else:
            return "h:{:#010x} #called:{}".format(self.head,
                                                  self.iterations())

    def iterations(self):
        if self._iterations == None:
            it = self.count
            par = self.parent
            while par:
                it /= par.iterations()
                par = par.parent
            self._iterations = it + 1
        return self._iterations

    def contains(self, other):
        """Return true if the other loop is contained in this loop."""
        return other.head > self.head and other.tail < self.tail


###############################################################################

class Call:
    """Create a class for call sites, to have a type to distinguish"""
    def __init__(self, call_site, return_address, callee):
        self.call_site = call_site
        self.return_address = return_address
        self.callee = callee
        self.global_count = 0


###############################################################################

class Function:
    # maintain a sequence number to keep track of the order functions are
    # visited the first time
    sequence_number = 0

    def __init__(self, name, entry):
        self.name  = name
        self.entry = entry
        self.prev  = entry
        self.exit  = None
        self.cfg   = {}
        self.count = 0
        self.seq   = Function.sequence_number
        Function.sequence_number += 1 # bump
        self.loop_tree = None
        self.height = 0

    def advance(self, address):
        """Advance to the next address inside the function.

        Creates and updates the CFG advancing to the next instruction in
        the execution trace contained in this function (call/return is not
        visible).
        """
        if address == self.entry:
            # fresh entry to function, prevent backedge
            self.prev = self.entry
            self.count += 1
        # entry for current address
        # successors is a dictionary, with a counter for each successor
        self.cfg.setdefault(address, {})
        # no self loop
        if address != self.prev:
            succs = self.cfg[self.prev]
            succs.setdefault(address, 0)
            succs[address] += 1
            self.prev = address
        # keep track of function exit (always point to the last visited
        # instruction)
        self.exit = address

    def edge_count(u, v):
        if u in self.cfg:
            return self.cfg[u].get(v, 0)
        return 0

    def _backedges(self):
        """DFS determining backedges."""
        visited = set()
        finished = set()
        be = []
        stack = [self.entry]
        while len(stack) > 0:
            v = stack.pop()
            assert v not in finished, "visiting node twice!"
            if v in visited:
                # post-order step
                finished.add(v)
                continue
            # visiting the node for the first time:
            # mark the node as visited and put it back to the stack
            visited.add(v)
            stack.append(v)
            for w in self.cfg[v]: # for each child
                if w in visited and w not in finished:
                    be.append(((v, w), self.cfg[v][w]))
                if w not in visited: stack.append(w)
        return be

    def _create_loop_tree(self):
        """Construct the loop tree lazily and return the root."""
        be = sorted(self._backedges(), key=lambda x: x[0][1])
        root = last = Loop((self.exit, self.entry), self.count - 1, None)
        for edge, cnt in be:
            # CAUTION: following two lines only work if we assume the latch is
            # also the node exiting the loop.
            assert len(self.cfg[edge[0]]) == 2
            exitnode = (set(self.cfg[edge[0]]) - {edge[1]}).pop()
            new = Loop(edge, cnt, exitnode)
            par = last
            while True:
                if par.contains(new):
                    new.parent = par
                    par.children.append(new)
                    break
                par = par.parent
            new.depth = par.depth + 1
            self.height = max(self.height, new.depth)
            last = new
        self.loop_tree = root

    def loops(self):
        root = self.loop_tree
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

    def dump(self):
        def dump_loop(loop):
            print "    "*loop.depth, str(loop)
            for child in loop.children:
                dump_loop(child)
        # dump function header
        print ("# {} (entry {:#010x}, exit {:#010x}, height {:d}):"
              ).format(self.name, self.entry, self.exit, self.height)
        dump_loop(self.loop_tree)

    def __str__(self):
        return '\n'.join("{}: {}".format(*pair)
                         for pair in self.cfg.iteritems())

    def write_graph(self, fname):
        with open(fname + ".dot", "w") as f:
            f.write(('digraph DynCFG_{0} {{\n'
                    '  graph[label="Dynamic CFG for \'{0}\' from trace", '
                             'ranksep=0.25, fontname="sans-serif"];\n'
                    '  edge [fontname="sans-serif"];\n'
                    '  node [shape=rectangle, '
                             'fontname="sans-serif"];\n').format(self.name))
            # print blocks in dfs-order
            visited = set()
            # due to python's bad recursion handling, use an iteratively
            # implemented depth-first search
            stack = [(None, self.entry)]
            while len(stack) > 0:
                prev, addr = stack.pop()
                if addr not in visited:
                    label = "{0:#08x}".format(addr) \
                            if type(addr) == type(0xffffffff) else addr
                    f.write('  {} [label="{}"];\n'.format(addr, label))
                if prev:
                    f.write('  {} -> {} [label="{}"];\n'.format(
                        prev, addr, self.cfg[prev][addr]))
                if addr in visited: continue
                visited.add(addr)
                if addr in self.cfg:
                    stack.extend([(addr, succ) for succ in self.cfg[addr]])
            f.write('}\n')
        assert(f.closed)
        call(["/usr/bin/dot", "-Tpng", "-o", fname + ".png", fname + ".dot"])


###############################################################################


class TraceAnalysis:
    def __init__(self, functionmap, trace):
        """Analyze a given trace.

        'functionmap' is a FunctionMap instance,
        'trace' is a generator function for the instruction address trace.
        """
        self._functionmap = functionmap
        # map: function_name -> Function object
        self._functions = {}
        # map: call_site -> Call object
        self._calls = {}

        self._call_stack = [None]
        self._prev = None
        for addr in trace():
            #addrs = [addr, addr+4]
            #for a in addrs: self.advance(a)
            self._advance(addr)

        # process each function
        for f in self._functions.values():
            f._create_loop_tree()


    def get_func_at(self, addr):
        """Get the function that contains the given address."""
        entry, name = self._functionmap[addr]
        # create if it does not exist yet
        return self._functions.setdefault(name, Function(name, entry))

    def functions(self):
        """Returns a list of all executed functions.

        The functions are sorted by the time they are executed for the first
        time.
        """
        return sorted(self._functions.values(), key=lambda x: x.seq)

    def calls(self):
        return self._calls.values()

    def call_graph(self):
        """Compute and return a call graph."""
        cg = {func : set() for func in self.functions()}
        for call in self.calls():
            caller = self.get_func_at(call.call_site)
            cg[caller].add(call.callee)
        return cg


    def _advance(self, addr):
        """Advance to a new address of the trace.

        Based on the function the address is contained in, it selects the
        dynamically created 'Function' instance and calls advance on it.
        Additionally, it tracks call/return edges.
        """
        func = self.get_func_at(addr)
        func.advance(addr)
        # we just entered a new function
        if addr == func.entry:
            # push (call_site, callee) on the call stack
            self._call_stack.append((self._prev, func))
        # we are not in the same function as with the previous address.
        # because it is not a function entry either (checked above) it must be
        # a return, with 'addr' as return address
        elif func != self._call_stack[-1][1]:
            call_site, callee = self._call_stack.pop()
            assert func == self._call_stack[-1][1]
            # record a call object
            co = self._calls.setdefault(call_site,
                                        Call(call_site, addr, callee))
            co.global_count += 1
        # remember last address
        self._prev = addr

    def call_sites_range(self, from_addr, to_addr):
        """Return a list of calls (static call sites) between two addresses.

        The return value is a list of calls sorted by call_site (address).
        """
        return sorted(call for call in self._calls.values()
                      if from_addr <= call.call_site <= to_addr)

    def loop_calls(self, loop):
        """"Return the calls contained in a given loop."""
        return self.call_sites_range(loop.head, loop.tail)


    def num_contexts(self, func):
        """Return the number of different contexts of a function."""
        return len([call.call_site for call in self.calls()
                   if call.callee == func])

    def write_callgraph(self, fname):
        with open(fname + ".dot", "w") as f:
            f.write('digraph CG {\n'
                    '  graph[label="Call-graph from trace", '
                             'ranksep=0.25, fontname="sans-serif"];\n'
                    '  edge [fontname="sans-serif"];\n'
                    '  node [shape=rectangle, '
                             'fontname="sans-serif"];\n')
            # print blocks in dfs-order
            visited = set()
            def dfs(cg, prev, func):
                if func not in visited:
                    f.write('  {};\n'.format(func.name))
                if prev:
                    f.write('  {} -> {};\n'.format(prev.name, func.name))
                if func in visited: return
                visited.add(func)
                for callee in cg[func]: dfs(cg, func, callee)
            dfs(self.call_graph(), None, self.functions()[0])
            f.write('}\n')
        assert(f.closed)
        call(["/usr/bin/dot", "-Tpng", "-o", fname + ".png", fname + ".dot"])

    def write_graphs(self, prefix=""):
        for f in self.functions():
            f.write_graph(prefix + f.name)
        self.write_callgraph(prefix + "callgraph")


    def dump(self):
        for f in self.functions():
            print ">", self.num_contexts(f), "contexts"
            f.dump()
        print
        print "# call_site/return_adddress (count) [caller -> callee]"
        call_list = sorted(self._calls.values(),
                           key=lambda c: (c.global_count, -c.call_site),
                           reverse=True)
        for call in call_list:
            print "{:#010x}/{:#010x} ({}) [{} -> {}]".format(
                call.call_site, call.return_address, call.global_count,
                self.get_func_at(call.call_site).name, call.callee.name)



###############################################################################

class FunctionMap:
    """Class to lookup the function an instruction address belongs to.

    Lookups of the form FM[addr] will return pairs
    (entry_address, function_name).

    The argument 'fname' points to a file containing the start address of each
    function.  Each line has the form \"address name\" and the lines are sorted
    by address.
    """
    def __init__(self, fname):
        # we use two separate lists with matching indices in order to
        # use binary search for lookup (bisect).
        self.entries = []
        self.names = []
        with open(fname, "r") as f:
            for line in f:
                addr, name = line.split(" ")
                self.entries.append(int(addr, 16))
                self.names.append(name.rstrip())

    def __getitem__(self, addr):
        """Lookup the function containing a specified address.

        Returns (entry_address, function_name) at a valid instruction address,
        otherwise an exception is raised.
        """
        i = bisect(self.entries, addr)
        if i > 0:
            # index of entry <= addr
            return self.entries[i-1], self.names[i-1]
        else:
            raise Exception("Invalid address")

    def func_next(self, addr):
        i = bisect(self.entries, addr)
        return self.entries[i] if i != len(self.entries) else 0x100000000

    def name_exists(self, name):
        return name in self.names


###############################################################################

def TraceGen(tracefile):
    """Trace Generator, given an address trace file (1 address/line).

    Each item yielded by the generator is the instruction address as number.
    """
    def trace():
        with open(tracefile, 'r') as ftrace:
            for x in ftrace: yield int(x, 16)
    # return the generator function (closure)
    return trace


##############################################################################

if __name__ == "__main__":
    import argparse
    # specify argument handling
    parser = argparse.ArgumentParser()
    # positional arguments
    parser.add_argument("func_symbols",
                        help="File containing the start address of each "
                             "function; each line has the form "
                             "\"address name\" and the lines are sorted by "
                             "address.")
    parser.add_argument("trace",
                        help="The instruction trace from simulation; "\
                             "one address (hex, w/o leading 0x) per line.")
    parser.add_argument("-p", "--print-graphs", action="store_true",
                        help="Print dynamic control-flow graphs.")
    args = parser.parse_args()

    # create analyzer and perform analysis
    T = TraceAnalysis(FunctionMap(args.func_symbols), TraceGen(args.trace))
    T.dump()

    if args.print_graphs:
        T.write_graphs("dyncfg_")
