/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIListCell.h"
#import "AIListOutlineView.h"
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradient.h>
//needed for GetDblTime()
#import <Carbon/Carbon.h>

#define MINIMUM_HEIGHT				48

@interface AIListOutlineView (PRIVATE)
- (void)_initListOutlineView;
@end

@implementation AIListOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initListOutlineView];
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	[self _initListOutlineView];
	
	return self;
}

- (void)_initListOutlineView
{
	updateShadowsWhileDrawing = NO;
	
	backgroundImage = nil;
	backgroundFade = 1.0;
	backgroundColor = nil;
	backgroundStyle = AINormalBackground;
	
	[self sizeLastColumnToFit];
}

- (void)dealloc
{	
	[backgroundImage release];
	[backgroundColor release];
	
	[super dealloc];
}

//Prevent the display of a focus ring around the contact list in 10.3 and greater
- (NSFocusRingType)focusRingType
{
    return NSFocusRingTypeNone;
}

//When our delegate is set, ask it for our data cells
- (void)setDelegate:(id)delegate
{
	[super setDelegate:delegate];
}

//Keep our column full width
- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[self sizeLastColumnToFit];
}

//Selection Hiding -----------------------------------------------------------------------------------------------------
//If our window isn't in the foreground, we're not displaying a selection.  So override this method to pass NO for
//selected in that situation
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
	if (![[self window] isKeyWindow]) selected = NO;
	[super _drawRowInRect:rect colored:colored selected:selected];
}
	
//When our view is inserted into a window, observe that window so we can hide selection when it's not main
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if ([newSuperview window]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:[newSuperview window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:[newSuperview window]];
    }
}

//Redraw our cells so they can select or de-select
- (void)windowBecameMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}
- (void)windowResignedMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}

//
- (void)cancelOperation:(id)sender
{
	[self deselectAll:nil];
}

//Sizing -----------------------------------------------------------------------------------------------------
// Returns our desired size
- (int)desiredHeight
{
	int desiredHeight = [self totalHeight] + desiredHeightPadding;
	return desiredHeight > MINIMUM_HEIGHT ? desiredHeight : MINIMUM_HEIGHT;
}

- (int)desiredWidth
{
	unsigned	row;
	unsigned	numberOfRows = [self numberOfRows];
	int			widestCell = 0;
	id			theDelegate = [self delegate];
	
	//Enumerate all rows, find the widest one
	for (row = 0; row < numberOfRows; row++) {
		id			item = [self itemAtRow:row];
		NSCell		*cell = ([self isExpandable:item] ? groupCell : contentCell);
	
		[theDelegate outlineView:self willDisplayCell:cell forTableColumn:nil item:item];
		int	width = [(AIListCell *)cell cellWidth];
		if (width > widestCell) widestCell = width;
	}

	return ((widestCell > minimumDesiredWidth) ? widestCell : minimumDesiredWidth);
}

- (void)setMinimumDesiredWidth:(int)inMinimumDesiredWidth
{
	minimumDesiredWidth = inMinimumDesiredWidth;
}

//Add padding to the desired height
- (void)setDesiredHeightPadding:(int)inPadding
{
	desiredHeightPadding = inPadding;
}


//Background image ---------------------------------------------------------------
//Draw our background image or color with transparency
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if ([self drawsBackground]) {
		//BG Color
		[[self backgroundColor] set];
		NSRectFill(clipRect);
		
		//Image
		NSScrollView	*enclosingScrollView = [self enclosingScrollView];
		if (backgroundImage && enclosingScrollView) {
			NSRect	visRect = [enclosingScrollView documentVisibleRect];
			NSSize	imageSize = [backgroundImage size];
			NSRect	imageRect = NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height);

			switch (backgroundStyle) {
				
				case AINormalBackground:{
					//Background image normal
					[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AIFillProportionatelyBackground:{
					//Background image proportional stretch
					
					//Make the width change by the same proportion as the height will change
					//visRect.size.width = imageSize.width * (visRect.size.height / imageSize.height);
					
					//Make the height change by the same proportion as the width will change
					visRect.size.height = imageSize.height * (visRect.size.width / imageSize.width);
					
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AIFillStretchBackground:{
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AITileBackground:{
					//Tiling
					NSPoint	currentOrigin;
					currentOrigin = visRect.origin;

					//We'll repeat this vertical process as long as necessary
					while (currentOrigin.y < (visRect.origin.y + visRect.size.height)) {
						//Reset the x axis to draw a series of images horizontally at this height
						currentOrigin.x = visRect.origin.x;
						
						//Draw as long as our origin is within the visible rect
						while (currentOrigin.x < (visRect.origin.x + visRect.size.width)) {
							//Draw at the current x and y at least once with the original size
							[backgroundImage drawInRect:NSMakeRect(currentOrigin.x, currentOrigin.y, imageSize.width, imageSize.height)
											   fromRect:imageRect
											  operation:NSCompositeSourceOver
											   fraction:backgroundFade];
							
							//Shift right for the next iteration
							currentOrigin.x += imageSize.width;
						}
						
						//Shift down for the next series of horizontal draws
						currentOrigin.y += imageSize.height;
					}
					break;
				}
			}
		}
		
	} else {
		//If we aren't drawing a background, fill the rect with clearColor
		[[NSColor clearColor] set];
		NSRectFill(clipRect);
	}
}

//Background -----------------------------------------------------------------
//
- (void)setBackgroundImage:(NSImage *)inImage
{
	if (backgroundImage != inImage) {
		[backgroundImage release];
		backgroundImage = [inImage retain];		
		[backgroundImage setFlipped:YES];
	}
	
	[(NSClipView *)[self superview] setCopiesOnScroll:(!backgroundImage)];
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundStyle:(AIBackgroundStyle)inBackgroundStyle
{
	backgroundStyle = inBackgroundStyle;
	[self setNeedsDisplay:YES];
}

//
- (void)setBackgroundOpacity:(float)opacity forWindowStyle:(LIST_WINDOW_STYLE)windowStyle
{
	backgroundOpacity = opacity;

	//Reset all our opacity dependent values
	[_backgroundColorWithOpacity release]; _backgroundColorWithOpacity = nil;
	[_rowColorWithOpacity release]; _rowColorWithOpacity = nil;
	
	//Turn our shadow drawing hack on if they're going to be visible through the transparency
	[self setUpdateShadowsWhileDrawing:((backgroundOpacity < 0.9) ||
										(windowStyle == WINDOW_STYLE_PILLOWS_FITTED))];

	//Mockie and pillow lists always require a non-opaque window, other lists only require a non-opaque window when
	//the user has requested transparency.
	if (windowStyle == WINDOW_STYLE_MOCKIE || windowStyle == WINDOW_STYLE_PILLOWS || windowStyle == WINDOW_STYLE_PILLOWS_FITTED) {
		[[self window] setOpaque:NO];
	} else {
		[[self window] setOpaque:(backgroundOpacity == 1.0)];
	}

	[self setNeedsDisplay:YES];

	/* This may be called repeatedly. We want to invalidate our shadow as our opacity changes, but we'll flicker
	 * if we do it immediately.
	 */
	[NSObject cancelPreviousPerformRequestsWithTarget:[self window]
											 selector:@selector(invalidateShadow)
											   object:nil];
	[[self window] performSelector:@selector(invalidateShadow)
	                    withObject:nil
	                    afterDelay:0.2];
}

- (void)setBackgroundFade:(float)fade
{
	backgroundFade = fade;
	[self setNeedsDisplay:YES];
}
- (float)backgroundFade
{
	//Factor in opacity
	return backgroundFade * backgroundOpacity;
}

//Background color (Opacity is added into the return automatically)
- (void)setBackgroundColor:(NSColor *)inColor
{
	if (backgroundColor != inColor) {
		[backgroundColor release];
		backgroundColor = [inColor retain];
		[_backgroundColorWithOpacity release];
		_backgroundColorWithOpacity = nil;
	}
	[self setNeedsDisplay:YES];
}
- (NSColor *)backgroundColor
{
	//Factor in opacity
	if (!_backgroundColorWithOpacity) { 
		_backgroundColorWithOpacity = [[backgroundColor colorWithAlphaComponent:backgroundOpacity] retain];
	}
	
	return _backgroundColorWithOpacity;
}

- (void)setHighlightColor:(NSColor *)inColor
{
	if (highlightColor != inColor) {
		[self willChangeValueForKey:@"highlightColor"];
		[highlightColor release];
		highlightColor = [inColor retain];
		[self  didChangeValueForKey:@"highlightColor"];
	}
	[self setNeedsDisplay:YES];
}
- (NSColor *)highlightColor
{
	return highlightColor;
}

//Alternating row color (Opacity is added into the return automatically)
- (void)setAlternatingRowColor:(NSColor *)color
{
	if (rowColor != color) {
		[rowColor release];
		rowColor = [color retain];
		[_rowColorWithOpacity release];
		_rowColorWithOpacity = nil;
	}
	
	[self setNeedsDisplay:YES];
}

- (NSColor *)alternatingRowColor
{
	if (!_rowColorWithOpacity) {
		_rowColorWithOpacity = [[rowColor colorWithAlphaComponent:backgroundOpacity] retain];
	}
	
	return _rowColorWithOpacity;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	
	[(NSClipView *)newSuperview setCopiesOnScroll:(!backgroundImage)];
}

- (void)drawRect:(NSRect)rect
{	
	[super drawRect:rect];

	/*	#################### Crappy Code ###################
	 *	10.3 compatibility:  10.3 does NOT invalidate the shadow
	 *	of a transparent window correctly, forcing us to do it manually each
	 *	time the window content is changed.  This is absolutely horrible for
	 *	performance, but the only way to avoid shadow ghosting in 10.3 :(
	 *
	 *  XXX - ToDo: Check if this is still a problem in 10.4
	 */
	if (updateShadowsWhileDrawing) [[self window] invalidateShadow];
}

- (void)_drawRowSelectionInRect:(NSRect)rect
{
	//Draw the gradient
	NSColor		*myHighlightColor = [self highlightColor];
	AIGradient 	*gradient = (myHighlightColor ?
							 [AIGradient gradientWithFirstColor:myHighlightColor
													secondColor:[myHighlightColor darkenAndAdjustSaturationBy:0.4] 
													  direction:AIVertical] :
							 [AIGradient selectedControlGradientWithDirection:AIVertical]);

	[gradient drawInRect:rect];
}

- (void)setUpdateShadowsWhileDrawing:(BOOL)update{
	updateShadowsWhileDrawing = update;
}

//Contact menu ---------------------------------------------------------------
//Return the selected object (to auto-configure the contact menu)
- (AIListObject *)listObject
{
    int selectedRow = [self selectedRow];

    if (selectedRow >= 0 && selectedRow < [self numberOfRows]) {
        return [self itemAtRow:selectedRow];
    } else {
        return nil;
    }
}

- (NSArray *)arrayOfListObjects
{
	return [self arrayOfSelectedItems];
}

@end

