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
#import <AIUtilities/CBApplicationAdditions.h>

#define MINIMUM_HEIGHT				48
#define MINIMUM_WIDTH				140

@interface AIListOutlineView (PRIVATE)
- (void)_initListOutlineView;
@end

@implementation AIListOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initListOutlineView];
    return(self);
}

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	[self _initListOutlineView];
	
	return(self);
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
    return(NSFocusRingTypeNone);
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
	if(![[self window] isKeyWindow]) selected = NO;
	[super _drawRowInRect:rect colored:colored selected:selected];
}
	
//When our view is inserted into a window, observe that window so we can hide selection when it's not main
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if([newSuperview window]){
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
	int desiredHeight = [self totalHeight]+2;
	return(desiredHeight > MINIMUM_HEIGHT ? desiredHeight : MINIMUM_HEIGHT);
}

- (int)desiredWidth
{
	unsigned	row;
	unsigned	numberOfRows = [self numberOfRows];
	int			widestCell = 0;
	id			theDelegate = [self delegate];
	
	//Enumerate all rows, find the widest one
	for(row = 0; row < numberOfRows; row++){
		id			item = [self itemAtRow:row];
		NSCell		*cell = ([self isExpandable:item] ? groupCell : contentCell);
	
		[theDelegate outlineView:self willDisplayCell:cell forTableColumn:nil item:item];
		int	width = [(AIListCell *)cell cellWidth];
		if(width > widestCell) widestCell = width;
	}
	
	return(((widestCell > MINIMUM_WIDTH) || ignoreMinimumWidth) ? widestCell : MINIMUM_WIDTH);
}

- (void)setIgnoreMinimumWidth:(BOOL)inFlag
{
	ignoreMinimumWidth = inFlag;
}

//Background image ---------------------------------------------------------------
//Draw our background image or color with transparency
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if([self drawsBackground]){
		//BG Color
		[backgroundColor set];
		NSRectFill(clipRect);
		
		//Image
		if(backgroundImage){
			NSRect visRect = [[self enclosingScrollView] documentVisibleRect];
			NSSize	imageSize = [backgroundImage size];
			
			switch(backgroundStyle) {
				
				case AINormalBackground:{
					//Background image normal
					[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
									   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
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
									   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AIFillStretchBackground:{
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AITileBackground:{
					//Tiling
					NSPoint	currentOrigin;
					currentOrigin = visRect.origin;
					
					//We'll repeat this vertical process as long as necessary
					while (currentOrigin.y < visRect.size.height){				
						//Reset the x axis to draw a series of images horizontally at this height
						currentOrigin.x = visRect.origin.x;
						
						//Draw as long as our origin is within the visible rect
						while(currentOrigin.x < visRect.size.width){
							//Draw at the current x and y at least once with the original size
							[backgroundImage drawInRect:NSMakeRect(currentOrigin.x, currentOrigin.y, imageSize.width, imageSize.height)
											   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
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
		
	}else{
		//If we aren't drawing a background, fill the rect with clearColor
		[[NSColor clearColor] set];
		NSRectFill(clipRect);
	}
}

//Background -----------------------------------------------------------------
//
- (void)setBackgroundImage:(NSImage *)inImage
{
	if(backgroundImage != inImage){
		[backgroundImage release];
		backgroundImage = [inImage retain];		
		[backgroundImage setFlipped:YES];
	}
	
	[(NSClipView *)[self superview] setCopiesOnScroll:(!backgroundImage)];
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundFade:(float)fade
{
	backgroundFade = fade;
}

- (void)setBackgroundColor:(NSColor *)inColor
{
	if(backgroundColor != inColor){
		[backgroundColor release];
		backgroundColor = [inColor retain];
	}
}
- (NSColor *)backgroundColor
{
	return(backgroundColor);
}

- (void)setBackgroundStyle:(AIBackgroundStyle)inBackgroundStyle
{
	backgroundStyle = inBackgroundStyle;
}


- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	
	[(NSClipView *)newSuperview setCopiesOnScroll:(!backgroundImage)];
}

/* ######################## Crappy code alert ########################
Drawing the background image/color should be as simple as subclassing
drawBackgroundInClipRect: but that method is only called in 10.3 and
we need 10.2 compatability.

We need to get called after the background draws, but before the rows
start drawing.  A crappy solution is to draw our background right
before the outline view tries to draw its first row.  We only need to
do this when running in 10.2
*/
- (void)drawRect:(NSRect)rect
{	
	if(![NSApp isOnPantherOrBetter]) _drawBackground = YES;
	[super drawRect:rect];

	/* #################### More Crappy Code ###################
		This time for 10.3 compatability.  10.3 does NOT invalidate the shadow
		of a transparent window correctly, forcing us to do it manually each
		time the window content is changed.  This is absolutely horrible for
		performance, but the only way to avoid shadow ghosting in 10.3 :(
																		 */
	if(updateShadowsWhileDrawing) [[self window] compatibleInvalidateShadow];
}
- (void)drawRow:(int)row clipRect:(NSRect)rect
{
	if(_drawBackground){
		_drawBackground = NO;
		[self drawBackgroundInClipRect:[self frame]];
	}
	[super drawRow:row clipRect:rect];
}
- (void)setUpdateShadowsWhileDrawing:(BOOL)update{
	updateShadowsWhileDrawing = update;
}
// ###################################################################



//Contact menu ---------------------------------------------------------------
//Return the selected object (to auto-configure the contact menu)
- (AIListObject *)listObject
{
    int selectedRow = [self selectedRow];

    if(selectedRow >= 0 && selectedRow < [self numberOfRows]){
        return([self itemAtRow:selectedRow]);
    }else{
        return(nil);
    }
}

- (NSArray *)arrayOfListObjects
{
	return([self arrayOfSelectedItems]);
}

@end

