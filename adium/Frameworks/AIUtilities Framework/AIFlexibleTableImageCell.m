//
//  AIFlexibleTableImageCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jan 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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

    return(self);
}

- (void)dealloc
{
    [image release];

    [super dealloc];
}

//Return our image
- (id <NSCopying>)objectValue
{
    return(image);
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
        cellFrame.origin.y += cellFrame.size.height;
//        cellFrame.origin.y -= [image size].height;

//        [image drawInRect:cellFrame fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) operation:NSCompositeSourceOver fraction:1.0];

        [image compositeToPoint:cellFrame.origin operation:NSCompositeSourceOver];
    }
}

@end
