#!/bin/sh

source common.sh
setupDirStructure
cd "$BUILDDIR"

# create universal libraries for AdiumDeps.
# "top-level" deps
LIBINTL=libintl.8
LIBGLIB=libglib-2.0.0
LIBGOBJECT=libgobject-2.0.0
LIBGTHREAD=libgthread-2.0.0
LIBGMODULE=libgmodule-2.0.0

# "purple" deps
MEANWHILE=libmeanwhile.1
GADU=libgadu.3.7.0
SASL=libsasl2.2

PURPLE_VERSION=0.5.0

LIBPURPLE=libpurple.$PURPLE_VERSION
PURPLE_FOLDER=libpurple-$PURPLE_VERSION

SCRIPT_DIR=$BASEDIR

# Copy the headers to the universal dir so that we can put them in the frameworks 
# once they are built. We stick the required headers for each framework into its own folder
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

rm -rf $UNIVERSAL_DIR/include/$PURPLE_FOLDER
cp -R $TARGET_DIR_I386/include/libpurple $UNIVERSAL_DIR/include/$PURPLE_FOLDER
# Another hack: we need libgadu.h
cp $TARGET_DIR_I386/include/libgadu.h $UNIVERSAL_DIR/include/$PURPLE_FOLDER/libgadu-i386.h
cp $TARGET_DIR_PPC/include/libgadu.h $UNIVERSAL_DIR/include/$PURPLE_FOLDER/libgadu-ppc.h
cp $SCRIPT_DIR/libgadu.h $UNIVERSAL_DIR/include/$PURPLE_FOLDER/
cd ..

cd $UNIVERSAL_DIR

for lib in $LIBINTL $LIBGLIB $LIBGOBJECT $LIBGTHREAD $LIBGMODULE $MEANWHILE \
           $GADU $LIBPURPLE; do
	echo "Making $lib universal..."
	python $SCRIPT_DIR/framework_maker/universalize.py \
	  i386:$TARGET_DIR_I386/lib/$lib.dylib \
	  ppc:$TARGET_DIR_PPC/lib/$lib.dylib \
	  $UNIVERSAL_DIR/$lib.dylib \
	  $TARGET_DIR_PPC/lib:$UNIVERSAL_DIR \
      $TARGET_DIR_I386/lib:$UNIVERSAL_DIR
done

#	echo "Making libmsn-pecan.so universal..."
#	python  $SCRIPT_DIR/framework_maker/universalize.py \
#	  i386:$TARGET_DIR_I386/lib/purple-2/libmsn-pecan.so \
#	  ppc:$TARGET_DIR_PPC/lib/purple-2/libmsn-pecan.so \
#	  $UNIVERSAL_DIR/libmsn-pecan.so \
#	  $TARGET_DIR_PPC/lib:$UNIVERSAL_DIR \
#      $TARGET_DIR_I386/lib:$UNIVERSAL_DIR

cd ..

export PATH="$PATH:$SCRIPT_DIR/rtool_trunk"
echo "Making a framework for $PURPLE_FOLDER and all dependencies..."
python $SCRIPT_DIR/framework_maker/frameworkize.py $UNIVERSAL_DIR/$LIBPURPLE.dylib $PWD/Frameworks

#msn pecan
# install_name_tool -change $UNIVERSAL_DIR/libmsn-pecan.so @executable_path/../Frameworks/Resources/libmsn-pecan.so $UNIVERSAL_DIR/libmsn-pecan.so
# install_name_tool -change $UNIVERSAL_DIR/libpurple.0.dylib @executable_path/../Frameworks/libpurple.framework/Versions/Current/libpurple $UNIVERSAL_DIR/libmsn-pecan.so
# install_name_tool -change $UNIVERSAL_DIR/libglib-2.0.0.dylib @executable_path/../Frameworks/libglib.framework/Versions/Current/libglib $UNIVERSAL_DIR/libmsn-pecan.so
# install_name_tool -change $UNIVERSAL_DIR/libgobject-2.0.0.dylib @executable_path/../Frameworks/libgobject.framework/Versions/Current/libgobject $UNIVERSAL_DIR/libmsn-pecan.so

echo "Adding the Adium framework header."
cp $SCRIPT_DIR/libpurple-full.h $PWD/Frameworks/libpurple.framework/Headers/libpurple.h

cp $SCRIPT_DIR/Libpurple-Info.plist $PWD/Frameworks/libpurple.framework/Resources/Info.plist

echo "Done - now run ./make_po_files.sh (if necessary) then ./copy_frameworks.sh"