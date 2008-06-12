#!/bin/sh

source common.sh
setupDirStructure
cd "$BUILDDIR"

DEBUG_SYMBOLS=TRUE
PROTOCOLS="bonjour gg irc jabber msn myspace novell oscar qq sametime simple yahoo zephyr"
MSN_PECAN_DIR="$PWD/msn-pecan-0.0.12"

if [ "x$PIDGIN_SOURCE" == "x" ] ; then
	echo 'Error: you need to set PIDGIN_SOURCE to be the location of' \
	'your pidgin source tree.'
	exit 1
fi

echo "Using Pidgin source from: $PIDGIN_SOURCE"

# Apply our openssl patch - enables using OpenSSL and allows libgadu with SSL
# support. This is OK because OpenSSL is part of the base system on OS X.

pushd $PIDGIN_SOURCE > /dev/null 2>&1
###
# Patches bringing in forward changes from libpurple:
#
###
# Patches for our own hackery
#
# libpurple_jabber_avoid_sasl_option_hack.diff is needed to avoid using PLAIN via SASL on Mac OS X 10.4, 
#		where it doesn't work properly
# libpurple_makefile_linkage_hacks.diff fixes some linkage problems
# libpurple_jabber_parser_error_handler.diff adds a handler for jabber errors
# 		which may fix crashes in __xmlRaiseError() --> _structuredErrorFunc().
# libpurple_xmlnode_parser_error_handler does the same for other xml parsing.
# libpurple_disable_last_seen_tracking.diff disables the last-seen tracking, 
# 		avoiding unnecessary blist.xml writes, since we don't ever use the information (we keep track of it ourselves).
###
# Add
#    "$PATCHDIR/libpurple-enable-msnp14.diff" \ 
# to allow enabling msnp14. Needs change below.
###
LIBPURPLE_PATCHES=("$PATCHDIR/libpurple_makefile_linkage_hacks.diff" \
					"$PATCHDIR/libpurple_disable_last_seen_tracking.diff" \
					"$PATCHDIR/libpurple-restrict-potfiles-to-libpurple.diff" \
					"$PATCHDIR/libpurple_jabber_parser_error_handler.diff" \
					"$PATCHDIR/libpurple_jabber_avoid_sasl_option_hack.diff" \
					"$PATCHDIR/libpurple_xmlnode_parser_error_handler.diff" \
					"$PATCHDIR/libpurple_zephyr_fix_krb4_flags.diff")
             
for patch in ${LIBPURPLE_PATCHES[@]} ; do
    echo "Applying $patch"
	patch --forward -p0 < $patch || true
done
popd > /dev/null 2>&1

for ARCH in ppc i386 ; do
    case $ARCH in
		ppc) export HOST=powerpc-apple-darwin9
			 export PATH="$PATH_PPC"
			 export ACLOCAL_FLAGS="-I $TARGET_DIR_PPC/share/aclocal"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig"
			 TARGET_DIR=$TARGET_DIR_PPC;;
		i386) export HOST=i686-apple-darwin9
			  export PATH="$PATH_I386"
			  export ACLOCAL_FLAGS="-I $TARGET_DIR_I386/share/aclocal"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig"
			  TARGET_DIR=$TARGET_DIR_I386;;
	esac

	#Get access to the sasl headers
    mkdir -p $TARGET_DIR/include/sasl || true
	cp $SOURCEDIR/cyrus-sasl-2.1.18/include/*.h $TARGET_DIR/include/sasl

    #Note that whether we use openssl or cdsa the same underlying workarounds (as seen in jabber.c, only usage at present 12/07) are needed
    export CFLAGS="$BASE_CFLAGS -arch $ARCH -I$TARGET_DIR/include -I$SDK_ROOT/usr/include/kerberosIV -DHAVE_SSL -DHAVE_OPENSSL -fno-common"

    if [ "$DEBUG_SYMBOLS" = "TRUE" ] ; then
        export CFLAGS="$CFLAGS -gdwarf-2 -g3" 
    fi

    export LDFLAGS="$BASE_LDFLAGS -L$TARGET_DIR/lib -arch $ARCH"
    export PKG_CONFIG="$TARGET_DIR_BASE-$ARCH/bin/pkg-config"
    export MSGFMT="`which msgfmt`"

    mkdir libpurple-$ARCH || true
    pushd libpurple-$ARCH > /dev/null 2>&1
        export ARCH
    	echo Compiling for $ARCH
		echo LDFLAGS is $LDFLAGS
		echo PKG_CONFIG is $PKG_CONFIG

    	# this part is really ew. We actually re-run autogen.sh per-arch.
    	# we pass configure --help so that it bails out and doesn't fubar the source
    	# tree, because otherwise we'd have to un-configure it. Stupid autotools.
    	pushd $PIDGIN_SOURCE > /dev/null 2>&1
    	   ./autogen.sh --help
    	popd > /dev/null 2>&1
    	# we don't need pkg-config for this
    	export LIBXML_CFLAGS='-I/usr/include/libxml2' 
    	export LIBXML_LIBS='-lxml2'
    	export GADU_CFLAGS="-I$TARGET_DIR/include"
    	export GADU_LIBS="-lgadu"
    	export MEANWHILE_CFLAGS="-I$TARGET_DIR/include/meanwhile -I$TARGET_DIR/include/glib-2.0 -I$TARGET_DIR/lib/glib-2.0/include"
    	export MEANWHILE_LIBS="-lmeanwhile -lglib-2.0 -liconv"
    	
    	###
    	# With change above, add 
    	#   --enable-msnp14 \
    	# to enable msnp14
    	###
    	$PIDGIN_SOURCE/configure \
    	        --disable-gtkui --disable-consoleui \
                --disable-perl \
                --enable-debug \
                --disable-static --enable-shared \
                --with-krb4 \
                --enable-cyrus-sasl \
                --prefix=$TARGET_DIR \
                --with-static-prpls="$PROTOCOLS" \
                --host=$HOST \
                --disable-gstreamer \
                --disable-avahi \
                --disable-dbus \
                --enable-gnutls=no --enable-nss=no --enable-openssl=no $@
        pushd libpurple > /dev/null 2>&1
            make -j $NUMBER_OF_CORES && make install
        popd > /dev/null 2>&1
    popd
    # HACK ALERT! We use the following internal-only headers:
    cp $PIDGIN_SOURCE/libpurple/protocols/oscar/oscar.h \
       $PIDGIN_SOURCE/libpurple/protocols/oscar/snactypes.h \
       $PIDGIN_SOURCE/libpurple/protocols/oscar/peer.h \
       $PIDGIN_SOURCE/libpurple/cmds.h \
       $PIDGIN_SOURCE/libpurple/internal.h \
       $PIDGIN_SOURCE/libpurple/protocols/msnp9/*.h \
       $PIDGIN_SOURCE/libpurple/protocols/yahoo/*.h \
       $PIDGIN_SOURCE/libpurple/protocols/gg/buddylist.h \
       $PIDGIN_SOURCE/libpurple/protocols/gg/gg.h \
       $PIDGIN_SOURCE/libpurple/protocols/gg/search.h \
       $PIDGIN_SOURCE/libpurple/protocols/jabber/buddy.h \
       $PIDGIN_SOURCE/libpurple/protocols/jabber/caps.h \
       $PIDGIN_SOURCE/libpurple/protocols/jabber/jutil.h \
       $PIDGIN_SOURCE/libpurple/protocols/jabber/presence.h \
       $PIDGIN_SOURCE/libpurple/protocols/jabber/si.h \
       $PIDGIN_SOURCE/libpurple/protocols/jabber/jabber.h \
	   $TARGET_DIR/include/libpurple

#    pushd $MSN_PECAN_DIR
#       make clean || exit 1
#       make -j $NUMBER_OF_CORES || exit 1
#       make install || exit 1
#    popd
done

pushd $PIDGIN_SOURCE > /dev/null 2>&1
	for patch in ${LIBPURPLE_PATCHES[@]} ; do
		patch -R -p0 < $patch || true
	done
popd > /dev/null 2>&1

echo "Done - now run ./universalize.sh"