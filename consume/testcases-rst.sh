#!/bin/sh
# Args:
# 1 format name
# 2 prefix for .in, .out
# 3 prefix for .env
# 4 prefix for .in, .out if $4 doesn't exist
# 5 cases
# 6 parse result e.g. "valid" or "invalid"

T="$TESTDIR"

print_section() {
	local header="$1"
	shift
	echo "$header"
	echo
	"$@" | sed -e 's/^/\t/g'
	echo
}

dump_or_ref() {
	if [ -h "$2" ]; then
		local dst="$(readlink "$2")"
		if [ "${dst%.out}" != "$dst" ]; then
			print_section "${1}:" echo "(same as the output for Case \"${dst%.out}\")"
		elif [ "${dst%.in}" != "$dst" ]; then
			print_section "${1}:" echo "(same as the input for Case \"${dst%.in}\")"
		else
			echo >&2 "ERROR: unknown symlink"
			exit 1
		fi
	else
		print_section "${1}::" ./make_printable.py "$2"
	fi
}

case="$2"

	if [ -f "${T}${2}.in" ]; then input="${T}${2}.in"; else input="${T}${4}.in"; fi
	if [ -f "${T}${2}.out" ]; then output="${T}${2}.out"; else output="${T}${4}.out"; fi
	envfile="${T}${3}.env"

	if [ -s "$output" ]; then
		dump_or_ref "Case \"$2\", **${5}**"': ``'"$(./make_printable.py "$envfile")"'`` maps' "$input"
		dump_or_ref 'to' "$output"

	else
		echo "Case \"$2\", **${5}**"': ``'"$(./make_printable.py "$envfile")"'``'
		echo

	fi
#done
