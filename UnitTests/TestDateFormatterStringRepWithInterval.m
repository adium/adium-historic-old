#import "TestDateFormatterStringRepWithInterval.h"
#import <AIUtilities/AIDateFormatterAdditions.h>

@implementation TestDateFormatterStringRepWithInterval

//Note: All of these delta values that we pass to NSCalendarDate need to be NEGATIVE, because we're looking to get a string representation of the interval since some time in the past.
- (void)testDateFormatterStringRepWithInterval_seconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-0
		          seconds:-10];
	NSString *string = [NSDateFormatter stringForTimeIntervalSinceDate:date];
	AISimplifiedAssertEqualObjects(string, @"10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hours {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_days {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHours {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeks {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHours {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDays {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHours {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutes {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutesSeconds {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}

@end
