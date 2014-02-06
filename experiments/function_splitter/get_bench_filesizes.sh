#!/bin/bash

# get the file sizes of the built binaries

find build -executable -type f -exec stat -c "%s, '%n'" {} \; | sort -n
