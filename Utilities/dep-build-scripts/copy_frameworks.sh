#!/bin/sh
#if this path has spaces, please review the script; it hasn't been tested with a path with spaces
ADIUM=~/adium

pushd build/Frameworks
tar cf frameworks.tar *.framework
mv frameworks.tar $ADIUM/Frameworks
popd

pushd $ADIUM/Frameworks
tar xf frameworks.tar
rm frameworks.tar
popd

pushd $ADIUM
pushd build
rm -rf */AdiumLibpurple.framework
popd
popd
