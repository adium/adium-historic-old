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
- (AISMVSenderCell *)initSenderCellWithString:(NSAttributedString *)inString;
@end

@implementation AISMVSenderCell

//Create a new cell
+ (AISMVSenderCell *)senderCellWithString:(NSAttributedString *)inString
{
    return([[[self alloc] initSenderCellWithString:inString] autorelease]);
}

//Returns the last calculated cellSize (so, the last value returned by cellSizeForBounds)
- (NSSize)cellSize{
    return(cellSize);
}

//Set the background color of this cell
- (void)setBackgroundColor:(NSColor *)inColor
{
    backgroundColor = [inColor retain];
}

//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame showName:(BOOL)showName inView:(NSView *)controlView
{
    //Draw our background
    if(backgroundColor){
        [AIGradient drawGradientInRect:cellFrame from:backgroundColor to:[backgroundColor darkenBy:0.09]];
    }else{
        [AIGradient drawGradientInRect:cellFrame from:[NSColor whiteColor] to:[NSColor redColor]];
    }
    
    //Draw the name string
    if(showName){
        cellFrame.size.width -= SENDER_PADDING_L + SENDER_PADDING_R;
        cellFrame.origin.x += SENDER_PADDING_L;

        [string drawInRect:cellFrame];
    }
}

//Private --------------------------------------------------------------------------------
- (AISMVSenderCell *)initSenderCellWithString:(NSAttributedString *)inString
{
    NSSize	stringSize;

    [super init];

    //Init
    string = [inString retain];
    backgroundColor = nil;
    
    //Precalc our cell size
    stringSize = [string size];
    cellSize = NSMakeSize(stringSize.width + SENDER_PADDING_L + SENDER_PADDING_R + STRING_ROUNDOFF_PADDING, stringSize.height);

    return(self);
}

- (void)dealloc
{
    [backgroundColor release];
    [string release];

    [super dealloc];
}

@end
