//
//  ESStaticView.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.
//

#import "ESStaticView.h"

/*
 A static image.
 */

@implementation ESStaticView

- (id)initWithFrame:(NSRect)frameRect image:(NSImage *)inImage{
    [super initWithFrame:frameRect];
    
    image = [inImage retain];
    sourceRect = NSMakeRect(0,0,[image size].width,[image size].height);

    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    
    image = nil;
    sourceRect = NSMakeRect(0,0,0,0);
    
    return(self);
}

- (void)dealloc
{
    [image release];
    
    [super dealloc];
}

- (void)setImage:(NSImage *)inImage
{
    if(inImage != image){
        if (image) {
            [image release]; image = nil;
        }
        if (inImage) {
            image = [inImage retain];
            sourceRect = NSMakeRect(0,0,[image size].width,[image size].height);
        }
        [self setNeedsDisplay:YES];
    }
}

- (NSImage *)image
{
    return image;   
}

- (BOOL)isOpaque
{
    return(NO);
}

- (void)drawRect:(NSRect)rect
{
    //Draw
    if (image) {
		
		//Works in the AIFlexibleTableImageCell but not here... I have no idea why.
	//	[image setFlipped:![image isFlipped]];
		
        if (NSContainsRect(rect,sourceRect)) {
            [image drawInRect:NSInsetRect(rect,(rect.size.width-sourceRect.size.width)/2,(rect.size.height-sourceRect.size.height)/2)
					 fromRect:sourceRect
					operation:NSCompositeSourceOver 
					 fraction:1.0];
        } else {
            [image drawInRect:rect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
		}
	//	[image setFlipped:![image isFlipped]];
		
    } else {
        //Clear
        [[NSColor clearColor] set];
        [NSBezierPath fillRect:rect];
    }
}

@end
