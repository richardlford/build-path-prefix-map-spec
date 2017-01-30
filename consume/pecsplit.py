#!/usr/bin/python3

import os
import sys

# Parsing the variable

chr_n0 = lambda x: (1/x, chr(x))[1]

def _dequote(part):
    return part.replace("%c", ':').replace("%e", '=').replace("%p", '%');

def decode(prefix_str):
    tuples = (part.split("=") for part in prefix_str.split(":") if part)
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
    # print() tries to auto-encode its args without surrogateescape
    sys.stdout.buffer.write(map_prefix(v, pm).encode("utf-8", errors="surrogateescape") + b"\n")
