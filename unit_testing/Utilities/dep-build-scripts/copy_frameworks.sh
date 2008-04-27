#!/bin/sh 
ADIUM="`dirname $0`/../.."

cp -r "`dirname $0`"/build/Frameworks/*.framework "$ADIUM/Frameworks/"

pushd "$ADIUM/build"
rm -rf */AdiumLibpurple.framework 
rm -rf */*/Adium.app/Contents/Frameworks/lib*
popd
