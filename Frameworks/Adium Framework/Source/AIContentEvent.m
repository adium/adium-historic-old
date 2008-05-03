//
//  AIContentEvent.m
//  Adium
//
//  Created by Evan Schoenberg on 7/8/06.
//

#import <Adium/AIContentEvent.h>

@implementation AIContentEvent

//Content Identifier
- (NSString *)type
{
    return CONTENT_EVENT_TYPE;
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = [super displayClasses];
	
	//Events are neither incoming nor outgoing, and really aren't statuses, but the way this is designed doesn't support that right now :(
	uint idx = [classes indexOfObject:@"incoming"];
	[classes removeObjectAtIndex:idx];
	idx = [classes indexOfObject:@"status"];
	[classes removeObjectAtIndex:idx];

	[classes addObject:@"event"];
	return classes;
}

- (NSAttributedString *)loggedMessage
{
	return [self message];
}

- (NSString *)eventType
{
	return statusType;
}

@end
