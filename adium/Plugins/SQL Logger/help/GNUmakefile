HTML_FILES := index.html resin.html technical.html tsearch.html \
	      performance.html quick_install.html

deploy: $(HTML_FILES)

clean: 
	rm -f $(HTML_FILES)

$(HTML_FILES): adium.xsl

%.html: %.xml
	xsltproc -o $@ adium.xsl $<
