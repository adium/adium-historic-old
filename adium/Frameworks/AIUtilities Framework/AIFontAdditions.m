//
//  AIFontAdditions.m
//  Adium
//
//  Created by Adam Iser on Wed Dec 25 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AIFontAdditions.h"


@implementation NSFont (AIFontAdditions)

//Returns an attributed string containing this font.  Useful for saving & restoring fonts to preferences/plists
- (NSAttributedString *)stringRepresentation
{
    return([NSString stringWithFormat:@"%@,%i",[self fontName],(int)[self pointSize]]);
}

@end

@implementation NSString (AIFontAdditions)

- (NSFont *)representedFont
{
    NSString	*fontName;
    float	fontSize;
    int		divider;
    
    divider = [self rangeOfString:@","].location;
    fontName = [self substringToIndex:divider];
    fontSize = [[self substringFromIndex:divider+1] intValue];

    return([NSFont fontWithName:fontName size:fontSize]);
}

@end
