/*
 * The AIHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AIHyperlinks Framework nor the
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

@implementation AHHyperlinkScanner

#pragma mark Init

//default initializer - use strict checking by default
- (id)init
{
	return [self initWithStrictChecking:YES];
}

//init with a user specified value for strict checking
- (id)initWithStrictChecking:(BOOL)flag
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

// method to determine the validity of a given string, only place where flex is called
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
#define INVALID_URL_EDGE_CHARACTERS @"\"'-,:;<>()[]{}.?!"
        endSet = [[NSCharacterSet characterSetWithCharactersInString:INVALID_URL_EDGE_CHARACTERS] retain];
    }
	
	static NSCharacterSet *startSet = nil;
    if (!startSet) {
        NSMutableCharacterSet *mutableStartSet = [[NSMutableCharacterSet alloc] init];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		//Note that endSet is composed of INVALID_URL_EDGE_CHARACTERS
        [mutableStartSet formUnionWithCharacterSet:endSet];
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

		static NSCharacterSet *enclosureStartSet;
		if(!enclosureStartSet){
#define INVALID_URL_ENCLOSURE_START_CHARACTERS @"([{"
			enclosureStartSet = [[NSCharacterSet characterSetWithCharactersInString:INVALID_URL_ENCLOSURE_START_CHARACTERS] retain];
		}
		
		static NSArray *enclosureStartArray;
		if(!enclosureStartArray){
			enclosureStartArray = [[NSArray arrayWithObjects:@"(",@"[",@"{",nil] retain];
		}

		static NSCharacterSet *enclosureEndSet;
		if(!enclosureEndSet){
#define INVALID_URL_ENCLOSURE_END_CHARACTERS @")]}"
			enclosureEndSet = [[NSCharacterSet characterSetWithCharactersInString:INVALID_URL_ENCLOSURE_END_CHARACTERS] retain];
		}
		
		static NSArray *enclosureStopArray;
		if(!enclosureStopArray){
			enclosureStopArray = [[NSArray arrayWithObjects:@")",@"]",@"}",nil] retain];
		}
		
		// Find balanced enclosure chars
		NSScanner *enclosureScanner = [[[NSScanner alloc] initWithString:scanString] autorelease];
		NSString  *matchStartChar = nil, *matchEndChar = nil;
		NSMutableArray   *enclosureArray = [NSMutableArray arrayWithCapacity:1];
		unsigned int encStart;
		while ([enclosureScanner scanUpToCharactersFromSet:enclosureStartSet intoString:nil] &&
			   [enclosureScanner scanLocation] < [scanString length]) {
			matchStartChar = [scanString substringWithRange:NSMakeRange([enclosureScanner scanLocation], 1)];
			if([enclosureStartArray containsObject:matchStartChar]) {
				encStart = [enclosureScanner scanLocation];
				while ([enclosureScanner scanUpToCharactersFromSet:enclosureEndSet intoString:nil] &&
					   [enclosureScanner scanLocation] < [scanString length]){
					matchEndChar = [scanString substringWithRange:NSMakeRange([enclosureScanner scanLocation], 1)];
					if([enclosureStopArray containsObject:matchEndChar] &&
					   [enclosureStartArray indexOfObjectIdenticalTo:matchStartChar] == [enclosureStopArray indexOfObjectIdenticalTo:matchEndChar]) {
						[enclosureArray addObject:NSStringFromRange(NSMakeRange(encStart, [enclosureScanner scanLocation] - encStart))];
					}
				}
			}
		}
		NSRange lastEnclosureRange = NSRangeFromString([enclosureArray lastObject]);
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
        location = AHStringOffset;
		
		[pool release];
    }
	
    // if we're here, then NSScanner hit the end of the string
    // set AHStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
    AHStringOffset = [inString length];
    return nil;
}

#pragma mark string and textview handleing

//fetch all the URL's from a string
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

// fetch all the URL's form a text view
-(NSArray *)allURLsFromTextView:(NSTextView *)inView
{
    // since a NSTextView is really just a glorified NSMutableAttributedString,
    // we can take the string and send it out to allURLsFromString:
    return [self allURLsFromString:[inView string]];
}

//scan an attributed string for URL's, then give them the proper link attribs.
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

// scan a textView for URL's, as above
- (void)linkifyTextView:(NSTextView *)inView
{
	NSAttributedString *newAttributedString;

	// like allURLsFromTextView before it, we can just call the linkifyString: method here
	// then replace the NSTextView's contents with it.
	newAttributedString = [self linkifyString:[inView attributedSubstringFromRange:NSMakeRange(0,[[inView string] length])]];

	[[inView textStorage] setAttributedString:newAttributedString];
}

@end