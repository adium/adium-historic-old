//
//  AIPlasticPlusButton.m
//  Adium
//
//  Created by Adam Iser on 8/9/04.
//

#import "AIPlasticPlusButton.h"
#import "ESImageAdditions.h"

@interface AIPlasticPlusButton(PRIVATE)
- (NSBezierPath *)popUpArrowPath;
@end

@implementation AIPlasticPlusButton

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect])) {
		[self setImage:[NSImage imageNamed:@"plus" forClass:[self class]]];
	}
	return self;    
}

- (void)dealloc
{
	[arrowPath release];
	[super dealloc];
}

//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
- (void)drawRect:(NSRect)rect
{
	//Let super do its thing
	[super drawRect:rect];
	
	//Draw the arrow, if needed
	if([self menu]){
		[[[NSColor blackColor] colorWithAlphaComponent:0.75] set];
		[[self popUpArrowPath] fill];
	}
}

//Path for the little popup arrow (Cached, depdenant upon our current frame)
- (NSBezierPath *)popUpArrowPath
{
	if(!arrowPath){
		NSRect frame = [self frame];

		arrowPath = [[NSBezierPath bezierPath] retain];
		[arrowPath moveToPoint:NSMakePoint(NSWidth(frame)-8, NSHeight(frame)-6)];
		[arrowPath relativeLineToPoint:NSMakePoint( 6, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-3, 3)];
		[arrowPath closePath];
	}
	
	return arrowPath;
}

//If our frame changes, release and clear the arrowPath cache so it will be recalculated when we next draw.
- (void)setFrame:(NSRect)inFrame
{
	[arrowPath release]; arrowPath = nil;
	
	[super setFrame:inFrame];
}

@end
