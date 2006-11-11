//
//  AIListScroller.m
//  Adium
//
//  Created by Colin Barrett on 10/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIListScroller.h"


@implementation AIListScroller

- (id)init
{
	if ((self = [super init])) {
		//Let the super know we really don't want those arrows there, ever.
		[super setArrowsPosition:NSScrollerArrowsNone];
	}
	
	return self;
}
/*
- (NSRect)rectForPart:(NSScrollerPart)aPart
{
	NSRect superRect = [super rectForPart:aPart];
	switch (aPart) {
		case NSScrollerDecrementLine:
		case NSScrollerIncrementLine:
			return NSZeroRect;
		case NSScrollerKnobSlot:
			return [self frame];
		default:
			return superRect;
	}
}
*/
- (void)setArrowsPosition:(NSScrollArrowPosition)location
{
	//stub. we don't want this to change.
}

- (NSScrollArrowPosition)arrowsPosition
{
	//No arrows. Ever.
	return NSScrollerArrowsNone;
}

- (BOOL)isOpqaue
{
	return NO;
}

- (void)drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
	//We hates knob slots
	[[NSColor clearColor] set];
	NSRectFill(rect);
}

//Using this on the advice of OpenHUD, see below
- (void)drawArrow:(NSScrollerArrow)arrow highlightPart:(int)flag
{
	//We also hates arrows
	[[NSColor redColor] set];
	NSRectFill([self rectForPart:(arrow == NSScrollerIncrementArrow ? NSScrollerIncrementLine : NSScrollerDecrementLine)]);
}

// The following method is ganked from OpenHUD
// This method, while in the documentation and the header, never seems to get called. At least in 10.4. Instead, drawArrow:highlightPart: (an undocumented method) is called. So in case this method was used in previous versions of the OS, I'm forwarding calls from this (seemingly useless) method to the one that actually does things.
- (void)drawArrow:(NSScrollerArrow)arrow highlight:(BOOL)highlight
{
	[self drawArrow:arrow highlightPart:highlight ? 0 : -1];
}

@end
