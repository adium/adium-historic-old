//
//  AIFlexibleTableFramedTextCell.h
//  Adium
//
//  Created by Adam Iser on Tue Sep 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableTextCell.h"

@interface AIFlexibleTableFramedTextCell : AIFlexibleTableTextCell {
    BOOL        drawTopDivider;
    BOOL	drawTop;
    BOOL	drawBottom;
    BOOL        drawSides;

    int         framePadLeft;
    
    NSColor 	*borderColor;
    NSColor	*bubbleColor;
    NSColor	*dividerColor;
}
+ (AIFlexibleTableFramedTextCell *)cellWithAttributedString:(NSAttributedString *)inString;

- (id)initWithAttributedString:(NSAttributedString *)inString;

- (void)setDrawTopDivider:(BOOL)inDrawTopDivider;
- (void)setDrawTop:(BOOL)inDrawTop;
- (void)setDrawBottom:(BOOL)inDrawBottom;
- (void)setDrawSides:(BOOL)inDrawSides;

- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor dividerColor:(NSColor *)inDividerColor;

@end
