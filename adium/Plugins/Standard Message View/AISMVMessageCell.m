/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AISMVMessageCell.h"
#import "AIContentMessage.h"

@interface AISMVMessageCell (PRIVATE)
- (AISMVMessageCell *)initMessageCellWithString:(NSAttributedString *)inString backgroundColor:(NSColor *)inBackgroundColor;
@end

//AIAttributedStringTextCell

#define MESSAGE_PADDING_Y 1
#define MESSAGE_PADDING_X 2

@implementation AISMVMessageCell

//Create a new cell
+ (AISMVMessageCell *)messageCellWithString:(NSAttributedString *)inString backgroundColor:(NSColor *)inBackgroundColor
{
    return([[[self alloc] initMessageCellWithString:inString backgroundColor:inBackgroundColor] autorelease]);
}

//Resizes this cell for the desired width.  Returns the resulting size
- (NSSize)sizeCellForWidth:(float)inWidth
{
    //Reformat the text
    [textContainer setContainerSize:NSMakeSize(inWidth - (MESSAGE_PADDING_X * 2) , 1e7)];
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    cellSize.width = inWidth;
    cellSize.height = [layoutManager usedRectForTextContainer:textContainer].size.height + (MESSAGE_PADDING_Y * 2);
    
    return(cellSize);
}

//Returns the last calculated cellSize (so, the last value returned by cellSizeForBounds)
- (NSSize)cellSize{
    return(cellSize);
}

//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Draw our background
    if(backgroundColor){
        [backgroundColor set];
    }else{
        [[NSColor whiteColor] set];
    }
    [NSBezierPath fillRect:cellFrame];
    
    //Draw the message string
    cellFrame.origin.x += MESSAGE_PADDING_X;
    cellFrame.origin.y += MESSAGE_PADDING_Y;
    [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];

}

//Private --------------------------------------------------------------------------------
- (AISMVMessageCell *)initMessageCellWithString:(NSAttributedString *)inString backgroundColor:(NSColor *)inBackgroundColor
{
    [super init];

    //Init
    string = [inString retain];
    backgroundColor = [inBackgroundColor retain];
    
    //Setup the layout manager and text container
    textStorage = [[NSTextStorage alloc] initWithAttributedString:inString];
    textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1e7, 1e7)];
    layoutManager = [[NSLayoutManager alloc] init];
    
    [textContainer setLineFragmentPadding:0.0];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];


    return(self);
}

- (void)dealloc
{
    [backgroundColor release];
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [string release];

    [super dealloc];
}

@end

