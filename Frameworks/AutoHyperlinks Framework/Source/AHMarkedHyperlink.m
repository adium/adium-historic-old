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

#import "AHMarkedHyperlink.h"

@implementation AHMarkedHyperlink

#pragma mark init and dealloc

// one really big init method that does it all...
- (id)initWithString:(NSString *)inString withValidationStatus:(AH_URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange
{
	if((self = [self init])) {
		[self setURLFromString:inString];
		linkRange = inRange;
		[self setParentString:pInString];
		urlStatus = status;
	}

	return self;
}

- (id)init
{
	if((self = [super init])){
		linkURL = nil;
		pString = nil;
	}

	return self;
}

- (void)dealloc
{
	[linkURL release];
	[pString release];

	[super dealloc];
}

#pragma mark Accessors

- (NSRange)range
{
	return linkRange;
}

- (NSString *)parentString
{
	return pString;
}

- (NSURL *)URL
{
	return linkURL;
}

- (AH_URI_VERIFICATION_STATUS)validationStatus
{
	return urlStatus;
}

- (BOOL)parentStringMatchesString:(NSString *)inString
{
	return [pString isEqualToString:inString];
}

#pragma mark Transformers

- (void)setRange:(NSRange)inRange
{
	linkRange = inRange;
}

- (void)setURL:(NSURL *)inURL
{
	if(linkURL != inURL){
		[linkURL release];
		linkURL = [inURL retain];
	}
}

- (void)setURLFromString:(NSString *)inString
{
	NSString	*linkString;

	linkString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
	                                        (CFStringRef)inString,
	                                        (CFStringRef)@"#%",
	                                        NULL,
	                                        kCFStringEncodingUTF8); // kCFStringEncodingISOLatin1 );

	[linkURL release];
	linkURL = [[NSURL alloc] initWithString:linkString];

	[linkString release];
}

- (void)setValidationStatus:(AH_URI_VERIFICATION_STATUS)status
{
	urlStatus = status;
}

- (void)setParentString:(NSString *)pInString
{
	if(pString != pInString){
		[pString release];
		pString = [pInString retain];
	}
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	AHMarkedHyperlink   *newLink = [[[self class] allocWithZone:zone] initWithString:[[self URL] absoluteString]
	                                                            withValidationStatus:[self validationStatus]
	                                                                    parentString:[self parentString]
	                                                                        andRange:[self range]];
	return newLink;
}

@end