#!/bin/sh
export CVS_RSH=ssh
cd /home/jmelloy/adium
rm -f changes
Utilities/stats/update.pl
cvs -z3 -Q up -Pd | fgrep -v ?
Utilities/stats/make_logfile.pl
Utilities/stats/find_logs.pl
if [ -f changes ]; then
    rm -fr stats
    mkdir stats
    /usr/java/j2sdk1.4.1_01/bin/java -jar /home/jmelloy/statcvs.jar \
        -output-dir "stats/" \
        -viewcvs http://cvs.sourceforge.net/viewcvs.py/adium/adium/ \
        -title "Adium 2.0" master.log \
        -exclude "**/*.png:**/*.aif:**/*.aiff:**/*.mp3:**/*.plist:**/*.tif:**/*.tiff:**/*.dylib:**/*.so:**/project.pbxproj:**/LIBS/**:**/cvs2cl.pl" \
        . > /dev/null
fi
if [ -f stats/index.html ] ; then
    rm -fr /home/jmelloy/www/adium/stats
    mv stats /home/jmelloy/www/adium/
fi
