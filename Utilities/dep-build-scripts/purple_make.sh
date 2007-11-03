GLIB=glib-2.14.1
MEANWHILE=meanwhile-1.0.2
GADU=libgadu-1.7.1
SASL=cyrus-sasl-2.1.21
INTLTOOL=intltool-0.36.2

BASE_CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk"
BASE_LDFLAGS="-headerpad_max_install_names -Wl,-syslibroot,/Developer/SDKs/MacOSX10.5.sdk"

NUMBER_OF_CORES=`sysctl -n hw.activecpu`

mkdir build || true
cd build
mkdir universal || true

TARGET_DIR_PPC="$PWD/root-ppc"
TARGET_DIR_I386="$PWD/root-i386"
TARGET_DIR_BASE="$PWD/root"
export PATH_USER="$PATH"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"

# Meanwhile
for ARCH in ppc i386 ; do
    export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
    mkdir meanwhile-$ARCH || true
    cd meanwhile-$ARCH
	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386";;
	esac
    ../../$MEANWHILE/configure --prefix=$TARGET_DIR --enable-static\
      --enable-shared --disable-doxygen --disable-mailme
    # We edit libtool before we run make. This is evil and makes me sad.
    cat libtool | sed 's%archive_cmds="\\\$CC%archive_cmds="\\\$CC -Wl,-syslibroot,/Developer/SDKs/MacOSX10.5.sdk -arch '$ARCH'%' > libtool.tmp
    mv libtool.tmp libtool
    make -j $NUMBER_OF_CORES && make install
    cd ..
done

# Gadu-gadu
for ARCH in ppc i386 ; do
	export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
	case $ARCH in
		ppc) HOST=powerpc-apple-darwin9
			 export PATH="$PATH_PPC"
			 TARGET_DIR="$TARGET_DIR_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig";;
		i386) HOST=i686-apple-darwin9
  		      TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig";;
	esac
	mkdir gadu-$ARCH || true
	cd gadu-$ARCH
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH
	../../$GADU/configure --prefix=$TARGET_DIR \
	    --enable-shared --host=$HOST
	make -j $NUMBER_OF_CORES && make install
	cd ..
done

# Cyrus-SASL
# Apply our patch
pushd ../$SASL
patch -p1 < ../$SASL.patch
popd

for ARCH in ppc i386 ; do
    export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
    mkdir cyrus-sasl-$ARCH || true
    cd cyrus-sasl-$ARCH
    case $ARCH in
        ppc) HOST=powerpc-apple-darwin8
             TARGET_DIR="$TARGET_DIR_PPC" ;;
        i386) HOST=i686-apple-darwin8 
             TARGET_DIR="$TARGET_DIR_I386" ;;
    esac
    # In my experience, --enable-static horks things. Not sure why. Be careful
    # if you turn it back on. Check things with a completely clean build.
    ../../$SASL/configure --prefix=$TARGET_DIR --disable-static \
      --enable-shared --disable-macos-framework --host=$HOST
    # EVIL HACK ALERT: http://www.theronge.com/2006/04/15/how-to-compile-cyrus-sasl-as-universal/
    # We edit libtool before we run make. This is evil and makes me sad.
    cat libtool | sed 's%archive_cmds="\\\$CC%archive_cmds="\\\$CC -Wl,-syslibroot,/Developer/SDKs/MacOSX10.5.sdk -arch '$ARCH'%' > libtool.tmp
    mv libtool.tmp libtool
    make -j $NUMBER_OF_CORES && make install
    cd ..
done

# Deapply our patch
pushd ../$SASL
patch -p1 -R < ../$SASL.patch
popd

# intltool so pidgin will configure
# need a native intltool in both ppc and i386
for ARCH in ppc i386 ; do
    mkdir intltool-$ARCH || true
    cd intltool-$ARCH
    case $ARCH in
        ppc) TARGET_DIR="$TARGET_DIR_PPC" ;;
        i386) TARGET_DIR="$TARGET_DIR_I386" ;;
    esac
    ../../$INTLTOOL/configure --prefix=$TARGET_DIR
    make -j $NUMBER_OF_CORES && make install
    cd ..
done
