HTML_FILES := index.html technical.html \
	      performance.html install.html

deploy: $(HTML_FILES)

clean:
	rm -f $(HTML_FILES)

$(HTML_FILES): transform.xsl

%.html: %.xml
	xsltproc -o $@ transform.xsl $<
