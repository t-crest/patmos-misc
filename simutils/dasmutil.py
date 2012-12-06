#!/usr/bin/env python
###############################################################################
#
# Utilities to analyze disassembly of patmos ELF binaries.
#
# TODO properly parse the disassembly to return function objects
#      on which you can iterate to return basic blocks, etc
#
# Author:
#   Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import os
import re, string
from subprocess import Popen, PIPE


###############################################################################

def _symtab_extract(binary, pattern):
  symtab_cmd = ['patmos-llvm-objdump', '-t', binary]
  symtab = Popen(symtab_cmd, stdout=PIPE)
  ro = re.compile(pattern) # regex object
  mos = [ ro.match(line) for line in symtab.stdout ]
  symtab.wait()
  return [ mo.groups() for mo in mos if mo ]

def func_addresses(binary):
  """Dictionary of addr-funcstart pairs."""
  pattern = (r'^\s*0*([{0}]+)\s+(?:g|l)\s+F [.]text\s+[{0}]{{8}}\s+(.*)\s*$')\
            .format(string.hexdigits)
  return dict(_symtab_extract(binary, pattern))


# bb_addresses can be used whne the binary is created with special bb symbols,
# i.e., with -mpatmos-enable-bb-symbols
def bb_addresses(binary):
  """Dictionary of addr-bbname pairs."""
  pattern = (r'^\s*0*([{0}]+)\s+[.]text\s+([{0}]{{8}})\s+([#].*)\s*$')\
            .format(string.hexdigits)
  return dict([ (g[0], tuple(g[1:]))
                for g in _symtab_extract(binary, pattern) ])

###############################################################################

def disassemble(binary):
  """Generator for objdump disassembly"""
  objdump_cmd = ['patmos-llvm-objdump', '-d', binary]
  objdump = Popen(objdump_cmd, stdout=PIPE)
  try:
    for line in objdump.stdout:
      yield line.expandtabs()
    objdump.wait()
  except:
    objdump.kill()


def disasm_enhance(binary):
  funcs = func_addresses(binary)
  # regex object
  ro = re.compile((r'^\s*0*(?P<addr>[{0}]+):\s*'\
                   r'(?P<mem>(?:[{0}]{{2}} ?){{4,8}})'\
                   r'\s*(?P<inst>.*)$').format(string.hexdigits))
  # some helpers:
  def padGuard(d): # space for default guard
    if not d['inst'].startswith('('):
      d['inst'] = ' '*7+d['inst']

  call_ro = re.compile(r'call\s+([0-9]+)')
  def patchCallTarget(d): # patch immediate call target
    call_mo = call_ro.match(d['inst'],7)
    if call_mo:
      tgt_wd = call_mo.group(1)
      tgt_addr = 4*int(tgt_wd)
      tgt_lbl = funcs.get(hex(tgt_addr)[2:], tgt_wd+' ???')
      d['inst'] = d['inst'].replace(tgt_wd, tgt_lbl)
  # list of function starts, pointing to the address of the size (base-4);
  # reversed, to pop items off as they match
  func_preview = sorted(
    [ (int(k,16)-4, v) for (k,v) in funcs.items()], reverse=True)

  # main loop
  next_func = func_preview.pop()
  for line in disassemble(binary):
    mo = ro.match(line) # matcher object
    # return: (address, line without \n)
    if mo:
      grp = mo.groupdict()
      # check for size before function start
      if int(grp['addr'],16)==next_func[0]:
        func_size = int(grp['mem'].replace(' ',''),16)
        continue
      # normal instruction:
      padGuard(grp)
      patchCallTarget(grp)
      # yield info
      yield grp['addr'], grp
    else:
      # check function label
      if line.startswith(next_func[1]+':'):
        yield None, '\n{}\n{}:\t(size={:#x}, {:d} words)\n'\
                      .format('-'*80, next_func[1], func_size, func_size/4)
        if len(func_preview)>0: next_func = func_preview.pop()
        continue
      yield None, line.rstrip()

###############################################################################


if __name__=='__main__':
  raise Exception("This module is not to be executed.")
