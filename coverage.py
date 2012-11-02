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


def disassemble(binary):
  objdump_cmd = ['patmos-llvm-objdump', '-d', binary]
  objdump = Popen(objdump_cmd, stdout=PIPE)
  ro = re.compile(r'^\s*0*([{0}]+):'.format(string.hexdigits)) # regex object
  try:
    for line in objdump.stdout:
      mo = ro.match(line) # matcher object
      # return: (address, line without \n)
      if mo:
        line = line.expandtabs()
        cpos = line.find(':')+1
        yield mo.group(1), line[0:cpos] + '  ' + \
                            line[cpos:cpos+32].lstrip() + line[62:-1]
      else:
        yield None, line[0:-1]
    objdump.wait()
  except:
    objdump.kill()


class Stats:
  """Stats for a trace"""
  def __init__(self, binary):
    self.binary = binary
    self.Hist = dict() # addresses
    self.total = 0
    self.maxcnt = 0

    # FIXME pickle hash
    cache = binary+'.trace'
    if os.path.isfile(cache):
      with open(cache) as cf:
        (self.Hist, self.total, self.maxcnt) = load(cf)
    else:
      for addr in trace(self.binary):
        self._put(addr)
      with open(cache, 'w') as cf:
        dump((self.Hist, self.total, self.maxcnt), cf)

  def _put(self, addr):
    cnt = 1 if addr not in self.Hist else self.Hist[addr]+1
    self.Hist[addr] = cnt
    self.maxcnt = max(cnt, self.maxcnt)
    self.total = self.total + 1

  def printCoverage(self):
    # colors = range(40,48) # all colors
    colors = [44, 46, 42, 43, 41] # heat scale
    # print scale
    segwidth = 80/len(colors) - 1
    seg = lambda col: '\033[{:d}m{}\033[0m'.format(col, ''.center(segwidth))
    scale = ' '.join( [seg(col) for col in colors])
    print scale, ''

    # print dasm
    maxwidth = len(str(self.maxcnt))
    for addr, line in disassemble(self.binary):
      if addr:
        # it's an instruction
        if addr in self.Hist:
          cnt = self.Hist[addr]
          heat = len(colors)*cnt / (self.maxcnt+1)
          print '\033[{:d}m {} {}\033[0m'.format(colors[heat],
                  str(cnt).rjust(maxwidth), line)
        else: print ' {} {}'.format(' '*maxwidth, line)
      else: print line


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
    S = Stats(sys.argv[1])
    S.printCoverage()
  except SimError as e:
    print e
    exit(1)
  except IOError:
    pass
