deploy: index.html resin.html technical.html tsearch.html performance.html

%.html: %.xml
	xsltproc -o $@ adium.xsl $<
