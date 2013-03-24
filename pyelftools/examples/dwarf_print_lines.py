#----------------------------------------------------------------------
# This script reads DWARF debug info from an ELF file and
# prints out function names and line number infos for every
# address that is given as an input. 
#
# This script is designed to be used with objdump or similar tools.
# To annotate the objdump output with line infos, use 
#
# objdump -d <binary> | dwarf_print_lines.py <binary>
# 
# Author: Stefan Hepp <hepp@complang.tuwien.ac.at>
# This code is in the public domain
#----------------------------------------------------------------------

from __future__ import print_function
import sys
import os
import argparse
import re

# We do not care about closed stdout pipe, just abort 
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)
signal.signal(signal.SIGINT,  signal.SIG_DFL)

# If elftools is not installed, maybe we're running from the root or examples
# dir of the source distribution
try:
    import elftools
except ImportError:
    sys.path.extend(['.', '..'])

from elftools.common.py3compat import itervalues, maxint, bytes2str
from elftools.elf.elffile import ELFFile


def decode_funcname(funcinfo, address):
    for info in funcinfo:
        lowpc = info[0]
        highpc = info[1]
        if lowpc <= address <= highpc:
            return info[2]
    return None


def decode_file_line(lineinfo, address):
    for info in lineinfo:
        stateaddress = info[0]
        nextaddress = info[1]
        if stateaddress <= address < nextaddress:
            filename = info[2]
            line = info[3]
            return filename, line
    return None, None

def load_lineinfo(dwarfinfo):
    # Load all line infos and all function names into lists
    # Lines contains tuples of startaddr, endaddress, filename, line
    lines = []
    # Functions contains tuples of lowpc, highpc, function
    functions = []
    for CU in dwarfinfo.iter_CUs():
        # First, look at line programs to find the file/line map
        lineprog = dwarfinfo.line_program_for_CU(CU)
        prevstate = None
        for entry in lineprog.get_entries():
            # We're interested in those entries where a new state is assigned
            state = entry.state
            if state is None: continue
            if prevstate and prevstate.address <= state.address and not prevstate.end_sequence:
                file_entry = lineprog['file_entry'][prevstate.file - 1]
                if file_entry.dir_index == 0:
                    # current directory
                    # TODO get directory of source file and prepend it 
                    filename = './%s' % (bytes2str(file_entry.name))
                else:
                    filename = '%s/%s' % (
                        bytes2str(lineprog['include_directory'][file_entry.dir_index - 1]),
                        bytes2str(file_entry.name))
                line = prevstate.line
                info = prevstate.address, state.address, filename, line
                lines.append( info )
            prevstate = state
        # Go over all DIEs in the DWARF information. Note that
        # this simplifies things by disregarding subprograms that may have 
        # split address ranges.
        for DIE in CU.iter_DIEs():
            try:
                if DIE.tag == 'DW_TAG_subprogram':
                    lowpc = DIE.attributes['DW_AT_low_pc'].value
                    highpc = DIE.attributes['DW_AT_high_pc'].value
                    function = DIE.attributes['DW_AT_name'].value
                    info = lowpc, highpc, bytes2str(function)
                    functions.append( info )
            except KeyError:
                continue
    return lines, functions

def print_lineinfos(lineinfo, functioninfo, input, printAllLines, printInput = True):
    # Try to match first column as hex PC
    ppc = re.compile("([a-fA-F0-9]+)[ \t\n]")
    # Try to match objdump format
    opc = re.compile(" +([a-f0-9]+):")
    
    lastLineNr = None
    lastFilename = None
    lastFunction = None

    for line in input:
        
        # Check if we have a PC at the beginning of the line
        PC = None
        for r in [ppc, opc]: 
            m = r.match(line)
            if m:
                PC = int(m.group(1), 16)
                break
        if PC is None:
            if printInput: print(line, end="")
            continue
        
        function = decode_funcname(functioninfo, PC)
        filename, linenr = decode_file_line(lineinfo, PC)
        
        if printAllLines:
            print('%s:%s, %s():' % (filename, linenr, function))
        else:
            if function and lastFunction != function:
                print("%s():" % function)
            if (filename or linenr) and (lastLineNr != linenr or lastFilename != filename):
        	   print("%s:%s" % (filename, linenr))
                
        lastFunction = function
        lastFilename = filename
        lastLineNr = linenr

        if printInput: print(line, end="")

def load_dwarfinfo(filename):
    elffile = ELFFile(filename)
    
    if not elffile.has_dwarf_info():
        print(filename.name + ': ELF file has no DWARF info!')
        sys.exit(1)
    
    # get_dwarf_info returns a DWARFInfo context object, which is the
    # starting point for all DWARF-based processing in pyelftools.
    dwarfinfo = elffile.get_dwarf_info()
    
    return dwarfinfo


parser = argparse.ArgumentParser(description='Display ELF debug infos.')
parser.add_argument('elffile', type=file, help='ELF file containing debug infos')
parser.add_argument('-a', '--all', action='store_true', help='Print line numbers for all found PCs, not only when it changes')
parser.add_argument('-l', '--lines', help='Display line numbers for the given input file (defaults to stdin)')

args = parser.parse_args()

# Load the ELF file
dwarfinfo = load_dwarfinfo(args.elffile)
# Load all dwarf line number and function infos into a lookup table
lineinfo, funcinfo = load_lineinfo(dwarfinfo)

if args.lines and args.lines != "-": 
    input = None
    try:
	input = open(args.lines, 'r')
    except:
	print("Could not open input file " + args.lines + ": " + e)
	sys.exit(1)
    
    print_lineinfos(lineinfo, funcinfo, input, args.all)
    
    input.close()
    
else:
    print_lineinfos(lineinfo, funcinfo, sys.stdin, args.all)

