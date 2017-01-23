TMPDIR = /run/shm/rb-prefix-map
T = testcases/

ALL_FORMATS = hexsplit
ALL_SOURCE = hexsplit.c
ALLCHECK_hexsplit = hexsplit.c.out hexsplit.js hexsplit.py

TESTCASES_0 = $(patsubst $(T)0.%.in,0.%,$(wildcard $(T)0.*.in))
TESTCASES_1 = $(patsubst $(T)1.%.in,1.%,$(wildcard $(T)1.*.in))

.PHONY: all
all: $(ALL_SOURCE:%=%.out)

%.c.out: %.c prefix_map.h
	$(CC) -Wall -o "$@" "$<"

.PHONY: check
check: $(ALL_FORMATS:%=check-%)

check-generic = \
	set -x; for i in $(1); do \
	  ./$$i $$(cat $(T)$(4).in) | diff -ru - "$(T)$(4).in" || exit 1; \
	  tmpout="$(T)$(4).$(2).env.tmpout"; \
	  BUILD_PATH_PREFIX_MAP="$$(cat $(T)$(4).$(2).env)" \
	  ./$$i $$(cat $(T)$(4).in) > "$$tmpout"; \
	  test $$? = $(3) && diff -ru "$$tmpout" "$(T)$(4).out" && \
	    rm -f "$$tmpout" || { rm -f "$$tmpout"; exit 1; }; \
	done;

.PHONY: check-%
check-%:
	$(MAKE) $(ALLCHECK_$*)
	$(foreach case,$(TESTCASES_0),$(call check-generic,$(ALLCHECK_$*),$*,0,$(case)))
	$(foreach case,$(TESTCASES_1),$(call check-generic,$(ALLCHECK_$*),$*,1,$(case)))

make-afl-test-case = \
	cat testcases/$(3).$(1).env testcases/$(3).in > afl-in-$(1)/$(3).in;

afl-in-%: $(wildcard $(T)/*.in) $(wildcard $(T)/*.env)
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
	afl-fuzz -i - -o "afl-out-$*" -- "./$<" -; else \
	mkdir -p $(TMPDIR); \
	ln -s "$$(mktemp -d -p $(TMPDIR))" "afl-out-$*"; \
	afl-fuzz -i "afl-in-$(basename $*)" -o "afl-out-$*" -- "./$<" -; fi

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
