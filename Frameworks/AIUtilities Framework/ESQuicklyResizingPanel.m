//
//  ESQuicklyResizingPanel.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Oct 25 2003.
//

#import "ESQuicklyResizingPanel.h"

//note: system default in 10.2 is 0.20 seconds - smaller is faster
#define DEFAULT_RESIZE_INTERVAL 0.05 

@implementation ESQuicklyResizingPanel

//Override all three panel initialization methods to set the default resizeInterval at init
- (id)init
{
	if((self = [super init]))
		resizeInterval = DEFAULT_RESIZE_INTERVAL;
	return self;
}
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)aScreen
{
	if((self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:flag screen:aScreen]))
		resizeInterval = DEFAULT_RESIZE_INTERVAL;
	return self;
}
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if((self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:flag]))
		resizeInterval = DEFAULT_RESIZE_INTERVAL;
	return self;
}

//accessing and setting the resizeInterval
- (NSTimeInterval)resizeInterval
{
    return resizeInterval;    
}
- (void)setResizeInterval:(NSTimeInterval)inInterval
{
    resizeInterval = inInterval;   
}

//newFrame is the desired frame size as the panel resizes
- (NSTimeInterval)animationResizeTime:(NSRect)newFrame
{
    return resizeInterval;    
}


@end
