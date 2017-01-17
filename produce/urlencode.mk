#!/usr/bin/make -f

# Setting the variable

spm_encode = $(subst\
$(empty) $(empty),+,$(subst\
=,%3D,$(subst\
;,%3B,$(subst\
+,%2B,$(subst\
&,%26,$(subst\
%,%25,$(1)))))))

export override SOURCE_PREFIX_MAP := $(if $(SOURCE_PREFIX_MAP),$(SOURCE_PREFIX_MAP)&,)$(call\
spm_encode,a a=xxx)=$(call\
spm_encode,b b)

print-%:; @echo "$($*)"
default: print-SOURCE_PREFIX_MAP

# We don't expect Makefiles to have to read or apply the variable.
