//
//  AIMessageAliasPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIMessageAliasPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIMessageAliasPlugin

- (void)installPlugin
{//Register us as a filter
    [[owner contentController] registerOutgoingContentFilter:self];
    
    hash = [[NSDictionary alloc] initWithObjectsAndKeys:@"$var$", @"%n", 
							@"$var$", @"%m", 
							@"$var$", @"%t", 
							@"$var$", @"%d", 
							@"$var$", @"%a",
							nil];
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        AIContentMessage *inObj = (AIContentMessage *)inObject;
	
	NSMutableAttributedString *mesg = [[inObj message] mutableCopy];
	
	NSString *pattern;
	NSString *replaceWith;
	
	NSEnumerator *enumerator = [hash keyEnumerator];
	
	while ((pattern = [enumerator nextObject]))
	{
	    NSRange range; 
	    int location;
	    int length;

	    replaceWith = [hash objectForKey:pattern];
	
	    if([replaceWith isEqualToString:@"$var$"])
	    {
		replaceWith = [self hashLookup:pattern contentMessage:inObj];
	    }

	    range = NSMakeRange( (0 - [replaceWith length])    , [[mesg string] length]);
	    do
	    {
		location = range.location + [replaceWith length];
		length = [[mesg string] length] - location;
	
		range = [[mesg string] rangeOfString:pattern options:nil range:(NSMakeRange(location, length))];

		if(range.location != NSNotFound)
		{
		    [mesg replaceCharactersInRange:range withString:replaceWith];
		}
	    }while( range.location != NSNotFound );
	}

	[inObj setMessage:mesg];
	[mesg release];
    }
}

- (NSString*) hashLookup:(NSString*)pattern contentMessage:(AIContentObject *)content
{
    if([pattern isEqualToString:@"%a"])
    {
	AIChat *chat = [content chat];
	AIListObject *contact = [chat listObject];
	
	if(contact == nil)
	{
	    return pattern;
	}
	else
	{
	    return [contact displayName];
	} 
    }
    else if([pattern isEqualToString:@"%n"])
    {
	AIChat *chat = [content chat];
	AIListObject *contact = [chat listObject];
	
	if(contact == nil)
	{
	    return pattern;
	}
	else
	{
	    return [contact UID];
	} 
    }
    else if([pattern isEqualToString:@"%m"])
    {
	id *contact = [content source]; 	
	
	if( [[contact className] isKindOfClass:[AIListContact class]] )
	{
	    return [contact displayName];
	}
	else
	{
	    return [contact UID];
	}
    }
    else if([pattern isEqualToString:@"%t"])
    {
	NSCalendarDate *timestamp = [NSCalendarDate calendarDate];
	NSString *hour = [timestamp descriptionWithCalendarFormat:@"%I"];
	NSMutableString *time;
	unichar *charHour = malloc(sizeof(unichar) * 2); 
	
	charHour[0] = [hour characterAtIndex:0];
	charHour[1] = [hour characterAtIndex:1];
	
	if(charHour[0] == '0')
	{
		charHour[0] = charHour[1];
		time = [[NSMutableString alloc] initWithCharacters:charHour length:1];
	}
	else
	{
		time = [[NSMutableString alloc] initWithCharacters:charHour length:2];
	}
	
	[time autorelease];
	free(charHour);
	
	[time appendString:[timestamp descriptionWithCalendarFormat:@":%M %p"]];
	
	
	return time;  
    }
    else if([pattern isEqualToString:@"%d"])
    {
	NSCalendarDate *date = [NSCalendarDate calendarDate];
	return [date descriptionWithCalendarFormat:@"%b %e, %Y"];  
    }
    
    
    return pattern;
}

- (void) dealloc
{
NSLog(@"Deallocating AIMessageAliasPlugin");
    [hash release];
    [super dealloc];
}
@end
