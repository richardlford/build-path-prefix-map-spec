# To add a new interpreted-language example, add it to ALLCHECK_pecsplit
# To add a new compiled-language example, add the source to ALL_SOURCE, the
# output to ALLCHECK_pecsplit, then add any relevant rules to compile it.

TMPDIR = /run/shm/rb-prefix-map
T = testcases/

ALL_FORMATS = pecsplit
ALL_SOURCE = pecsplit.c pecsplit.rs
ALLCHECK_pecsplit = pecsplit.c.out pecsplit.rs.out pecsplit.js pecsplit.py

export AFL_USE_ASAN=1
AFL_MEMLIM = none
# 20971595M also seems to work with afl-gcc amd64 6.2.1-5

CC ?= cc
RUSTC ?= rustc

# Args:
# 1 key, e.g. "0" or "pecsplit.0"
# 2 suffix that indicates a test, e.g. "in" or "env"
find_testcases = \
	TESTCASES_$(1) = $(patsubst $(T)$(1).%.$(2),$(1).%,$(wildcard $(T)$(1).*.$(2)))
$(eval $(call find_testcases,0,in))
$(eval $(call find_testcases,1,in))
$(foreach format,$(ALL_FORMATS),$(eval $(call find_testcases,$(format).0,env)))
$(foreach format,$(ALL_FORMATS),$(eval $(call find_testcases,$(format).1,env)))

.PHONY: all
all: $(ALL_SOURCE:%=%.out)

%.c.out: %.c prefix_map.h
	$(CC) -Wall -o "$@" "$<"

%.rs.out: %.rs
	$(RUSTC) -W warnings -o "$@" "$<"

.PHONY: check
check: $(ALL_FORMATS:%=check-%)

export TESTDIR = $(T)
.PHONY: check-%
check-%:
	$(MAKE) $(ALLCHECK_$*)
	for case in $(TESTCASES_0); do ./check-generic.sh "$(ALLCHECK_$*)" $* 0 $$case $$case.$* $$case; done
	for case in $(TESTCASES_1); do ./check-generic.sh "$(ALLCHECK_$*)" $* 1 $$case $$case.$* $$case; done
	for case in $(TESTCASES_$*.0); do ./check-generic.sh "$(ALLCHECK_$*)" $* 0 $$case $$case $*.0; done
	for case in $(TESTCASES_$*.1); do ./check-generic.sh "$(ALLCHECK_$*)" $* 1 $$case $$case $*.1; done

make-afl-test-case = \
	cat testcases/$(3).$(1).env testcases/$(3).in > afl-in-$(1)/$(3).in;

afl-in-%: $(wildcard $(T)*.in) $(wildcard $(T)*.env)
	mkdir -p "$@"
	$(foreach case,$(TESTCASES_0),$(call make-afl-test-case,$*,0,$(case)))
	$(foreach case,$(TESTCASES_1),$(call make-afl-test-case,$*,1,$(case)))
	touch "$@"

.PHONY: fuzz-%
fuzz-%: %.out
	$(MAKE) afl-in-$(basename $*)
	@echo "$(CC)" | grep -i afl || \
	echo >&2 "warning: you didn't set CC=afl-gcc, fuzzing might not work"
	set -e; if test -d "afl-out-$*"; then \
	echo >&2 "afl-out-$* exists, reusing. run 'make reset-fuzz-$* to delete it."; \
	afl-fuzz -m $(AFL_MEMLIM) -i - -o "afl-out-$*" -- "./$<" -; else \
	mkdir -p $(TMPDIR); \
	ln -s "$$(mktemp -d -p $(TMPDIR))" "afl-out-$*"; \
	afl-fuzz -m $(AFL_MEMLIM) -i "afl-in-$(basename $*)" -o "afl-out-$*" -- "./$<" -; fi

.PHONY: reset-fuzz-%
reset-fuzz-%:
	rm -rf "$$(readlink -f "afl-out-$*")" && rm -rf "afl-out-$*"
	rmdir -p "$(TMPDIR)" 2>/dev/null || true

.PHONY: clean
clean:
	rm -f $(ALL_SOURCE:%=%.out)
	rm -rf $(ALL_FORMATS:%=afl-in-%)

.PHONY: clean-all
clean-all: clean $(ALL_SOURCE:%=reset-fuzz-%)
