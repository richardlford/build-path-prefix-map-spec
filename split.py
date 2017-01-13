#!/usr/bin/python3

import os
import sys

# Parsing the variable

val = os.getenv("SOURCE_PREFIX_MAP", "")
pm = [r.rsplit("=", 1) for r in reversed(list(filter(None, val.split('\t'))))]

# Applying the variable

def normprefix(string):
    for src, dst in pm:
        if string.startswith(src):
            return dst + string[len(src):]
    return string

for v in sys.argv[1:]:
    print(normprefix(v))
