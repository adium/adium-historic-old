//
//  AISMVColumn.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIFlexibleTableCell, AIFlexibleTableView;

@interface AIFlexibleTableColumn : NSObject {
    NSMutableArray	*cellArray;

    float		width;
    BOOL		flexibleWidth;
}

- (NSArray *)cellArray;
- (AIFlexibleTableCell *)cellAtIndex:(int)index;

- (BOOL)addCell:(AIFlexibleTableCell *)inCell forRow:(int)inRow;
- (BOOL)removeCellAtRow:(int)inRow;
- (void)removeAllCells;

- (void)setWidth:(float)inWidth;
- (float)width;

- (void)setFlexibleWidth:(BOOL)inFlexible;
- (BOOL)flexibleWidth;


@end
