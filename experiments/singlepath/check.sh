#!/bin/bash


diff <(pasim $1.elf) <(pasim $1.sp.elf)
