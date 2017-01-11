#!/bin/bash
# See also
# https://www.w3.org/International/questions/qa-controls
# https://www.w3.org/TR/html5/syntax.html#character-references
# https://validator.w3.org/

set -e
set -o pipefail # and this is why we need bash

r1="a=b"
r2="/lol/wtf=bbq/project std::ftw???\latex{evil}=y"
check1() {
	local sep="$1"; shift
	set -x
	test "$r1" = "$("$@")"
	test "$r2$sep$r1" = "$(SOURCE_PREFIX_MAP=$r2 "$@")"
	{ set +x; } 2>/dev/null
}

checkall() {
	echo >&2 ">>>> testing $1"
	for i in sh mk; do
		check1 "$2" ./"$3.$i"
	done
    echo >&2 "<<<< end testing"
}

to_html() {
	echo '<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>results</title><style>pre { border:1px solid black; }</style></head><body><p>Try c+p the below into a text editor and/ or into <a href="https://validator.w3.org/#validate_by_input">W3C Markup Validator</a>.</p><div>'
	sed -e 's,^>>>> \(.*\),\1\n<pre>,g' \
	    -e 's,^<<<< .*,</pre>,g'
#	    -e 's//\&#x1E;/g' \
#	    -e 's//\&#x1F;/g' \
#	    -e 's//\&#x0B;/g' \
#	    -e 's//\&#x0C;/g' \
#	    -e 's//\&#x85;/g'
	echo "</div></body></html>"
}

{
# Very awkward to use in Makefile
checkall "newline" "
" newline

# Miight conflict with other uses
# Slight abuse-of-purpose
SEP="	" checkall "tab" "	" char

# not commonly-used, never see this in a file path
# fits the "intended purpose" of the character
# Not valid HTML5 or XML 1.0
SEP="" checkall "record-separator 0x1E" "" char

# Not valid HTML5 or XML 1.0
# However this usage matches the "purpose" of the characters and is more flexible than "="
r1="ab" \
r2="/lol/wtf=bbq/project std::ftw???\latex{evil}y" \
checkall "2-separators 0x1E and 0x1F" "" 2sep

# Valid HTML5, but invalid XML 1.0 (but valid XML 1.1)
# Abuse-of-purpose
SEP="" checkall "form-feed" "" char

# Invalid in HTML and XML, but "seems like" newline
SEP="" checkall "vtab" "" char

# Downside are that this is encoding-dependent and may copy-paste incorrectly
# It is acceptable in XML 1.0/1.1
SEP="" checkall "next-line 0x85" "" char

} 2>&1 | tee /dev/stderr | to_html > results.html

echo >&2 "===="
echo >&2 "tests succeeded, html log available in results.html"
