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

#import "AIContactListCollectionCell.h"

#define SUB_LABEL_HEIGHT 	16
#define LABEL_FONT_SIZE		12
#define SUB_LABEL_FONT_SIZE	10

@interface AIContactListCollectionCell (PRIVATE)
- (void)_init;
@end

@implementation AIContactListCollectionCell

- (id)init
{
    [super init];
    [self _init];
    
    return(self);
}

- (void)_init
{
    label = nil;
    subLabel = nil;
}

//Duplicate this object
- (id)copyWithZone:(NSZone *)zone
{
    AIContactListCollectionCell	*newCell = [super copyWithZone:zone];

    //Manually call the new cell's init method (it won't be called by copy w/ zone)
    [newCell _init];
    
    [newCell setLabel:label subLabel:subLabel];

    return(newCell);
}

- (void)setLabel:(NSString *)inLabel subLabel:(NSString *)inSubLabel
{
    if(subLabel != inSubLabel){
        [subLabel release]; subLabel = [inSubLabel retain];
    }
    if(label != inLabel){
        [label release]; label = [inLabel retain];
    }
}


- (NSSize)cellSizeForBounds:(NSRect)aRect
{
    //Our cell height is determined by the image
    return( NSMakeSize(aRect.size.width, (int)[[self image] size].height) );
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSImage	*image = [self image];
    NSColor 	*highlightColor;
    BOOL 	highlighted;
    BOOL	drawInverted;
    NSRect	imageRect;
    BOOL	enabled = [self isEnabled];

    //Determine our highlight state and color
    highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
    highlighted = [self isHighlighted];
    if(highlighted) {
        [highlightColor set];
        NSRectFill(cellFrame);
    }
    drawInverted = (highlighted && [highlightColor isEqual:[NSColor alternateSelectedControlColor]]);

    //Draw the image
    if(image != nil){
        NSSize	imageSize = [image size];

        //Left aligned, centered vertically
        imageRect.origin.x = cellFrame.origin.x;
        imageRect.size.width = imageSize.width;
        imageRect.origin.y = cellFrame.origin.y + ( (cellFrame.size.height - imageSize.height) / 2.0)
            + imageSize.height;
        imageRect.size.height = imageSize.height;

        //Draw Image
//        [image setFlipped:YES]; //flipped vertically
        if(enabled){
            [image compositeToPoint:imageRect.origin operation:NSCompositeSourceOver fraction:1.0];
        }else{
            [image dissolveToPoint:imageRect.origin fraction:0.7];
        }

    }

    //Draw the label
    if(label != nil){
        NSRect	labelRect;
        NSColor	*labelColor;

        labelRect.origin.x = imageRect.origin.x + imageRect.size.width;
        labelRect.size.width = cellFrame.size.width - imageRect.size.width;
        labelRect.origin.y = cellFrame.origin.y;
        labelRect.size.height = (subLabel ? (cellFrame.size.height - SUB_LABEL_HEIGHT) : (cellFrame.size.height) );

        if(drawInverted){
            labelColor = [NSColor alternateSelectedControlTextColor];
        }else{
            labelColor = (enabled ? [NSColor blackColor] : [NSColor grayColor]);
        }
        
        [label drawInRect:labelRect withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize:LABEL_FONT_SIZE], NSFontAttributeName,
            labelColor, NSForegroundColorAttributeName,
            nil]];
    }

    //Draw the sublabel
    if(subLabel != nil){
        NSRect	labelRect;
        NSColor	*labelColor;

        labelRect.origin.x = imageRect.origin.x + imageRect.size.width;
        labelRect.size.width = cellFrame.size.width - imageRect.size.width;
        labelRect.origin.y = cellFrame.origin.y + cellFrame.size.height - SUB_LABEL_HEIGHT;
        labelRect.size.height = SUB_LABEL_HEIGHT;

        if(drawInverted){
            labelColor = [NSColor alternateSelectedControlTextColor];
        }else{
            labelColor = (enabled ? [NSColor grayColor] : [NSColor lightGrayColor]);
        }

        [subLabel drawInRect:labelRect withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize:SUB_LABEL_FONT_SIZE], NSFontAttributeName,
            labelColor, NSForegroundColorAttributeName,
            nil]];
        
    }

}

@end
