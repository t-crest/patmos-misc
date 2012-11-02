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
  # regex object
  ro = re.compile((r'^\s*0*(?P<addr>[{0}]+):\s*'\
                   r'(?P<mem>(?:[{0}]{{2}} ?){{4,8}})'\
                   r'\s*(?P<inst>.*)$').format(string.hexdigits))
  try:
    for line in objdump.stdout:
      mo = ro.match(line.expandtabs()) # matcher object
      # return: (address, line without \n)
      if mo:
        grp = mo.groupdict()
        # space for default guard
        if not grp['inst'].startswith('('):
          grp['inst'] = ' '*7+grp['inst']
        yield grp['addr'], grp
      else:
        yield None, line[0:-1]
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
    self.maxaddrlen = max(len(addr), self.maxaddrlen)
    self.total = self.total + 1

  def objdump(self):
    # colors = range(40,48) # all colors
    colors = [44, 46, 42, 43, 41] # heat scale
    # print scale
    segwidth = 80/len(colors) - 1
    seg = lambda col: '\033[{:d}m{:^{segwidth}}\033[0m' \
                      .format(col, '~', segwidth=segwidth)
    print ' '.join( [seg(col) for col in colors])

    # prepare template
    tpl = '{{cnt:>{0}}}  {{addr:>{1}}}: {{mem:24}}  {{inst}}'\
            .format( len(str(self.maxcnt)), self.maxaddrlen )
    assert( None not in self.Hist )
    for addr, line in disassemble(self.binary):
      if not addr: print line; continue
      # it's an instruction
      if addr in self.Hist:
        cnt = self.Hist[addr]
        heat = len(colors)*cnt / (self.maxcnt+1)
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
