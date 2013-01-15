#!/usr/bin/env python
###############################################################################
#
# Create bitprofile (branch history) of a patmos simulation.
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

class BitProf:
  """Bit profile generated from a simulation trace"""
  def __init__(self, binary, observe_list=None):
    self.binary = binary
    self.bittraces = dict()
    if not observe_list:
      self.observe_list = set(v[1] for v in self.func_map().values())
    else:
      self.observe_list = observe_list
    # TODO include observe_list in checksum
    self.checksum = checksum(binary)
    # start simulation and generating of edge profile
    self._simulate()


  def func_map(self):
    """Return a map of addr: func info

    Format:
      addr: (hexaddr, fname, size)

    where addr and size are of type int, in bytes
    """
    return { int(t[0],16) : (t[0], t[2], int(t[1],16))
                for t in dasmutil.func_addresses(self.binary) }

  def _simulate(self):

    # get branches
    branches    = dasmutil.find_inst_addr(self.binary, ['br'], 0)
    # get fallthrough addresses
    fallthrough = dasmutil.find_inst_addr(self.binary, ['br'], 3)

    # map: branch -> fallthrough addr
    brf = { b:f for b, f in zip(branches, fallthrough) }
    print brf

    # main iteration:
    try:
      await = []
      for i, addr in enumerate(simutil.trace(self.binary)):
        if addr in brf:
          # initialize with empty list
          if addr not in self.bittraces: self.bittraces[addr] = []
          await.append( (i+3, addr, brf[addr]) )
        if len(await)>0 and await[0][0]==i:
          x = await.pop(0)
          self.bittraces[x[1]].append(1 if x[2]!=addr else 0)
    except simutil.SimError:
      # ignore exit code (if the application returns other than 0)
      pass

  def dump(self):
    for k,v in sorted(self.bittraces.items(), key=lambda x: int(x[0],16)):
      print "{}: {}".format(k,''.join(str(c) for c in v))

###############################################################################

def createBitProf(binary,observe_list):
  """BitProf factory - create or load bit profile"""
  cache = binary+'.bitprof'
  if os.path.isfile(cache):
    with open(cache) as cf:
      P = load(cf)
      if P.checksum == checksum(binary):
        return P
  # slow path
  P = BitProf(binary,observe_list)
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

  BP = createBitProf(binary, observe_list)
  BP.dump()

