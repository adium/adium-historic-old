//
//  AISMVColumn.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIFlexibleTableCell;

@interface AIFlexibleTableColumn : NSObject {
    NSMutableArray	*cellArray;

    float		width;
    BOOL		flexibleWidth;
}

- (NSArray *)cellArray;
- (int)addCell:(AIFlexibleTableCell *)inCell;
- (float)width;
- (void)setWidth:(float)inWidth;
- (void)setFlexibleWidth:(BOOL)inFlexible;
- (BOOL)flexibleWidth;
    
@end
