//
//  AILogDateFormatter.m
//  Adium
//
//  Created by Evan Schoenberg on 7/30/06.
//

#import "AILogDateFormatter.h"
#import "AICalendarDate.h"

@implementation AILogDateFormatter

- (NSString *)stringForObjectValue:(NSDate *)date
{
	if ([self respondsToSelector:@selector(timeStyle)] && [date isKindOfClass:[AICalendarDate class]]) {
		NSDateFormatterStyle timeStyle = [self timeStyle];
		if ((timeStyle != NSDateFormatterNoStyle) &&
			([(AICalendarDate *)date granularity] == AIDayGranularity)) {
			//Currently supposed to show time, but the date does not have that level of granularity
			NSString	*returnValue;

			[self setTimeStyle:NSDateFormatterNoStyle];
			returnValue = [super stringForObjectValue:date];
			[self setTimeStyle:timeStyle];

			return returnValue;
		}	
	}

	return [super stringForObjectValue:date];
}

@end
