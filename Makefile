ALL = split
ALL_CHECK = split split.py

.PHONY: all
all: $(ALL)

%: %.c
	gcc -o "$@" "$<"

.PHONY: check-apply
check-apply: apply.out.1 apply.out.2 $(ALL_CHECK)
	set -ex; for i in $(ALL_CHECK); do \
	  SOURCE_PREFIX_MAP='/a/b=yyy=ERROR	/a=lol		/b=foo	/a/b=yyy=secreteh' \
	  ./$$i /a/d /b/1234 /a/b=yyy/xxx | diff -ru - apply.out.1; \
	done
	set -ex; for i in $(ALL_CHECK); do \
	  ./$$i /a/d /b/1234 /a/b=yyy/xxx | diff -ru - apply.out.2; \
	done

.PHONY: clean
clean:
	rm -f $(ALL)
