/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#include <unistd.h>
#include <limits.h>

@implementation NSString (AIStringAdditions)

//Random alphanumeric string
+ (NSString *)randomStringOfLength:(unsigned int)inLength
{
	srandom(TickCount());

	if(!inLength) return [NSString string];

	NSString *string = nil;
	char *buf = malloc(inLength);

	if(buf) {
		static const char alphanumeric[] = {
			'0', '1', '2', '3', '4', '5', '6', '7',
			'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
			'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
			'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
			'W', 'X', 'Y', 'Z'
		};
		register unsigned remaining = inLength;
		while(remaining--) {
			buf[remaining] = alphanumeric[random() % sizeof(alphanumeric)];
		}
		string = [[[NSString alloc] initWithBytes:buf length:inLength encoding:NSASCIIStringEncoding] autorelease];
		free(buf);
	}

	return string;
}

+ (NSString *)stringWithContentsOfASCIIFile:(NSString *)path
{
	return ([[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path]
								   encoding:NSASCIIStringEncoding] autorelease]);
}


/*	compactedString
 *	returns the string in all lowercase without spaces
 */
- (NSString *)compactedString
{
	NSMutableString 	*outName;
	unsigned			pos = 0, len;
	NSRange				range;
	range.length = 0;
	
	outName = [self mutableCopy];
	CFStringLowercase((CFMutableStringRef)outName, /*locale*/ NULL);
	len = [outName length];
	
	while(pos < len) {
		if([outName characterAtIndex:pos] == ' ') {
			if(range.length++ == 0) {
				range.location = pos;
			}
			++pos;
		} else {
			if(range.length) {
				[outName deleteCharactersInRange:range];
				pos  = range.location;
				len -= range.length;
				range.length = 0;
			} else {
				++pos;
			}
		}
	}
	
	return([outName autorelease]);
}

- (int)intValueFromHex
{
    NSScanner	*scanner = [NSScanner scannerWithString:self];
    unsigned	value;

    [scanner scanHexInt:&value];

    return(value);
}

#define BUNDLE_STRING	@"$$BundlePath$$"
//
- (NSString *)stringByExpandingBundlePath
{
    if([self hasPrefix:BUNDLE_STRING]){
        return [[[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath] stringByAppendingString:[self substringFromIndex:[BUNDLE_STRING length]]];
    }else{
        return(self);
    }
}

//
- (NSString *)stringByCollapsingBundlePath
{
    NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath];

    if([self hasPrefix:bundlePath]){
        return [BUNDLE_STRING stringByAppendingString:[self substringFromIndex:[bundlePath length]]];
    }else{
        return(self);
    }
}


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
		returnString = [[self substringToIndex:length-1] stringByAppendingString:[NSString stringWithUTF8String:"\xE2\x80\xA6"]];
	} else {
		//We don't need to truncate, so don't append an ellipsis
		returnString = [[self retain] autorelease];
	}
	
	return (returnString);
}

- (NSString *)safeFilenameString
{
	//create a translation table for fast substitution.
	static UniChar table[USHRT_MAX + 1];
	static BOOL tableInitialized = NO;
	NSString *result;
	if(!tableInitialized) {
		for(register unsigned i = 0; i <= USHRT_MAX; ++i) {
			table[i] = i;
		}
		table['/'] = '-';
		tableInitialized = YES;
	}

	unsigned length = [self length];
	if(length > NAME_MAX) {
		NSLog(@"-safeFilenameString called on a string longer than %u characters (it will be truncated): @\"%@\"", NAME_MAX, self);
		length = NAME_MAX;
	}
	if(!length) {
		//it will be an empty string anyway, so save the malloc and all the translation work.
		result = [NSString string];
	} else {
		//there are characters here; translate them.
		NSRange range = { 0, length };
		UniChar *buf = malloc(length * sizeof(UniChar));
		if(!buf) {
			//can't malloc the memory - see if NSMutableString can do it
			NSMutableString *string = [self mutableCopy];
	
			[string replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:range];
	
			result = [string autorelease];
		} else {
			CFStringGetCharacters((CFStringRef)self, *(CFRange *)&range, buf);
	
			register unsigned remaining = length;
			register UniChar *ch = buf;
			while(remaining--) {
				*ch = table[*ch];
				++ch;
			}
	
			result = [NSString stringWithCharacters:buf length:length];
			free(buf);
		}
	}

	return result;
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

//stringByEncodingURLEscapes
// Percent escape all characters except for a-z, A-Z, 0-9, '_', and '-'
// Convert spaces to '+'
- (NSString *)stringByEncodingURLEscapes
{
    unsigned		sourceLength = [self length];
    const char		*cSource = [self cString];
    char			*cDest;
    NSMutableData	*destData;
    unsigned		s = 0;
    unsigned		d = 0;
	
    //Worst case scenario is 3 times the original length (every character escaped)
    destData = [NSMutableData dataWithLength:(sourceLength * 3)];
    cDest = [destData mutableBytes];
    
    while(s < sourceLength){
        char	ch = cSource[s];
		
        if( (ch >= 'a'  &&  ch <= 'z') ||
            (ch >= 'A'  &&  ch <= 'Z') ||
            (ch >= '0'  &&  ch <= '9') ||
            (ch == '_') || (ch == '-'))
		{
            
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
	
    return [[[NSString alloc] initWithBytes:cDest length:d encoding:NSASCIIStringEncoding] autorelease];
}

//stringByDecodingURLEscapes
// Remove percent escapes for all characters except for a-z, A-Z, 0-9, '_', and '-', converting to original character
// Convert '+' back to a space
- (NSString *)stringByDecodingURLEscapes
{
    unsigned		sourceLength = [self length];
    const char		*cSource = [self cString];
    char			*cDest;
    NSMutableData	*destData;
    unsigned		s = 0;
    unsigned		d = 0;
	
    //Best case scenario is 1/3 the original length (every character escaped); worst should be the same length
    destData = [NSMutableData dataWithLength:sourceLength];
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
	
    return [[[NSString alloc] initWithBytes:cDest length:d encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)string
{
	return self;
}

- (NSString *)stringByEscapingForHTML
{
	NSCharacterSet *mustBeEscaped = [NSCharacterSet characterSetWithCharactersInString:@"&<>\""];
	NSMutableString *result = [NSMutableString string];
	NSString *lastChunk = nil;
	NSScanner *scanner = [NSScanner scannerWithString:self];

	//We don't want to skip any characters; NSScanner skips whitespace and newlines by default
	[scanner setCharactersToBeSkipped:[[[NSCharacterSet alloc] init] autorelease]];
	
	unsigned curLocation = 0, maxLocation = [self length];

	while(1) {
		if ([scanner scanUpToCharactersFromSet:mustBeEscaped intoString:&lastChunk]){
			[result appendString:lastChunk];
			curLocation = [scanner scanLocation];
		}
		if(curLocation >= maxLocation){
			break;

		}else{
			switch([self characterAtIndex:curLocation]) {
				case '&':
					[result appendString:@"&amp;"];
					break;
				case '"':
					[result appendString:@"&quot;"];
					break;
				case '<':
					[result appendString:@"&lt;"];
					break;
				case '>':
					[result appendString:@"&gt;"];
					break;
				/*
					case ' ':
					[result appendString:@"&nbsp;"];
					break;
				*/
			}
			[scanner setScanLocation:++curLocation];
		}
	}
	
//	NSLog(@"escaped string: %@\ninto string: %@", self, result);
	return result;
}

- (NSString *)stringByUnescapingFromHTML
{
	if([self length] == 0) return self; //avoids various RangeExceptions.
	
	static NSString *ampersand = @"&", *semicolon = @";";
	
	NSString *segment = nil, *entity = nil;
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCaseSensitive:YES];
	unsigned myLength = [self length];
	NSMutableString *result = [NSMutableString string];
	
	do {
		if([scanner scanUpToString:ampersand intoString:&segment] || [self characterAtIndex:[scanner scanLocation]] == '&') {
//			NSLog(@"scanned to ampersand");
			if(segment) {
				[result appendString:segment];
				segment = nil;
			}
			if(![scanner isAtEnd]) {
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		}
		if([scanner scanUpToString:semicolon intoString:&entity]) {
			unsigned number;
			if([entity characterAtIndex:0] == '#') {
//				NSLog(@"it's numeric: entity is %@", entity);
				NSScanner *numScanner = [NSScanner scannerWithString:entity];
				[numScanner setCaseSensitive:YES];
				unichar secondCharacter = [entity characterAtIndex:1];
				BOOL appendIt = NO;
				if(secondCharacter == 'x' || secondCharacter == 'X') {
					//hexadecimal: "#x..." or "#X..."
//					NSLog(@"characterAtIndex:2 == '%C'", [entity characterAtIndex:2]);
					[numScanner setScanLocation:2];
					appendIt = [numScanner scanHexInt:&number];
				} else {
					//decimal: "#..."
//					NSLog(@"characterAtIndex:1 == '%C'", [entity characterAtIndex:1]);
					[numScanner setScanLocation:1];
					appendIt = [numScanner scanUnsignedInt:&number];
				}
//				NSLog(@"appendIt: %u", appendIt);
				if(appendIt) {
					unichar chars[2] = { number, 0xffff };
					CFIndex length = 1;
					if(number > 0xffff) {
						//split into surrogate pair
						AIGetSurrogates(number, &chars[0], &chars[1]);
						++length;
					}
					CFStringAppendCharacters((CFMutableStringRef)result, chars, length);
				}
			} else {
				//named entity. for now, we only support the five essential ones.
				static NSDictionary *entityNames = nil;
				if(entityNames == nil) {
					entityNames = [[NSDictionary alloc] initWithObjectsAndKeys:
						[NSNumber numberWithUnsignedInt:'"'], @"quot",
						[NSNumber numberWithUnsignedInt:'&'], @"amp",
						[NSNumber numberWithUnsignedInt:'<'], @"lt",
						[NSNumber numberWithUnsignedInt:'>'], @"gt",
						[NSNumber numberWithUnsignedInt:' '], @"nbsp",
						nil];
				}
				number = [[entityNames objectForKey:[entity lowercaseString]] unsignedIntValue];
//				NSLog(@"named entity: entity value for name @\"%@\" is (0x%x) '%C'", [entity lowercaseString], (unichar)number, number);
				if(number) {
					[result appendFormat:@"%C", (unichar)number];
				}
			}
			if(![scanner isAtEnd]) {
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		} //if([scanner scanUpToString:semicolon intoString:&entity])
	} while([scanner scanLocation] < myLength);
//	NSLog(@"unescaped %@\ninto %@", self, result);
	return result;
}

enum characterNatureMask {
	whitespaceNature = 0x1, //space + \t\n\r\f\a 
	unsafeNature, //backslash + !$`"'
};
static enum characterNatureMask characterNature[USHRT_MAX+1] = {
	//this array is initialised such that the space character (0x20)
	//	does not have the whitespace nature.
	//this was done for brevity, as the entire array is bzeroed and then
	//	properly initialised in -stringByEscapingForShell below.
	0,0,0,0, 0,0,0,0, //0x00..0x07
	0,0,0,0, 0,0,0,0, //0x08..0x0f
	0,0,0,0, 0,0,0,0, //0x10..0x17
	0,0,0, //0x18..0x20
};

- (NSString *)stringByEscapingForShell
{
	if(!(characterNature[' '] & whitespaceNature)) {
		//if space doesn't have the whitespace nature, clearly we need to build the nature array.

		//first, set all characters to zero.
		bzero(&characterNature, sizeof(characterNature));

		//then memorise which characters have the whitespace nature.
		characterNature['\a'] = whitespaceNature;
		characterNature['\t'] = whitespaceNature;
		characterNature['\n'] = whitespaceNature;
		characterNature['\f'] = whitespaceNature;
		characterNature['\r'] = whitespaceNature;
		characterNature[' ']  = whitespaceNature;
		//NOTE: if you give more characters the whitespace nature, be sure to
		//	update escapeNames below.

		//finally, memorise which characters have the unsafe (for shells) nature.
		characterNature['\\'] = unsafeNature;
		characterNature['\''] = unsafeNature;
		characterNature['"']  = unsafeNature;
		characterNature['`']  = unsafeNature;
		characterNature['!']  = unsafeNature;
		characterNature['$']  = unsafeNature;
	}

	unsigned myLength = [self length];
	unichar *myBuf = malloc(sizeof(unichar) * myLength);
	if(!myBuf) return nil;
	[self getCharacters:myBuf];
	const unichar *myBufPtr = myBuf;

	size_t buflen = 0;
	unichar *buf = NULL;

	const size_t buflenIncrement = getpagesize() / sizeof(unichar);

	/*the boundary guard happens everywhere that i increases, and MUST happen
	 *	at the beginning of the loop.
	 *
	 *initialising buflen to 0 and buf to NULL as we have done above means that
	 *	realloc will act as malloc:
	 *	-	i is 0 at the beginning of the loop
	 *	-	so is buflen
	 *	-	and buf is NULL
	 *	-	realloc(NULL, ...) == malloc(...)
	 *
	 *oh, and 'SBEFS' stands for String By Escaping For Shell
	 *	(the name of this method).
	 */
#define SBEFS_BOUNDARY_GUARD \
	do { \
		if(i == buflen) { \
			buf = realloc(buf, sizeof(unichar) * (buflen += buflenIncrement)); \
			if(!buf) { \
				NSLog(@"in stringByEscapingForShell: could not allocate %lu bytes", (unsigned long)(sizeof(unichar) * buflen)); \
				free(myBuf); \
				return nil; \
			} \
		} \
	} while(0)

	unsigned i = 0;
	for(; myLength--; ++i) {
		SBEFS_BOUNDARY_GUARD;

		if(characterNature[*myBufPtr] & whitespaceNature) {
			//escape this character using a named escape
			static unichar escapeNames[] = {
				0, 0, 0, 0, 0, 0, 0,
				'a', //0x07 BEL: '\a' 
				0,
				't', //0x09 HT: '\t'
				'n', //0x0a LF: '\n'
				0,
				'f', //0x0c FF: '\f'
				'r', //0x0d CR: '\r'
				0, 0, //0x0e-0x0f
				0, 0, 0, 0,  0, 0, 0, 0, //0x10-0x17
				0, 0, 0, 0,  0, 0, 0, 0, //0x18-0x1f
				' ', //0x20 SP: '\ '
			};
			buf[i++] = '\\';
			SBEFS_BOUNDARY_GUARD;
			buf[i] = escapeNames[*myBufPtr];
		} else {
			if(characterNature[*myBufPtr] & unsafeNature) {
				//escape this character
				buf[i++] = '\\';
				SBEFS_BOUNDARY_GUARD;
			}

			buf[i] = *myBufPtr;
		}
		++myBufPtr;
	}

#undef SBEFS_BOUNDARY_GUARD

	free(myBuf);

	NSString *result = [NSString stringWithCharacters:buf length:i];
	free(buf);

	return result;
}

- (NSString *)volumePath
{
	NSEnumerator *pathEnum = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] objectEnumerator];
	NSString *volumePath;
	while((volumePath = [pathEnum nextObject])) {
		if([self hasPrefix:[volumePath stringByAppendingString:@"/"]])
			break;
	}
	if(!volumePath)
		volumePath = @"/";
	return volumePath;
}

@end
