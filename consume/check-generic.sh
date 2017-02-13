#!/bin/sh
# Args:
# 1 programs to run, whitespace-separated
# 2 format name
# 3 expected exit code
# 4 prefix for .in, .out
# 5 prefix for .env
# 6 prefix for .in, .out if $4 doesn't exist

T="$TESTDIR"

for i in $1; do
	if test -f "${T}${4}.in.ignore-$i"; then
		set +x
		printf >&2 "\033[1;31m================================================================\033[0m\n"
		printf >&2 "\033[1;31mvvvv IGNORING $i for ${4}.in because: vvvv\033[0m\n"
		cat >&2 "${T}${4}.in.ignore-$i"
		printf >&2 "\033[1;31m^^^^ IGNORING $i for ${4}.in because: ^^^^\033[0m\n"
		printf >&2 "\033[1;31m================================================================\033[0m\n"
		set -x
		continue
	fi
	if [ -f "${T}${4}.in" ]; then input="${T}${4}.in"; else input="${T}${6}.in"; fi
	if [ -f "${T}${4}.out" ]; then output="${T}${4}.out"; else output="${T}${6}.out"; fi

	set -x
	./$i $(cat "$input") | diff -ru - "$input" || exit 1
	tmpout="${T}${5}.env.tmpout"

	BUILD_PATH_PREFIX_MAP="$(cat ${T}${5}.env)" \
	./$i $(cat "$input") > "$tmpout"
	test $? = "${3}" && diff -ru "$tmpout" "$output" && \
	  rm -f "$tmpout" || { rm -f "$tmpout"; exit 1; }
	set +x 2>/dev/null
done;
