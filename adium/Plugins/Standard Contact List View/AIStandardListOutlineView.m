//
//  AIStandardListOutlineView.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIStandardListOutlineView.h"


@implementation AIStandardListOutlineView

- (void)dealloc
{
	[backgroundImage release];
	[super dealloc];
}

//
- (void)setBackgroundImage:(NSImage *)inImage
{
	[backgroundImage release]; backgroundImage = nil;

	backgroundImage = [inImage retain];
	[backgroundImage setFlipped:YES];

	[[self superview] setCopiesOnScroll:(backgroundImage != nil)];
	[self setNeedsDisplay:YES];
}

//
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	[(NSClipView *)newSuperview setCopiesOnScroll:(backgroundImage != nil)];
}

//
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	NSRect visRect = [[self enclosingScrollView] documentVisibleRect];

	[super drawBackgroundInClipRect:clipRect];
	
	if(backgroundImage){
		NSSize	imageSize = [backgroundImage size];

		[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeCopy
				 fraction:1.0];
	}	
}

@end
