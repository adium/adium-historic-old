/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
    A cell that displays an image and text
*/

#import "AIImageTextCell.h"


@implementation AIImageTextCell

//Init
- (id)init
{
    [super init];

    font = nil;
    subString = nil;
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [font release];
	[subString release];

    [super dealloc];
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIImageTextCell	*newCell = [[AIImageTextCell alloc] init];
	[newCell setFont:font];
	[newCell setSubString:subString];
	return(newCell);
}

//Font used to display our text
- (void)setFont:(NSFont *)obj
{
    if(font != obj){
        [font release];
        font = [obj retain];
    }
}
- (NSFont *)font{
    return(font);
}

//Substring (Displayed in gray below our main string)
- (void)setSubString:(NSString *)inSubString
{
    if(subString != inSubString){
        [subString release];
        subString = [inSubString retain];
    }
}

//Draw
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSString	*title = [self objectValue];
    NSImage	*image = [self image];
    BOOL 	highlighted;

    highlighted = [self isHighlighted];
    if(highlighted) {
        [self _drawHighlightWithFrame:cellFrame inView:controlView];
    }

    //Draw the cell's image
    if(image != nil){
        NSSize	size = [image size];
        NSPoint	destPoint = cellFrame.origin;
        
        //Adjust the rects
        destPoint.y += cellFrame.size.height;
        destPoint.x += 2;
        cellFrame.size.width -= size.width + 4;
        cellFrame.origin.x += size.width + 5;

        //Center image vertically
        if(size.height < cellFrame.size.height){
            destPoint.y -= (cellFrame.size.height - size.height) / 2.0;
        }
        
        [image compositeToPoint:destPoint operation:NSCompositeSourceOver];
    }
    
    //Draw the cell's text
    if(title != nil){
        NSColor			*textColor;
        NSDictionary		*attributes;
        int			stringHeight;

        //Determine the correct text color
        if(highlighted){
            textColor = [NSColor alternateSelectedControlTextColor]; //Draw the text inverted
        }else{
            if([self isEnabled]){
                textColor = [NSColor controlTextColor]; //Draw the text regular
            }else{
                textColor = [NSColor grayColor]; //Draw the text disabled
            }
        }

        //Adjust if a substring is present
        if(subString) cellFrame.size.height /= 2;

        //
        if(font){
            attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,textColor,NSForegroundColorAttributeName,nil];
        }else{
            attributes = [NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,nil];
        }

        //Calculate the centered rect
        stringHeight = [title sizeWithAttributes:attributes].height;
        if(stringHeight < cellFrame.size.height){
            cellFrame.origin.y += (cellFrame.size.height - stringHeight) / 2.0;
        }
        
        //Draw the string
        [title drawInRect:cellFrame withAttributes:attributes];

        //Draw the substring
        if(subString){
            //Determine the correct text color
            if(highlighted){
                textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0]; //Draw the text inverted
            }else{
                if([self isEnabled]){
                    textColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0]; //Draw the text regular
                }else{
                    textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0]; //Draw the text disabled
                }
            }
            
            cellFrame.origin.y += (cellFrame.size.height);

            attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10], NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
            [subString drawInRect:cellFrame withAttributes:attributes];
        }
    }
}

@end
