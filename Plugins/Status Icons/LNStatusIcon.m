#import "LNStatusIcon.h"

@implementation LNStatusIcon

+ (id)statusIcon
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
    [super init];    
    return(self);
}


- (void)dealloc
{
    [imageArray release];
    [super dealloc];
}


- (void)setImageArray:(NSArray *)inImageArray
{
    maxWidth = 0;

    if(imageArray != inImageArray){
        [imageArray release];
        imageArray = [inImageArray retain];
    }   

    int index;
    
    //--Calculate Max Width and Flip all of the Images---
    for(index = 0; index < [imageArray count]; index++){
    
        maxWidth += ([(NSImage *)[imageArray objectAtIndex:index] size]).width; 
        [[imageArray objectAtIndex:index] setFlipped:TRUE];
    }

}




- (void)drawInRect:(NSRect)inRect
{

    NSImage		*currentImage;
    NSEnumerator	*enumerator;
    
    float		currentWidth = 0;
    
    
    enumerator = [imageArray objectEnumerator];
    
    while(currentImage = [enumerator nextObject]){
    
        [currentImage drawAtPoint:NSMakePoint(inRect.origin.x + currentWidth, inRect.origin.y + ceil((inRect.size.height / 2.0)) - ceil(([currentImage size].height / 2.0))) fromRect:NSMakeRect(0, 0, [currentImage size].width, [currentImage size].height) operation:NSCompositeSourceOver fraction:1.0];

        currentWidth += [currentImage size].width;

    }
}

- (float)widthForHeight:(int)inHeight
{
    return(maxWidth);
}


@end
