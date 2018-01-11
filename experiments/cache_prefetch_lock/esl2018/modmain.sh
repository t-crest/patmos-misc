#!/bin/bash
find . -name "*.c" -exec sed -i'.orig' '/\(int\|void\)\s\+main/i\'$'\n''__attribute__((noinline))' '{}' \+
#find . -name "*.c" | xargs sed -i "" 's/.*[^_]main.*;$/int main( void ) __attribute__ ((noinline));/'
