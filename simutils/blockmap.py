#!/usr/bin/env python
###############################################################################
#
# Create map for edge-frequencies of a (single-path) execution.
# TODO
#
# Author:
#   Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import dasmutil
import simutil

from bisect import bisect_right
import re, string


###############################################################################

def find_le(a, x):
  "Find rightmost value less than or equal to x"
  i = bisect_right(a, x)
  if i: return a[i-1]
  raise ValueError


###############################################################################

# TODO (re)use the dasm enhance generator
def dasm_bblabels(binary, observe):
  ro = re.compile(r'^\s*0*(?P<addr>[{}]+):'.format(string.hexdigits))
  funcs = dasmutil.func_addresses(binary)
  bbs = dasmutil.bb_addresses(binary)
  capture = False
  func_sizes = set([ hex(int(k,16)-4)[2:] for k in funcs ])
  with open(binary+'.dis','w') as f:
    for line in dasmutil.disassemble(binary):
      mo = ro.match(line)
      if mo:
        addr = mo.group(1)
        if addr in func_sizes:
          continue # ignore fsizes
        if addr in funcs:
          capture = (funcs[addr] in observe)
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

  # format:
  #  addr: (func, bbname, number, size)
  # addr and size are of type int, in bytes
  bbs_a = dict([ (int(k,16),tuple(v[1][1:].split('#')+[int(v[0],16)]))
                    for k,v in dasmutil.bb_addresses(binary).items() ])
  bbs_lst = sorted(bbs_a.keys())
  funcs_a = dasmutil.func_addresses(binary)

  def update_edge(A, prev, cur):
    if prev not in A: A[prev] = dict()
    pentry = A[prev]
    pentry[cur] = pentry[cur] + 1 if cur in pentry else 1

  def bbtup2str(bb):
    return "{1}#{2} <{3}>".format(*bb)


  # main dictionary with an entry for each function to be observed
  edges = dict()
  # sets for special blocks and edges
  entry_blocks = set([int(x,16) for x in funcs_a])
  call_edges = set()
  ret_edges = set()

  # temporary pointers for the iteration
  last_bb = None
  cur_func = None
  callstack = []

  # which functions should be observed?
  if len(sys.argv) >= 3:
    observe_list = set(sys.argv[2].split(','))
  else:
    observe_list = set(funcs_a.values())
    edges[None] = dict() # fix for entry point

  # disassemble with proper labels
  dasm_bblabels(binary, observe_list)

  # main iteration: build up tables (adjacency lists, special sets)
  try:
    for addr in simutil.trace(binary):
      cur_bb = find_le( bbs_lst, int(addr,16) )
      if cur_bb != last_bb:
        # update transitions
        if cur_func in edges:
          update_edge(edges[cur_func], last_bb, cur_bb)
        # function call?
        if addr in funcs_a:
          call_edges.add( (last_bb, cur_bb) )
          callstack.append( (cur_func, last_bb) )
          cur_func = funcs_a[addr]
          if cur_func in observe_list and cur_func not in edges:
            edges[cur_func] = dict()
        # function return?
        if bbs_a[cur_bb][0] != cur_func:
          ret_edges.add( (last_bb, cur_bb) )
          cur_func = callstack[-1][0]
          callstack.pop()
        last_bb = cur_bb
  except simutil.SimError:
    # ignore exit code (if the application returns other than 0)
    pass

  # dump adjacency lists
  for fname, ftab in edges.items():
    print fname if fname else "<None>", ":"
    for bb, bsuccs in sorted(ftab.items()):
      # print block name
      print "\t", bbtup2str(bbs_a[bb]) if bb else "<None>",
      print "(ENTRY)" if bb in entry_blocks else ""
      # print successors
      for x,cnt in sorted(bsuccs.items()):
        if   (bb,x) in call_edges: extedge = " CALL({})".format(bbs_a[x][0])
        elif (bb,x) in ret_edges:  extedge = " RET({})".format(bbs_a[x][0])
        else: extedge = ""
        print "\t -> {} ({:d}){}".format(
          bbtup2str(bbs_a[x]) if x else "<None>", cnt, extedge)


  # export .dot graphs

  # output-directory
  import os
  try:
    os.mkdir(binary+'.dots')
  except: pass

  def bb2id(bbaddr):
    return bbs_a[bbaddr][2]

  # a file for each function
  for fname, ftab in edges.items():
    if not fname: continue # omit absolut entry point
    with open(binary+'.dots/'+fname+'.dot','w') as f:
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
          if   (bb,x) in call_edges: extedge = " <CALL>"
          elif (bb,x) in ret_edges:  extedge = " <RET>"
          else: extedge = ""
          if not x in ftab:
            f.write('  B{} [label="{}"];\n'.format(x, bbs_a[x][0]))
          f.write('  B{} -> B{} [label="{:d}{}"];\n'
            .format(bb, x, cnt, extedge))
      f.write('}\n')
    assert(f.closed)


  # dump as YAML
  with open('blockmap.yaml','w') as f:
    f.write("%YAML 1.2\n---\n")
    for fname, ftab in edges.items():
      if not fname: continue
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
            if   (bb,x) in call_edges:
              f.write("    # CALL({})\n".format(bbs_a[x][0]))
            elif (bb,x) in ret_edges:
              f.write("    # RET({})\n".format(bbs_a[x][0]))
            continue
          f.write("    {}#{}: {}\n".format(bbs_a[x][1], bbs_a[x][2], cnt))
    f.write("...\n")
