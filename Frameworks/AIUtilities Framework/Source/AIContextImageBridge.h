//
//  AIContextImageBridge.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Thu Feb 12 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface AIContextImageBridge : NSObject
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
- (id)initWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;
+ (id)bridgeWithSize:(NSSize)size;
+ (id)bridgeWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;

#pragma mark Accessors
- (unsigned char *)buffer;
- (CGContextRef)context;
- (NSImage *)image;

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
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

//conveniences.
//these substitute plotIconWithType: and plotIconWithType:creator: for
//  plotIcon: above.
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds;
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds;
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const RGBColor *)color flags:(PlotIconRefFlags)flags;

@end
