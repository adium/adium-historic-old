//
//  GetMetadataForHTMLLog-Additions.m
//  AdiumSpotlightImporter
//
//  Created by Evan Schoenberg on 5/25/06.
//

#import "GetMetadataForHTMLLog-Additions.h"

/*
 * @brief These additions are all from AIUtilities
 *
 * The spotlight importer should include this file to get these specific additions.
 * If the GetMetadataForHTMLLog class is used in a situation in which AIUtilities is linked in already, it is
 * not necessary to include this implementation file.
 */
@implementation NSScanner (AdiumSpotlightImporterAdditions)

- (BOOL)scanUnsignedInt:(unsigned int *)unsignedIntValue
{
	//skip characters if necessary
	NSCharacterSet *skipSet = [self charactersToBeSkipped];
	[self setCharactersToBeSkipped:nil];
	[self scanCharactersFromSet:skipSet intoString:NULL];
	[self setCharactersToBeSkipped:skipSet];
	
	NSString *string = [self string];
	NSRange range = NSMakeRange([self scanLocation], 0);
	register unsigned length = [string length] - range.location; //register because it is used in the loop below.
	range.length = length;
	
	unichar *buf = malloc(length * sizeof(unichar));
	[string getCharacters:buf range:range];
	
	register unsigned i = 0;
	
	if (length && (buf[i] == '+')) {
		++i;
	}
	if (i >= length) return NO;
	if ((buf[i] < '0') || (buf[i] > '9')) return NO;
	
	unsigned total = 0;
	while (i < length) {
		if ((buf[i] >= '0') && (buf[i] <= '9')) {
			total *= 10;
			total += buf[i] - '0';
			++i;
		} else {
			break;
		}
	}
	[self setScanLocation:i];
	*unsignedIntValue = total;
	return YES;
}

@end

//From AIUtilities
@implementation NSString (AdiumSpotlightImporterAdditions)

BOOL AIGetSurrogates(UTF32Char in, UTF16Char *outHigh, UTF16Char *outLow)
{
	if (in < 0x10000) {
		if (outHigh) *outHigh = 0;
		if (outLow)  *outLow  = in;
		return NO;
	} else {
		enum {
			UTF32LowShiftToUTF16High = 10,
			UTF32HighShiftToUTF16High,
			UTF16HighMask = 31,  //0b0000 0111 1100 0000
			UTF16LowMask  = 63,  //0b0000 0000 0011 1111
			UTF32LowMask = 1023, //0b0000 0011 1111 1111
			UTF16HighAdditiveMask = 55296, //0b1101 1000 0000 0000
			UTF16LowAdditiveMask  = 56320, //0b1101 1100 0000 0000
		};
		
		if (outHigh) {
			*outHigh = \
			((in >> UTF32HighShiftToUTF16High) & UTF16HighMask) \
			| ((in >> UTF32LowShiftToUTF16High) & UTF16LowMask) \
			| UTF16HighAdditiveMask;
		}
		
		if (outLow) {
			*outLow = (in & UTF32LowMask) | UTF16LowAdditiveMask;
		}
		
		return YES;
	}
}

- (NSString *)stringByUnescapingFromHTML
{
	if ([self length] == 0) return [[self copy] autorelease]; //avoids various RangeExceptions.
	
	static NSString *ampersand = @"&", *semicolon = @";";
	
	NSString *segment = nil, *entity = nil;
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCaseSensitive:YES];
	unsigned myLength = [self length];
	NSMutableString *result = [NSMutableString string];
	
	do {
		if ([scanner scanUpToString:ampersand intoString:&segment] || [self characterAtIndex:[scanner scanLocation]] == '&') {
			if (segment) {
				[result appendString:segment];
				segment = nil;
			}
			if (![scanner isAtEnd]) {
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		}
		if ([scanner scanUpToString:semicolon intoString:&entity]) {
			unsigned number;
			if ([entity characterAtIndex:0] == '#') {
				NSScanner	*numScanner;
				unichar		secondCharacter;
				BOOL		appendIt = NO;
				
				numScanner = [NSScanner scannerWithString:entity];
				[numScanner setCaseSensitive:YES];
				secondCharacter = [entity characterAtIndex:1];
				
				if (secondCharacter == 'x' || secondCharacter == 'X') {
					//hexadecimal: "#x..." or "#X..."
					[numScanner setScanLocation:2];
					appendIt = [numScanner scanHexInt:&number];
					
				} else {
					//decimal: "#..."
					[numScanner setScanLocation:1];
					appendIt = [numScanner scanUnsignedInt:&number];
				}
				
				if (appendIt) {
					unichar chars[2] = { number, 0xffff };
					CFIndex length = 1;
					if (number > 0xffff) {
						//split into surrogate pair
						AIGetSurrogates(number, &chars[0], &chars[1]);
						++length;
					}
					CFStringAppendCharacters((CFMutableStringRef)result, chars, length);
				}
			} else {
				//named entity. for now, we only support the five essential ones.
				static NSDictionary *entityNames = nil;
				if (entityNames == nil) {
					entityNames = [[NSDictionary alloc] initWithObjectsAndKeys:
						[NSNumber numberWithUnsignedInt:'"'], @"quot",
						[NSNumber numberWithUnsignedInt:'&'], @"amp",
						[NSNumber numberWithUnsignedInt:'<'], @"lt",
						[NSNumber numberWithUnsignedInt:'>'], @"gt",
						[NSNumber numberWithUnsignedInt:' '], @"nbsp",
						nil];
				}
				number = [[entityNames objectForKey:[entity lowercaseString]] unsignedIntValue];
				if (number) {
					[result appendFormat:@"%C", (unichar)number];
				}
			}
			if (![scanner isAtEnd]) {
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		} //if ([scanner scanUpToString:semicolon intoString:&entity])
	} while ([scanner scanLocation] < myLength);
	//	NSLog(@"unescaped %@\ninto %@", self, result);
	return result;
}

@end