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

//Add and access cells.  Returns YES if our column's width changes
- (BOOL)addCell:(AIFlexibleTableCell *)inCell
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
    [cellArray addObject:inCell];

    return(columnWidthDidChange);
}

- (void)removeAllCells
{
    [cellArray release];
    cellArray = [[NSMutableArray alloc] init];
}

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
