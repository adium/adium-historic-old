//
//  AIListScroller.m
//  Adium
//
//  Created by Colin Barrett on 10/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIListScroller.h"


@interface NSScroller(lolihaetgcc)
- (NSRect)_drawingRectForPart:(NSScrollerPart)aPart;
@end


@implementation AIListScroller

- (id)init
{
	if ((self = [super init])) {
		//Let the super know we really don't want those arrows there, ever.
		[super setArrowsPosition:NSScrollerArrowsNone];
		
		backgroundColor = [[NSColor whiteColor] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[backgroundColor release];
	
	[super dealloc];
}

- (NSColor *)backgroundColor
{
	return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)newColor
{

	if (backgroundColor != newColor) {
		[backgroundColor release];
		backgroundColor = [newColor retain];
	}
	
	[self setNeedsDisplay:YES];

}

- (NSRect)_drawingRectForPart:(NSScrollerPart)aPart
{
	NSRect superRect = [super _drawingRectForPart:aPart];
	
	NSLog(@"part %d, rect %@", aPart, NSStringFromRect(superRect));
	
	
	switch (aPart) {
		//case NSScrollerKnob:
		case NSScrollerKnobSlot:
			return [self bounds];
			
		case NSScrollerNoPart:
		case NSScrollerDecrementLine:
		case NSScrollerIncrementLine:
			return NSZeroRect;
			
		default:
			return superRect;
	}
	
	return superRect;
}

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
	return [backgroundColor alphaComponent] == 1.0;
}

- (void)drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
	//We hates knob slots
	[backgroundColor set];
	NSRectFill(rect);
}

//Using this on the advice of OpenHUD, see below
- (void)drawArrow:(NSScrollerArrow)arrow highlightPart:(int)flag
{
	//We also hates arrows
	[backgroundColor set];
	NSRectFill([self rectForPart:(arrow == NSScrollerIncrementArrow ? NSScrollerIncrementLine : NSScrollerDecrementLine)]);
}

// The following method is ganked from OpenHUD
// This method, while in the documentation and the header, never seems to get called. At least in 10.4. Instead, drawArrow:highlightPart: (an undocumented method) is called. So in case this method was used in previous versions of the OS, I'm forwarding calls from this (seemingly useless) method to the one that actually does things.
- (void)drawArrow:(NSScrollerArrow)arrow highlight:(BOOL)highlight
{
	NSLog(@"bool highlight is called");
	[self drawArrow:arrow highlightPart:highlight ? 0 : -1];
}

//This method also doesn't seem to get called. Forwarding messages to drawingRectForPart, which does.
- (NSRect)rectForPart:(NSScrollerPart)partCode
{
	return [self _drawingRectForPart:partCode];
}

@end
