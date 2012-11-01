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

import re
import os
from subprocess import Popen, PIPE


# Get a set of PC values
# binary name -> set of addr
def getAddrsFromTrace(binary):
  addr = set()
  # send stdout to /dev/null
  with open(os.devnull, 'w') as fnull:
    pasim = Popen(['pasim', '--debug=1', '--debug-fmt=default', binary],
                  stderr=PIPE, stdout=fnull)
    # regex object
    ro = re.compile('^.*PC : 0*([0-9a-fA-F]{1,8})')
    for line in pasim.stderr:
      mo = ro.match(line) # matcher object
      if mo: addr.add( mo.group(1) )
    # processed each line, now wait
    ret = pasim.wait()
    if ret: exit(ret)
  return addr


# Mark in disassembly
# binary name, addrs -> <stdout>
def printCoverage(binary, addr):
  dump = Popen(['patmos-llvm-objdump', '-d', binary], stdout=PIPE)
  # regex object
  ro = re.compile('^\s*0*([0-9a-fA-F]+):')
  try:
    for line in dump.stdout:
      mo = ro.match(line) # matcher object
      if mo and (mo.group(1) in addr):
        print '\033[44m', line.rstrip()+'\033[0m'
      else: print line,
    dump.wait()
  except:
    dump.kill()


def usage():
  print """
  Usage: %s <binary>

  - Prints coverage listing to stdout.
  - You might want to store and/or view the output with 'less -R'
  """ % sys.argv[0]
  exit(1)

# main entry point
if __name__=='__main__':
  import sys
  if len(sys.argv) < 2: usage()
  binary = sys.argv[1]
  addr = getAddrsFromTrace(binary)
  printCoverage(binary, addr)
  exit(0)
