//
//  BZContextImageBridge.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Thu Feb 12 2004.
//

/*!
@class BZContextImageBridge
@abstract Used to translate between Quartz and NSImage.
@discussion 
	Quick-start for <tt>BZContextImageBridge</tt>:

1. Create a bridge.
	BZContextImageBridge *bridge = [BZContextImageBridge bridgeWithSize:NSMakeSize(42.0f, 10.0f)];

2. Obtain the context. The context is retained for you (see below).
	CGContextRef context = [bridge context];

3. Draw into the context. (note: it is a bitmap context, so you cannot use PDF functions on it.)

4. Call image. If you call image more than once, the image will not be re-created (although, since the image uses the same backing store as the context, this should not be a problem).
	NSImage *image = [bridge image];

You can obtain greater control over the bridge by initing it using initWithSize:bitsPerComponent:componentsPerPixel:hasAlpha:.

If you use bridgeWithSize:, the bridge is autoreleased.

The <u>Icon Services interfaces</u> gives you a nice Cocoa interface for drawing icons in the context.
They come in full and abstracted flavours.

Summary of methods (without types):
wrapping GetIconRef:
  getIconWithType:
  getIconWithType:creator:
wrapping other GetIconRef functions:
  [future expansion]
wrapping PlotIconRefInContext:
	plotIcon:inRect:
	plotIcon:inRect:alignment:transform:labelNSColor:flags:
	plotIcon:inRect:alignment:transform:labelIndex:flags:
	plotIcon:inRect:alignment:transform:labelRGBColor:flags:
For more information, read the Icon Services documentation. They all return the status code returned from the Carbon calls on which these methods are based.
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

- (id)initWithSize:(NSSize)size;

/*!
	@method initWithSize:bitsPerComponent:componentsPerPixel:hasAlpha:
	@abstract Init the BZContextImageBridge with custom settings
	@discussion
		If hasAlpha is true, include that in componentsPerPixel. if it is false, subtract it from componentsPerPixel. IOW:
			hasAlpha	componentsPerPixel	result
			YES			4U					RGBA
			NO			3U					RGB
	@result  A <tt>BZContextImageBridge</tt> object
*/
- (id)initWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;

//convenience.
+ (id)bridgeWithSize:(NSSize)size;
+ (id)bridgeWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;

- (void)dealloc;

#pragma mark Accessors

- (unsigned char *)buffer;

//this method retains the context for you. you MUST release it.
- (CGContextRef)context;

//if the image hasn't been created yet, image calls refreshImage to create it.
//if it has been created, it returns that image.
//call refreshImage yourself if you want a guaranteed-current image (at the possible expense of performance).
//either way, the image is autoreleased.
- (NSImage *)image;
- (NSImage *)refreshImage;

- (unsigned)bitsPerComponent;
- (unsigned)componentsPerPixel;
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

- (IconRef)getIconWithType:(OSType)type;
- (IconRef)getIconWithType:(OSType)type creator:(OSType)creator;

- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds;
//the NSColor must be in an RGB colour space.
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
//the label index is one you would pass to Icon Services' GetLabel function
// (i.e. an integer from 1 to 7).
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

//conveniences.
//these substitute plotIconWithType: and plotIconWithType:creator: for
//  plotIcon: above.

- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds;
//the NSColor must be in an RGB colour space.
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
//the label index is one you would pass to Icon Services' GetLabel function
// (i.e. an integer from 1 to 7).
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds;
//the NSColor must be in an RGB colour space.
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
//the label index is one you would pass to Icon Services' GetLabel function
// (i.e. an integer from 1 to 7).
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

@end
