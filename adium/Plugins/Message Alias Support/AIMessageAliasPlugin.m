//
//  AIMessageAliasPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//

#import "AIMessageAliasPlugin.h"

@implementation AIMessageAliasPlugin

- (void)installPlugin
{
    //Register us as a filter
    [[adium contentController] registerOutgoingContentFilter:self];
    [[adium contentController] registerIncomingContentFilter:self];
    
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
	[hash release]; hash=nil;
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject
{
    NSMutableAttributedString   *mesg = nil;
    if (inAttributedString){
        NSString                *originalAttributedString = [inAttributedString string];
        NSEnumerator            *enumerator = [hash keyEnumerator];
        NSString                *pattern;	
        NSString                *replaceWith;
        
        //This loop gets run for every key in the dictionary
	while (pattern = [enumerator nextObject]){
            //if the original string contained this pattern
            if ([originalAttributedString rangeOfString:pattern].location != NSNotFound){
                if (!mesg){
                    mesg = [[inAttributedString mutableCopyWithZone:nil] autorelease];
                }
                
                //if key is a var go find out what the replacement text should be
                if([(replaceWith = [hash objectForKey:pattern]) isEqualToString:@"$var$"]){
                    replaceWith = [self hashLookup:pattern contentMessage:inObject listObject:inListObject];
                }
                
                [mesg replaceOccurrencesOfString:pattern 
                                      withString:replaceWith
                                         options:NSLiteralSearch 
                                           range:NSMakeRange(0,[mesg length])];
            }
        }
    }
    return (mesg ? mesg : inAttributedString);
}


- (NSString*)hashLookup:(NSString*)pattern contentMessage:(AIContentObject *)content listObject:(AIListObject *)listObject
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
		NSMutableString *time;
		unichar			*charHour = malloc(sizeof(unichar) * 2); 
		
		charHour[0] = [hour characterAtIndex:0];
		charHour[1] = [hour characterAtIndex:1];
		
		if(charHour[0] == '0') {
            charHour[0] = charHour[1];
            time = [[[NSMutableString alloc] initWithCharacters:charHour length:1] autorelease];
		} else {
            time = [[[NSMutableString alloc] initWithCharacters:charHour length:2] autorelease];
		}
		
		free(charHour);
		
		[time appendString:[timestamp descriptionWithCalendarFormat:@":%M %p"]];
		
		return time;  
    } else if([pattern isEqualToString:@"%d"]) {
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat:@"%b %e, %Y"];  
    }
    
    return pattern;
}

@end
