//
//  AIFlexibleTableCell.m
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIFlexibleTableCell.h"

#define FRACTIONAL_PADDING 1.0

@interface AIFlexibleTableCell (PRIVATE)
- (AIFlexibleTableCell *)initWithAttributedString:(NSAttributedString *)inString;
- (void)dealloc;
@end

@implementation AIFlexibleTableCell

//Create a new cell from an attributed string
+ (AIFlexibleTableCell *)cellWithAttributedString:(NSAttributedString *)inString
{
    return([[[self alloc] initWithAttributedString:inString] autorelease]);    
}

//Create a new cell from a regular string and properties
+ (AIFlexibleTableCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment background:(NSColor *)inBackColor gradient:(NSColor *)inGradientColor
{
    AIFlexibleTableCell		*cell;
    NSDictionary		*attributes;
    NSMutableParagraphStyle	*paragraphStyle;
    NSAttributedString		*attributedString;

    //Create a paragraph style with the correct alignment
    paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setAlignment:inAlignment];

    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:inTextColor, NSForegroundColorAttributeName, inFont, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    attributedString = [[NSAttributedString alloc] initWithString:inString attributes:attributes];

    //Build the cell
    cell = [AIFlexibleTableCell cellWithAttributedString:attributedString];
    if(inGradientColor){
        [cell setBackgroundGradientFrom:inBackColor to:inGradientColor];
    }else{
        [cell setBackgroundColor:inBackColor];
    }

    return(cell);
}

//init
- (AIFlexibleTableCell *)initWithAttributedString:(NSAttributedString *)inString
{    
    [super init];
    
    backgroundColor = nil;
    gradientColor = nil;
    dividerColor = nil;
    drawContents = YES;

    textStorage = nil;
    textContainer = nil;
    layoutManager = nil;
    
    cellSize = [inString size];
    string = [inString retain];
    frame = NSMakeRect(0,0,0,0);
    selected = NO;

    return(self);
}

//dealloc
- (void)dealloc
{
    [backgroundColor release];
    [gradientColor release];
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [dividerColor release];
    [string release];
    
    [super dealloc];
}

//Configure ----------------------------------------------------------------------
- (void)setBackgroundColor:(NSColor *)inColor
{
    if(backgroundColor != inColor){
        [backgroundColor release]; backgroundColor = nil;
        backgroundColor = [inColor retain];
    }
    [gradientColor release]; gradientColor = nil;
}

- (void)setBackgroundGradientFrom:(NSColor *)inColorA to:(NSColor *)inColorB
{
    if(backgroundColor != inColorA){
        [backgroundColor release]; backgroundColor = nil;
        backgroundColor = [inColorA retain];
    }
    if(gradientColor != inColorB){
        [gradientColor release]; gradientColor = nil;
        gradientColor = [inColorB retain];
    }
}

- (void)setDrawContents:(BOOL)inValue
{
    drawContents = inValue;
}

- (void)setDividerColor:(NSColor *)inColor
{
    if(inColor != dividerColor){
        [dividerColor release]; dividerColor = nil;
        dividerColor = [inColor retain];
    }
}

- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom
{
    leftPadding = inLeft;
    rightPadding = inRight;
    topPadding = inTop;
    bottomPadding = inBottom;
}

- (void)setSelected:(BOOL)inSelected
{
    selected = inSelected;
}


// Access ------------------------------------------------------------------------------
- (NSSize)paddingInset{
    return(NSMakeSize(leftPadding, topPadding));
}

- (NSAttributedString *)string{
    return(string);
}

// Sizing ------------------------------------------------------------------------------
//Returns the size required to display this cell without wrapping
- (NSSize)cellSize
{
    return(NSMakeSize(cellSize.width + (leftPadding + rightPadding) + FRACTIONAL_PADDING, cellSize.height + (topPadding + bottomPadding))); //We add padding to offset any fractional character widths
}

//Dynamically resizes this cell for the desired width
- (void)sizeCellForWidth:(float)inWidth
{
    if(!textStorage){
        //Once a dynamic width is requested, we build the necessary text management instances to handle wrapping and formatting.  This avoids the overhead (memory and speed) of these classes when drawing simple, non-wrapping strings.  Once these classes are present, this cell will use them to draw and properly wrap.

        //Setup the layout manager and text container
        textStorage = [[NSTextStorage alloc] initWithAttributedString:string];
        textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1e7, 1e7)];
        layoutManager = [[NSLayoutManager alloc] init];

        [textContainer setLineFragmentPadding:0.0];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
    }
    
    //Reformat the text
    [textContainer setContainerSize:NSMakeSize(inWidth - (leftPadding + rightPadding)/* - FRACTIONAL_PADDING*/, 1e7)];
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    //Save the new cell dimensions
    cellSize = [layoutManager usedRectForTextContainer:textContainer].size;
}

// Drawing -------------------------------------------------------------------------------
//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    frame = cellFrame;
    
    //Draw the background
    if(!selected){
        if(!gradientColor){ //Plain background
            [backgroundColor set];
            [NSBezierPath fillRect:cellFrame];

        }else{ //Gradient background
            [AIGradient drawGradientInRect:cellFrame from:backgroundColor to:gradientColor];

        }
    }else{
        [[NSColor alternateSelectedControlColor] set];
        [NSBezierPath fillRect:cellFrame];
    }

    //Draw our divider line (offset 0.5 for an aliased line)
    if(dividerColor){
        [dividerColor set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + 0.5)
                                  toPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + 0.5)];
    }

    //Draw our string contents
    if(drawContents){
        cellFrame.origin.x += leftPadding;
        cellFrame.size.width -= leftPadding + rightPadding;

        cellFrame.origin.y += topPadding;
        cellFrame.size.height -= topPadding + bottomPadding;

        if(!selected){
            if(layoutManager){ //Draw our string with wrapping (slower)
                [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];
            }else{
                [string drawInRect:cellFrame]; //Draw our string without wrapping (faster)
            }
        }else{
            NSMutableAttributedString *mutableString = [string mutableCopy];

            [mutableString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,[mutableString length])];

            if(layoutManager){ //Draw our string with wrapping (slower)
                NSTextStorage	*whiteTextStorage = [[NSTextStorage alloc] initWithAttributedString:mutableString];
                NSTextContainer	*whiteTextContainer = [[NSTextContainer alloc] initWithContainerSize:cellFrame.size];
                NSLayoutManager	*whiteLayoutManager = [[NSLayoutManager alloc] init];

                [whiteTextContainer setLineFragmentPadding:0.0];
                [whiteLayoutManager addTextContainer:whiteTextContainer];
                [whiteTextStorage addLayoutManager:whiteLayoutManager];

                [layoutManager drawGlyphsForGlyphRange:[whiteLayoutManager glyphRangeForTextContainer:whiteTextContainer]
                                               atPoint:cellFrame.origin];

                [whiteTextStorage release];
                [whiteTextContainer release];
                [whiteLayoutManager release];
                
            }else{
                [mutableString drawInRect:cellFrame]; //Draw our string in white
                
            }
            [mutableString release];
        }
    }
}

//Returns the last frame where this cell was drawn
- (NSRect)frame
{
    return(frame);
}


@end
