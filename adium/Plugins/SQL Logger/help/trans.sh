#/bin/sh

for i in *.xml; do
    xsltproc -o `echo $i | sed -e 's/.xml$/.html/'` adium.xsl $i;
done;
