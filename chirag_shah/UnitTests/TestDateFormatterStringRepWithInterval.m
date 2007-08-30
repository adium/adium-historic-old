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
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 seconds", @"Unexpected string for time interval");
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
		          seconds:-10];
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
		          minutes:-10
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
		          seconds:-10];
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
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 weeks 5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}

- (void)testDateFormatterStringRepWithInterval_seconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hours_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_days_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHours_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeks_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHours_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDays_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHours_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutes_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutesSeconds_abbreviated {
	NSDate *date = [[NSCalendarDate calendarDate]
		dateByAddingYears:-0
		           months:-0
		             days:7 * -5 + -5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5w 5d 10h 10m 10s", @"Unexpected string for time interval");
}

@end
