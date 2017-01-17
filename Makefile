TMPDIR = /run/shm/rb-prefix-map

ALL = split

ALLCHECK_split = split split.py
envvar_1_split = /a/b=yyy=ERROR	/a=lol		/b=foo	/a/b=yyy=secreteh

ALLCHECK_urlencode = urlencode.py
envvar_1_urlencode = /a/b%3Dyyy=ERROR&/a=lol&/b=foo&/a/b%3Dyyy=secreteh

.PHONY: all
all: $(ALL)

%: %.c source_prefix_map.h
	$(CC) -o "$@" "$<"

check-apply-generic = \
	set -ex; for i in $(1); do \
	  SOURCE_PREFIX_MAP='$(2)' \
	  ./$$i /a/d /b/1234 /a/b=yyy/xxx | diff -ru - apply.out.1; \
	done

check-apply-none = \
	set -ex; for i in $(1); do \
	  ./$$i /a/d /b/1234 /a/b=yyy/xxx | diff -ru - apply.out.2; \
	done

.PHONY: check
check: check-apply-split check-apply-urlencode

.PHONY: check-apply-%
check-apply-%: apply.out.1 apply.out.2
	$(MAKE) $(ALLCHECK_$*)
	$(call check-apply-generic,$(ALLCHECK_$*),$(envvar_1_$*))
	$(call check-apply-none,$(ALLCHECK_$*))

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
