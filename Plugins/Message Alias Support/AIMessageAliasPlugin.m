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

#import "AIMessageAliasPlugin.h"
#import "AIContentController.h"
#import "AIAccountController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>

@interface AIMessageAliasPlugin (PRIVATE)
- (NSMutableAttributedString *)replaceKeywordsInString:(NSAttributedString *)original context:(id)context;
@end

@implementation AIMessageAliasPlugin

- (void)installPlugin
{
    //Register us as a filter
	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterAutoReplyContent direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	NSMutableAttributedString	*filteredMessage = nil;
	
	if (inAttributedString) {
		//Filter keywords in the message
		filteredMessage = [self replaceKeywordsInString:inAttributedString context:context];
		
		//Filter keywords in URLs (For AIM subprofile links, mostly)
		int	length = [(filteredMessage ? filteredMessage : inAttributedString) length];
		NSRange scanRange = NSMakeRange(0, 0);
		while (NSMaxRange(scanRange) < length) {
			id linkURL = [(filteredMessage ? filteredMessage : inAttributedString) attribute:NSLinkAttributeName
																					 atIndex:NSMaxRange(scanRange)
																			  effectiveRange:&scanRange];
			if (linkURL) {
				NSString	*linkURLString;
				
				if ([linkURL isKindOfClass:[NSURL class]]) {
					linkURLString = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
																						   (CFStringRef)[(NSURL *)linkURL absoluteString],
																						   /* characters to leave escaped */ CFSTR(""));
					[linkURLString autorelease];
					
				} else {
					linkURLString = (NSString *)linkURL;
				}
				
				if (linkURLString) {
					//If we found a URL, replace any keywords within it
					NSString	*result = [[self replaceKeywordsInString:[NSAttributedString stringWithString:linkURLString]
																 context:context] string];
					
					if (result) {
						NSURL		*newURL;
						NSString	*escapedLinkURLString;
						
						if (!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
						escapedLinkURLString = (NSString *)CFURLCreateStringByAddingPercentEscapes(/* allocator */ kCFAllocatorDefault,
																								   (CFStringRef)result,
																								   /* characters to leave unescaped */ NULL,
																								   /* legal characters to escape */ NULL,
																								   kCFStringEncodingUTF8);
						newURL = [NSURL URLWithString:escapedLinkURLString];
						
						if (newURL) {
							[filteredMessage addAttribute:NSLinkAttributeName
													value:newURL
													range:scanRange];
						}
						[escapedLinkURLString release];
					}
				}
			}
		}
	}
	
    return(filteredMessage ? filteredMessage : inAttributedString);
}

- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

//Replace any keywords in the passed string
//Returns a mutable version of the passed string if keywords have been replaced.  Otherwise returns
- (NSMutableAttributedString *)replaceKeywordsInString:(NSAttributedString *)attributedString context:(id)context
{
	NSString					*str = [attributedString string];
	NSMutableAttributedString	*newAttributedString = nil;

	//Our Name
	//If we're passed content, our account will be the destination of that content
	//If we're passed a list object, we can use the name of the preferred account for that object
	if ([str rangeOfString:@"%n"].location != NSNotFound) {
		NSString	*replacement = nil;

		if ([context isKindOfClass:[AIContentObject class]]) {
			replacement = [[context destination] UID]; //This exists primarily for AIM compatibility; AIM uses the UID (no formatting).
		} else if ([context isKindOfClass:[AIListContact class]]) {
			replacement = [[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																				  toContact:context] formattedUID];
		}

		if (replacement) {
			if (!newAttributedString) newAttributedString = [[attributedString mutableCopy] autorelease];
			
			[newAttributedString replaceOccurrencesOfString:@"%n"
												 withString:replacement
													options:NSLiteralSearch
													  range:NSMakeRange(0, [newAttributedString length])];
		}
	}

	//Current Date
	if ([str rangeOfString:@"%d"].location != NSNotFound) {
		NSCalendarDate	*currentDate = [NSCalendarDate calendarDate];
		NSString		*calendarFormat = [[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString];

		if (!newAttributedString) newAttributedString = [[attributedString mutableCopy] autorelease];
		
		[newAttributedString replaceOccurrencesOfString:@"%d"
											 withString:[currentDate descriptionWithCalendarFormat:calendarFormat]
												options:NSLiteralSearch
												  range:NSMakeRange(0, [newAttributedString length])];
	}
	
	//Current Time
	if ([str rangeOfString:@"%t"].location != NSNotFound) {
		NSCalendarDate 	*currentDate = [NSCalendarDate calendarDate];
		NSString		*localDateFormat = [NSDateFormatter localizedDateFormatStringShowingSeconds:YES
																					  showingAMorPM:YES];
		
		if (!newAttributedString) newAttributedString = [[attributedString mutableCopy] autorelease];

		[newAttributedString replaceOccurrencesOfString:@"%t"
											 withString:[currentDate descriptionWithCalendarFormat:localDateFormat]
												options:NSLiteralSearch
												  range:NSMakeRange(0, [newAttributedString length])];
	}
	
	return newAttributedString;
}

@end

