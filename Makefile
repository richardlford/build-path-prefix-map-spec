all: spec.html

%.html: %.rst %.css
	rst2html5 --stylesheet minimal.css,"$*.css" "$<" > "$@"

spec.rst: spec-main.rst spec-testcases.rst
	cat $^ > "$@"

T = testcases-pecsplit.rst
.PHONY: consume/$(T)
consume/$(T):
	$(MAKE) -C consume $(T)

spec-testcases.rst: consume/testcases-pecsplit.rst
	cp "$<" "$@"

spec.css: consume/testcases-rst.css
	cp "$<" "$@"

.PHONY: clean
clean:
	rm -f *.html spec.css spec-testcases.rst spec.rst
