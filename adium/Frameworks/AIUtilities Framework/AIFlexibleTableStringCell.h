//
//  AIFlexibleTableStringCell.h
//  Adium
//
//  Created by Adam Iser on Mon Sep 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableCell.h"

@interface AIFlexibleTableStringCell : AIFlexibleTableCell {
    NSAttributedString	*string;
}

+ (AIFlexibleTableStringCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment;
+ (AIFlexibleTableStringCell *)cellWithAttributedString:(NSAttributedString *)inString;

@end
