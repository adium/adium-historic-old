//
//  AIFlexibleTableColumn.m
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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

//Add and access cells
- (int)addCell:(AIFlexibleTableCell *)inCell
{
    //If this cell is wider than our column, resize ourself so it fits
    if(!flexibleWidth){
        int	cellWidth = [inCell cellSize].width;

        if(cellWidth > width){
            width = cellWidth;
            //[view columnDidResize:self];
        }
    }

    //Add the cell
    [cellArray addObject:inCell];

    //If our width is flexible, resize the cell to fix our width and return the resulting height
    if(flexibleWidth){
        return([inCell sizeCellForWidth:width]);
    }else{ //Otherwise, return the cell's set height  
        return([inCell cellSize].height);       
    }
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
