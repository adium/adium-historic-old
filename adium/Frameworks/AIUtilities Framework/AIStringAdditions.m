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

#import "AIStringAdditions.h"
#import <Carbon/Carbon.h>

@implementation NSString (AIStringAdditions)

//Random alphanumeric string
+ (NSString *)randomStringOfLength:(int)inLength
{
	NSMutableString	*string = [[NSString alloc] init];
	NSString		*randomCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	NSString		*randomString;
	int				i;
	
	//Prepare our random
	srandom(TickCount());

	//Add the random characters (This is a slow implementation, but it's not really important)
	for(i = 0; i < inLength; i++){
		char	randomChar = [randomCharacters characterAtIndex:(random() % [randomCharacters length])];
		string = [string stringByAppendingString:[NSString stringWithFormat:@"%c",randomChar]];
	}
	
	return([string autorelease]);
}

/* compactedString
*   returns the string in all lowercase without spaces
*/
- (NSString *)compactedString
{
    NSMutableString 	*outName;
    short		pos;

    outName = [[NSMutableString alloc] initWithString:[self lowercaseString]];
    for(pos = 0;pos < [outName length];pos++){
        if([outName characterAtIndex:pos] == ' '){
            [outName deleteCharactersInRange:NSMakeRange(pos,1)];
            pos--;
        }
    }

    return([outName autorelease]);
}

- (int)intValueFromHex
{
    NSScanner		*scanner = [NSScanner scannerWithString:self];
    int			value;

    [scanner scanHexInt:&value];

    return(value);
}

#define BUNDLE_STRING	@"$$BundlePath$$"
//
- (NSString *)stringByExpandingBundlePath
{
    if([self hasPrefix:BUNDLE_STRING]){
        return([NSString stringWithFormat:@"%@%@",
            [NSString stringWithFormat:[[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath]],
            [self substringFromIndex:[(NSString *)BUNDLE_STRING length]]]);
    }else{
        return(self);
    }
}

//
- (NSString *)stringByCollapsingBundlePath
{
    NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath];

    if([self hasPrefix:bundlePath]){
        return([NSString stringWithFormat:@"$$BundlePath$$%@",[self substringFromIndex:[bundlePath length]]]);
    }else{
        return(self);
    }
}

//
- (NSString *)stringByTruncatingTailToWidth:(float)inWidth
{
    NSMutableString 	*string = [self mutableCopy];
    
    //Use carbon to truncate the string (this only works when drawing in the system font!)
    TruncateThemeText((CFMutableStringRef)string, kThemeSmallSystemFont, kThemeStateActive, inWidth, truncEnd, NULL);
    
    return([string autorelease]);
}

@end
