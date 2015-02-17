#!/bin/bash

FUNC=$1

grep -E "call.*to <${FUNC}>|return.*from <${FUNC}>" |\
awk '
  BEGIN { x = -1; }
  {
    if (x == -1) x = $2;
    else {
      print "'${FUNC}'", $2 - x;
      x = -1;
    }
  }
'
