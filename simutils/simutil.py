#!/usr/bin/env python
###############################################################################
#
# Utilities to process the simulation data from the pasim simulator,
# when simulating a patmos ELF binary
#
# Author:
#   Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import os
import re, string
from subprocess import Popen, PIPE


###############################################################################

class SimError(Exception):
  def __init__(self,code):
    self.exitcode=code
  def __str__(self):
    return "pasim terminated exceptionally: {}".format(self.exitcode)

###############################################################################

def trace(binary):
  """Generator for execution trace (instr addresses)"""
  pasim_cmd = ['pasim', '--debug=0', '--debug-fmt=trace', '-G0', '-m16M', binary]
  # send stdout to /dev/null
  with open(os.devnull, 'w') as fnull:
    pasim = Popen(pasim_cmd, stderr=PIPE, stdout=fnull)
    for line in pasim.stderr:
      pc_cyc = line.rstrip().split()
      yield (int(pc_cyc[0],16), int(pc_cyc[1]))
    # processed each line, now wait
    ret = pasim.wait()
    if ret: raise SimError(ret)


###############################################################################

def trace_ex(binary):
  """Generator for extended execution trace in EX stage (instr addresses + PRR before)"""
  pasim_cmd = ['pasim', '--debug=0', '--debug-fmt=long', binary]
  # send stdout to /dev/null
  with open(os.devnull, 'w') as fnull:
    pasim = Popen(pasim_cmd, stderr=PIPE, stdout=fnull)
    ro = re.compile(r'^.*PRR: ([0-9]{8}) .* PC : 0*([0-9a-fA-F]{1,8})') # regex object
    pipeline = [None, None] # initial pipeline fill
    for line in pasim.stderr:
      mo = ro.match(line) # matcher object
      if mo:
        (prr, inst) = mo.groups()
        pipeline.append(inst)
        yield prr, pipeline.pop(0)
    # drain pipelne
    yield prr, pipeline.pop(0)
    yield prr, pipeline.pop(0)
    # processed each line, now wait
    ret = pasim.wait()
    if ret: raise SimError(ret)

###############################################################################


if __name__=='__main__':
  raise Exception("This module is not to be executed.")
