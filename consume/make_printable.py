#!/usr/bin/python3

import string
import sys
import textwrap

sanitized = [x for x in string.printable if x not in string.whitespace or x in " \n"]

contents = open(sys.argv[1], 'rb').readlines()
for line in contents:
    line = line.rstrip(b'\n')
    try:
        line = line.decode("utf-8")
        if all(x in sanitized for x in line):
            print(line)
        else:
            print("\u200b".join(repr(line)))
    except UnicodeDecodeError:
        print("".join(repr(line)))
