//
//  AIBezierPathAdditions.m
//  Adium
//
//  Created by Mac-arena the Bored Zo and Chris Serino.

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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


@implementation NSBezierPath (AIBezierPathAdditions)

+ (NSBezierPath *)bezierPathRoundedRectOfSize:(NSSize)backgroundSize
{
	NSRect pathRect = { { 0, 0 }, backgroundSize };

	return [self bezierPathWithRoundedRect:pathRect];
}

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)bounds
{
	return [self bezierPathWithRoundedRect:bounds radius:bounds.size.height / 2.0];
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

    return [[path retain] autorelease];
}

@end
