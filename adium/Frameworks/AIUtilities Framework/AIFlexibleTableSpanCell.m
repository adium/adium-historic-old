//
//  AIFlexibleTableSpanCell.m
//  Adium
//
//  Created by Adam Iser on Mon Sep 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableSpanCell.h"

@interface AIFlexibleTableSpanCell (PRIVATE)
- (id)initForCell:(AIFlexibleTableCell *)inCell;
@end

@implementation AIFlexibleTableSpanCell

//
+ (id)spanCellFor:(AIFlexibleTableCell *)inCell
{
    return([[[self alloc] initForCell:inCell] autorelease]);
}

//
- (id)initForCell:(AIFlexibleTableCell *)inCell
{
    [super init];

    masterCell = [inCell retain];
    
    return(self);
}

//
- (void)dealloc
{
    [masterCell release];

    [super dealloc];
}

//Assert if someone tries to span a span cell
- (void)setRowSpan:(int)inRowSpan
{
    NSAssert(NO,@"Cannot set row span of a span cell.");
}

//Access to our master cell
- (AIFlexibleTableCell *)masterCell{
    return(masterCell);
}

@end
