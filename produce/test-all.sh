#!/bin/sh

set -ex

ALLCHECK="pecsplit.mk pecsplit.pl"

test_mapping() {
	#echo "$PS4$0" "$@" >&2
	local src="$1"
	local dst="$2"
	local res_expect="$3"
	local res_actual

	for i in $ALLCHECK; do
		res_actual="$(NEWSRC="$src" NEWDST="$dst" "./$i" ./print.sh)"
		test "$res_actual" = "$res_expect" -o "$res_actual" = ":$res_expect"
		res_actual="$(BUILD_PATH_PREFIX_MAP=a=b NEWSRC="$src" NEWDST="$dst" "./$i" ./print.sh)"
		test "$res_actual" = "a=b:$res_expect"
		res_actual="$(BUILD_PATH_PREFIX_MAP=/ab%+cd=/b NEWSRC="$src" NEWDST="$dst" "./$i" ./print.sh)"
		test "$res_actual" = "/ab%+cd=/b:$res_expect"
	done
}

test_mapping 'foo' 'bar' \
	'bar=foo'

test_mapping '/a/b=yyy' 'libbar-3-bison++_41:10.5-3~rc1pre3+dfsg1.1-3nmu1+b4' \
	'libbar-3-bison++_41%.10.5-3~rc1pre3+dfsg1.1-3nmu1+b4=/a/b%+yyy'
