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
    [[adium contentController] registerOutgoingContentFilter:self];
    [[adium contentController] registerIncomingContentFilter:self];
    [[adium contentController] registerStringFilter:self];
	
    //Build the dictionary
    //	Eventually This Dictionary will become mutable and be updated from a preference pane 
    hash = [[NSDictionary alloc] initWithObjectsAndKeys:@"$var$", @"%n", 
        @"$var$", @"%m", 
        @"$var$", @"%t", 
        @"$var$", @"%d", 
        @"$var$", @"%a",
        nil];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterOutgoingContentFilter:self];
	[[adium contentController] unregisterIncomingContentFilter:self];
	[[adium contentController] unregisterStringFilter:self];
	[hash release]; hash = nil;
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject
{
   	return [self _filterString:[inAttributedString string] 
				originalObject:inAttributedString
				 contentObject:inObject
					listObject:inListObject];
}

- (NSString *)filterString:(NSString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject;
{
	return [self _filterString:inString
				originalObject:inString 
				 contentObject:inObject 
					listObject:inListObject];
}

- (id)_filterString:(NSString *)inString originalObject:(id)originalObject contentObject:(AIContentObject *)content listObject:(AIListObject *)listObject
{
	id<DummyStringProtocol>		mesg = nil;
	NSMutableString				* str = nil;
		
    if(inString){
        NSEnumerator			* enumerator = [hash keyEnumerator];
        NSString                * pattern;	
        NSString                * replaceWith;
		NSRange					range, searchRange;
        
        //This loop gets run for every key in the dictionary
		while (pattern = [enumerator nextObject]){
            //if the original string contained this pattern
			if([inString rangeOfString:pattern].location != NSNotFound) {
				if (!mesg){				//This is potentially unecessary, if the %* is actually followed by an alnum, and so does not get replaced
					mesg = [[originalObject mutableCopy] autorelease];
					str = [mesg mutableString];
				}
				replaceWith = nil;
				searchRange = NSMakeRange(0,[inString length]);
				while(searchRange.location < [str length] && (range = [str rangeOfString:pattern options:NSLiteralSearch range:searchRange]).location != NSNotFound) {
					searchRange.location = range.location + range.length;
					searchRange.length = [str length] - searchRange.location;
					if(searchRange.location < [str length] && (isalnum([str characterAtIndex:searchRange.location]) || [str characterAtIndex:searchRange.location] == '_'))
						continue;
					
					if(replaceWith == nil) {
						//if key is a var go find out what the replacement text should be
						if([(replaceWith = [hash objectForKey:pattern]) isEqualToString:@"$var$"]){
							replaceWith = [self hashLookup:pattern contentObject:content listObject:listObject];
						}
					}
					//Adjust searchRange to start from the end of the replacement
					//length can stay the same, because the string's length also increases the same amount
					searchRange.location += [replaceWith length] - [pattern length];
					
					[str replaceCharactersInRange:range withString:replaceWith];
				}
            }
        }
    }
	
    return (mesg ? mesg : originalObject);
}

- (NSString*)hashLookup:(NSString*)pattern contentObject:(AIContentObject *)content listObject:(AIListObject *)listObject
{
    if([pattern isEqualToString:@"%a"]){
		if (content) {
			//Use the destination if possible, otherwise rely on the listObject of the associated chat
			AIListObject	*destination = [content destination];
			if(destination) {
				return [destination displayName];
			} else {
				AIChat			*chat = [content chat];
				AIListObject	*contact = [chat listObject];
				
				if (contact) {
					return [contact displayName];
				}
			}
		} else if (listObject) {
			AIAccount *account = nil;
			
			if ([listObject isKindOfClass:[AIListContact class]]) {
				//if no content was passed but a AIListContact was, substitute the display name of the best account
				//connected to that list object
				account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			  toListObject:listObject];
			}
			
			if (account) {
				return [account displayName];
			}
		}
		
    } else if([pattern isEqualToString:@"%n"]) {
		if (content) {
			//Use the destination if possible, otherwise rely on the listObject of the associated chat
			AIListObject	*destination = [content destination];
			if(destination) {
				return [destination UID];
			} else {
				AIChat			*chat = [content chat];
				AIListObject	*contact = [chat listObject];
				
				if (contact) {
					return [contact UID];
				}
			}
		} else if (listObject) {
			AIAccount *account = nil;

			if ([listObject isKindOfClass:[AIListContact class]]) {
				//if no content was passed but a AIListContact was, substitute the display name of the best account connected to that list object
				account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:listObject];
			}
			
			if (account) {
				return [account displayName];
			}
		}
		
    } else if([pattern isEqualToString:@"%m"]) {
		if (content) {
			return [[content source] displayName]; 	
		} else if (listObject) {
			if ([listObject isKindOfClass:[AIListContact class]]) {
				//if no content was passed by but a AIListContact context was, substitute the display name of the list object
				return [listObject displayName];
			}
		}
		
    } else if([pattern isEqualToString:@"%t"]) {
		NSCalendarDate  *timestamp = [NSCalendarDate calendarDate];
		NSString		*hour = [timestamp descriptionWithCalendarFormat:@"%I"];
		NSMutableString *timeString;
		unichar			*charHour = malloc(sizeof(unichar) * 2); 
		
		charHour[0] = [hour characterAtIndex:0];
		charHour[1] = [hour characterAtIndex:1];
		
		if(charHour[0] == '0') {
            charHour[0] = charHour[1];
            timeString = [[[NSMutableString alloc] initWithCharacters:charHour length:1] autorelease];
		} else {
            timeString = [[[NSMutableString alloc] initWithCharacters:charHour length:2] autorelease];
		}
		
		free(charHour);
		
		[timeString appendString:[timestamp descriptionWithCalendarFormat:@":%M %p"]];
		
		return timeString;  
		
    } else if([pattern isEqualToString:@"%d"]) {
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat:@"%b %e, %Y"];  
    }
    
	//No change: return the original pattern
    return pattern;
}

@end
