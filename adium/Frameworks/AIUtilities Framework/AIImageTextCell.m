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

- (id)init
{
    [super init];

    font = nil;
    
    return(self);
}

- (void)dealloc
{
    [font release];

    [super dealloc];
}

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

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSString	*title = [self objectValue];
    NSImage	*image = [self image];
    NSColor 	*highlightColor;
    BOOL 	highlighted;

    highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
    highlighted = [self isHighlighted];
    if(highlighted) {
        [highlightColor set];
        NSRectFill(cellFrame);
    }

    //Draw the cell's image
    if(image != nil){
        NSSize	size = [image size];
        NSPoint	destPoint = cellFrame.origin;
        
        //Adjust the rects
        destPoint.y += cellFrame.size.height;
        destPoint.x += 2;
        cellFrame.size.width -= size.width + 4;
        cellFrame.origin.x += size.width + 4;

        [image compositeToPoint:destPoint operation:NSCompositeSourceOver];
    }
    
    //Draw the cell's text
    if(title != nil){
        NSDictionary		*attributes;
        int			stringHeight;
        
        // If we are highlighted AND are drawing with the alternate color, then we want to draw our text with the alternate text color.
        // For any other case, we should draw using our normal text color.
	if(highlighted && [highlightColor isEqual:[NSColor alternateSelectedControlColor]]){
            //Draw the text inverted
            if(font){
                attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor alternateSelectedControlTextColor],NSForegroundColorAttributeName,nil];
            }else{
                attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor alternateSelectedControlTextColor],NSForegroundColorAttributeName,nil];
            }
            
        }else{
            //Draw the text regular
            if([self isEnabled]){
                if(font){
                    attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,nil];
                }else{
                    attributes = [NSDictionary dictionaryWithObjectsAndKeys:nil];
                }
            }else{
                attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,font,NSFontAttributeName,nil];
            }
        }

        //Calculate the centered rect
        stringHeight = [title sizeWithAttributes:attributes].height;
        if(stringHeight < cellFrame.size.height){
            cellFrame.origin.y += (cellFrame.size.height - stringHeight) / 2.0;
        }
        
        //Draw the string
        [title drawInRect:cellFrame withAttributes:attributes];
    }
}

@end
