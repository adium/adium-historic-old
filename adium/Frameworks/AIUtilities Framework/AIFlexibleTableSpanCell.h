//
//  AIFlexibleTableSpanCell.h
//  Adium
//
//  Created by Adam Iser on Mon Sep 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIFlexibleTableCell.h"

@interface AIFlexibleTableSpanCell : AIFlexibleTableCell {
    AIFlexibleTableCell	*masterCell;

}

+ (id)spanCellFor:(AIFlexibleTableCell *)inCell;
- (AIFlexibleTableCell *)masterCell;

@end
