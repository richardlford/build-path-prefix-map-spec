#!/usr/bin/python3

import string
import sys
import textwrap

sanitized = [x for x in string.printable if x not in string.whitespace or x in " \n"]

contents = open(sys.argv[1], 'rb').read().rstrip(b'\n')
try:
    contents = contents.decode("utf-8")
    if all(x in sanitized for x in contents):
        print(contents)
    else:
        print("\u200b".join(repr(contents)))
except UnicodeDecodeError:
    print("".join(repr(contents)))
