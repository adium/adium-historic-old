/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
    A text cell with vertically centered text
*/

#import "AIVerticallyCenteredTextCell.h"


@implementation AIVerticallyCenteredTextCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSString		*stringValue = [self stringValue];
    NSDictionary	*attributes = [NSDictionary dictionaryWithObjectsAndKeys:nil];
    int			stringHeight;
    
    //Calculate the centered rect
    stringHeight = [stringValue sizeWithAttributes:attributes].height;
    if(stringHeight < cellFrame.size.height){
        cellFrame.origin.y += (cellFrame.size.height - stringHeight) / 2.0;
    }

    //Draw the string
    [stringValue drawInRect:cellFrame withAttributes:attributes];
}


@end
