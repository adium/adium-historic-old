//
//  AIFlexibleTableTextCell.h
//  Adium
//
//  Created by Adam Iser on Thu Jan 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIFlexibleTableCell.h"

@class AIFlexibleTableColumn, AIFlexibleLink, AILinkTrackingController;

@interface AIFlexibleTableTextCell : AIFlexibleTableCell {
    NSTextView			*editor;
    NSScrollView		*editorScroll;
    AIFlexibleTableColumn	*editedColumn;
    int				editedRow;

    NSAttributedString		*string;
    BOOL			containsLinks;
    
    //Link
    AILinkTrackingController	*linkTrackingController;
    
    //Text rendering cache
    NSTextStorage 		*textStorage;
    NSTextContainer 		*textContainer;
    NSLayoutManager 		*layoutManager;
    NSRange			glyphRange;
}

+ (AIFlexibleTableTextCell *)cellWithAttributedString:(NSAttributedString *)inString;
+ (AIFlexibleTableTextCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment background:(NSColor *)inBackColor gradient:(NSColor *)inGradientColor;
- (AIFlexibleTableTextCell *)initWithAttributedString:(NSAttributedString *)inString;
- (NSSize)cellSize;
- (void)sizeCellForWidth:(float)inWidth;
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)editAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn inView:(NSView *)controlView;
- (id <NSCopying>)endEditing;
- (void)resetCursorRectsInView:(NSView *)controlView visibleRect:(NSRect)visibleRect;
- (BOOL)usesCursorRects;

@end
