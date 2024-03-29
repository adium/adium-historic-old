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

#import "AIColoredBoxView.h"

/*
    A colored box
    $Id$
*/

@implementation AIColoredBoxView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		color = nil;
	}
	return self;
}

- (void)dealloc
{
    [color release];

    [super dealloc];
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)setColor:(NSColor *)inColor
{
    if (inColor != color) {
        [color release];
        color = [inColor retain];
    }
}

- (void)drawRect:(NSRect)rect
{    
    //Clear the rect
    [[NSColor clearColor] set];
    [NSBezierPath fillRect:rect];

    //Fill it with our color
    if (!color) {
        color = [[NSColor whiteColor] retain];
    }
    [color set];
    [NSBezierPath fillRect:rect];
    
    //Draw our contents
    [super drawRect:rect];
}

@end
