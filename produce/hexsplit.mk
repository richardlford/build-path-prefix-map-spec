#!/usr/bin/make -f

# Setting the variable

spm_encode = $(subst :,%3a,$(subst =,%3d,$(subst %,%25,$(1))))

export override SOURCE_PREFIX_MAP := $(if $(SOURCE_PREFIX_MAP),$(SOURCE_PREFIX_MAP)&,)$(call\
spm_encode,aa with 100% sauce)=$(call\
spm_encode,bbb)

print-%:; @echo "$($*)"
default: print-SOURCE_PREFIX_MAP

# We don't expect Makefiles to have to read or apply the variable.
