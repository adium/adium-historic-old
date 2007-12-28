if [ `sw_vers -productVersion | cut -f 1,2 -d '.'` == 10.4 ] ; then
    IS_ON_10_4=TRUE
else
    IS_ON_10_4=FALSE
fi

GLIB=glib-2.14.1
MEANWHILE=meanwhile-1.0.2
GADU=libgadu-1.7.1
INTLTOOL=intltool-0.36.2
PROTOCOLS="bonjour gg irc jabber msn myspace novell oscar qq sametime simple yahoo zephyr"
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

# On 10.5+, we need glibtoolize to be libtoolize for pidgin, their silly
# autogen.sh expects it to be that way right now. In the future I'm hoping 
# to offer a patch to pidgin so that it'll check and see if glibtoolize
# exists if it doesn't find libtoolize.
if [ "$IS_ON_10_4" == "FALSE" ] ; then
    ln -s /usr/bin/glibtoolize $TARGET_DIR_PPC/bin/libtoolize
    ln -s /usr/bin/glibtoolize $TARGET_DIR_I386/bin/libtoolize
fi

# Apply our openssl patch - enables using OpenSSL and allows libgadu with SSL
# support. This is OK because OpenSSL is part of the base system on OS X.

pushd $PIDGIN_SOURCE
###
# Patches bringing in forward changes from libpurple:
#
#  libpurple_jabber_fallback_on_old_auth.diff is in im.pidgin.pidgin but not the 2.3.1 branch; diff from 2e5cda103238f64d27e4ed5aa92c149f6d50a5ec to 16e6cd4ffd8a8308380dc016f0afa782a7750374 -evands 12/07
# libpurple_jabber_use_builtin_digestmd5.diff is in im.pidgin.pidgin but not the 2.3.1 branch; diff from 16e6cd4ffd8a8308380dc016f0afa782a7750374 to f6430c7013d08f95c60248eeb22c752a0107499b -evands 12/07
###
# Patches for our own hackery
#
# libpurple_jabber_avoid_sasl_option_hack.diff is needed to avoid using PLAIN via SASL on Mac OS X 10.4, where it doesn't work properly
# libpurple_makefile_linkage_hacks.diff fixes some linkage problems
###
for patch in "$PATCHDIR/libpurple_makefile_linkage_hacks.diff" \
             "$PATCHDIR/libpurple-restrict-potfiles-to-libpurple.diff" \
             "$PATCHDIR/libpurple_jabber_use_builtin_digestmd5.diff" \
             "$PATCHDIR/libpurple_jabber_fallback_on_old_auth.diff" ; do
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
	
	#Get access to the sasl headers
    mkdir -p $TARGET_DIR/include/sasl || true
	cp $PATCHDIR/cyrus-sasl-2.1.18/include/*.h $TARGET_DIR/include/sasl

    export CFLAGS="$BASE_CFLAGS -arch $ARCH -I$TARGET_DIR/include -I$SDK_ROOT/usr/include/kerberosIV -DHAVE_SSL -fno-common"
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
	$PIDGIN_SOURCE/configure \
	        --disable-gtkui --disable-consoleui \
            --disable-perl \
            --enable-debug \
            --disable-static --enable-shared \
            --enable-krb4 \
            --enable-cyrus-sasl \
            --prefix=$TARGET_DIR \
            --with-static-prpls="$PROTOCOLS" --disable-plugins \
            --host=$HOST \
            --enable-gnutls=no --enable-nss=no --enable-openssl=no $@
    cd libpurple
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
for patch in "$PATCHDIR/libpurple_makefile_linkage_hacks.diff" \
             "$PATCHDIR/libpurple-restrict-potfiles-to-libpurple.diff" \
             "$PATCHDIR/libpurple_jabber_use_builtin_digestmd5.diff" \
             "$PATCHDIR/libpurple_jabber_fallback_on_old_auth.diff" ; do
	patch -R -p0 < $patch
done
popd
