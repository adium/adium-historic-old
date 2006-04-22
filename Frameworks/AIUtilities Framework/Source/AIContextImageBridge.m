//
//  AIContextImageBridge.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Thu Feb 12 2004.
//

#import "AIContextImageBridge.h"

@interface AIContextImageBridge(PRIVATE)
@end

enum {
	defaultBitsPerComponent = 8,
	defaultComponentsPerPixel = 4,
};
const BOOL defaultHasAlpha = YES;

/*!
 * @class AIContextImageBridge
 * @brief Used to translate between Quartz and NSImage.
 *
 * Quick-start for <tt>AIContextImageBridge</tt>:
 * 
 * 1. Create a bridge.
 * 	AIContextImageBridge *bridge = [AIContextImageBridge bridgeWithSize:NSMakeSize(42.0f, 10.0f)];
 * 
 * 2. Obtain the context. The context is retained for you (see below).
 * 	CGContextRef context = [bridge context];
 * 
 * 3. Draw into the context. (note: it is a bitmap context, so you cannot use PDF functions on it.)
 * 
 * 4. Call image. If you call image more than once, the image will not be re-created (although, since the image uses the same backing store as the context, this should not be a problem).
 * 	NSImage *image = [bridge image];
 * 
 * You can obtain greater control over the bridge by initing it using initWithSize:bitsPerComponent:componentsPerPixel:hasAlpha:.
 * 
 * If you use bridgeWithSize:, the bridge is autoreleased.
 * 
 * The <tt>Icon Services</tt> interfaces gives you a nice Cocoa interface for drawing icons in the context.
 * They come in full and abstracted flavours.
 * 
 * Summary of Icon Services methods (without types):
 * - wrapping GetIconRef:
 *   getIconWithType:
 *   getIconWithType:creator:
 * - wrapping other GetIconRef functions:
 *   [future expansion]
 * - wrapping PlotIconRefInContext:
 *   plotIcon:inRect:
 *   plotIcon:inRect:alignment:transform:labelNSColor:flags:
 *   plotIcon:inRect:alignment:transform:labelIndex:flags:
 *   plotIcon:inRect:alignment:transform:labelRGBColor:flags:
 * 
 * For more information, read the Icon Services documentation. They all return the status code returned from the Carbon calls on which these methods are based.<br>
 */
@implementation AIContextImageBridge

/*!
 * @brief Init a <tt>AIContextImageBridge</tt> with higher granularity of control
 * 
 * The initialized bridge will use 32-bit RGBA.
 */
- (id)initWithSize:(NSSize)size
{
	return [self initWithSize:size bitsPerComponent:defaultBitsPerComponent componentsPerPixel:defaultComponentsPerPixel hasAlpha:defaultHasAlpha];
}

/*!
 * @brief Init a <tt>AIContextImageBridge</tt> with finer granularity of control
 * 
 *	If hasAlpha is true, one of the components counted is an alpha component. For example:<br>
 * 			hasAlpha	componentsPerPixel	result<br>
 * 			YES			4U					RGBA<br>
 * 			NO			3U					RGB<br>
 * @return  An initialised <tt>AIContextImageBridge</tt> object
 */
- (id)initWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha
{
	unsigned bytesPerRow = (sizeof(unsigned char) * ((bpc / 8) * cpp)) * (unsigned)size.width;

	//we use calloc because it fills the buffer with 0 - that includes the
	//  alpha, so when calloc is done, the buffer is filled with transparent.
	buffer = calloc(bytesPerRow * (unsigned)size.height, sizeof(unsigned char));
	if (buffer == NULL) return nil;

	CGColorSpaceRef deviceRGB = CGColorSpaceCreateDeviceRGB();
	if (deviceRGB == NULL) {
		free(buffer);
		return nil;
	}

	context = CGBitmapContextCreate(buffer, size.width, size.height, bpc, bytesPerRow, deviceRGB, hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone);
	CFRelease(deviceRGB);
	if (context == NULL) {
		free(buffer);
		return nil;
	}

	image = nil;
	mysize = size;
	mybitsPerComponent = bpc;
	mycomponentsPerPixel = cpp;
	myhasAlpha = hasAlpha;

	return self;
}

/*!
 * @brief Create an autoreleased <tt>AIContextImageBridge</tt>
 */
+ (id)bridgeWithSize:(NSSize)size
{
	return [[[self alloc] initWithSize:size] autorelease];
}

/*!
 * @brief Create an autoreleased <tt>AIContextImageBridge</tt> with finer granularity of control
 */
+ (id)bridgeWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha
{
	return [[[self alloc] initWithSize:size
					  bitsPerComponent:defaultBitsPerComponent
					componentsPerPixel:defaultComponentsPerPixel
							  hasAlpha:defaultHasAlpha] autorelease];
}

- (void)dealloc
{
	if (buffer) free(buffer);
	if (context) CGContextRelease(context);
	[image release];

	[super dealloc];
}

#pragma mark Accessors

/*!
 * @brief Access the raw bytes that back the image</tt>
 */
- (unsigned char *)buffer;
{
	return buffer;
}

/*!
 * @brief Access the Quartz context for the image
 *
 * This method retains the context on the behalf of the caller. It is the caller's responsibility to release it.
 */
- (CGContextRef)context;
{
	CGContextRetain(context);
	return context;
}

/*!
 * @brief Obtain an <tt>NSImage</tt>
 *
 * The image may be cached. If you have made changes to the context, call <tt>-refreshImage</tt> instead.
 * If the image hasn't been created yet, we call refreshImage to create it.
 * If it has been created, we return that image.
 */
- (NSImage *)image;
{
	if (image == nil) {
		unsigned bitsPerPixel = mybitsPerComponent  * mycomponentsPerPixel;
		unsigned bytesPerRow  = (bitsPerPixel / 8U) * mysize.width;
		NSBitmapImageRep *representation = [[[NSBitmapImageRep alloc]
							initWithBitmapDataPlanes:&buffer
							pixelsWide:mysize.width
							pixelsHigh:mysize.height
							bitsPerSample:mybitsPerComponent
							samplesPerPixel:mycomponentsPerPixel
							hasAlpha:myhasAlpha
							isPlanar:NO
							colorSpaceName:NSDeviceRGBColorSpace
							bytesPerRow:bytesPerRow
							bitsPerPixel:bitsPerPixel] autorelease];
		image = [[NSImage alloc] initWithSize:mysize];
		[image addRepresentation:representation];
	}
	return image;
}

/*!
 * @brief Access the number of bits per component in the image
 *
 * For example, a 32-bit RGBA image has 8 bits per component.
 */
- (unsigned)bitsPerComponent
{
	return mybitsPerComponent;
}

/*!
 * @brief Access the number of components per pixel in the image
 *
 * This includes the alpha component, if any. For example, a 32-bit RGBA image has 4 components per pixel.
 */
- (unsigned)componentsPerPixel
{
	return mycomponentsPerPixel;
}

/*!
 * @brief Access the pixel dimensions of the image
 */
- (NSSize)size
{
	return mysize;
}

#pragma mark Icon Services interfaces
//Icon Services interfaces.
//gives you a nice Cocoa interface for drawing icons in the context.
//comes in full and abstracted flavours.

/*!
 * @brief Obtain a Carbon IconRef for an HFS file type
 *
 * This is the same as calling <code>getIconWithType:type creator:kSystemIconsCreator</code>.
 *
 * The caller is responsible for releasing the IconRef.
 */
- (IconRef)getIconWithType:(OSType)type
{
	return [self getIconWithType:type creator:0];
}

/*!
 * @brief Obtain a Carbon IconRef for an HFS file type and creator code
 *
 * For example, <code>getIconWithType:'AAPL' creator:'hook'</code> returns the icon for iTunes.
 *
 * The caller is responsible for releasing the IconRef.
 */
- (IconRef)getIconWithType:(OSType)type creator:(OSType)creator
{
	IconRef icon;
	OSStatus err;

	err = GetIconRef(kOnSystemDisk, creator, type, &icon);
	return (err == noErr) ? icon : NULL;
}

/*!
 * @brief Plot a Carbon icon into the image
 *
 * Calls through to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code> with NULL as the colour.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds
{
	OSStatus err = [self plotIcon:icon inRect:bounds alignment:kAlignNone transform:kTransformNone labelRGBColor:NULL flags:kPlotIconRefNormalFlags];

	return err;
}

/*!
 * @brief Plot a Carbon icon into the image with finer granularity of control
 *
 * The NSColor must be in an RGB colour space.
 *
 * Calls through to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags
{
	RGBColor  rgb;
	RGBColor *rgbptr;
	if (color != nil) {
		float red, green, blue;
		[color getRed:&red green:&green blue:&blue alpha:NULL];
		rgb.red   = 65535 * red;
		rgb.green = 65535 * green;
		rgb.blue  = 65535 * blue;
		rgbptr = &rgb;
	} else {
		rgbptr = NULL;
	}

	return [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:rgbptr flags:flags];
}

/*!
 * @brief Plot a Carbon icon into the image with finer granularity of control
 *
 * The label index is one you would pass to Icon Services' GetLabel function (i.e. an integer from 1 to 7).
 *
 * Calls through to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags
{
	RGBColor rgb;
	OSStatus err;

	err = GetLabel(label, &rgb, /*labelString*/ NULL);
	if (err == noErr) {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:&rgb flags:flags];
	}

	return err;
}

/*!
 * @brief Plot a Carbon icon into the image with finer granularity of control
 *
 * @param align An alignment type from Icon Services. See <tt>HIServices/Icons.h></tt>.
 * @param transform A transform type from Icon Services. See <tt>HIServices/Icons.h></tt>.
 * @param color A pointer to a Carbon RGBColor structure. RGBColors have three unsigned 16-bit components (no alpha), which range from 0 to 65535.
 * @param flags Plot flags from Icon Services. See <tt>HIServices/Icons.h></tt>. Usually you will pass kPlotIconRefNormalFlags here.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags
{
	if (icon == NULL) return NO;

	CGRect cgbounds = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);

	OSStatus err = PlotIconRefInContext(context, &cgbounds, align, transform, color, flags, icon);

	return err;
}

#pragma mark Icon Services conveniences

//conveniences.
//these substitute plotIconWithType: and plotIconWithType:creator: for
//  plotIcon: above.

#pragma mark ...without creator

/*!
 * @brief Plot an icon into the image
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to
 * <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code> with NULL as the colour.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds
{
	IconRef icon = [self getIconWithType:type];

	if (icon == NULL) {
		return noSuchIconErr;
	} else {
		OSStatus err = [self plotIcon:icon inRect:bounds];
		ReleaseIconRef(icon);
		return err;
	}
}

/*!
* @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that 
 * to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The NSColor must be in an RGB colour space.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags
{
	[color retain];

	IconRef icon = [self getIconWithType:type];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelNSColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	[color release];

	return err;
}

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelIndex:flags:</code>.
 *
 * The label index is one you would pass to Icon Services' GetLabel function (i.e. an integer from 1 to 7).
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelIndex:label flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

#pragma mark ...with creator

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:</code>.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds
{
	IconRef icon = [self getIconWithType:type creator:creator];

	if (icon == NULL) {
		return noSuchIconErr;
	} else {
		OSStatus err = [self plotIcon:icon inRect:bounds];
		ReleaseIconRef(icon);
		return err;
	}
}

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The NSColor must be in an RGB colour space.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags
{
	[color retain];

	IconRef icon = [self getIconWithType:type creator:creator];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelNSColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	[color release];

	return err;
}

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The label index is one you would pass to Icon Services' GetLabel function (i.e. an integer from 1 to 7).
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type creator:creator];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelIndex:label flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to
 * <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type creator:creator];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

@end
