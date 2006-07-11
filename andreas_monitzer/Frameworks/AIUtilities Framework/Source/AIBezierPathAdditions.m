//
//  AIBezierPathAdditions.m
//  Adium
//
//  Created by Mac-arena the Bored Zo and Chris Serino.

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIBezierPathAdditions.h"

#define ONE_THIRD  (1.0/3.0)
#define TWO_THIRDS (2.0/3.0)
#define ONE_HALF    0.5

#define DEFAULT_SHAFT_WIDTH ONE_THIRD
#define DEFAULT_SHAFT_LENGTH_MULTI 1.0

@implementation NSBezierPath (AIBezierPathAdditions)

#pragma mark Rounded rectangles

+ (NSBezierPath *)bezierPathRoundedRectOfSize:(NSSize)backgroundSize
{
	NSRect pathRect = NSMakeRect(0, 0, backgroundSize.width, backgroundSize.height);

	return [self bezierPathWithRoundedRect:pathRect];
}

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)bounds
{
	return [self bezierPathWithRoundedRect:bounds radius:MIN(bounds.size.width, bounds.size.height) / 2.0];
}

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius
{
    NSBezierPath	*path = [NSBezierPath bezierPath];
    NSPoint 		topLeft, topRight, bottomLeft, bottomRight;
    
    topLeft = NSMakePoint(rect.origin.x, rect.origin.y);
    topRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y);
    bottomLeft = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
    bottomRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);

    [path appendBezierPathWithArcWithCenter:NSMakePoint(topLeft.x + radius, topLeft.y + radius)
                                     radius:radius
                                 startAngle:180
                                   endAngle:270
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(topRight.x - radius, topRight.y)];
    
    [path appendBezierPathWithArcWithCenter:NSMakePoint(topRight.x - radius, topRight.y + radius)
                                     radius:radius
                                 startAngle:270
                                   endAngle:0
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(bottomRight.x, bottomRight.y - radius)];
    
    [path appendBezierPathWithArcWithCenter:NSMakePoint(bottomRight.x - radius, bottomRight.y - radius)
                                     radius:radius
                                 startAngle:0
                                   endAngle:90
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(bottomLeft.x + radius, bottomLeft.y)];

    [path appendBezierPathWithArcWithCenter:NSMakePoint(bottomLeft.x + radius, bottomLeft.y - radius)
                                     radius:radius
                                 startAngle:90
                                   endAngle:180
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(topLeft.x, topLeft.y + radius)];

    return path;
}

+ (NSBezierPath *)bezierPathWithRoundedTopCorners:(NSRect)rect radius:(float)radius
{
    NSBezierPath	*path = [NSBezierPath bezierPath];
    NSPoint 		topLeft, topRight, bottomLeft, bottomRight;
    
    topLeft = NSMakePoint(rect.origin.x, rect.origin.y);
    topRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y);
    bottomLeft = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
    bottomRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
	
	[path moveToPoint:NSMakePoint(bottomLeft.x, bottomLeft.y)];
	[path lineToPoint:NSMakePoint(topLeft.x, topLeft.y + radius)];
	
    [path appendBezierPathWithArcWithCenter:NSMakePoint(topLeft.x + radius, topLeft.y + radius)
                                     radius:radius
                                 startAngle:180
                                   endAngle:270
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(topRight.x - radius, topRight.y)];
    
    [path appendBezierPathWithArcWithCenter:NSMakePoint(topRight.x - radius, topRight.y + radius)
                                     radius:radius
                                 startAngle:270
                                   endAngle:0
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(bottomRight.x, bottomRight.y)];
	[path closePath];
	
    return path;
}

+ (NSBezierPath *)bezierPathWithRoundedBottomCorners:(NSRect)rect radius:(float)radius
{
    NSBezierPath	*path = [NSBezierPath bezierPath];
    NSPoint 		topLeft, topRight, bottomLeft, bottomRight;
    
    topLeft = NSMakePoint(rect.origin.x, rect.origin.y);
    topRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y);
    bottomLeft = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
    bottomRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
	
	[path moveToPoint:NSMakePoint(topRight.x, topRight.y)];
	[path lineToPoint:NSMakePoint(bottomRight.x, bottomRight.y - radius)];
	
    [path appendBezierPathWithArcWithCenter:NSMakePoint(bottomRight.x - radius, bottomRight.y - radius)
                                     radius:radius
                                 startAngle:0
                                   endAngle:90
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(bottomLeft.x + radius, bottomLeft.y)];
	
    [path appendBezierPathWithArcWithCenter:NSMakePoint(bottomLeft.x + radius, bottomLeft.y - radius)
                                     radius:radius
                                 startAngle:90
                                   endAngle:180
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint(topLeft.x, topLeft.y)];
	[path closePath];
	
    return path;
}

#pragma mark Arrows

+ (NSBezierPath *)bezierPathWithArrowWithShaftLengthMultiplier:(float)shaftLengthMulti shaftWidth:(float)shaftWidth {
	NSBezierPath *arrowPath = [NSBezierPath bezierPath];

	/*   5
	 *  / \ 
	 * /   \    1-7 = points
	 *6-7 3-4   the point of the triangle is 100% from the bottom.
	 *    |     the back edge of the triangle is 50% * shaftLengthMulti from the bottom.
	 *  1-2
	 */

	const float shaftLength = ONE_HALF * shaftLengthMulti;
	const float shaftEndY = -(shaftLength - ONE_HALF); //the end of the arrow shaft (points 1-2).
	//wing width = the distance between 6 and 7 and 3 and 4.
	const float wingWidth = (1.0 - shaftWidth) * 0.5;

	//start with the bottom vertex.
	[arrowPath moveToPoint:NSMakePoint(wingWidth,  shaftEndY)]; //1
	[arrowPath relativeLineToPoint:NSMakePoint(shaftWidth, 0.0)]; //2
	//up to the inner right corner.
	[arrowPath relativeLineToPoint:NSMakePoint(0.0, shaftLength)]; //3
	//far right.
	[arrowPath relativeLineToPoint:NSMakePoint(wingWidth,  0.0)]; //4
	//top center - the point of the arrow.
	[arrowPath lineToPoint:NSMakePoint(ONE_HALF,  1.0)]; //5
	//far left.
	[arrowPath lineToPoint:NSMakePoint(0.0,  ONE_HALF)]; //6
	//inner left corner.
	[arrowPath relativeLineToPoint:NSMakePoint(wingWidth,  0.0)]; //7
	//to the finish line! yay!
	[arrowPath closePath];

	return arrowPath;
}

+ (NSBezierPath *)bezierPathWithArrowWithShaftLengthMultiplier:(float)shaftLengthMulti {
	return [self bezierPathWithArrowWithShaftLengthMultiplier:shaftLengthMulti
	                                               shaftWidth:DEFAULT_SHAFT_WIDTH];
}
+ (NSBezierPath *)bezierPathWithArrowWithShaftWidth:(float)shaftWidth {
	return [self bezierPathWithArrowWithShaftLengthMultiplier:DEFAULT_SHAFT_LENGTH_MULTI
	                                               shaftWidth:shaftWidth];
}
+ (NSBezierPath *)bezierPathWithArrow {
	return [self bezierPathWithArrowWithShaftLengthMultiplier:DEFAULT_SHAFT_LENGTH_MULTI
	                                               shaftWidth:DEFAULT_SHAFT_WIDTH];
}

#pragma mark Nifty things

//these three are in-place.
- (NSBezierPath *)flipHorizontally {
	NSAffineTransform *transform = [NSAffineTransform transform];

	//adapted from http://developer.apple.com/documentation/Carbon/Conceptual/QuickDrawToQuartz2D/tq_other/chapter_3_section_2.html
	[transform translateXBy: 1.0 yBy: 0.0];
	[transform     scaleXBy:-1.0 yBy: 1.0];

	[self transformUsingAffineTransform:transform];
	return self;
}
- (NSBezierPath *)flipVertically {
	NSAffineTransform *transform = [NSAffineTransform transform];

	//http://developer.apple.com/documentation/Carbon/Conceptual/QuickDrawToQuartz2D/tq_other/chapter_3_section_2.html
	[transform translateXBy: 0.0 yBy: 1.0];
	[transform     scaleXBy: 1.0 yBy:-1.0];

	[self transformUsingAffineTransform:transform];
	return self;
}
- (NSBezierPath *)scaleToSize:(NSSize)newSize {
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:newSize.width yBy:newSize.height];

	[self transformUsingAffineTransform:transform];
	return self;	
}

//these three return an autoreleased copy.
- (NSBezierPath *)bezierPathByFlippingHorizontally {
	return [[[self copy] autorelease] flipHorizontally];
}
- (NSBezierPath *)bezierPathByFlippingVertically {
	return [[[self copy] autorelease] flipVertically];
}
- (NSBezierPath *)bezierPathByScalingToSize:(NSSize)newSize {
	return [[[self copy] autorelease] scaleToSize:newSize];
}

@end
