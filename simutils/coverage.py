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

import os.path
import re, string
import hashlib
import math
from cPickle import dump, load

import dasmutil
import simutil

###############################################################################

def checksum(fn):
  """Compute the SHA1 sum of a file"""
  sha1 = hashlib.sha1()
  with open(fn) as f:
    sha1.update(f.read())
  return sha1.hexdigest()


def maxidxlt(ranges, cnt):
  """Compute the largest index i in ranges such that cnt<=ranges[i]"""
  return max(i for i,r in enumerate(ranges) if r<=cnt)



###############################################################################


class Stats:
  """Stats for a trace"""
  def __init__(self, binary):
    self.binary = binary
    self.Hist = dict() # addresses
    self.total = 0
    self.maxcnt = 0
    self.maxaddrlen = 0
    self.checksum = checksum(binary)
    for addr in simutil.trace(self.binary):
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

    #TODO plot?
    #L = self.Hist.values()
    #print [ (s, L.count(s)/float(self.total)) for s in set(L)]

    # print scale
    segwidth = 80/len(colors) - 1
    seg = lambda col,q: '\033[{:d}m{:^{segwidth}}\033[0m' \
                      .format(col, 'p<={:0.2f}'.format(q), segwidth=segwidth)
    print ' '.join(seg(x,y) for x,y in zip(colors,quantiles))

    # prepare template
    tpl = '{{cnt:>{0}}}  {{addr:>{1}}}: {{mem:24}}  {{inst}}'\
            .format( len(str(self.maxcnt)), self.maxaddrlen )
    assert( None not in self.Hist )
    for line, inst in dasmutil.DisAsm(self.binary):
      if not inst: print line, ; continue
      # it's an instruction
      if inst['addr'] in self.Hist:
        cnt = self.Hist[inst['addr']]
        #heat = len(colors)*cnt / (self.maxcnt+1)
        heat = maxidxlt(ranges, cnt)
        print '\033[{:d}m'.format(colors[heat])+\
              tpl.format(cnt=str(cnt), **inst).ljust(79)+\
              '\033[0m'
      else:
        print tpl.format(cnt='', **inst)


###############################################################################

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


###############################################################################

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
  except simutil.SimError as e:
    print e
    exit(1)
  except IOError:
    pass
