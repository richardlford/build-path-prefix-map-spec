#!/usr/bin/python3

import os
import re
import sys
from urllib.parse import parse_qsl

# Parsing the variable

pm = parse_qsl(os.getenv("SOURCE_PREFIX_MAP", ""))

# Applying the variable

def map_prefix(string, pm):
    for src, dst in reversed(pm):
        if string.startswith(src):
            return dst + string[len(src):]
    return string

for v in sys.argv[1:]:
    print(map_prefix(v, pm))
