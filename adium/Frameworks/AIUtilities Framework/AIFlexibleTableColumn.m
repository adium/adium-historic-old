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

#import "AIFlexibleTableView.h"
#import "AIFlexibleTableColumn.h"
#import "AIFlexibleTableCell.h"

@implementation AIFlexibleTableColumn

- (id)init
{
    [super init];

    cellArray = [[NSMutableArray alloc] init];
    width = 0;
    flexibleWidth = NO;
    
    return(self);
}

//Add a cell.  Returns YES if our column's width changes
- (BOOL)addCell:(AIFlexibleTableCell *)inCell forRow:(int)inRow
{
    BOOL columnWidthDidChange = NO;
    
    //If this cell is wider than our column, resize ourself so it fits
    if(!flexibleWidth){
        int	cellWidth = [inCell cellSize].width;

        if(cellWidth > width){
            width = cellWidth;
            columnWidthDidChange = YES;
        }
    }

    //Size and add the cell
    [inCell sizeCellForWidth:width];
    [cellArray insertObject:inCell atIndex:inRow];

    return(columnWidthDidChange);
}

//Remove a cell.  Returns YES if our column's width changes
- (BOOL)removeCellAtRow:(int)inRow
{
    AIFlexibleTableCell		*deletedCell = [[cellArray objectAtIndex:inRow] retain]; //Hang onto the cell temporarily
    BOOL			columnWidthDidChange = NO;

    //Remove the cell from this column
    [cellArray removeObjectAtIndex:inRow];
    
    //If this cell is the width of our column, it could be our widest cell.  To avoid sizing errors, we need to recalculate our max width. (This does not apply if we're a flexible width cell)
    if(!flexibleWidth && [deletedCell cellSize].width == width){ //Recalculate our width
        NSEnumerator		*cellEnumerator = [cellArray objectEnumerator];
        AIFlexibleTableCell	*cell;
        int			newWidth = 0;
        
        cellEnumerator = [cellArray objectEnumerator];
        while((cell = [cellEnumerator nextObject])){
            if([cell cellSize].width > newWidth){
                newWidth = [cell cellSize].width;
            }
        }

        if(newWidth != width){ //The width did change
            width = newWidth;
            columnWidthDidChange = YES;
        }
    }

    return(columnWidthDidChange);
}

//Remove all the cells
- (void)removeAllCells
{
    //Set our width to 0
    width = 0;

    //Remove all the cells
    [cellArray release];
    cellArray = [[NSMutableArray alloc] init];
}

//Return the cells in this column
- (NSArray *)cellArray{
    return(cellArray);
}

//Return a specific cell
- (AIFlexibleTableCell *)cellAtIndex:(int)index
{
    if(index >= 0 && index < [cellArray count]){
        return([cellArray objectAtIndex:index]);
    }else{
        return(nil);
    }
}



//A column with flexible width stretches to fill any available space in the view
- (void)setFlexibleWidth:(BOOL)inFlexible
{
    flexibleWidth = inFlexible;
}
- (BOOL)flexibleWidth{
    return(flexibleWidth);
}


//Set and get this column's width
- (void)setWidth:(float)inWidth
{
    width = inWidth;
}
- (float)width{
    return(width);
}


@end
