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

    BOOL    suppressTopLeftCorner;
    BOOL    suppressTopRightCorner;
    BOOL    suppressBottomRightCorner;
    BOOL    suppressBottomLeftCorner;
    BOOL    suppressTopBorder;
    BOOL    suppressBottomBorder;
    
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

- (void)setSuppressTopRightCorner:(BOOL)inSuppressTopRightCorner;
- (void)setSuppressTopLeftCorner:(BOOL)inSuppressTopLeftCorner;
- (void)setSuppressBottomRightCorner:(BOOL)inSuppressBottomRightCorner;
- (void)setSuppressBottomLeftCorner:(BOOL)inSuppressBottomLeftCorner;
- (void)setSuppressTopBorder:(BOOL)inSuppressTopBorder;
- (void)setSuppressBottomBorder:(BOOL)inSuppressBottomBorder;

- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor dividerColor:(NSColor *)inDividerColor;

@end
