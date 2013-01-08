#!/usr/bin/env python
###############################################################################
#
# Utilities to analyze disassembly of patmos ELF binaries.
#
# Author:
#   Daniel Prokesch <daniel.prokesch@gmail.com>
#
###############################################################################

import os
import re, string
import bisect
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
  """Sorted list of function info tuples (hexaddr, hexsize, name)"""
  pattern = (r'^\s*0*([{0}]+)\s+(?:g|l)\s+F [.]text\s+([{0}]{{8}})\s+(.*)\s*$')\
            .format(string.hexdigits)
  return sorted(_symtab_extract(binary, pattern),
                key=lambda tup: int(tup[0],16) )


# bb_addresses can be used when the binary is created with special bb symbols,
# i.e., with -mpatmos-enable-bb-symbols
def bb_addresses(binary, irbb=False):
  """Sorted list of bb info tuples (hexaddr, hexsize, name).

  Set irbb=True if you want to extract the special bb information (if present).
  """
  pattern = (r'^\s*0*([{0}]+)\s+[.]text\s+([{0}]{{8}})\s+({1}.*)\s*$')\
            .format(string.hexdigits, "[#]" if irbb else "[^#]")
  # (addr, size, name)
  return sorted( _symtab_extract(binary, pattern),
                key=lambda tup: int(tup[0],16) )

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



###############################################################################

class DisAsm(object):
  def __init__(self, binary):
    self.binary = binary
    self.funcs = func_addresses(self.binary)
    self.faddr = [ int(t[0],16) for t in self.funcs ]
    self.call_ro = re.compile(r'call\s+([0-9]+)')

  def func_at(self, addr):
    i = bisect.bisect_left(self.faddr, addr)
    if i != len(self.faddr) and self.faddr[i] == addr:
      return self.funcs[i]
    return None

  def _pad_guard(self, inst):
    return ' '*7+inst if not inst.startswith('(') else inst

  def _patch_call(self, grp):
    call_mo = self.call_ro.match(grp['inst'],7)
    if call_mo:
      tgt_wd = call_mo.group(1)
      tgt_addr = 4*int(tgt_wd)
      tgt_func = self.func_at(tgt_addr)
      tgt_lbl = tgt_func[2] if tgt_func else tgt_wd+' ???'
      grp['inst'] = grp['inst'].replace(tgt_wd, tgt_lbl)
      grp['call'] = tgt_addr


  def __iter__(self):
    """Generator for enhanced disassembly"""
    # regex object
    ro = re.compile((r'^\s*0*(?P<addr>[{0}]+):\s*'\
                     r'(?P<mem>(?:[{0}]{{2}} ?){{4,8}})'\
                     r'\s*(?P<inst>.*)$').format(string.hexdigits))

    # list of function starts, pointing to the address of the size (base-4);
    # reversed, to pop items off as they match
    func_preview = [ (k-4, self.func_at(k)) for k in self.faddr ]
    func_preview.reverse()
    # main loop
    next_size, next_func = func_preview.pop()
    for line in disassemble(self.binary):
      mo = ro.match(line)
      if mo:
        # line is an inst, provide additional info
        grp = mo.groupdict()
        # check for size before function start
        if int(grp['addr'],16)==next_size:
          func_size = int(grp['mem'].replace(' ',''),16)
          continue
        # normal instruction:
        grp['inst'] = self._pad_guard(grp['inst'])
        self._patch_call(grp)
        yield line, grp
      else:
        # check function label
        if line==(next_func[2]+':\n'):
          assert( func_size == int(next_func[1],16) )
          yield '\n{}\n{}:\t(size={:#x}, {:d} words)\n\n' \
                .format('-'*80, next_func[2], func_size, func_size/4), None
          if len(func_preview)>0: next_size, next_func = func_preview.pop()
          continue
        yield line, None

###############################################################################

def find_inst_addr(binary, which, cyc_offset=0):
  """Get a list of addresses of certain instructions, with given offset"""
  dasm = DisAsm(binary)
  allinst = [ inst for line, inst in dasm if inst ]
  match = [ x+' ' in inst['inst'] for x in which for inst in allinst ]
  return [ x['addr'] for i,x in enumerate(allinst) if match[i-cyc_offset] ]


def ret_points(binary):
  return find_inst_addr(binary, ['call'], 3)


###############################################################################

if __name__=='__main__':
  raise Exception("This module is not to be executed.")
