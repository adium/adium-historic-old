//
//  AIListGroupCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"
#import "AIListOutlineView.h"

#define FLIPPY_TEXT_PADDING		3

@implementation AIListGroupCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Dealloc
- (void)dealloc
{
	[self flushGradientCache];
	[super dealloc];
}


//Display Options ------------------------------------------------------------------------------------------------------
#pragma mark Display Options
//Color of our display name shadow
- (void)setShadowColor:(NSColor *)inColor
{
	if(inColor != shadowColor){
		[shadowColor release];
		shadowColor = [inColor retain];
	}
}
- (NSColor *)shadowColor{
	return(shadowColor);
}

//
- (void)setDrawsBackground:(BOOL)inValue
{
	drawsBackground = inValue;
}

//Set the background color and alternate/gradient background color of this group
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor
{
	if(inBackgroundColor != backgroundColor){
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
	if(inGradientColor != gradientColor){
		[gradientColor release];
		gradientColor = [inGradientColor retain];
	}
	
	//Reset gradient cache
	[self flushGradientCache];
}


//Sizing & Padding -----------------------------------------------------------------------------------------------------
#pragma mark Sizing & Padding
//Padding.  Gives our cell a bit of extra padding for the group name and flippy triangle
- (int)topPadding{
	return([super topPadding] + 1);
}
- (int)bottomPadding{
	return([super bottomPadding] + 1);
}
- (int)leftPadding{
	return([super leftPadding] + 2);
}
- (int)rightPadding{
	return([super rightPadding] + 4);
}

//Cell height and width
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];

	return(NSMakeSize(0, [[self font] defaultLineHeightForFont] + size.height));
}
- (int)cellWidth
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
	return([super cellWidth] + [self flippyIndent] + [displayName size].width + 1);
}

//Calculates the distance from left margin to our display name.  This is the indent caused by group nesting.
- (int)flippyIndent
{
	if([self textAlignment] != NSCenterTextAlignment){
		NSSize size = [self cellSize];
		return(size.height*.4 + size.height*.2 + FLIPPY_TEXT_PADDING);
	}else{
		return(0);
	}
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	//Draw flippy triangle
	[[self flippyColor] set];
	
	NSBezierPath	*arrowPath = [NSBezierPath bezierPath];
	NSPoint			center = NSMakePoint(rect.origin.x + rect.size.height*.4, rect.origin.y + (rect.size.height/2.0));

	if([controlView isItemExpanded:listObject]){
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.3, center.y - rect.size.height*.15)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.6, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-rect.size.height*.3, rect.size.height*.4)];		
	}else{
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.2, center.y - rect.size.height*.3)];
		[arrowPath relativeLineToPoint:NSMakePoint( 0, rect.size.height*.6)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.4, -rect.size.height*.3)];		
	}
		
	[arrowPath closePath];
	[arrowPath fill];

	if([self textAlignment] != NSCenterTextAlignment){
		rect.origin.x += rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
		rect.size.width -= rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
	}

	[self drawDisplayNameWithFrame:rect];
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if(![self cellIsSelected] && drawsBackground){
		[[self cachedGradient:rect.size] drawInRect:rect
										   fromRect:NSMakeRect(0,0,rect.size.width,rect.size.height)
										  operation:NSCompositeCopy
										   fraction:1.0];
	}
}

//Color of our flippy triangle.  By default we use the cell's text color.
- (NSColor *)flippyColor
{
	return([self textColor]);
}

//Add a simple shadow to our text attributes
- (NSDictionary *)additionalLabelAttributes
{
	if([NSApp isOnPantherOrBetter] && shadowColor){
		Class 	shadowClass = NSClassFromString(@"NSShadow"); //Weak Linking for 10.2 compatability
		id		shadow = [[[shadowClass alloc] init] autorelease];
		
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:shadowColor];
		
		return([NSDictionary dictionaryWithObject:shadow forKey:NSShadowAttributeName]);
	}else{
		return(nil);
	}
}


//Gradient -------------------------------------------------------------------------------------------------------------
#pragma mark Gradient
//Generates and caches an NSImage containing the group background gradient
- (NSImage *)cachedGradient:(NSSize)inSize
{
	if(!_gradient || !NSEqualSizes(inSize,_gradientSize)){
		[_gradient release];
		_gradient = [[NSImage alloc] initWithSize:inSize];
		_gradientSize = inSize;
		
		[_gradient lockFocus];
		[self drawBackgroundGradientInRect:NSMakeRect(0,0,inSize.width,inSize.height)];
		[_gradient unlockFocus];
	}
	
	return(_gradient);
}

//Draw our background gradient
- (void)drawBackgroundGradientInRect:(NSRect)inRect
{
	[[self backgroundGradient] drawInRect:inRect];
}

//Group background gradient
- (AIGradient *)backgroundGradient
{
	return([AIGradient gradientWithFirstColor:backgroundColor
								  secondColor:gradientColor
									direction:AIVertical]);
}

//Reset gradient cache
- (void)flushGradientCache
{
	[_gradient release]; _gradient = nil;
}

@end
