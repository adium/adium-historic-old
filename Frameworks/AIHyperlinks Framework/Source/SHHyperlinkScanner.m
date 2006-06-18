/*
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SHHyperlinkScanner.h"
#import "SHLinkLexer.h"
#import "SHMarkedHyperlink.h"

#define	DEFAULT_URL_SCHEME	@"http://"

@implementation SHHyperlinkScanner

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
		SHStringOffset = 0;
	}

	return self;
}

- (void)dealloc
{
	[urlSchemes release];
	[super dealloc];
}

#pragma mark utility

- (URI_VERIFICATION_STATUS)validationStatus
{
	return validStatus;
}

#pragma mark primitive methods

// method to determine the validity of a given string, only place where flex is called
- (BOOL)isStringValidURL:(NSString *)inString
{
    SH_BUFFER_STATE buf;  // buffer for flex to scan from
	const char		*inStringUTF8;
    unsigned		utf8Length;
    
	validStatus = SH_URL_INVALID; // assume the URL is invalid

	if (!(inStringUTF8 = [inString UTF8String])) {
		return NO;
	}

	utf8Length = strlen(inStringUTF8); // length of the string in utf-8
    
	// initialize the buffer (flex automatically switches to the buffer in this function)
    buf = SH_scan_string(inStringUTF8);

    // call flex to parse the input
    validStatus = SHlex();

    // condition for valid URI's
    if(validStatus == SH_URL_VALID || validStatus == SH_MAILTO_VALID || validStatus == SH_FILE_VALID){
        SH_delete_buffer(buf); //remove the buffer from flex.
        buf = NULL; //null the buffer pointer for safty's sake.
        
        // check that the whole string was matched by flex.
        // this prevents silly things like "blah...com" from being seen as links
        if(SHleng == utf8Length){
            return YES;
        }
    // condition for degenerate URL's (A.K.A. URI's sans specifiers), requres strict checking to be NO.
    }else if((validStatus == SH_URL_DEGENERATE || validStatus == SH_MAILTO_DEGENERATE) && !useStrictChecking){
        SH_delete_buffer(buf);
        buf = NULL;
        if(SHleng == utf8Length){
            return YES;
        }
    // if it ain't vaild, and it ain't degenerate, then it's invalid.
    }else{
        SH_delete_buffer(buf);
        buf = NULL;
        return NO;
    }
    // default case, if the range checking above fails.
    return NO;
}

- (SHMarkedHyperlink *)nextURLFromString:(NSString *)inString
{
    NSString    *scanString = nil;

	//get our location from SHStringOffset, so we can pick up where we left off
    int			location = SHStringOffset;

	static NSCharacterSet *skipSet = nil;
    if (!skipSet) {
        NSMutableCharacterSet *mutableSkipSet = [[NSMutableCharacterSet alloc] init];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
		skipSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableSkipSet bitmapRepresentation]] retain];
		[mutableSkipSet release];
    }

	static NSCharacterSet *startSet = nil;
    if (!startSet) {
        NSMutableCharacterSet *mutableStartSet = [[NSMutableCharacterSet alloc] init];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'-,:;<([{.?!"]];
		startSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableStartSet bitmapRepresentation]] retain];
		[mutableStartSet release];
    }

	static NSCharacterSet *endSet = nil;
    if (!endSet) {
        endSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"',;>)]}.?!"] retain];
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
		
        if(localStringLen > 2 && [startSet characterIsMember:[scanString characterAtIndex:0]]){
            scanString = [scanString substringFromIndex:1];
            localStringLen = [scanString length];
        }
		
        if(localStringLen > 2 && [endSet characterIsMember:[scanString characterAtIndex:localStringLen - 1]]){
            scanString = [scanString substringToIndex:localStringLen - 1];
			finalStringLen = [scanString length];
        }else{
			finalStringLen = localStringLen;
		}

        SHStringOffset = [preScanner scanLocation] - finalStringLen;

        // if we have a valid URL then save the scanned string, and make a SHMarkedHyperlink out of it.
        // this way, we can preserve things like the matched string (to be converted to a NSURL),
        // parent string, it's validation status (valid, file, degenerate, etc), and it's range in the parent string
        if((finalStringLen > 0) && [self isStringValidURL:scanString]){
            SHMarkedHyperlink	*markedLink;
			NSRange				urlRange;
			
			urlRange = NSMakeRange([preScanner scanLocation] - localStringLen, finalStringLen);

            //insert typical specifiers if the URL is degenerate
            switch(validStatus){
                case SH_URL_DEGENERATE:
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

                case SH_MAILTO_DEGENERATE:
					scanString = [@"mailto:" stringByAppendingString:scanString];
                    break;
                default:
                    break;
            }
            
            //make a marked link
            markedLink = [[SHMarkedHyperlink alloc] initWithString:scanString
											  withValidationStatus:validStatus
													  parentString:inString
														  andRange:urlRange];
            return [markedLink autorelease];
        }
		
        //step location after scanning a string
        location = SHStringOffset;
		
		[pool release];
    }
	
    // if we're here, then NSScanner hit the end of the string
    // set SHStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
    SHStringOffset = [inString length];
    return nil;
}

#pragma mark string and textview handleing

//fetch all the URL's from a string
-(NSArray *)allURLsFromString:(NSString *)inString
{
    SHStringOffset = 0; //set the offset to 0.
    NSMutableArray		*rangeArray = nil;
    SHMarkedHyperlink	*markedLink;
    
    //build an array of marked links.
    while([inString length] > SHStringOffset){
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
		SHMarkedHyperlink			*markedLink;
		
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
