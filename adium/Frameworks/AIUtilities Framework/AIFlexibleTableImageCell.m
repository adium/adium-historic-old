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

#import "AIFlexibleTableImageCell.h"
#import "CSBezierPathAdditions.h"

#define ALIAS_SHIFT_X		0.5
#define ALIAS_SHIFT_Y		0.5

@interface AIFlexibleTableImageCell (PRIVATE)
- (id)initWithImage:(NSImage *)inImage;
@end

@implementation AIFlexibleTableImageCell

//Create a new image cell
+ (AIFlexibleTableImageCell *)cellWithImage:(NSImage *)inImage
{
    return([[[self alloc] initWithImage:inImage] autorelease]);
}

//Init
- (id)initWithImage:(NSImage *)inImage
{
    [super init];

    image = [inImage retain];
    
    contentSize = [image size]; //defaults to the size of the image
    imageSize = [image size];

    drawFrame = NO;
    borderColor = nil;
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [image release];

    [super dealloc];
}

//Set our desired size
- (void)setDesiredFrameSize:(NSSize)inSize
{
    contentSize = inSize;
}

//Set the image frame color
- (void)setFrameColor:(NSColor *)inBorderColor
{
    if(borderColor != inBorderColor){
        [borderColor release];
        borderColor = [inBorderColor retain];
    }
}

//Toggle display of the image frame
- (void)setDrawsFrame:(BOOL)inDrawFrame
{
    drawFrame = inDrawFrame;    
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
    NSAffineTransform * aliasShift = [NSAffineTransform transform];
    [aliasShift translateXBy:ALIAS_SHIFT_X yBy:ALIAS_SHIFT_Y];
    
    [image setFlipped:![image isFlipped]];
    [image drawInRect:cellFrame fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:opacity];
    [image setFlipped:![image isFlipped]];

    //
    if(drawFrame){
        NSBezierPath * internalPath = [NSBezierPath bezierPathWithRoundedRect:cellFrame radius:4];
        
        [internalPath transformUsingAffineTransform:aliasShift];
        
        [backgroundColor set]; 
        NSBezierPath * externalPath = [NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame,-1,-1)];
        [externalPath transformUsingAffineTransform:aliasShift];
        [externalPath appendBezierPath:internalPath];
        [externalPath setWindingRule:NSEvenOddWindingRule];
        
        [externalPath fill];
        
        [borderColor set];
        [internalPath stroke];
    }
}

@end

