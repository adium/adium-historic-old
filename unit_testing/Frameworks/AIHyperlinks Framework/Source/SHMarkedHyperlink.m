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

#import "SHMarkedHyperlink.h"

@implementation SHMarkedHyperlink

#pragma mark init and dealloc

// one really big init method that does it all...
- (id)initWithString:(NSString *)inString withValidationStatus:(URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange
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

- (URI_VERIFICATION_STATUS)validationStatus
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

- (void)setValidationStatus:(URI_VERIFICATION_STATUS)status
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
	SHMarkedHyperlink   *newLink = [[[self class] allocWithZone:zone] initWithString:[[self URL] absoluteString]
	                                                            withValidationStatus:[self validationStatus]
	                                                                    parentString:[self parentString]
	                                                                        andRange:[self range]];
	return newLink;
}

@end
