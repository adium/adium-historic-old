//
//  AIMessageAliasPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIMessageAliasPlugin.h"

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

	//Filter keywords in the message
	filteredMessage = [self replaceKeywordsInString:inAttributedString context:context];

	//Filter keywords in URLs (For AIM subprofile links, mostly)
	int	length = [(filteredMessage ? filteredMessage : inAttributedString) length];
    NSRange scanRange = NSMakeRange(0, 0);
    while(NSMaxRange(scanRange) < length){
        NSString *linkURL = [(filteredMessage ? filteredMessage : inAttributedString) attribute:NSLinkAttributeName
																						atIndex:NSMaxRange(scanRange)
																				 effectiveRange:&scanRange];
		if([linkURL isKindOfClass:[NSURL class]]) linkURL = [(NSURL *)linkURL absoluteString];
		
		//If we found a URL, replace any keywords within it
		if(linkURL){
			NSString	*result = [[self replaceKeywordsInString:[NSAttributedString stringWithString:linkURL]
														 context:context] string];

			if(result){
				if(!filteredMessage) filteredMessage = [inAttributedString mutableCopy];
				[filteredMessage addAttribute:NSLinkAttributeName
										value:result
										range:scanRange];
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
	if([str rangeOfString:@"%n"].location != NSNotFound){
		NSString	*replacement = nil;

		if([context isKindOfClass:[AIContentObject class]]){
			replacement = [[context destination] UID]; //This exists primarily for AIM compatibility; AIM uses the UID (no formatting).
		}else if([context isKindOfClass:[AIListObject class]]){
			replacement = [[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																				  toContact:context] formattedUID];
		}

		if(!newAttributedString) newAttributedString = [[attributedString mutableCopy] autorelease];

		[newAttributedString replaceOccurrencesOfString:@"%n"
										  withString:replacement
											 options:NSLiteralSearch
											   range:NSMakeRange(0, [newAttributedString length])];
	}

	//Current Date
	if([str rangeOfString:@"%d"].location != NSNotFound){
		NSCalendarDate *currentDate = [NSCalendarDate calendarDate];
		
		if(!newAttributedString) newAttributedString = [[attributedString mutableCopy] autorelease];
		
		[newAttributedString replaceOccurrencesOfString:@"%d"
											 withString:[currentDate descriptionWithCalendarFormat:@"%m/%d/%y"]
												options:NSLiteralSearch
												  range:NSMakeRange(0, [newAttributedString length])];
	}
	
	//Current Time
	if([str rangeOfString:@"%t"].location != NSNotFound){
		NSCalendarDate 	*currentDate = [NSCalendarDate calendarDate];
		NSString		*localDateFormat = [NSDateFormatter localizedDateFormatStringShowingSeconds:YES
																					  showingAMorPM:YES];
		
		if(!newAttributedString) newAttributedString = [[attributedString mutableCopy] autorelease];

		[newAttributedString replaceOccurrencesOfString:@"%t"
											 withString:[currentDate descriptionWithCalendarFormat:localDateFormat]
												options:NSLiteralSearch
												  range:NSMakeRange(0, [newAttributedString length])];
	}
	
	return newAttributedString;
}

@end

