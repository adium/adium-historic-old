//
//  BZContextImageBridge.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Thu Feb 12 2004.
//

/*!
 * @class BZContextImageBridge
 * @brief Used to translate between Quartz and NSImage.
 *
 * Quick-start for <tt>BZContextImageBridge</tt>:
 * 
 * 1. Create a bridge.
 * 	BZContextImageBridge *bridge = [BZContextImageBridge bridgeWithSize:NSMakeSize(42.0f, 10.0f)];
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

@interface BZContextImageBridge : NSObject
{
	unsigned char *buffer; //the backing store for both the context and the image representation.
	CGContextRef context;
	NSImage *image;
@private
//	NSBitmapImageRep *representation;
	NSSize mysize;
	unsigned mybitsPerComponent; //defaults to 8U.
	unsigned mycomponentsPerPixel; //defaults to 4U.
	BOOL myhasAlpha; //defaults to YES.
}

/*!
 * @brief Init a <tt>BZContextImageBridge</tt> with higher granularity of control
 * 
 * The initialised bridge will use 32-bit RGBA.
 */
- (id)initWithSize:(NSSize)size;

/*!
 * @brief Init a <tt>BZContextImageBridge</tt> with finer granularity of control
 * 
 *	If hasAlpha is true, one of the components counted is an alpha component. For example:<br>
 * 			hasAlpha	componentsPerPixel	result<br>
 * 			YES			4U					RGBA<br>
 * 			NO			3U					RGB<br>
 * @return  An initialised <tt>BZContextImageBridge</tt> object
 */
- (id)initWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;

/*!
 * @brief Create an autoreleased <tt>BZContextImageBridge</tt>
 */
+ (id)bridgeWithSize:(NSSize)size;
/*!
 * @brief Create an autoreleased <tt>BZContextImageBridge</tt> with finer granularity of control
 */
+ (id)bridgeWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;

#pragma mark Accessors

/*!
 * @brief Access the raw bytes that back the image</tt>
 */
- (unsigned char *)buffer;

/*!
 * @brief Access the Quartz context for the image
 *
 * This method retains the context on the behalf of the caller. It is the caller's responsibility to release it.
 */
- (CGContextRef)context;

//if the image hasn't been created yet, image calls refreshImage to create it.
//if it has been created, it returns that image.
//call refreshImage yourself if you want a guaranteed-current image (at the possible expense of performance).
//either way, the image is autoreleased.

/*!
 * @brief Obtain an <tt>NSImage</tt>
 *
 * The image may be cached. If you have made changes to the context, call <tt>-refreshImage</tt> instead.
 */
- (NSImage *)image;
/*!
 * @brief Obtain a guaranteed-current <tt>NSImage</tt>
 *
 * The image is (re)generated whenever this method is called. For this reason, you may wish to use <tt>-image</tt> instead if performance is an issue.
 */
- (NSImage *)refreshImage;

/*!
 * @brief Access the number of bits per component in the image
 *
 * For example, a 32-bit RGBA image has 8 bits per component.
 */
- (unsigned)bitsPerComponent;
/*!
 * @brief Access the number of components per pixel in the image
 *
 * This includes the alpha component, if any. For example, a 32-bit RGBA image has 4 components per pixel.
 */
- (unsigned)componentsPerPixel;
/*!
 * @brief Access the pixel dimensions of the image
 */
- (NSSize)size;

//Icon Services interfaces.
//gives you a nice Cocoa interface for drawing icons in the context.
//comes in full and abstracted flavours.

/*easy summary of methods (without types):
 *wrapping GetIconRef:
 *  getIconWithType:
 *  getIconWithType:creator:
 *wrapping other GetIconRef functions:
 *  [future expansion]
 *wrapping PlotIconRefInContext:
 *	plotIcon:inRect:
 *	plotIcon:inRect:alignment:transform:labelNSColor:flags:
 *	plotIcon:inRect:alignment:transform:labelIndex:flags:
 *	plotIcon:inRect:alignment:transform:labelRGBColor:flags:
 *for more information, read the Icon Services documentation.
 *they all return the status code returned from the Carbon calls on which these
 *  methods are based.
 */

/*!
 * @brief Obtain a Carbon IconRef for an HFS file type
 *
 * This is the same as calling <code>getIconWithType:type creator:kSystemIconsCreator</code>.
 *
 * The caller is responsible for releasing the IconRef.
 */
- (IconRef)getIconWithType:(OSType)type;
/*!
 * @brief Obtain a Carbon IconRef for an HFS file type and creator code
 *
 * For example, <code>getIconWithType:'AAPL' creator:'hook'</code> returns the icon for iTunes.
 *
 * The caller is responsible for releasing the IconRef.
 */
- (IconRef)getIconWithType:(OSType)type creator:(OSType)creator;

/*!
 * @brief Plot a Carbon icon into the image
 *
 * Calls through to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code> with NULL as the colour.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds;
/*!
 * @brief Plot a Carbon icon into the image with finer granularity of control
 *
 * The NSColor must be in an RGB colour space.
 *
 * Calls through to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
/*!
 * @brief Plot a Carbon icon into the image with finer granularity of control
 *
 * The label index is one you would pass to Icon Services' GetLabel function (i.e. an integer from 1 to 7).
 *
 * Calls through to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
/*!
 * @brief Plot a Carbon icon into the image with finer granularity of control
 *
 * @param align An alignment type from Icon Services. See <tt>HIServices/Icons.h></tt>.
 * @param transform A transform type from Icon Services. See <tt>HIServices/Icons.h></tt>.
 * @param color A pointer to a Carbon RGBColor structure. RGBColors have three unsigned 16-bit components (no alpha), which range from 0 to 65535.
 * @param flags Plot flags from Icon Services. See <tt>HIServices/Icons.h></tt>. Usually you will pass kPlotIconRefNormalFlags here.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

//conveniences.
//these substitute plotIconWithType: and plotIconWithType:creator: for
//  plotIcon: above.

/*!
 * @brief Plot an icon into the image
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code> with NULL as the colour.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds;
/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The NSColor must be in an RGB colour space.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The label index is one you would pass to Icon Services' GetLabel function (i.e. an integer from 1 to 7).
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds;
/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The NSColor must be in an RGB colour space.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 *
 * The label index is one you would pass to Icon Services' GetLabel function (i.e. an integer from 1 to 7).
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
/*!
 * @brief Plot an icon into the image with finer granularity of control
 *
 * Looks up the icon with <code>-getIconWithType:creator:</code>, then passes that to <code>-plotIcon:inRect:alignment:transform:labelRGBColor:flags:</code>.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

@end
