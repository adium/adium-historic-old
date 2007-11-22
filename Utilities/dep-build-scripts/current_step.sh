GLIB=glib-2.14.1
MEANWHILE=meanwhile-1.0.2
GADU=libgadu-1.7.1
INTLTOOL=intltool-0.36.2
PROTOCOLS="gg irc jabber msn myspace novell oscar qq sametime simple yahoo zephyr"
PATCHDIR="$PWD"

if [ "x$PIDGIN_SOURCE" == "x" ] ; then
	echo 'Error: you need to set PIDGIN_SOURCE to be the location of' \
	'your pidgin source tree.'
	exit 1
fi

SDK_ROOT="/Developer/SDKs/MacOSX10.4u.sdk"
BASE_CFLAGS="-mmacosx-version-min=10.4 -isysroot $SDK_ROOT"
BASE_LDFLAGS="-mmacosx-version-min=10.4 -headerpad_max_install_names -Wl,-syslibroot,$SDK_ROOT"

NUMBER_OF_CORES=`sysctl -n hw.activecpu`

mkdir build || true
cd build
mkdir universal || true

TARGET_DIR_PPC="$PWD/root-ppc"
TARGET_DIR_I386="$PWD/root-i386"
TARGET_DIR_BASE="$PWD/root"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"

# we need glibtoolize to be libtoolize for pidgin, their silly autogen.sh
# it to be that way right now. In the future I'm hoping to offer a patch to
# pidgin so that it'll check and see if glibtoolize exists if it doesn't find
# libtoolize.
ln -s /usr/bin/glibtoolize $TARGET_DIR_PPC/bin/libtoolize
ln -s /usr/bin/glibtoolize $TARGET_DIR_I386/bin/libtoolize

# Apply our openssl patch - enables using OpenSSL and allows libgadu with SSL
# support. This is OK because OpenSSL is part of the base system on OS X.

pushd $PIDGIN_SOURCE
#  "$PATCHDIR/libpurple_jabber_avoid_sasl_option_hack.diff"
for patch in "$PATCHDIR/libpurple_sasl_hack.diff" \
 "$PATCHDIR/libpurple_jabber_avoid_sasl_option_hack.diff" \
             "$PATCHDIR/libpurple_myspace_hack.diff" ; do
    echo "Applying $patch"
	cat $patch | patch --forward -p0
done
popd

for ARCH in ppc i386 ; do
    case $ARCH in
		ppc) export HOST=powerpc-apple-darwin9
			 export PATH="$PATH_PPC"
			 export ACLOCAL_FLAGS="-I$TARGET_DIR_PPC/share/aclocal"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig"
			 TARGET_DIR=$TARGET_DIR_PPC;;
		i386) export HOST=i686-apple-darwin9
			  export PATH="$PATH_I386"
			  export ACLOCAL_FLAGS="-I$TARGET_DIR_I386/share/aclocal"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig"
			  TARGET_DIR=$TARGET_DIR_I386;;
	esac
    export CFLAGS="$BASE_CFLAGS -arch $ARCH -I$TARGET_DIR/include -I$SDK_ROOT/usr/include/kerberosIV -DHAVE_SSL "
	export LDFLAGS="$BASE_LDFLAGS -L$TARGET_DIR/lib -arch $ARCH"
    mkdir libpurple-$ARCH || true
    cd libpurple-$ARCH
	export ARCH
	export PKG_CONFIG="`which pkg-config`"
	export MSGFMT="`which msgfmt`"
	# this part is really ew. We actually re-run autogen.sh per-arch.
	# we pass configure --help so that it bails out and doesn't fubar the source
	# tree, because otherwise we'd have to un-configure it. Stupid autotools.
	pushd $PIDGIN_SOURCE
	./autogen.sh --help
	popd
	# we don't need pkg-config for this
	export LIBXML_CFLAGS='-I/usr/include/libxml2' 
	export LIBXML_LIBS='-lxml2'
	export GADU_CFLAGS="-I$TARGET_DIR/include"
	export GADU_LIBS="-lgadu"
	export MEANWHILE_CFLAGS="-I$TARGET_DIR/include/meanwhile -I$TARGET_DIR/include/glib-2.0 -I$TARGET_DIR/lib/glib-2.0/include"
	export MEANWHILE_LIBS="-lmeanwhile -lglib-2.0 -liconv"
	#            --enable-cyrus-sasl \
	$PIDGIN_SOURCE/configure \
	        --disable-gtkui --disable-consoleui \
            --disable-perl \
            --enable-debug \
            --disable-static --enable-shared \
            --disable-dependency-tracking \
            --enable-krb4 \
            --prefix=$TARGET_DIR \
            --with-static-prpls="$PROTOCOLS" --disable-plugins \
            --host=$HOST \
            --enable-gnutls=no --enable-nss=no --enable-openssl=no $@
    cd libpurple
    echo 'inspect sources (edit them?) and then make && make install'
    make -j $NUMBER_OF_CORES && make install
    # HACK ALERT! We use the following internal-only headers:
    cp $PIDGIN_SOURCE/libpurple/protocols/oscar/oscar.h \
       $PIDGIN_SOURCE/libpurple/protocols/oscar/oscar-adium.h \
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
    cd ../..
done

pushd $PIDGIN_SOURCE
for patch in "$PATCHDIR/libpurple_sasl_hack.diff" \
             "$PATCHDIR/libpurple_myspace_hack.diff"; do
	patch -R -p0 < $patch
done
popd
