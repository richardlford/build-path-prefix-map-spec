NodeJS does not provide an easy way to *not* UTF-8-decode process.env or
process.argv.

(Invalid UTF-8 bytes are all replaced with U+FFFD REPLACEMENT CHARACTER)
