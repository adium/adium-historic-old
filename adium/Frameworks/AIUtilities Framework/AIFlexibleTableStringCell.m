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

#import "AIFlexibleTableStringCell.h"

@interface AIFlexibleTableStringCell (PRIVATE)
- (AIFlexibleTableStringCell *)initWithAttributedString:(NSAttributedString *)inString;
@end

@implementation AIFlexibleTableStringCell

//Create a new cell from a regular string and some attributes
+ (AIFlexibleTableStringCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment
{
    AIFlexibleTableStringCell	*cell;
    NSDictionary		*attributes;
    NSAttributedString		*attributedString;

    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
	inTextColor, NSForegroundColorAttributeName,
	inFont, NSFontAttributeName,
	[NSParagraphStyle styleWithAlignment:inAlignment], NSParagraphStyleAttributeName,
	nil];
    attributedString = [[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease];

    //Build the cell
    cell = [AIFlexibleTableStringCell cellWithAttributedString:attributedString];
    [cell setType:NSTextCellType];

    return(cell);
}

//Create a new cell from an attributed string
+ (AIFlexibleTableStringCell *)cellWithAttributedString:(NSAttributedString *)inString
{
    return([[[self alloc] initWithAttributedString:inString] autorelease]);
}

//Init
- (AIFlexibleTableStringCell *)initWithAttributedString:(NSAttributedString *)inString
{
    [super init];

    string = [inString retain];
    contentSize = [string size];

    return(self);
}

//Dealloc
- (void)dealloc
{
    [string release];

    [super dealloc];
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (isOpaque) {
        [string drawInRect:cellFrame];
    } else {
        NSImage             *image;
        
        //Build an image of our rect before we draw
        image = [[NSImage alloc] initWithSize:cellFrame.size];
        [image setFlipped:[controlView isFlipped]];
        [image addRepresentation:[[[NSBitmapImageRep alloc] initWithFocusedViewRect:cellFrame] autorelease]];
        
        [controlView lockFocus];
        //Draw our string
        [string drawInRect:cellFrame];
        
        //Fade our new drawing back towards the original
        [image drawInRect:cellFrame fromRect:NSMakeRect(0,0,cellFrame.size.width,cellFrame.size.height) operation:NSCompositeSourceOver fraction:(1-opacity)];
        [controlView unlockFocus];
        [image release];
    }
}

@end
