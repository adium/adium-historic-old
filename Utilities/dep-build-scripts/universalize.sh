#create universal libraries for AdiumDeps.
# "top-level" deps
LIBINTL=libintl.8.dylib
LIBGLIB=libglib-2.0.0.dylib
LIBGOBJECT=libgobject-2.0.0.dylib
LIBGTHREAD=libgthread-2.0.0.dylib
LIBGMODULE=libgmodule-2.0.0.dylib

# "purple" deps
MEANWHILE=libmeanwhile.1.dylib
GADU=libgadu.3.7.0.dylib
SASL=libsasl2.2.dylib
PURPLE=libpurple.0.2.3.dylib


SCRIPT_DIR=$PWD

mkdir build || true
cd build

TARGET_DIR_PPC="$PWD/root-ppc"
TARGET_DIR_I386="$PWD/root-i386"
TARGET_DIR_BASE="$PWD/root"

mkdir universal || true
UNIVERSAL_DIR="$PWD/universal"

# Copy the headers to the universal dir so that we can put them in the frameworks once they are built. We stick the required headers for each framework into it's own folder
# named after the project to keep the frameworkize script library independent.

mkdir $UNIVERSAL_DIR/include || true
cd $UNIVERSAL_DIR/include

mkdir libintl-8 || true
cp $TARGET_DIR_I386/include/libintl.h $UNIVERSAL_DIR/include/libintl-8/

mkdir libglib-2.0.0 || true
cp -R $TARGET_DIR_I386/include/glib-2.0 $UNIVERSAL_DIR/include/libglib-2.0.0/
cp $TARGET_DIR_I386/lib/glib-2.0/include/glibconfig.h \
    $UNIVERSAL_DIR/include/libglib-2.0.0/glib-2.0/glibconfig-i386.h
cp $TARGET_DIR_PPC/lib/glib-2.0/include/glibconfig.h \
    $UNIVERSAL_DIR/include/libglib-2.0.0/glib-2.0/glibconfig-ppc.h
cp $SCRIPT_DIR/glibconfig.h $UNIVERSAL_DIR/include/libglib-2.0.0/glib-2.0

mkdir libgmodule-2.0.0 || true
cp $TARGET_DIR_I386/include/glib-2.0/gmodule.h $UNIVERSAL_DIR/include/libgmodule-2.0.0/

mkdir libgobject-2.0.0 || true
cp $TARGET_DIR_I386/include/glib-2.0/glib-object.h $UNIVERSAL_DIR/include/libgobject-2.0.0/
cp -R $TARGET_DIR_I386/include/glib-2.0/gobject/ $UNIVERSAL_DIR/include/libgobject-2.0.0/

mkdir libgthread-2.0.0 || true
# no headers to copy, make an empty file so that rtool isn't sad
touch libgthread-2.0.0/no_headers_here.txt

rm -rf $UNIVERSAL_DIR/include/libpurple-0.2.3
cp -R $TARGET_DIR_I386/include/libpurple $UNIVERSAL_DIR/include/libpurple-0.2.3
# Another hack: we need libgadu.h
cp $TARGET_DIR_I386/include/libgadu.h $UNIVERSAL_DIR/include/libpurple-0.2.3/libgadu-i386.h
cp $TARGET_DIR_PPC/include/libgadu.h $UNIVERSAL_DIR/include/libpurple-0.2.3/libgadu-ppc.h
cp $SCRIPT_DIR/libgadu.h $UNIVERSAL_DIR/include/libpurple-0.2.3/
cd ..

cd $UNIVERSAL_DIR

for lib in $LIBINTL $LIBGLIB $LIBGOBJECT $LIBGTHREAD $LIBGMODULE $MEANWHILE \
           $GADU $SASL $PURPLE; do
	echo "Making $lib universal..."
	python  $SCRIPT_DIR/framework_maker/universalize.py \
	  i386:$TARGET_DIR_I386/lib/$lib \
	  ppc:$TARGET_DIR_PPC/lib/$lib \
	  $UNIVERSAL_DIR/$lib \
	  $TARGET_DIR_PPC/lib:$UNIVERSAL_DIR \
      $TARGET_DIR_I386/lib:$UNIVERSAL_DIR
done

cd ..

export PATH="$PATH:$SCRIPT_DIR/rtool_trunk"
echo "Making a framework for $PURPLE and all dependencies..."
python $SCRIPT_DIR/framework_maker/frameworkize.py $UNIVERSAL_DIR/libpurple.0.2.3.dylib $PWD/Frameworks

echo "Adding the Adium framework header."
cp $SCRIPT_DIR/libpurple-full.h \
   $PWD/Frameworks/libpurple.framework/Headers/libpurple.h
