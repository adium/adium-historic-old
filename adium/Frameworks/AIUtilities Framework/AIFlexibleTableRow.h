//
//  AIFlexibleTableRow.h
//  Adium
//
//  Created by Adam Iser on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIFlexibleTableView;

@interface AIFlexibleTableRow : NSObject {
    AIFlexibleTableView	*tableView;
    NSArray		*cellArray;
    int			height;
    BOOL		spansRows;
}

+ (id)rowWithCells:(NSArray *)inCells;
- (void)drawAtPoint:(NSPoint)point visibleRect:(NSRect)visibleRect inView:(NSView *)controlView;
- (void)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView;
- (BOOL)spansRows;

- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset;
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode;
- (void)deselectContent;
- (NSAttributedString *)selectedString;
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset;

- (int)sizeRowForWidth:(int)inWidth;
- (int)height;

- (void)setTableView:(AIFlexibleTableView *)inView;
- (AIFlexibleTableView *)tableView;
    
@end
