/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
//It appears to be leaking an NSString somehow.
+ (NSFont *)cachedFontWithName:(NSString *)fontName size:(float)fontSize
{
    static NSMutableDictionary	*fontDict = nil;
    NSString					*sizeString = [NSString stringWithFormat:@"%0.2f",fontSize];
    NSMutableDictionary			*sizeDict = nil;
    NSFont						*font = nil;

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

		//If the font doesn't exist on the system, use the controlContentFont
		if (!font){
			font = [NSFont controlContentFontOfSize:fontSize];
			NSAssert(font != nil, @"controlContentFont not found.");
		}

        [sizeDict setObject:font
                     forKey:sizeString];
        [fontDict setObject:sizeDict forKey:fontName];
    }

    return(font);
}

//Returns an attributed string containing this font.  Useful for saving & restoring fonts to preferences/plists
- (NSAttributedString *)stringRepresentation
{
    return([NSString stringWithFormat:@"%@,%i",[self fontName],(int)[self pointSize]]);
}

- (BOOL)supportsBold
{
	NSFontManager	*fontManager = [NSFontManager sharedFontManager];

	if(self != [fontManager convertFont:self toHaveTrait:NSBoldFontMask] || 
	   self != [fontManager convertFont:self toHaveTrait:NSUnboldFontMask]){
		return YES;
	}
	
	return NO;
}

- (BOOL)supportsItalics
{
	NSFontManager	*fontManager = [NSFontManager sharedFontManager];
	
	if(self != [fontManager convertFont:self toHaveTrait:NSItalicFontMask] || 
	   self != [fontManager convertFont:self toHaveTrait:NSUnitalicFontMask]){
		return YES;
	}
	
	return NO;
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
