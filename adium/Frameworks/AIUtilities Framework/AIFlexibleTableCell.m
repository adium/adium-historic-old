/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIFlexibleTableCell.h"
#import "AIFlexibleTableRow.h"

@interface AIFlexibleTableCell (PRIVATE)
- (id)init;
- (void)dealloc;
@end

@implementation AIFlexibleTableCell

//init
- (id)init
{
    [super init];

    contentSize = NSMakeSize(0,0);
    variableWidth = NO;
    backgroundColor = nil;
    leftPadding = 0;
    rightPadding = 0;
    topPadding = 0;
    leftPadding = 0;
    rowSpan = 1;
    
    opacity = 1.0;
    isOpaque = YES;
    
    return(self);
}

//dealloc
- (void)dealloc
{
    [backgroundColor release];

    [super dealloc];
}

//Set this cell's background color
- (void)setBackgroundColor:(NSColor *)inColor
{
    if(backgroundColor != inColor){
        [backgroundColor release]; backgroundColor = [inColor retain];
    }
}
- (NSColor *)contentBackgroundColor
{
	return backgroundColor;
}

//Set and get the row this cell is in
- (void)setTableRow:(AIFlexibleTableRow *)inRow
{
    tableRow = inRow;
}
- (AIFlexibleTableRow *)tableRow
{
    return(tableRow);
}

- (void)setOpacity:(float)inOpacity
{
    opacity = inOpacity;
    if (opacity != 1.0)
        isOpaque = NO;
}

//Padding ------------------------------------------------------------------------------
//Set side padding
- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom
{
    leftPadding = inLeft;
    rightPadding = inRight;
    topPadding = inTop;
    bottomPadding = inBottom;
}
- (NSSize)paddingInset{
    return(NSMakeSize(leftPadding, topPadding));
}


//Spanning ------------------------------------------------------------------------------
//The number of rows this cell spans
- (void)setRowSpan:(int)inRowSpan
{
    rowSpan = inRowSpan;
    [tableRow updateSpanningAndResizeRow:YES];
}
- (int)rowSpan{
    return(rowSpan);
}

//YES if this cell is spanned into
- (BOOL)isSpannedInto
{
    return(NO);
}


//Cursor Tracking ----------------------------------------------------------------------
//Reset our cursor rects (returns YES if cursor rects were modified)
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    return(NO);
}

//Handle a mouse down
- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{    
    return(NO);
}

//
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    return nil;
}

//
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode
{

}

//
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    return(NO);
}

//
- (void)deselectContent
{

}

//
- (NSAttributedString *)selectedString
{
    return(nil);
}


//Sizing ------------------------------------------------------------------------------
//The size of our cell (content + padding)
- (NSSize)cellSize
{
    NSSize	size = [self contentSize];

    return(NSMakeSize(leftPadding + size.width + rightPadding, topPadding + size.height + bottomPadding));
}

//The size of our content
- (NSSize)contentSize
{
    return(contentSize);
}

//Set to YES if the width of this cell is variable
- (void)setVariableWidth:(BOOL)inVariableWidth
{
    variableWidth = inVariableWidth;
}
- (BOOL)variableWidth{
    return(variableWidth);
}

//Resize this cell to the desired width
- (void)sizeCellForWidth:(float)inWidth
{
    contentSize.width = inWidth - (leftPadding + rightPadding);
    contentSize.height = [self sizeContentForWidth:contentSize.width];
}

//Resize the content of this cell to the desired width, returns new height
- (int)sizeContentForWidth:(float)inWidth
{
    return(contentSize.height);
}


// Drawing -------------------------------------------------------------------------------
//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{    
    //Draw the background
    [(backgroundColor ? backgroundColor : [NSColor whiteColor]) set];
    [NSBezierPath fillRect:cellFrame];
    
    //Draw Contents
    cellFrame.origin.x += leftPadding;
    cellFrame.size.width -= leftPadding + rightPadding;
    cellFrame.origin.y += topPadding;
    cellFrame.size.height -= topPadding + bottomPadding;
    [self drawContentsWithFrame:cellFrame inView:controlView];
}

//Draw our contents
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{

}

@end
