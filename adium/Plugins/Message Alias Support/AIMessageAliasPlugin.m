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
  
    //Build the dictionary
    //	Eventually This Dictionary will become mutable and be updated from a preference pane 
    hash = [[NSDictionary alloc] initWithObjectsAndKeys:@"$var$", @"%n", 
							@"$var$", @"%m", 
							@"$var$", @"%t", 
							@"$var$", @"%d", 
							@"$var$", @"%a",
							nil];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject
{
    NSMutableAttributedString   *mesg = nil;
    if (inAttributedString)
    {
        NSString                *originalAttributedString = [inAttributedString string];
        NSEnumerator            *enumerator = [hash keyEnumerator];
        NSString                *pattern;	
        NSString                *replaceWith;
        
        //This loop gets run for every key in the dictionary
	while (pattern = [enumerator nextObject])
	{
            //if the original string contained this pattern
            if ([originalAttributedString rangeOfString:pattern].location != NSNotFound){
                if (!mesg){
                    mesg = [[inAttributedString mutableCopyWithZone:nil] autorelease];
                }
                
                if([(replaceWith = [hash objectForKey:pattern]) isEqualToString:@"$var$"])
                {//if key is a var go find out what the replacement text should be
                    replaceWith = [self hashLookup:pattern contentMessage:inObject];
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


- (NSString*)hashLookup:(NSString*)pattern contentMessage:(AIContentObject *)content
{
    if([pattern isEqualToString:@"%a"]){
	AIChat *chat = [content chat];
	AIListObject *contact = [chat listObject];
	
	if(contact == nil){
	    return pattern;
	}else{
	    return [contact displayName];
	} 
    } else if([pattern isEqualToString:@"%n"]) {
	AIChat *chat = [content chat];
	AIListObject *contact = [chat listObject];
	
	if(contact == nil){
	    return pattern;
	}else{
	    return [contact UID];
	} 
    } else if([pattern isEqualToString:@"%m"]) {
	id contact = [content source]; 	
	
	if( [contact isKindOfClass:[AIListContact class]] ) {
	    return [(AIListContact *)contact displayName];
	} else if ([contact isKindOfClass:[AIAccount class]] ){
	    return [(AIAccount *)contact UID];
	} else {
	    return pattern;
	}
    } else if([pattern isEqualToString:@"%t"]) {
	NSCalendarDate *timestamp = [NSCalendarDate calendarDate];
	NSString *hour = [timestamp descriptionWithCalendarFormat:@"%I"];
	NSMutableString *time;
	unichar *charHour = malloc(sizeof(unichar) * 2); 
	
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

- (void)uninstallPlugin
{
     [hash release];
}

- (void)dealloc
{
    [super dealloc];
}
@end
