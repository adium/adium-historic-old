//
//  AIFontAdditions.m
//  Adium
//
//  Created by Adam Iser on Wed Dec 25 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AIFontAdditions.h"


@implementation NSFont (AIFontAdditions)

//Returns the requested font
//NSFont's 'FontWithName' method leaks memory.  This wrapper attempts to minimize the leaking.
+ (NSFont *)cachedFontWithName:(NSString *)fontName size:(float)fontSize
{
    static NSMutableDictionary	*fontDict = nil;
    NSString			*sizeString = [NSString stringWithFormat:@"%0.2f",fontSize];
    NSMutableDictionary		*sizeDict = nil;
    NSFont			*font = nil;

    if(!fontDict){
        fontDict = [[NSMutableDictionary alloc] init];
    }

    sizeDict = [fontDict objectForKey:fontName];
    if(!sizeDict){
        sizeDict = [[NSMutableDictionary alloc] init];
        [fontDict setObject:sizeDict forKey:fontName];
    }

    font = [sizeDict objectForKey:sizeString];
    if(!font){
        font = [NSFont fontWithName:fontName size:fontSize];

        [sizeDict setObject:font
                     forKey:[NSString stringWithFormat:@"%0.2f",fontSize]];
        [fontDict setObject:sizeDict forKey:fontName];
    }

    return(font);
}

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
