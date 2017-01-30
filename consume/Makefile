# To add a new interpreted-language example, add it to ALLCHECK_pecsplit
# To add a new compiled-language example, add the source to ALL_SOURCE, the
# output to ALLCHECK_pecsplit, then add any relevant rules to compile it.

TMPDIR = /run/shm/rb-prefix-map
T = testcases/

ALL_FORMATS = pecsplit
ALL_SOURCE = pecsplit.c
ALLCHECK_pecsplit = pecsplit.c.out pecsplit.js pecsplit.py

export AFL_USE_ASAN=1
AFL_MEMLIM = none
# 20971595M also seems to work with afl-gcc amd64 6.2.1-5

find_testcases = \
	TESTCASES_$(1) = $(patsubst $(T)$(1).%.in,$(1).%,$(wildcard $(T)$(1).*.in))
$(eval $(call find_testcases,0))
$(eval $(call find_testcases,1))
$(foreach format,$(ALL_FORMATS),$(eval $(call find_testcases,$(format).0)))
$(foreach format,$(ALL_FORMATS),$(eval $(call find_testcases,$(format).1)))

.PHONY: all
all: $(ALL_SOURCE:%=%.out)

%.c.out: %.c prefix_map.h
	$(CC) -Wall -o "$@" "$<"

.PHONY: check
check: $(ALL_FORMATS:%=check-%)

# 1 progname
# 2 format
# 3 expected exit code
# 4 input
# 5 env
# 6 output
check-generic = \
	set -x; for i in $(1); do \
	  if test -f "$(T)$(4).in.ignore-$$i"; then \
	    set +x; \
	    printf >&2 "\033[1;31m================================================================\033[0m\n"; \
	    printf >&2 "\033[1;31mvvvv IGNORING $$i for $(4).in because: vvvv\033[0m\n"; \
	    cat >&2 "$(T)$(4).in.ignore-$$i"; \
	    printf >&2 "\033[1;31m^^^^ IGNORING $$i for $(4).in because: ^^^^\033[0m\n"; \
	    printf >&2 "\033[1;31m================================================================\033[0m\n"; \
	    set -x; \
	    continue; \
	  fi; \
	  ./$$i $$(cat $(T)$(4).in) | diff -ru - "$(T)$(4).in" || exit 1; \
	  tmpout="$(T)$(5).env.tmpout"; \
	  BUILD_PATH_PREFIX_MAP="$$(cat $(T)$(5).env)" \
	  ./$$i $$(cat $(T)$(4).in) > "$$tmpout"; \
	  test $$? = $(3) && diff -ru "$$tmpout" "$(T)$(6).out" && \
	    rm -f "$$tmpout" || { rm -f "$$tmpout"; exit 1; }; \
	done;

.PHONY: check-%
check-%:
	$(MAKE) $(ALLCHECK_$*)
	$(foreach case,$(TESTCASES_0),$(call check-generic,$(ALLCHECK_$*),$*,0,$(case),$(case).$*,$(case)))
	$(foreach case,$(TESTCASES_1),$(call check-generic,$(ALLCHECK_$*),$*,1,$(case),$(case).$*,$(case)))
	$(foreach case,$(TESTCASES_$*.0),$(call check-generic,$(ALLCHECK_$*),$*,0,$(case),$(case),$(case)))
	$(foreach case,$(TESTCASES_$*.1),$(call check-generic,$(ALLCHECK_$*),$*,1,$(case),$(case),$(case)))

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
