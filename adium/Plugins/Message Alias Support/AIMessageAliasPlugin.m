//
//  AIMessageAliasPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//

#import "AIMessageAliasPlugin.h"

@interface AIMessageAliasPlugin (PRIVATE)
- (NSMutableAttributedString *)replaceKeywordsInString:(NSAttributedString *)original context:(id)context;
- (NSMutableAttributedString *)replaceOccurencesOfString:(NSString *)keyword
									  inAttributedString:(NSAttributedString *)original
											  withString:(NSString *)replacement
							  usingExistingMutableOutput:(NSMutableAttributedString *)mutableOutput;
@end

@implementation AIMessageAliasPlugin

- (void)installPlugin
{
    //Register us as a filter
	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
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

//Replace any keywords in the passed string
//Returns a mutable version of the passed string if keywords have been replaced.  Otherwise returns
- (NSMutableAttributedString *)replaceKeywordsInString:(NSAttributedString *)original context:(id)context
{
	NSString					*str = [original string];
	NSMutableAttributedString	*filteredMessage = nil;
	
	//Our Name
	//If we're passed content, our account will be the destination of that content
	//If we're passed a list object, we can use the name of the preferred account for that object
	if([str rangeOfString:@"%n"].location != NSNotFound){
		NSString	*replacement = nil;
		
		if([context isKindOfClass:[AIContentObject class]]){
			replacement = [[context destination] displayName];
		}else if([context isKindOfClass:[AIListObject class]]){
			replacement = [[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			   toListObject:context] displayName];
		}
		
		if(replacement){
			filteredMessage = [self replaceOccurencesOfString:@"%n"
										   inAttributedString:original
												   withString:replacement
								   usingExistingMutableOutput:filteredMessage];
		}
	}
	
	//Current Date
	if([str rangeOfString:@"%d"].location != NSNotFound){
		NSCalendarDate *currentDate = [NSCalendarDate calendarDate];
		
		filteredMessage = [self replaceOccurencesOfString:@"%d"
									   inAttributedString:original
											   withString:[currentDate descriptionWithCalendarFormat:@"%m/%d/%y"]
							   usingExistingMutableOutput:filteredMessage];		
	}
	
	//Current Time
	if([str rangeOfString:@"%t"].location != NSNotFound){
		NSCalendarDate 	*currentDate = [NSCalendarDate calendarDate];
		NSString		*localDateFormat = [NSDateFormatter localizedDateFormatStringShowingSeconds:YES
																					  showingAMorPM:YES];
		
		filteredMessage = [self replaceOccurencesOfString:@"%t"
									   inAttributedString:original
											   withString:[currentDate descriptionWithCalendarFormat:localDateFormat]
							   usingExistingMutableOutput:filteredMessage];		
	}
	
	return(filteredMessage);
}

//Replace any keywords in the passed string
//Returns a mutable version of the passed string if keywords have been replaced.  Otherwise returns

//Replace a keyword with another string.  If an existing mutable version of the string exists, pass it to increase
//performance.  If a mutable will return nil if no keywords exist in the string and a mutable variant was not passed
- (NSMutableAttributedString *)replaceOccurencesOfString:(NSString *)keyword
							   inAttributedString:(NSAttributedString *)original
									   withString:(NSString *)replacement
					   usingExistingMutableOutput:(NSMutableAttributedString *)mutableOutput
{
	int		scanIndex = 0;
	NSRange range;

	if(!mutableOutput) mutableOutput = [[original mutableCopy] autorelease];

	do{
		NSString	*scanString = [mutableOutput string];

		range = [scanString rangeOfString:keyword
								  options:0
									range:NSMakeRange(scanIndex, [scanString length] - scanIndex)];
		if(range.location != NSNotFound){
			[mutableOutput replaceCharactersInRange:range withString:replacement];
		}
		
		scanIndex = range.location;
	}while(range.location != NSNotFound);

	return(mutableOutput);
}

@end

