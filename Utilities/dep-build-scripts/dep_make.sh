#!/bin/sh
LOG_FILE=$PWD/dep_make.log
echo "Beginning build at" `date` > $LOG_FILE 2>&1

PKGCONFIG=pkg-config-0.22
GETTEXT=gettext-0.16.1
GLIB=glib-2.14.1

BASE_CFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.4u.sdk"
BASE_LDFLAGS="-mmacosx-version-min=10.4 -headerpad_max_install_names -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk"

NUMBER_OF_CORES=`sysctl -n hw.activecpu`

mkdir build >/dev/null 2>&1 || true
cd build
mkdir universal >/dev/null 2>&1 || true

TARGET_DIR_PPC="$PWD/root-ppc"
TARGET_DIR_I386="$PWD/root-i386"
TARGET_DIR_BASE="$PWD/root"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"

#pkg-config
# We only need a native pkg-config, it's not a runtime dependency,
# but we need a native one in both directories
#unset CFLAGS
echo 'Building pkg-config for i386...'
TARGET_DIR=$TARGET_DIR_I386
mkdir pkg-config-`arch` >/dev/null 2>&1 || true
cd pkg-config-`arch`
echo '  Configuring...'
../../$PKGCONFIG/configure --prefix="$TARGET_DIR" >> $LOG_FILE 2>&1
echo '  make && make install'
make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
cd ..

echo 'pkg-config for ppc...'
TARGET_DIR=$TARGET_DIR_PPC
mkdir pkg-config-`arch` >/dev/null 2>&1 || true
cd pkg-config-`arch`
echo '  Configuring...'
../../$PKGCONFIG/configure --prefix="$TARGET_DIR" >> $LOG_FILE 2>&1
echo '  make && make install'
make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
cd ..

#gettext
# caveat - some of the build files in gettext appear to not respect CFLAGS
# and are compiling to `arch` instead of $ARCH. Lame.
for ARCH in ppc i386 ; do
	echo "Building gettext for $ARCH"
	export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
	case $ARCH in
		ppc) HOST=powerpc-apple-darwin8
			 export PATH=$PATH_PPC;;
		i386) HOST=i686-apple-darwin8
			  export PATH=$PATH_I386;;
	esac
	mkdir gettext-$ARCH >/dev/null 2>&1 || true
	cd gettext-$ARCH
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH
	echo '  Configuring...'
	../../$GETTEXT/configure --prefix=$TARGET_DIR --disable-static \
	    --enable-shared --host=$HOST >> $LOG_FILE 2>&1
	echo '  make && make install'
	make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
	cd ..
done

#glib
for ARCH in ppc i386; do
	echo "Building glib for $ARCH"
	LOCAL_BIN_DIR="$TARGET_DIR_BASE-$ARCH/bin"
	LOCAL_LIB_DIR="$TARGET_DIR_BASE-$ARCH/lib"
	LOCAL_INCLUDE_DIR="$TARGET_DIR_BASE-$ARCH/include"
	LOCAL_FLAGS="-L$LOCAL_LIB_DIR -I$LOCAL_INCLUDE_DIR -lintl -liconv"
	export PKG_CONFIG="$LOCAL_BIN_DIR/pkg-config"
	export MSGFMT="$LOCAL_BIN_DIR/msgfmt"
	
	export CFLAGS="$LOCAL_FLAGS $BASE_CFLAGS -arch $ARCH"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="$LOCAL_FLAGS $BASE_LDFLAGS -arch $ARCH"
	case $ARCH in
		ppc) HOST=powerpc-apple-darwin8;;
		i386) HOST=i686-apple-darwin8;;
	esac
	mkdir glib-$ARCH >/dev/null 2>&1 || true
	cd glib-$ARCH
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH
	echo '  Configuring...'
	../../$GLIB/configure \
	   --prefix=$TARGET_DIR \
	   --with-libiconv \
	   --disable-static --enable-shared \
	   --host=$HOST >> $LOG_FILE 2>&1
	echo '  make && make install'
	make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
	cd ..
done

#libogg
#libvorbis
#libspeex
#libtheora
#taglib
#liboil - 3 patches
#gstreamer
#gst-plugins-base
#gst-plugins-good
#gst-plugins-bad
