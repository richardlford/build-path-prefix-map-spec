#!/usr/bin/make -f
# The ugliest one, we can't use standard Makefile idioms because of the newline

# Setting the variable

ifdef SOURCE_PREFIX_MAP
export override define SOURCE_PREFIX_MAP :=
$(SOURCE_PREFIX_MAP)
a=b
endef
else
export override SOURCE_PREFIX_MAP := a=b
endif

# Alternative method that is slightly shorter but results in an extra empty first mapping
#export override define SOURCE_PREFIX_MAP :=
#$(SOURCE_PREFIX_MAP)
#a=b
#endef

# Can't print of a Makefile variable containing newlines due to its special
# treatment within recipes; we have to print it as a shell variable instead.
print-SOURCE_PREFIX_MAP:
	@echo "$$SOURCE_PREFIX_MAP"

# We don't expect Makefiles to have to read or apply the variable.
