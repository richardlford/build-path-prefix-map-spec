#!/usr/bin/make -f

# Setting the variable

export override SOURCE_PREFIX_MAP := $(if $(SOURCE_PREFIX_MAP),$(SOURCE_PREFIX_MAP),)ab
print-%:; @echo "$($*)"
default: print-SOURCE_PREFIX_MAP

# We don't expect Makefiles to have to read or apply the variable.
