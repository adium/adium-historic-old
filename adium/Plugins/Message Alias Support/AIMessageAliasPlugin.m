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
{
    //Register us as a filter
    [[owner contentController] registerOutgoingContentFilter:self];
  
    //Build the dictionary
    //	Eventually This Dictionary will become mutable and be updated from a preference pane 
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

	NSMutableAttributedString *mesg = [[inObj message] mutableCopyWithZone:nil];
	
	NSString *pattern;
	NSString *replaceWith;
	
	NSEnumerator *enumerator = [hash keyEnumerator];
	
	NSRange range;
	int location;
	int length;
	
	while (pattern = [enumerator nextObject])
	{//This loop gets run for every key in the dictionary


	    if([(replaceWith = [hash objectForKey:pattern]) isEqualToString:@"$var$"])
	    {//if key is a var go find out what the replacement text should be
		replaceWith = [self hashLookup:pattern contentMessage:inObj];
	    }

	    //create a range...
	    //	The initial position doesn't make sense...it gets set to 0 in a few lines
	    // 	this is just to make things more dynamic in the do/while loop
	    range = NSMakeRange( (0 - [replaceWith length])    , [[mesg string] length]);
	    do
	    {//execute this loop until we don't see any more instances of the pattern
		location = range.location + [replaceWith length];
		length = [[mesg string] length] - location;
	
		//find the pattern in the message
		//	notice that the range gets moved to just behind the last replacement
		//	this is to prevent infinite loops 
		range = [[mesg string] rangeOfString:pattern options:nil range:(NSMakeRange(location, length))];
		
		if(range.location != NSNotFound)
		{//If pattern was found in string do the replacement
		    [mesg replaceCharactersInRange:range withString:replaceWith];
		}
	    }while( range.location != NSNotFound );
	}

	[inObj setMessage:mesg]; 
	[mesg release];
    }
}

- (NSString*) hashLookup:(NSString*)pattern contentMessage:(AIContentMessage *)content
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
	id contact = [content source]; 	
	
	if( [contact isKindOfClass:[AIListContact class]] ) {
	    return [(AIListContact *)contact displayName];
	} else if ([contact isKindOfClass:[AIAccount class]] ){
	    return [(AIAccount *)contact UID];
	} else {
	    return pattern;
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

- (void) uninstallPlugin
{
     [hash release];
}

- (void) dealloc
{
    NSLog(@"Deallocating AIMessageAliasPlugin");
    [super dealloc];
}
@end
