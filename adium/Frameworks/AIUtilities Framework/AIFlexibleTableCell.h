//
//  AISMVCell.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIFlexibleTableView, AIFlexibleTableColumn;

@interface AIFlexibleTableCell : NSCell {
    AIFlexibleTableView	*tableView;

    //Background
    NSColor 		*backgroundColor;
    NSColor 		*gradientColor;

    //Padding
    int			leftPadding;
    int			rightPadding;
    int			topPadding;
    int			bottomPadding;

    //Size / Drawing
    BOOL		drawContents;
    NSSize		cellSize;
    NSRect		frame;
    NSColor		*dividerColor;
    BOOL		selected;

}

- (void)setTableView:(AIFlexibleTableView *)inView;

//Configure
- (void)setBackgroundColor:(NSColor *)inColor;
- (void)setBackgroundGradientFrom:(NSColor *)inColorA to:(NSColor *)inColorB;
- (void)setDrawContents:(BOOL)inValue;
- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom;
- (void)setDividerColor:(NSColor *)inColor;
- (void)setSelected:(BOOL)inSelected;

//Access
- (NSSize)paddingInset;
- (void)editAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn inView:(NSView *)controlView;
- (id <NSCopying>)endEditing;

//Selection
- (int)characterIndexAtPoint:(NSPoint)point;
- (BOOL)selectFrom:(int)sourceIndex to:(int)destIndex;
- (NSAttributedString *)stringFromIndex:(int)sourceIndex to:(int)destIndex;

//Cursor Tracking
- (BOOL)resetCursorRectsInView:(NSView *)controlView visibleRect:(NSRect)visibleRect;
- (BOOL)handleMouseDown:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;

//Sizing
- (NSSize)cellSize;
- (void)sizeCellForWidth:(float)inWidth;

//Drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)setFrame:(NSRect)inFrame;
- (NSRect)frame;

@end