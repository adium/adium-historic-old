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
#import "AIColorAdditions.h"

@implementation NSString (AIStringAdditions)

//Random alphanumeric string
+ (NSString *)randomStringOfLength:(unsigned int)inLength
{
    NSMutableString	*string = [[NSMutableString alloc] init];
    int				i;

    //Prepare our random
    srandom(TickCount());

    //Add the random characters
    for(i = 0; i < inLength; i++){
	//get a random number between 0 and 35
	int randomNum = (random() % 36);
	//0-9 are the digits; add 7 to get to A-Z
	if (randomNum > 9) randomNum+=7;
	
	char randomChar = '0' + randomNum;
	[string appendString:[NSString stringWithFormat:@"%c",randomChar]];
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

- (NSString *)stringWithEllipsisByTruncatingToLength:(unsigned int)length
{
	NSString *returnString;
	
	if (length < [self length]) {
		//Truncate and append the ellipsis
		returnString = [[self substringToIndex:length] stringByAppendingString:@"É"];
	} else {
		//We don't need to truncate, so don't append an ellipsis
		returnString = self;
	}
	
	return (returnString);
}

- (NSString *)safeFilenameString
{
    NSMutableString     *string = [self mutableCopy];
    
    [string replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0,[string length])];
    
    return([string autorelease]);
}

//- (NSString *)stringByEncodingURLEscapes
//{
//    NSScanner *s = [NSScanner scannerWithString:self];
//    NSCharacterSet *notUrlCode = [[NSCharacterSet characterSetWithCharactersInString:
//        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.+!*'(),;/?:@=&"] 		invertedSet];
//    NSMutableString *encodedString = [[NSMutableString alloc] initWithString:@""];
//    NSString *read;
//    
//    while(![s isAtEnd])
//    {
//        [s scanUpToCharactersFromSet:notUrlCode intoString:&read];
//        if(read)
//            [encodedString appendString:read];
//        if(![s isAtEnd])
//        {
//            [encodedString appendFormat:@"%%%x", [self characterAtIndex:[s scanLocation]]];
//            [s setScanLocation:[s scanLocation]+1];
//        }
//    }
//    
//    return([encodedString autorelease]);
//}
//
//- (NSString *)stringByDecodingURLEscapes
//{
//    NSScanner *s = [NSScanner scannerWithString:self];
//    NSMutableString *decodedString = [[NSMutableString alloc] initWithString:@""];
//    NSString *read;
//    
//    while(![s isAtEnd])
//    {
//        [s scanUpToString:@"%" intoString:&read];
//        if(read)
//            [decodedString appendString:read];
//        if(![s isAtEnd])
//        {
//            [decodedString appendString:[NSString stringWithFormat:@"%c", 
//                [[NSString stringWithFormat:@"%li",
//                    strtol([[self substringWithRange:NSMakeRange([s scanLocation]+1, 2)] cString], 
//                        NULL, 16)] 
//                intValue]]];
//                
//            [s setScanLocation:[s scanLocation]+3];
//
//        }
//    }
//    return([decodedString autorelease]);
//
//}
//
//- (BOOL)isURLEncoded
//{
//    NSCharacterSet *notUrlCode = [[NSCharacterSet characterSetWithCharactersInString:
//        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.+!*'(),;/?:@=&"] 		invertedSet];
//    NSCharacterSet *notHexSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCEFabcdef"]
//        invertedSet];
//    NSScanner *s = [NSScanner scannerWithString:self]; 
//    
//    if([self rangeOfCharacterFromSet:notUrlCode].location != NSNotFound)
//        return NO;
//    
//    while(![s isAtEnd])
//    {
//        [s scanUpToString:@"%" intoString:nil];
//        
//        if([[self substringWithRange:NSMakeRange([s scanLocation]+1, 2)] rangeOfCharacterFromSet:notHexSet].location != NSNotFound)
//            return NO;
//    }
//    
//    return YES;
//}








//char intToHex(int digit)
//{
//    if(digit > 9){
//        return('a' + digit - 10);
//    }else{
//        return('0' + digit);
//    }
//}
//
//int hexToInt(char hex)
//{
//    if(hex >= '0' && hex <= '9'){
//        return(hex - '0');
//		
//    }else if(hex >= 'a' && hex <= 'f'){
//        return(hex - 'a' + 10);
//		
//    }else if(hex >= 'A' && hex <= 'F'){
//        return(hex - 'A' + 10);
//		
//    }else{
//        return(0);
//		
//    }
//}

//URLEncode
// Percent escape all characters except for a-z, A-Z, 0-9, '_', and '-'
// Convert spaces to '+'
- (NSString *)stringByEncodingURLEscapes
{
    int			sourceLength = [self length];
    const char		*cSource = [self cString];
    char		*cDest;
    NSMutableData	*destData;
    int			s = 0;
    int			d = 0;
	
    //Worst case scenario is 3 times the origional length (every character escaped)
    destData = [NSMutableData dataWithLength:(sourceLength * 3)];
    cDest = [destData mutableBytes];
    
    while(s < sourceLength){
        char	ch = cSource[s];
		
        if( (ch >= 'a' && ch <= 'z') ||
            (ch >= 'A' && ch <= 'Z') ||
            (ch >= '0' && ch <= '9') ||
            (ch == 95) || (ch == 45)){ //'_' or '-'
            
            cDest[d] = ch;
            d++;
        }else if(ch == ' '){
            cDest[d] = '+';
            d++;
			
        }else{
            cDest[d] = '%';
            cDest[d+1] = intToHex(ch / 16);
            cDest[d+2] = intToHex(ch % 16);
            d += 3;
        }
		
        s++;
    }
	
    return([NSString stringWithCString:cDest length:d]);
}

//URLEncode
// Percent escape all characters except for a-z, A-Z, 0-9, '_', and '-'
// Convert spaces to '+'
- (NSString *)stringByDecodingURLEscapes
{
    int			sourceLength = [self length];
    const char		*cSource = [self cString];
    char		*cDest;
    NSMutableData	*destData;
    int			s = 0;
    int			d = 0;
	
    //Worst case scenario is 3 times the origional length (every character escaped)
    destData = [NSMutableData dataWithLength:(sourceLength * 3)];
    cDest = [destData mutableBytes];
    
    while(s < sourceLength){
        char	ch = cSource[s];
		
        if(ch == '%'){
            cDest[d] = ( hexToInt(cSource[s+1]) * 16 ) + hexToInt(cSource[s+2]);
            s += 3;
			
        }else if(ch == '+'){
            cDest[d] = ' ';
            s++;
			
        }else{
            cDest[d] = ch;
            s++;
        }
		
        d++;
    }
	
    return([NSString stringWithCString:cDest length:d]);
}

- (NSString *)string
{
	return self;
}




@end
