#!/bin/sh

PATCHDIR="$PWD"

pushd $PIDGIN_SOURCE

for patch in "$PATCHDIR/libpurple-restrict-potfiles-to-libpurple.diff" ; do
    echo "Applying $patch"
	cat $patch | patch --forward -p0
done

popd

pushd $PATCHDIR/build/libpurple-i386/po
#make update-po && make all && make install
make all && make install
popd

pushd $PATCHDIR/build/root-i386/share/locale
mkdir $PATCHDIR/build/Frameworks/libpurple.framework/Resources || true
cp -v -r * $PATCHDIR/build/Frameworks/libpurple.framework/Resources
popd

pushd $PATCHDIR/build/Frameworks/libpurple.framework/Resources
find . \( -name gettext-runtime.mo -or -name gettext-tools.mo -or -name glib20.mo \) -type f -delete
popd

