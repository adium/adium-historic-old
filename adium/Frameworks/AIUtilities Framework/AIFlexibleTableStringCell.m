//
//  AIFlexibleTableStringCell.m
//  Adium
//
//  Created by Adam Iser on Mon Sep 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableStringCell.h"

@interface AIFlexibleTableStringCell (PRIVATE)
- (AIFlexibleTableStringCell *)initWithAttributedString:(NSAttributedString *)inString;
@end

@implementation AIFlexibleTableStringCell

//
+ (AIFlexibleTableStringCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment
{
    AIFlexibleTableStringCell	*cell;
    NSDictionary		*attributes;
    NSAttributedString		*attributedString;

    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
	inTextColor, NSForegroundColorAttributeName,
	inFont, NSFontAttributeName,
	[NSParagraphStyle styleWithAlignment:inAlignment], NSParagraphStyleAttributeName,
	nil];
    attributedString = [[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease];

    //Build the cell
    cell = [AIFlexibleTableStringCell cellWithAttributedString:attributedString];
    [cell setType:NSTextCellType];

    return(cell);
}

//Create a new cell from an attributed string
+ (AIFlexibleTableStringCell *)cellWithAttributedString:(NSAttributedString *)inString
{
    return([[[self alloc] initWithAttributedString:inString] autorelease]);
}

//
- (AIFlexibleTableStringCell *)initWithAttributedString:(NSAttributedString *)inString
{
    [super init];

    string = [inString retain];
    contentSize = [string size];

    return(self);
}

//
- (void)dealloc
{
    [string release];

    [super dealloc];
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [string drawInRect:cellFrame];
}

@end
