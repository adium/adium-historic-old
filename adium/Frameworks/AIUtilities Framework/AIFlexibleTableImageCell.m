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



