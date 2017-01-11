#!/bin/sh

# Setting the variable

export SOURCE_PREFIX_MAP="${SOURCE_PREFIX_MAP:+$SOURCE_PREFIX_MAP}ab"
echo "$SOURCE_PREFIX_MAP"

# We don't expect shell scripts to have to read or apply the variable.
