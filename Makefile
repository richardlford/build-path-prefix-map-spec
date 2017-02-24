all: spec.html

%.xml: %.rst %.t.xml Makefile
	# ain't nobody got time to manually type XML tags
	pandoc --template "$*.t.xml" -s "$<" -t docbook > "$@"

%.html: %.xml %.xsl fixup-footnotes.xsl
	xmlto -x "$*.xsl" html-nochunks "$<"
	xsltproc --html -o "$@" fixup-footnotes.xsl "$@"

spec.rst: spec-main.rst spec-testcases.rst
	cat $^ > "$@"

T = testcases-pecsplit.rst
.PHONY: consume/$(T)
consume/$(T):
	$(MAKE) -C consume $(T)

spec-testcases.rst: consume/testcases-pecsplit.rst
	cp "$<" "$@"

.PHONY: clean
clean:
	rm -f *.html spec-testcases.rst spec.rst
