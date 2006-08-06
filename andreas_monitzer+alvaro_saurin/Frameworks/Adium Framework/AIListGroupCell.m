/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIListGroupCell.h"
#import "AIListOutlineView.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradient.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>

#define FLIPPY_TEXT_PADDING		4

@implementation AIListGroupCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupCell *newCell = [super copyWithZone:zone];
	
	newCell->shadowColor = [shadowColor retain];
	newCell->backgroundColor = [backgroundColor retain];
	newCell->gradientColor = [gradientColor retain];
	newCell->_gradient = [_gradient retain];
	drawsGradientEdges = NO;
	
	return newCell;
}

//Init
- (id)init
{
	if ((self = [super init])) {
		shadowColor = nil;
		backgroundColor = nil;
		gradientColor = nil;
		_gradient = nil;
	}
	
	return self;
}

//Dealloc
- (void)dealloc
{
	[shadowColor release];
	[backgroundColor release];
	[gradientColor release];

	[self flushGradientCache];
	[super dealloc];
}


//Display Options ------------------------------------------------------------------------------------------------------
#pragma mark Display Options
//Color of our display name shadow
- (void)setShadowColor:(NSColor *)inColor
{
	if (inColor != shadowColor) {
		[shadowColor release];
		shadowColor = [inColor retain];
	}
}
- (NSColor *)shadowColor{
	return shadowColor;
}

//
- (void)setDrawsBackground:(BOOL)inValue
{
	drawsBackground = inValue;
}

//Set the background color and alternate/gradient background color of this group
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor
{
	if (inBackgroundColor != backgroundColor) {
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
	if (inGradientColor != gradientColor) {
		[gradientColor release];
		gradientColor = [inGradientColor retain];
	}
	
	//Reset gradient cache
	[self flushGradientCache];
}

//
- (void)setDrawsGradientEdges:(BOOL)inValue
{
	drawsGradientEdges = inValue;
}



//Sizing & Padding -----------------------------------------------------------------------------------------------------
#pragma mark Sizing & Padding
//Padding.  Gives our cell a bit of extra padding for the group name and flippy triangle
- (int)topPadding{
	return [super topPadding] + 1;
}
- (int)bottomPadding{
	return [super bottomPadding] + 1;
}
- (int)leftPadding{
	return [super leftPadding] + 2;
}
- (int)rightPadding{
	return [super rightPadding] + 4;
}

//Cell height and width
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];

	return NSMakeSize(0, [[self font] defaultLineHeightForFont] + size.height);
}
- (int)cellWidth
{
	NSAttributedString	*displayName;
	NSSize				nameSize; 
	
	//Get the size of our display name
	displayName = [[NSAttributedString alloc] initWithString:[self labelString] attributes:[self labelAttributes]];
	nameSize = [displayName size];
	[displayName release];
		
	return [super cellWidth] + [self flippyIndent] + nameSize.width + 1;
}

//Calculates the distance from left margin to our display name.  This is the indent caused by group nesting.
- (int)flippyIndent
{
//	if ([self textAlignment] != NSCenterTextAlignment) {
		NSSize size = [self cellSize];
		return size.height*.4 + size.height*.2 + FLIPPY_TEXT_PADDING;
/*	} else {
		return 0;
	}
*/
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

	if ([controlView isItemExpanded:listObject]) {
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.3, center.y - rect.size.height*.15)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.6, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-rect.size.height*.3, rect.size.height*.4)];		
	} else {
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.2, center.y - rect.size.height*.3)];
		[arrowPath relativeLineToPoint:NSMakePoint( 0, rect.size.height*.6)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.4, -rect.size.height*.3)];		
	}
		
	[arrowPath closePath];
	[arrowPath fill];

//	if ([self textAlignment] != NSCenterTextAlignment) {
		rect.origin.x += rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
		rect.size.width -= rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
//	}

	[self drawDisplayNameWithFrame:rect];
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (![self cellIsSelected] && drawsBackground) {
		[[self cachedGradient:rect.size] drawInRect:rect
										   fromRect:NSMakeRect(0,0,rect.size.width,rect.size.height)
										  operation:NSCompositeCopy
										   fraction:1.0];
	}
}

//Color of our flippy triangle.  By default we use the cell's text color.
- (NSColor *)flippyColor
{
	return [self textColor];
}

/*
 * @brief Additional label attributes
 *
 * We override the paragraph style to be truncating middle.
 * The user's layout preferences may have indicated to add a shadow to the text.
 */
- (NSDictionary *)additionalLabelAttributes
{
	NSMutableDictionary *additionalLabelAttributes = [NSMutableDictionary dictionary];
	
	if (shadowColor) {
		NSShadow	*shadow = [[[NSShadow alloc] init] autorelease];
		
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:shadowColor];
		
		[additionalLabelAttributes setObject:shadow forKey:NSShadowAttributeName];
	}
	
	static NSMutableParagraphStyle *leftParagraphStyleWithTruncatingMiddle = nil;
	if (!leftParagraphStyleWithTruncatingMiddle) {
		leftParagraphStyleWithTruncatingMiddle = [[NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																			  lineBreakMode:NSLineBreakByTruncatingMiddle] retain];
	}

	[leftParagraphStyleWithTruncatingMiddle setMaximumLineHeight:(float)labelFontHeight];

	[additionalLabelAttributes setObject:leftParagraphStyleWithTruncatingMiddle
								  forKey:NSParagraphStyleAttributeName];
	
	return additionalLabelAttributes;
}


//Gradient -------------------------------------------------------------------------------------------------------------
#pragma mark Gradient
//Generates and caches an NSImage containing the group background gradient
- (NSImage *)cachedGradient:(NSSize)inSize
{
	if (!_gradient || !NSEqualSizes(inSize,_gradientSize)) {
		[_gradient release];
		_gradient = [[NSImage alloc] initWithSize:inSize];
		_gradientSize = inSize;
		
		[_gradient lockFocus];
		[self drawBackgroundGradientInRect:NSMakeRect(0,0,inSize.width,inSize.height)];
		[_gradient unlockFocus];
	}
	
	return _gradient;
}

//Draw our background gradient
- (void)drawBackgroundGradientInRect:(NSRect)inRect
{
	float backgroundL;
	float gradientL;
	
	//Gradient
	[[self backgroundGradient] drawInRect:inRect];
	
	//Add a sealing line at the light side of the gradient to make it look more polished.  Apple does this with
	//most gradients in OS X.
	[backgroundColor getHue:nil luminance:&backgroundL saturation:nil];
	[gradientColor getHue:nil luminance:&gradientL saturation:nil];
	
	if (gradientL < backgroundL) { //Seal the top
		[gradientColor set];
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x, inRect.origin.y, inRect.size.width, 1)];
	} else { //Seal the bottom
		[backgroundColor set];
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x, inRect.origin.y + inRect.size.height - 1, inRect.size.width, 1)];
	}
	
	//Seal the edges
	if (drawsGradientEdges) {
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x, inRect.origin.y, 1, inRect.size.height)];
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x+inRect.size.width-1, inRect.origin.y, 1, inRect.size.height)];
	}
}

//Group background gradient
- (AIGradient *)backgroundGradient
{
	return [AIGradient gradientWithFirstColor:backgroundColor
								  secondColor:gradientColor
									direction:AIVertical];
}

//Reset gradient cache
- (void)flushGradientCache
{
	[_gradient release]; _gradient = nil;
}

@end
