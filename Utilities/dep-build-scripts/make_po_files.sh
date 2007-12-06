#!/bin/sh

PATCHDIR="$PWD"

pushd $PIDGIN_SOURCE

for patch in "$PATCHDIR/libpurple-restrict-potfiles-to-libpurple.diff" ; do
    echo "Applying $patch"
	cat $patch | patch --forward -p0
done

pushd po
make update-po && make all && make install
popd
