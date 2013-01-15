#!/usr/bin/env python
###############################################################################
#
# Create bb edge profile of a patmos simulation.
#
# Currently only works when bb-symbols were generated,
# i.e., with -mpatmos-enable-bb-symbols
#
# Author:
#   Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import dasmutil
import simutil

import bisect
import re, string

import hashlib
from cPickle import dump, load
import os, os.path

###############################################################################

def find_le(a, x):
  "Find rightmost value less than or equal to x"
  i = bisect.bisect_right(a, x)
  if i: return a[i-1]
  raise ValueError

###############################################################################

def checksum(fn):
  """Compute the SHA1 sum of a file"""
  sha1 = hashlib.sha1()
  with open(fn) as f:
    sha1.update(f.read())
  return sha1.hexdigest()

###############################################################################


###############################################################################

class EdgeProf:
  """Edge profile generated from a simulation trace"""
  def __init__(self, binary, observe_list=None):
    self.binary = binary
    # main dictionary with an entry for each function to be observed
    self.edges = dict()
    # sets for special edges
    self.call_edges = set()
    self.ret_edges = set()
    if not observe_list:
      self.observe_list = set(v[1] for v in self.func_map().values())
      self.edges[None] = dict() # fix for entry point
    else:
      self.observe_list = observe_list
    # TODO include observe_list in checksum
    self.checksum = checksum(binary)
    # start simulation and generating of edge profile
    self._simulate()

  def _update_edge(self, func, prev, cur):
    A = self.edges[func]
    if prev not in A: A[prev] = dict()
    pentry = A[prev]
    pentry[cur] = pentry[cur] + 1 if cur in pentry else 1

  def bb_map(self):
    """Return a map of addr: bb info

    Format:
      addr: (func, bbname, number, size)

    where addr and size are of type int, in bytes
    """
    return { int(t[0],16) : tuple(t[2][1:].split('#')+[int(t[1],16)])
              for t in dasmutil.bb_addresses(self.binary, True) }

  def func_map(self):
    """Return a map of addr: func info

    Format:
      addr: (hexaddr, fname, size)

    where addr and size are of type int, in bytes
    """
    return { int(t[0],16) : (t[0], t[2], int(t[1],16))
                for t in dasmutil.func_addresses(self.binary) }

  def _simulate(self):
    bbs_a = self.bb_map()
    funcs_a = self.func_map()
    funcs_lst = sorted(funcs_a.keys())

    # temporary pointers for the iteration
    last_bb = None
    last_func = None
    callstack = []
    # main iteration: build up tables (adjacency lists, special sets)
    try:
      for addr in simutil.trace(self.binary):
        iaddr = int(addr,16)
        if iaddr in bbs_a:
          cur_bb = iaddr
          # function call?
          # - no need to check if last inst was a call point:
          #   loops don't target function entries (prologue)
          if iaddr in funcs_a:
            callstack.append( (last_func, last_bb) )
            cur_func = iaddr
            cur_func_name = funcs_a[cur_func][1]
            if cur_func_name in self.observe_list and \
               cur_func not in self.edges:
              self.edges[cur_func] = dict()
            self.call_edges.add( (last_bb, cur_bb) )
        else:
          # check if function changed, if so then it must be a RET
          cur_func = find_le(funcs_lst, iaddr)
          if cur_func == last_func:
            # normal inst, nothing to update
            continue
          assert( cur_func == callstack[-1][0] )
          cur_func, cur_bb = callstack.pop()
          self.ret_edges.add( (last_bb, cur_bb) )

        # update transitions
        if last_func in self.edges:
          self._update_edge(last_func, last_bb, cur_bb)
        last_bb = cur_bb
        last_func = cur_func
    except simutil.SimError:
      # ignore exit code (if the application returns other than 0)
      pass

  def dump(self):
    """Print a representation to stdout"""
    def bbtup2str(bb):
      return "{1}#{2} <{3}>".format(*bb)
    bbs_a = self.bb_map()
    funcs_a = self.func_map()
    # dump adjacency lists
    for faddr, ftab in self.edges.items():
      print funcs_a[faddr][1] if faddr else "<None>", ":"
      for bb, bsuccs in sorted(ftab.items()):
        # print block name
        print "\t", bbtup2str(bbs_a[bb]) if bb else "<None>",
        print "(ENTRY)" if bb in funcs_a else ""
        # print successors
        for x,cnt in sorted(bsuccs.items()):
          if   (bb,x) in self.call_edges:
            extedge = " CALL({})".format(bbs_a[x][0])
          elif (bb,x) in self.ret_edges:
            extedge = " RET({})".format(bbs_a[x][0])
          else: extedge = ""
          print "\t -> {} ({:d}){}".format(
            bbtup2str(bbs_a[x]) if x else "<None>", cnt, extedge)

  def yaml(self, fname):
    """Dump as YAML"""
    bbs_a = self.bb_map()
    funcs_a = self.func_map()
    with open(fname,'w') as f:
      f.write("%YAML 1.2\n---\n")
      for faddr, ftab in self.edges.items():
        if not faddr: continue
        fname = funcs_a[faddr][1]
        f.write(fname + ":\n")
        for bb, bsuccs in sorted(ftab.items()):
          if not bb: continue
          # print block name
          f.write("  {1}#{2}:\n".format(*bbs_a[bb]))
          # print successors
          for x,cnt in sorted(bsuccs.items()):
            assert(x)
            # out-edges only as comment
            if bbs_a[x][0] != fname:
              if   (bb,x) in self.call_edges:
                f.write("    # CALL({})\n".format(bbs_a[x][0]))
              elif (bb,x) in self.ret_edges:
                f.write("    # RET({})\n".format(bbs_a[x][0]))
              continue
            f.write("    {}#{}: {}\n".format(bbs_a[x][1], bbs_a[x][2], cnt))
      f.write("...\n")

  def dots(self, outdir):
    """Export .dot graphs"""
    # output-directory
    try:
      os.mkdir(outdir)
    except: pass
    bbs_a = self.bb_map()
    funcs_a = self.func_map()
    # a file for each function
    for faddr, ftab in self.edges.items():
      if not faddr: continue # omit absolut entry point
      fname = funcs_a[faddr][1]
      with open(outdir+'/'+fname+'.dot','w') as f:
        f.write('digraph MCFG_{0} {{\n'\
                '  graph[label="Function: {0}",fontname="sans-serif"];\n'\
                '  edge [fontname="sans-serif"];\n'\
                '  node [shape=rectangle,fontname="sans-serif"];\n'\
            .format(fname))
        # define all bbs
        for bb in sorted(ftab, key=lambda k: bbs_a[k][2]):
          if not bb: continue
          f.write('  B{} [label="{} #{}\\n<{:d}>"];\n'
            .format(bb, bbs_a[bb][1], bbs_a[bb][2], bbs_a[bb][3]))
        # use numbering id for node names as well
        for bb, bsuccs in ftab.items():
          for x,cnt in bsuccs.items():
            if not x: continue
            if   (bb,x) in self.call_edges: extedge = " <CALL>"
            elif (bb,x) in self.ret_edges:  extedge = " <RET>"
            else: extedge = ""
            if not x in ftab:
              f.write('  B{} [label="{}"];\n'.format(x, bbs_a[x][0]))
            f.write('  B{} -> B{} [label="{:d}{}"];\n'
              .format(bb, x, cnt, extedge))
        f.write('}\n')
      assert(f.closed)



  def disasm(self, fname):
    # TODO (re)use the dasm enhance generator
    ro = re.compile(r'^\s*0*(?P<addr>[{}]+):'.format(string.hexdigits))
    funcs = { t[0]:t[2] for t in dasmutil.func_addresses(self.binary) }
    bbs = { t[0]:tuple(t[1:])
              for t in dasmutil.bb_addresses(self.binary, True) }
    capture = False
    func_sizes = set( hex(int(k,16)-4)[2:] for k in funcs )
    with open(fname,'w') as f:
      for line in dasmutil.disassemble(self.binary):
        mo = ro.match(line)
        if mo:
          addr = mo.group(1)
          if addr in func_sizes:
            continue # ignore fsizes
          if addr in funcs:
            capture = (funcs[addr] in self.observe_list)
            if capture:
              f.write('='*100+'\n') # separator
              f.write(hold) # function name
              f.write('-'*(len(hold)-1)+'\n')

          if capture and addr in bbs:
            lbl = bbs[addr][1].split('#')
            f.write('#'.join(lbl[2:])+':\n')
        else:
          if len(line.strip())>0: # hold
            hold = line
            continue

        if capture: f.write(line)
    assert(f.closed)


###############################################################################

def createEdgeProf(binary,observe_list):
  """EdgeProf factory - create or load edge profile"""
  cache = binary+'.edgeprof'
  if os.path.isfile(cache):
    with open(cache) as cf:
      P = load(cf)
      if P.checksum == checksum(binary):
        return P
  # slow path
  P = EdgeProf(binary,observe_list)
  with open(cache, 'w') as cf:
    dump(P, cf)
  return P


###############################################################################

# TODO refactor

# main entry point
if __name__=='__main__':
  import sys

  def usage():
    print """
    Usage: {} <binary>

    - TODO
    """.format(sys.argv[0])
    exit(1)


  if len(sys.argv) < 2: usage()

  binary = sys.argv[1]

  # which functions should be observed?
  observe_list = None
  if len(sys.argv) >= 3:
    observe_list = set(sys.argv[2].split(','))

  EP = createEdgeProf(binary, observe_list)
  EP.dump()

  # disassemble with bb labels
  EP.disasm(binary+'.dis')

  EP.yaml(binary+'.yaml')
  EP.dots(binary+'.dots')



