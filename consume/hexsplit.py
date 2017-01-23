#!/usr/bin/python3

import os
import sys

# Parsing the variable

def _dequote(part):
    subs = part.split("%")
    # Will raise if there are <2 chars after % or if these aren't valid hex
    return subs[0] + "".join(chr(int(sub[0:2], 16)) + sub[2:] for sub in subs[1:])

def decode(prefix_str):
    tuples = (part.split("=") for part in prefix_str.split(":") if part) if prefix_str else ()
    # Will raise if any tuple can't be destructured into a pair
    return [(_dequote(src), _dequote(dst)) for src, dst in tuples]

pm = decode(os.getenv("BUILD_PATH_PREFIX_MAP", ""))

# Applying the variable

def map_prefix(string, pm):
    for src, dst in reversed(pm):
        if string.startswith(src):
            return dst + string[len(src):]
    return string

for v in sys.argv[1:]:
    print(map_prefix(v, pm))
