//Adapted from Colloquy  (www.colloquy.info)

#import <Cocoa/Cocoa.h>

@interface MVMenuButton : NSButton <NSCopying> {
	NSImage				*bigImage;
	NSImage				*smallImage;
	NSToolbarItem 		*toolbarItem;
	NSBezierPath 		*arrowPath;
	
	BOOL				drawsArrow;
	NSControlSize 		controlSize;
}

- (void)setControlSize:(NSControlSize)inSize;
- (NSControlSize)controlSize;

- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;
- (void)setSmallImage:(NSImage *)image;
- (NSImage *)smallImage;

- (void)setToolbarItem:(NSToolbarItem *)item;
- (NSToolbarItem *)toolbarItem;

- (void)setDrawsArrow:(BOOL)inDraw;
- (BOOL)drawsArrow;

- (id)copyWithZone:(NSZone *)zone;

@end
