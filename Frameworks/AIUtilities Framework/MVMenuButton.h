//Adapted from Colloquy  (www.colloquy.info)

#import <Cocoa/Cocoa.h>

/*!
	@class MVMenuButton
	@abstract Button with a popup menu for use with an NSToolbarItem
	@discussion Button which has a popup menu, including a menu arrow in the bottom right corner, for use as the custom view of an NSToolbarItem
*/
@interface MVMenuButton : NSButton <NSCopying> {
	NSImage				*bigImage;
	NSImage				*smallImage;
	NSToolbarItem 		*toolbarItem;
	NSBezierPath 		*arrowPath;
	
	BOOL				drawsArrow;
	NSControlSize 		controlSize;
}

/*!
	@method setControlSize:
	@abstract Set the controlSize
	@discussion Set the <tt>NSControlSize</tt> at which the button will be displayed.
	@param inSize A value of type <tt>NSControlSize</tt>
*/ 
- (void)setControlSize:(NSControlSize)inSize;
/*!
	@method controlSize
	@abstract Returns the controlSize
	@discussion The current <tt>NSControlSize</tt> at which the button will be displayed.
	@result A value of type <tt>NSControlSize</tt>
*/ 
- (NSControlSize)controlSize;

/*!
	@method setImage:
	@abstract Set the image of the button
	@discussion Set the image of the button.  It will be automatically sized as necessary.
	@param inImage An <tt>NSImage</tt> to use.
*/ 
- (void)setImage:(NSImage *)inImage;
/*!
	@method image
	@abstract Returns the image of the button
	@discussion Returns the image of the button
	@result An <tt>NSImage</tt>.
*/ 
- (NSImage *)image;

/*!
	@method setToolbarItem:
	@abstract Set the toolbar item associated with this button
	@discussion Set the toolbar item associated with this button. This is used for synchronizing sizing.
	@param item The <tt>NSToolbarItem</tt> to associate.
*/
- (void)setToolbarItem:(NSToolbarItem *)item;

/*!
	@method toolbarItem
	@abstract Returns the toolbar item associated with this button
	@discussion Returns the toolbar item associated with this button.
	@result The <tt>NSToolbarItem</tt>
*/
- (NSToolbarItem *)toolbarItem;

/*!
	@method setDrawsArrow:
	@abstract Set whether the button draws a dropdown arrow.
	@discussion Set whether the button draws a dropdown arrow. The arrow is black and positioned in the lower righthand corner of the button; it is used to indicate that clicking on the button will reveal further information or choices.
	@param inDraw YES if the arrow should be drawn.
*/
- (void)setDrawsArrow:(BOOL)inDraw;
/*!
	@method drawsArrow
	@abstract Returns if the button draws its arrow
	@discussion Returns if the button draws its arrow
	@result YES if the arrow is drawn.
*/
- (BOOL)drawsArrow;

@end
