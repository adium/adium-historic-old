//
//  AIFlexibleTableFramedTextCell.h
//  Adium
//
//  Created by Adam Iser on Tue Sep 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableTextCell.h"

@interface AIFlexibleTableFramedTextCell : AIFlexibleTableTextCell {
    BOOL	drawTop;
    BOOL	drawBottom;
    BOOL        drawLeft;
    BOOL        drawRight;
    BOOL        drawSides;

    BOOL    suppressTopLeftCorner;
    BOOL    suppressTopRightCorner;
    BOOL    suppressBottomRightCorner;
    BOOL    suppressBottomLeftCorner;
    BOOL    suppressTopBorder;
    BOOL    suppressBottomBorder;
    
    NSColor 	*borderColor;
    NSColor	*bubbleColor;
}
+ (AIFlexibleTableFramedTextCell *)cellWithAttributedString:(NSAttributedString *)inString;

- (id)initWithAttributedString:(NSAttributedString *)inString;

- (void)setDrawTop:(BOOL)inDrawTop;
- (void)setDrawBottom:(BOOL)inDrawBottom;
- (void)setDrawLeft:(BOOL)inDrawLeft;
- (void)setDrawRight:(BOOL)inDrawRight;

- (void)setSuppressTopRightCorner:(BOOL)inSuppressTopRightCorner;
- (void)setSuppressTopLeftCorner:(BOOL)inSuppressTopLeftCorner;
- (void)setSuppressBottomRightCorner:(BOOL)inSuppressBottomRightCorner;
- (void)setSuppressBottomLeftCorner:(BOOL)inSuppressBottomLeftCorner;
- (void)setSuppressTopBorder:(BOOL)inSuppressTopBorder;
- (void)setSuppressBottomBorder:(BOOL)inSuppressBottomBorder;

- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor;

@end
