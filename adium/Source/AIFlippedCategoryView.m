/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIFlippedCategoryView.h"

@implementation AIFlippedCategoryView

//Return yes so this view's origin is the top left corner, and it behaves more naturally in scroll views
- (BOOL)isFlipped
{
    return(YES);
}

//Draw
/*- (void)drawRect:(NSRect)rect
{
    static NSColor *color;
    
    //Fill the rect with aqua stripes
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:rect];

    //Soften the stripes by painting 50% white over them
    if(!color){
        color = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.5] retain];
    }
    [color set];
    [NSBezierPath fillRect:rect];
}*/


- (void)dealloc
{
    [super dealloc];
}

@end
