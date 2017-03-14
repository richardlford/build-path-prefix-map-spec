SPEC = build-path-prefix-map-spec

all: check-produce check-consume $(SPEC).html

%.html: %.xml %.xsl fixup-footnotes.xsl
	xmlto -x "$*.xsl" html-nochunks "$<"
	xsltproc --html -o "$@" fixup-footnotes.xsl "$@"

%.xml: %.rst %.in.xml Makefile
	# ain't nobody got time to manually type XML tags
	pandoc --template "$*.in.xml" -s "$<" -t docbook > "$@"

$(SPEC).rst: $(SPEC).in.rst $(SPEC)-testcases.rst
	cat $^ > "$@"

T = testcases-pecsplit.rst
.PHONY: consume/$(T)
consume/$(T):
	$(MAKE) -C consume $(T)

$(SPEC)-testcases.rst: consume/testcases-pecsplit.rst
	cp "$<" "$@"

.PHONY: check-consume
check-consume:
	cd consume && $(MAKE) check

.PHONY: clean-consume
clean-consume:
	cd consume && $(MAKE) clean

.PHONY: check-produce
check-produce:
	cd produce && ./test-all.sh

.PHONY: clean
clean: clean-consume
	rm -f *.html $(SPEC).xml $(SPEC)-testcases.rst $(SPEC).rst
