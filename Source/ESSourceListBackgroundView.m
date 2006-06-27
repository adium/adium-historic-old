//
//  ESSourceListBackgroundView.m
//  Adium
//
//  Created by Evan Schoenberg on 6/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ESSourceListBackgroundView.h"


@implementation ESSourceListBackgroundView

- (void)_initSourceListBackgroundView
{
	background = [[NSImage imageNamed:@"sourceListBackground" forClass:[self class]] retain];
	backgroundSize = [background size];
	
	[self setNeedsDisplay:YES];
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _initSourceListBackgroundView];
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _initSourceListBackgroundView];
	}
	
	return self;
}

- (void)dealloc
{
	[background release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	NSRect	frame = [self frame];
	
	//Draw the background, tiling across
    NSRect sourceRect = NSMakeRect(0, 0, backgroundSize.width, backgroundSize.height);
    NSRect destRect = NSMakeRect(frame.origin.x, frame.origin.y, sourceRect.size.width, frame.size.height);
	
    while ((destRect.origin.x < NSMaxX(frame)) && destRect.size.width > 0) {
        //Crop
        if (NSMaxX(destRect) > NSMaxX(frame)) {
            sourceRect.size.width = NSWidth(destRect);
        }
		
        [background drawInRect:destRect
					  fromRect:sourceRect
					 operation:NSCompositeSourceOver
					  fraction:1.0];
        destRect.origin.x += destRect.size.width;
    }
}

@end
