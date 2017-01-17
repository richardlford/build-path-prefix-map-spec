#!/usr/bin/python3

import os
import re
import sys
from urllib.parse import parse_qsl

# Parsing the variable

val = os.getenv("SOURCE_PREFIX_MAP", "")
pm = parse_qsl(val)

# Applying the variable

def normprefix(string):
    for src, dst in reversed(pm):
        if string.startswith(src):
            return dst + string[len(src):]
    return string

for v in sys.argv[1:]:
    print(normprefix(v))
