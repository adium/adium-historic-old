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

#import "AISMVSenderCell.h"
#import <AIUtilities/AIUtilities.h>

#define SENDER_PADDING_L 2
#define SENDER_PADDING_R 1
#define STRING_ROUNDOFF_PADDING 1

@interface AISMVSenderCell (PRIVATE)
- (AISMVSenderCell *)initSenderCellWithString:(NSString *)inString textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont;
@end

@implementation AISMVSenderCell

//Create a new cell
+ (AISMVSenderCell *)senderCellWithString:(NSString *)inString textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont
{
    return([[[self alloc] initSenderCellWithString:inString textColor:inTextColor backgroundColor:inBackColor font:inFont] autorelease]);
}

//Returns the last calculated cellSize (so, the last value returned by cellSizeForBounds)
- (NSSize)cellSize
{
    return(cellSize);
}

//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame showName:(BOOL)showName inView:(NSView *)controlView
{
    //Draw our background
    [AIGradient drawGradientInRect:cellFrame from:backgroundColor to:darkBackgroundColor];

    //Draw the name string
    if(showName){
        cellFrame.size.width -= SENDER_PADDING_L + SENDER_PADDING_R;
        cellFrame.origin.x += SENDER_PADDING_L;

        [attributedSenderString drawInRect:cellFrame];
    }
}

//Private --------------------------------------------------------------------------------
- (AISMVSenderCell *)initSenderCellWithString:(NSString *)inString textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont
{
    NSMutableParagraphStyle	*paragraphStyle;
    NSDictionary		*attributes;
    NSSize			stringSize;
    
    //Init
    [super init];
    backgroundColor = [inBackColor retain];
    darkBackgroundColor = [[backgroundColor darkenBy:0.09] retain];

    //Apply attributes to the name
    paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setAlignment:NSRightTextAlignment];

    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        inTextColor, NSForegroundColorAttributeName,
        inFont, NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];

    attributedSenderString = [[NSAttributedString alloc] initWithString:inString attributes:attributes];

    //Pre-calculate the cell size
    stringSize = [attributedSenderString size];
    cellSize = NSMakeSize((int)stringSize.width + SENDER_PADDING_L + SENDER_PADDING_R + STRING_ROUNDOFF_PADDING, stringSize.height);

    return(self);
}

- (void)dealloc
{
    [backgroundColor release];
    [attributedSenderString release];
    [darkBackgroundColor release];

    [super dealloc];
}

@end
