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

#import "AIFlexibleTableImageCell.h"


@interface AIFlexibleTableImageCell (PRIVATE)
- (id)initWithImage:(NSImage *)inImage;
@end

@implementation AIFlexibleTableImageCell

+ (AIFlexibleTableImageCell *)cellWithImage:(NSImage *)inImage
{
    return([[[self alloc] initWithImage:inImage] autorelease]);
}

- (id)initWithImage:(NSImage *)inImage
{
    [super init];

    image = [inImage retain];
    [image setFlipped:YES];

    return(self);
}

- (void)dealloc
{
    [image release];

    [super dealloc];
}

//The desired size of our cell without wrapping
- (NSSize)cellSize
{
    NSSize	imageSize = [image size];

    return(NSMakeSize(imageSize.width + (leftPadding + rightPadding), imageSize.height + (topPadding + bottomPadding)));
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Draw our image
    if(drawContents){
        NSSize	imageSize = [image size];

        cellFrame.size.height = imageSize.height;
        [image drawInRect:cellFrame fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }
}

@end



