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
		arrowPath = [[self popUpArrowPath] retain];
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

//Path for the little popup arrow (Cached)
- (NSBezierPath *)popUpArrowPath
{
	arrowPath = [NSBezierPath bezierPath];
	[arrowPath moveToPoint:NSMakePoint(NSWidth(frame)-8, NSHeight(frame)-6)];
	[arrowPath relativeLineToPoint:NSMakePoint( 6, 0)];
	[arrowPath relativeLineToPoint:NSMakePoint(-3, 3)];
	[arrowPath closePath];

	return arrowPath;
}

@end
