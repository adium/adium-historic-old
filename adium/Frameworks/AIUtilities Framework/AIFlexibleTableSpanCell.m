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

#import "AIFlexibleTableSpanCell.h"

@interface AIFlexibleTableSpanCell (PRIVATE)
- (id)initForCell:(AIFlexibleTableCell *)inCell spannedIndex:(int)inIndex;
@end

@implementation AIFlexibleTableSpanCell

//Create a new span cell
+ (id)spanCellFor:(AIFlexibleTableCell *)inCell spannedIndex:(int)inIndex
{
    return([[[self alloc] initForCell:inCell spannedIndex:inIndex] autorelease]);
}

//Init
- (id)initForCell:(AIFlexibleTableCell *)inCell spannedIndex:(int)inIndex
{
    [super init];

    //
    masterCell = [inCell retain];
    spannedIndex = inIndex;

    //Set width to the width of our master cell
    [self sizeCellForWidth:[masterCell cellSize].width];
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [masterCell release];

    [super dealloc];
}

//This cell is spanned into
- (BOOL)isSpannedInto
{
    return(YES);
}

//The index we are within the spanned cells
- (int)spannedIndex
{
    return(spannedIndex);    
}

//Assert if someone tries to span a span cell
- (void)setRowSpan:(int)inRowSpan
{
    NSAssert(NO,@"Cannot set row span of a span cell.");
}

//Access to our master cell
- (AIFlexibleTableCell *)masterCell
{
    return(masterCell);
}

@end
