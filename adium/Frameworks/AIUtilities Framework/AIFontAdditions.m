/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

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
        sizeDict = [NSMutableDictionary dictionary];
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

    return([NSFont cachedFontWithName:fontName size:fontSize]);
}

@end
