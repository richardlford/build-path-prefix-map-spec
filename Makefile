all: spec.html

%.html: %.xml %.xsl fixup-footnotes.xsl
	xmlto -x "$*.xsl" html-nochunks "$<"
	xsltproc --html -o "$@" fixup-footnotes.xsl "$@"

%.xml: %.rst %.in.xml Makefile
	# ain't nobody got time to manually type XML tags
	pandoc --template "$*.in.xml" -s "$<" -t docbook > "$@"

spec.rst: spec.in.rst spec-testcases.rst
	cat $^ > "$@"

T = testcases-pecsplit.rst
.PHONY: consume/$(T)
consume/$(T):
	$(MAKE) -C consume $(T)

spec-testcases.rst: consume/testcases-pecsplit.rst
	cp "$<" "$@"

.PHONY: clean
clean:
	rm -f *.html spec.xml spec-testcases.rst spec.rst
