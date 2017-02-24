all: spec.html

%.xml: %.rst %.t.xml
	# ain't nobody got time to manually type XML tags
	pandoc --template "$*.t.xml" -s "$<" -t docbook > "$@"

%.html: %.xml %.xsl
	xmlto -x "$*.xsl" html-nochunks "$<"

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
