#!/usr/bin/env python
###############################################################################
#
# Find out about code coverage for a patmos binary
# of a single simulation trace.
#
# Author:
#   Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import os, os.path
import re, string
import hashlib
import math
from subprocess import Popen, PIPE
from cPickle import dump, load

class SimError(Exception):
  def __init__(self,code):
    self.exitcode=code
  def __str__(self):
    return "pasim terminated exceptionally: {}".format(self.exitcode)

def trace(binary):
  """Generator for execution trace (instr addresses)"""
  pasim_cmd = ['pasim', '--debug=1', '--debug-fmt=default', binary]
  # send stdout to /dev/null
  with open(os.devnull, 'w') as fnull:
    pasim = Popen(pasim_cmd, stderr=PIPE, stdout=fnull)
    ro = re.compile(r'^.*PC : 0*([0-9a-fA-F]{1,8})') # regex object
    for line in pasim.stderr:
      mo = ro.match(line) # matcher object
      if mo: yield mo.group(1)
    # processed each line, now wait
    ret = pasim.wait()
    if ret: raise SimError(ret)


def func_addresses(binary):
  """Dictionary of addr-funcstart pairs."""
  symtab_cmd = ['patmos-llvm-objdump', '-t', binary]
  symtab = Popen(symtab_cmd, stdout=PIPE)
  # regex object
  ro = re.compile(
    (r'^\s*0*([{0}]+)\s+(g|l)\s+F [.]text\s+[{0}]{{8}}\s+(.*)\s*$')
    .format(string.hexdigits))
  funcs = dict()
  mos = [ ro.match(line) for line in symtab.stdout ]
  symtab.wait()
  return dict([ mo.group(1,3) for mo in mos if mo ])


def disassemble(binary):
  """Generator for objdump disassembly"""
  funcs = func_addresses(binary)
  objdump_cmd = ['patmos-llvm-objdump', '-d',
                  '-fpatmos-print-bytes=call', binary]
  objdump = Popen(objdump_cmd, stdout=PIPE)
  # regex object
  ro = re.compile((r'^\s*0*(?P<addr>[{0}]+):\s*'\
                   r'(?P<mem>(?:[{0}]{{2}} ?){{4,8}})'\
                   r'\s*(?P<inst>.*)$').format(string.hexdigits))
  try:
    func_list = sorted(funcs.items(), key=lambda (a,f): (len(a),a),reverse=True)
    next_func = func_list.pop()
    for line in objdump.stdout:
      mo = ro.match(line.expandtabs()) # matcher object
      # return: (address, line without \n)
      if mo:
        grp = mo.groupdict()
        #iaddr = int(grp['addr'],16)
        if grp['addr'] == next_func[0]:
          yield None, '\n{}:'.format(next_func[1])
          if len(func_list)>0: next_func = func_list.pop()
        # space for default guard
        if not grp['inst'].startswith('('):
          grp['inst'] = ' '*7+grp['inst']
        yield grp['addr'], grp
      else:
        yield None, line.rstrip()
    objdump.wait()
  except:# Exception as e:
    objdump.kill()
    #raise e


def checksum(fn):
  """Compute the SHA1 sum of a file"""
  sha1 = hashlib.sha1()
  with open(fn) as f:
    sha1.update(f.read())
  return sha1.hexdigest()


def maxidxlt(ranges, cnt):
  """Compute the largest index i in ranges such that cnt<=ranges[i]"""
  chk = [ r<=cnt for r in ranges ]
  return -1 if all(chk) else chk.index(False)-1





class Stats:
  """Stats for a trace"""
  def __init__(self, binary):
    self.binary = binary
    self.Hist = dict() # addresses
    self.total = 0
    self.maxcnt = 0
    self.maxaddrlen = 0
    self.checksum = checksum(binary)
    for addr in trace(self.binary):
      self._put(addr)

  def _put(self, addr):
    cnt = 1 if addr not in self.Hist else self.Hist[addr]+1
    self.Hist[addr] = cnt
    self.maxcnt = max(cnt, self.maxcnt)
    # NB: following does not account for addr of unexecuted instructions
    self.maxaddrlen = max(len(addr), self.maxaddrlen)
    self.total = self.total + 1

  def _qranges(self, quantiles):
    ol = sorted(self.Hist.values())
    return [ ol[int(math.ceil(q*len(ol)))-1] for q in quantiles ]

  def objdump(self):
    # colors = range(40,48) # all colors
    colors = [44, 46, 42, 43, 41] # heat scale
    quantiles = [ 0.25, 0.5, 0.75, 0.9, 1.00]
    assert( len(colors) == len(quantiles) )
    ranges = self._qranges(quantiles)
    #print ranges

    #TODO plot?
    #L = self.Hist.values()
    #print [ (s, L.count(s)/float(self.total)) for s in set(L)]

    # print scale
    segwidth = 80/len(colors) - 1
    seg = lambda col,q: '\033[{:d}m{:^{segwidth}}\033[0m' \
                      .format(col, 'p<={:0.2f}'.format(q), segwidth=segwidth)
    print ' '.join( [seg(x,y) for x,y in zip(colors,quantiles)])

    # prepare template
    tpl = '{{cnt:>{0}}}  {{addr:>{1}}}: {{mem:24}}  {{inst}}'\
            .format( len(str(self.maxcnt)), self.maxaddrlen )
    assert( None not in self.Hist )
    for addr, line in disassemble(self.binary):
      if not addr: print line; continue
      # it's an instruction
      if addr in self.Hist:
        cnt = self.Hist[addr]
        #heat = len(colors)*cnt / (self.maxcnt+1)
        heat = maxidxlt(ranges, cnt)
        print '\033[{:d}m'.format(colors[heat])+\
              tpl.format(cnt=str(cnt), **line).ljust(79)+\
              '\033[0m'
      else:
        print tpl.format(cnt='', **line)



def createStats(binary):
  """Stats factory - create or load stats"""
  cache = binary+'.trace'
  if os.path.isfile(cache):
    with open(cache) as cf:
      S = load(cf)
      if S.checksum == checksum(binary):
        return S
  # slow path
  S = Stats(binary)
  with open(cache, 'w') as cf:
    dump(S, cf)
  return S



# main entry point
if __name__=='__main__':
  import sys

  def usage():
    print """
    Usage: {} <binary>

    - Prints coverage listing to stdout.
    - You might want to store and/or view the output with 'less -R'
    """.format(sys.argv[0])
    exit(1)


  if len(sys.argv) < 2: usage()

  try:
    S = createStats(sys.argv[1])
    S.objdump()
  except SimError as e:
    print e
    exit(1)
  except IOError:
    pass
