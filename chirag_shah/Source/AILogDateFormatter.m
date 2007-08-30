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
		int today = [[NSCalendarDate calendarDate] dayOfCommonEra];
		int dateDay = [(AICalendarDate *)date dayOfCommonEra];
		NSDateFormatterStyle timeStyle = [self timeStyle];

		if ((dateDay == today) || (dateDay == (today - 1))) {
			NSString			*dayString = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:((dateDay == today) ? NSThisDayDesignations : NSPriorDayDesignations)] objectAtIndex:0] capitalizedString];
			NSMutableString		*returnValue = [dayString mutableCopy];

			if ((timeStyle != NSDateFormatterNoStyle) &&
				([(AICalendarDate *)date granularity] == AISecondGranularity)) {
				//Supposed to show time, and the date has sufficient granularity to show it
				NSDateFormatterStyle dateStyle = [self dateStyle];
				[self setDateStyle:NSDateFormatterNoStyle];
				[returnValue appendString:@" "];
				[returnValue appendString:[super stringForObjectValue:date]];
				[self setDateStyle:dateStyle];
			}
			
			return [returnValue autorelease];

		} else {
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
	}

	return [super stringForObjectValue:date];
}

@end
