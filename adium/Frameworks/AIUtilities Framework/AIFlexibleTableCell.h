//
//  AISMVCell.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIFlexibleTableCell : NSCell {

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
    NSAttributedString	*string;
    BOOL		selected;

    //Text rendering cache
    NSTextStorage 	*textStorage;
    NSTextContainer 	*textContainer;
    NSLayoutManager 	*layoutManager;
    NSRange		glyphRange;
}

+ (AIFlexibleTableCell *)cellWithAttributedString:(NSAttributedString *)inString;
+ (AIFlexibleTableCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment background:(NSColor *)inBackColor gradient:(NSColor *)inGradientColor;

//Configure
- (void)setBackgroundColor:(NSColor *)inColor;
- (void)setBackgroundGradientFrom:(NSColor *)inColorA to:(NSColor *)inColorB;
- (void)setDrawContents:(BOOL)inValue;
- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom;
- (void)setDividerColor:(NSColor *)inColor;
- (void)setSelected:(BOOL)inSelected;

//Access
- (NSAttributedString *)string;
- (NSSize)paddingInset;

//Sizing
- (NSSize)cellSize;
- (void)sizeCellForWidth:(float)inWidth;

//Drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSRect)frame;

@end
