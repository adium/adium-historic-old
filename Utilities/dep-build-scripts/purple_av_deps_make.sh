#!/bin/bash
LIBOGG=libogg-1.1.3
LIBVORBIS=libvorbis-1.2.0
LIBSPEEX=speex-1.0.5

mkdir -p build/universal
cd build

SDK_ROOT="/Developer/SDKs/MacOSX10.4u.sdk"
BASE_CFLAGS="-mmacosx-version-min=10.4 -isysroot $SDK_ROOT"
BASE_LDFLAGS="-mmacosx-version-min=10.4 -headerpad_max_install_names -Wl,-syslibroot,$SDK_ROOT"

NUMBER_OF_CORES=`sysctl -n hw.activecpu`

TARGET_DIR_PPC="$PWD/root-ppc"
TARGET_DIR_I386="$PWD/root-i386"
TARGET_DIR_BASE="$PWD/root"
export PATH_USER="$PATH"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"

#libogg
for ARCH in ppc i386 ; do
    export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
    mkdir -p libogg-$ARCH
    cd libogg-$ARCH
    export ARCH
	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386";;
	esac
    ../../$LIBOGG/configure --prefix=$TARGET_DIR 
	# We edit libtool before we run make. This is evil and makes me sad.
    cat libtool | sed 's%archive_cmds="\\\$CC%archive_cmds="\\\$CC -mmacosx-version-min=10.4 -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk -arch '$ARCH'%' > libtool.tmp
    mv libtool.tmp libtool
    make -j $NUMBER_OF_CORES && make install
    cd ..
done


#libvorbis
for ARCH in ppc i386 ; do
    export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
    mkdir -p libvorbis-$ARCH
    cd libvorbis-$ARCH
    export ARCH
	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386";;
	esac
    ../../$LIBVORBIS/configure --prefix=$TARGET_DIR 
    make -j $NUMBER_OF_CORES && make install
    cd ..
done

#libspeex
for ARCH in ppc i386 ; do
    export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
    mkdir -p libspeex-$ARCH
    cd libspeex-$ARCH
    export ARCH
	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386";;
	esac
    ../../$LIBSPEEX/configure --prefix=$TARGET_DIR --with-ogg-dir=$TARGET_DIR
    make -j $NUMBER_OF_CORES && make install
    cd ..
done

#libtheora
#taglib
#liboil (patches?)
#gstreamer
