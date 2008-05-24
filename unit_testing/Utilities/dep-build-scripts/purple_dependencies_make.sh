MEANWHILE=meanwhile-1.0.2
GADU=libgadu-1.7.1
INTLTOOL=intltool-0.36.2

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
export PATH_USER="$PATH"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"

# Meanwhile
# Apply patches
pushd ../$MEANWHILE
patch --forward -p1 < ../meanwhile_ft_newservers_fix_1626349.diff
patch --forward -p1 < ../meanwhile_prescence_newservers_fix_1626349.diff
popd

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
    cat libtool | sed 's%archive_cmds="\\\$CC%archive_cmds="\\\$CC -mmacosx-version-min=10.4 -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk -arch '$ARCH'%' > libtool.tmp
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
