//
//  AIFlexibleTableColumn.m
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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
    }else{ //If our width is flexible, resize the cell to fit
        [inCell sizeCellForWidth:width];
    }

    //Add the cell
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
