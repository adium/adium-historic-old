//
//  AIMessageAliasPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//

#import "AIMessageAliasPlugin.h"

@interface AIMessageAliasPlugin (PRIVATE)
- (id)_filterString:(NSString *)inString originalObject:(id)originalObject contentObject:(AIContentObject *)content listObject:(AIListObject *)listObject;
- (NSString *)hashLookup:(NSString *)pattern contentObject:(AIContentObject *)content listObject:(AIListObject *)listObject;
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
	NSString					*str = [inAttributedString string];
	NSMutableAttributedString	*filteredMessage = nil;
	NSRange						range;
	
	//Our Name
	//If we're passed content, our account will be the destination of that content
	//If we're passed a list object, we can use the name of the preferred account for that object
	do{
		range = [str rangeOfString:@"%n"];
		
		if(range.location != NSNotFound){
			NSString	*replacement = nil;
			
			if([context isKindOfClass:[AIContentObject class]]){
				replacement = [[context destination] displayName];
			}else if([context isKindOfClass:[AIListObject class]]){
				replacement = [[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																				   toListObject:context] displayName];
			}
			
			if(replacement){
				if(!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
				[filteredMessage replaceCharactersInRange:range withString:replacement];
				str = [filteredMessage string];
			}
		}
		
	}while(range.location != NSNotFound);

	
	//Current Date
	do{
		range = [str rangeOfString:@"%d"];
		
		if(range.location != NSNotFound){
			NSCalendarDate *currentDate = [NSCalendarDate calendarDate];
			
			if(!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
			[filteredMessage replaceCharactersInRange:range
										   withString:[currentDate descriptionWithCalendarFormat:@"%m/%d/%y"]];
			str = [filteredMessage string];
		}
		
	}while(range.location != NSNotFound);

	
	//Current Time
	do{
		range = [str rangeOfString:@"%t"];
		
		if(range.location != NSNotFound){
			NSCalendarDate 	*currentDate = [NSCalendarDate calendarDate];
			NSString		*localDateFormat = [NSDateFormatter localizedDateFormatStringShowingSeconds:YES
																						  showingAMorPM:YES];
			[filteredMessage replaceCharactersInRange:range
										   withString:[currentDate descriptionWithCalendarFormat:localDateFormat]];
			str = [filteredMessage string];
		}
		
	}while(range.location != NSNotFound);
	
	
    return(filteredMessage ? filteredMessage : inAttributedString);
}

@end

