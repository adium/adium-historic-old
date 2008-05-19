/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AHHyperlinkScanner.h"
#import "AHLinkLexer.h"
#import "AHMarkedHyperlink.h"

#define	DEFAULT_URL_SCHEME	@"http://"

@interface AHHyperlinkScanner (PRIVATE)
- (AHMarkedHyperlink *)nextURLFromString:(NSString *)inString;
@end

@implementation AHHyperlinkScanner

#pragma mark Init

/*!
 * @brief Init
 *
 * Defaults to strict URL checking (only links with schemes are matched).
 *
 * @return A new AHHyperlinkScanner.
 */
- (id)init
{
	return [self initWithStrictChecking:YES];
}

/*!
 * @brief Init
 *
 * @param flag Sets strict checking preference.
 * @return A new AHHyperlinkScanner.
 */- (id)initWithStrictChecking:(BOOL)flag
{
	if((self = [super init])){
		urlSchemes = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"ftp://", @"ftp",
			nil];
		useStrictChecking = flag;
		AHStringOffset = 0;
	}

	return self;
}

- (void)dealloc
{
	[urlSchemes release];
	[super dealloc];
}

#pragma mark utility

- (AH_URI_VERIFICATION_STATUS)validationStatus
{
	return validStatus;
}

#pragma mark primitive methods

/*!
 * @brief Determine the validity of a given string
 *
 * @param inString The string to be verified
 * @return Boolean
 */
- (BOOL)isStringValidURL:(NSString *)inString
{
    AH_BUFFER_STATE buf;  // buffer for flex to scan from
	const char		*inStringUTF8;
    unsigned		utf8Length;
    
	validStatus = AH_URL_INVALID; // assume the URL is invalid

	if (!(inStringUTF8 = [inString UTF8String])) {
		return NO;
	}

	utf8Length = strlen(inStringUTF8); // length of the string in utf-8
    
	// initialize the buffer (flex automatically switches to the buffer in this function)
    buf = AH_scan_string(inStringUTF8);

    // call flex to parse the input
    validStatus = AHlex();

    // condition for valid URI's
    if(validStatus == AH_URL_VALID || validStatus == AH_MAILTO_VALID || validStatus == AH_FILE_VALID){
        AH_delete_buffer(buf); //remove the buffer from flex.
        buf = NULL; //null the buffer pointer for safty's sake.
        
        // check that the whole string was matched by flex.
        // this prevents silly things like "blah...com" from being seen as links
        if(AHleng == utf8Length){
            return YES;
        }
    // condition for degenerate URL's (A.K.A. URI's sans specifiers), requres strict checking to be NO.
    }else if((validStatus == AH_URL_DEGENERATE || validStatus == AH_MAILTO_DEGENERATE) && !useStrictChecking){
        AH_delete_buffer(buf);
        buf = NULL;
        if(AHleng == utf8Length){
            return YES;
        }
    // if it ain't vaild, and it ain't degenerate, then it's invalid.
    }else{
        AH_delete_buffer(buf);
        buf = NULL;
        return NO;
    }
    // default case, if the range checking above fails.
    return NO;
}

/*!
 * @brief Retreives the next URL from the given string
 * 
 * Private to AHHyperlinkScanner.  Calling on this externally could create some weird results.
 *
 * @return a AHMarkedHyperlink representing the given URL or nil, if there are no more hyperlinks. 
 */
- (AHMarkedHyperlink *)nextURLFromString:(NSString *)inString
{
    NSString    *scanString = nil;

	//get our location from AHStringOffset, so we can pick up where we left off
    int			location = AHStringOffset;

	static NSCharacterSet *skipSet = nil;
    if (!skipSet) {
        NSMutableCharacterSet *mutableSkipSet = [[NSMutableCharacterSet alloc] init];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
		[mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
		skipSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableSkipSet bitmapRepresentation]] retain];
		[mutableSkipSet release];
    }

	static NSCharacterSet *endSet = nil;
    if (!endSet) {
        endSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"',:;>)]}.?!"] retain];
    }
	
	static NSCharacterSet *startSet = nil;
    if (!startSet) {
        NSMutableCharacterSet *mutableStartSet = [[NSMutableCharacterSet alloc] init];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"\"',:;<([{.?!-"]];
		startSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableStartSet bitmapRepresentation]] retain];
		[mutableStartSet release];
    }

	static NSCharacterSet *hostnameComponentSeparatorSet = nil;	
   	if (!hostnameComponentSeparatorSet) {
   		hostnameComponentSeparatorSet = [[NSCharacterSet characterSetWithCharactersInString:@"./"] retain];
   	}
	
    // scan upto the next whitespace char so that we don't unnecessarity confuse flex
    // otherwise we end up validating urls that look like this "http://www.adiumx.com/ <--cool"
    NSScanner *preScanner = [[[NSScanner alloc] initWithString:inString] autorelease];
    [preScanner setCharactersToBeSkipped:skipSet];
    [preScanner setScanLocation:location];

    [preScanner scanCharactersFromSet:startSet intoString:nil];

    while([preScanner scanUpToCharactersFromSet:skipSet intoString:&scanString]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
        unsigned int localStringLen = [scanString length];
		unsigned int finalStringLen;
		
		while (localStringLen > 2 && [startSet characterIsMember:[scanString characterAtIndex:0]]) {
			scanString = [scanString substringFromIndex:1];
			localStringLen--;
		}

		finalStringLen = localStringLen;
		
		static NSArray *enclosureStartArray;
		if(!enclosureStartArray){
			enclosureStartArray = [[NSArray arrayWithObjects:@"(",@"[",@"{",nil] retain];
		}

		static NSCharacterSet *enclosureSet;
		if(!enclosureSet){
#define URL_ENCLOSURE_CHARACTERS @"()[]{}"
			enclosureSet = [[NSCharacterSet characterSetWithCharactersInString:URL_ENCLOSURE_CHARACTERS] retain];
		}
		
		static NSArray *enclosureStopArray;
		if(!enclosureStopArray){
			enclosureStopArray = [[NSArray arrayWithObjects:@")",@"]",@"}",nil] retain];
		}
		
		// Find balanced enclosure chars
#define ENC_INDEX_KEY @"encIndex"
#define ENC_CHAR_KEY @"encChar"
		NSMutableArray	*enclosureStack = [NSMutableArray arrayWithCapacity:2]; // totally arbitrary.
		NSMutableArray	*enclosureArray = [NSMutableArray arrayWithCapacity:2];
		NSString  *matchChar = nil;
		NSScanner *enclosureScanner = [[[NSScanner alloc] initWithString:scanString] autorelease];
		NSDictionary *encDict;
		while([enclosureScanner scanLocation] < [[enclosureScanner string] length]) {
			[enclosureScanner scanUpToCharactersFromSet:enclosureSet intoString:nil];
			if([enclosureScanner scanLocation] >= [[enclosureScanner string] length]) break;
			matchChar = [scanString substringWithRange:NSMakeRange([enclosureScanner scanLocation], 1)];
			if([enclosureStartArray containsObject:matchChar]) {
				encDict = [NSDictionary	dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:[enclosureScanner scanLocation]], matchChar, nil]
													  forKeys:[NSArray arrayWithObjects:ENC_INDEX_KEY, ENC_CHAR_KEY, nil]];
				[enclosureStack addObject:encDict];
			}else if([enclosureStopArray containsObject:matchChar]) {
				NSEnumerator *encEnumerator = [enclosureStack objectEnumerator];
				while ((encDict = [encEnumerator nextObject])) {
					unsigned int encTagIndex = [(NSNumber *)[encDict objectForKey:ENC_INDEX_KEY] unsignedIntegerValue];
					unsigned int encStartIndex = [enclosureStartArray indexOfObjectIdenticalTo:[encDict objectForKey:ENC_CHAR_KEY]];
					if([enclosureStopArray indexOfObjectIdenticalTo:matchChar] == encStartIndex) {
						NSRange encRange = NSMakeRange(encTagIndex, [enclosureScanner scanLocation] - encTagIndex);
						[enclosureStack removeObject:encDict];
						[enclosureArray addObject:NSStringFromRange(encRange)];
						break;
					}
				}
			}
			if([enclosureScanner scanLocation] < [[enclosureScanner string] length])
				[enclosureScanner setScanLocation:[enclosureScanner scanLocation]+1];
		}
		NSRange lastEnclosureRange = NSMakeRange(0, 0);
		if([enclosureArray count]) lastEnclosureRange = NSRangeFromString([enclosureArray lastObject]);
		while (finalStringLen > 2 && [endSet characterIsMember:[scanString characterAtIndex:finalStringLen - 1]]) {
			if((lastEnclosureRange.location + lastEnclosureRange.length + 1) < finalStringLen){
				scanString = [scanString substringToIndex:finalStringLen - 1];
				finalStringLen--;
			}else break;
		}

        AHStringOffset = [preScanner scanLocation] - finalStringLen;

        // if we have a valid URL then save the scanned string, and make a SHMarkedHyperlink out of it.
        // this way, we can preserve things like the matched string (to be converted to a NSURL),
        // parent string, it's validation status (valid, file, degenerate, etc), and it's range in the parent string
        if((finalStringLen > 0) && [self isStringValidURL:scanString]){
            AHMarkedHyperlink	*markedLink;
			NSRange				urlRange;
			
			urlRange = NSMakeRange([preScanner scanLocation] - localStringLen, finalStringLen);

            //insert typical specifiers if the URL is degenerate
            switch(validStatus){
                case AH_URL_DEGENERATE:
                {
                    NSString *scheme = DEFAULT_URL_SCHEME;
                    NSScanner *dotScanner = [[NSScanner alloc] initWithString:scanString];

                    NSString *firstComponent = nil;
                    [dotScanner scanUpToCharactersFromSet:hostnameComponentSeparatorSet
                                               intoString:&firstComponent];

                    if(firstComponent) {
                    	NSString *hostnameScheme = [urlSchemes objectForKey:firstComponent];
                    	if(hostnameScheme) scheme = hostnameScheme;
                    }

                    scanString = [scheme stringByAppendingString:scanString];

                    [dotScanner release];

                    break;
                }

                case AH_MAILTO_DEGENERATE:
					scanString = [@"mailto:" stringByAppendingString:scanString];
                    break;
                default:
                    break;
            }
            
            //make a marked link
            markedLink = [[AHMarkedHyperlink alloc] initWithString:scanString
											  withValidationStatus:validStatus
													  parentString:inString
														  andRange:urlRange];
            return [markedLink autorelease];
        }
		
        //step location after scanning a string
        [preScanner setScanLocation:location++];
		
		[pool release];
    }
	
    // if we're here, then NSScanner hit the end of the string
    // set AHStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
    AHStringOffset = [inString length];
    return nil;
}

#pragma mark string and textview handleing

/*!
 * @brief Fetches all the URLs from a string
 * @param inString The NSString with potential URLs in it
 * @return An array of AHMarkedHyperlinks representing each matched URL in the string or nil if no matches.
 */
-(NSArray *)allURLsFromString:(NSString *)inString
{
    AHStringOffset = 0; //set the offset to 0.
    NSMutableArray		*rangeArray = nil;
    AHMarkedHyperlink	*markedLink;
    
    //build an array of marked links.
    while([inString length] > AHStringOffset){
        if((markedLink = [self nextURLFromString:inString])){
			if(!rangeArray) rangeArray = [NSMutableArray array];
            [rangeArray addObject:markedLink];
        }
    }
    
	return rangeArray;
}

/*!
 * @brief Fetches all the URLs from a NSTextView
 * @param inView The NSTextView with potential URLs in it
 * @return An array of AHMarkedHyperlinks representing each matched URL in the textView or nil if no matches.
 */
-(NSArray *)allURLsFromTextView:(NSTextView *)inView
{
    // since a NSTextView is really just a glorified NSMutableAttributedString,
    // we can take the string and send it out to allURLsFromString:
    return [self allURLsFromString:[inView string]];
}

/*!
 * @brief Scans an attributed string for URLs then adds the link attribs and objects.
 * @param inString The NSAttributedString to be linkified
 * @return An autoreleased NSAttributedString.
 */
-(NSAttributedString *)linkifyString:(NSAttributedString *)inString
{
    //build an array from the input string and get its obj. enumerator
    NSArray				*rangeArray = [self allURLsFromString:[inString string]];

	if([rangeArray count]){
		NSMutableAttributedString	*linkifiedString;
		NSEnumerator				*enumerator;
		AHMarkedHyperlink			*markedLink;
		
		linkifiedString = [[inString mutableCopy] autorelease];

		//for each SHMarkedHyperlink, add the proper URL to the proper range in the string.
		enumerator = [rangeArray objectEnumerator];
		while((markedLink = [enumerator nextObject])){
			NSURL *markedLinkURL;
			
			if((markedLinkURL = [markedLink URL])){
				[linkifiedString addAttribute:NSLinkAttributeName
										value:markedLinkURL 
										range:[markedLink range]];
			}
		}
		
		return linkifiedString;

    }else{
		//If no links were found, just return the string we were passed
		return [[inString retain] autorelease];
	}
}

/*!
 * @brief Scans a NSTextView's text store for URLs then adds the link attribs and objects.
 * 
 * This scan happens in place: the origional NSTextView is modified, and nothing is returned.
 * @param inView The NSTextView to be linkified.
 */
- (void)linkifyTextView:(NSTextView *)inView
{
	NSAttributedString *newAttributedString;

	// like allURLsFromTextView before it, we can just call the linkifyString: method here
	// then replace the NSTextView's contents with it.
	newAttributedString = [self linkifyString:[inView attributedSubstringFromRange:NSMakeRange(0,[[inView string] length])]];

	[[inView textStorage] setAttributedString:newAttributedString];
}

@end
