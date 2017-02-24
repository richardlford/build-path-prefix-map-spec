#!/usr/bin/make -sf

# Setting the variable

pfmap_enquote = $(subst :,%.,$(subst =,%+,$(subst %,%\#,$(1))))

export override BUILD_PATH_PREFIX_MAP := $(BUILD_PATH_PREFIX_MAP):$(call\
pfmap_enquote,$(NEWSRC))=$(call\
pfmap_enquote,$(NEWDST))

.PHONY: print.sh
print.sh:
	./$@
