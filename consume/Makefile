TMPDIR = /run/shm/rb-prefix-map

ALL = hexsplit
ALLCHECK_hexsplit = hexsplit hexsplit.js hexsplit.py

.PHONY: all
all: $(ALL)

%: %.c prefix_map.h
	$(CC) -Wall -o "$@" "$<"

check-apply-generic = \
	set -ex; for i in $(1); do \
	  BUILD_PATH_PREFIX_MAP="$$(cat 0.$(2)-$(3).env)" \
	  ./$$i $$(cat 0.in) | diff -ru - 0.$(2).out; \
	done

check-apply-none = \
	set -ex; for i in $(1); do \
	  ./$$i $$(cat 0.in) | diff -ru - 0.in; \
	done

.PHONY: check
check: check-apply-hexsplit

.PHONY: check-apply-%
check-apply-%:
	$(MAKE) $(ALLCHECK_$*)
	$(call check-apply-none,$(ALLCHECK_$*))
	$(call check-apply-generic,$(ALLCHECK_$*),0,$*)

.PHONY: fuzz-%
fuzz-%: %
	@echo "$(CC)" | grep -i afl || \
	echo >&2 "warning: you didn't set CC=afl-gcc, fuzzing might not work"
	@set -e; if test -d "afl-out-$*"; then \
	echo >&2 "afl-out-$* exists, reusing. run 'make reset-fuzz-$* to delete it."; \
	afl-fuzz -i - -o "afl-out-$*" -- "./$*" -; else \
	mkdir -p $(TMPDIR); \
	ln -s "$$(mktemp -d -p $(TMPDIR))" "afl-out-$*"; \
	afl-fuzz -i "afl-in-$(basename $*)" -o "afl-out-$*" -- "./$*" -; fi

.PHONY: reset-fuzz-%
reset-fuzz-%: %
	rm -rf "$$(readlink -f "afl-out-$*")" && rm -rf "afl-out-$*"
	rmdir -p "$(TMPDIR)" 2>/dev/null || true

.PHONY: clean
clean:
	rm -f $(ALL)
