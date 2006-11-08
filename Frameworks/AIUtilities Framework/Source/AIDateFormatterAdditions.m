//
//  AIDateFormatterAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.
//

#import "AIDateFormatterAdditions.h"
#import "AIApplicationAdditions.h"
#import "AIStringUtilities.h"

#define ONE_WEEK AILocalizedStringFromTableInBundle(@"1 week", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_WEEKS AILocalizedStringFromTableInBundle(@"%i weeks", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_DAY AILocalizedStringFromTableInBundle(@"1 day", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_DAYS AILocalizedStringFromTableInBundle(@"%i days", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_HOUR AILocalizedStringFromTableInBundle(@"1 hour", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_HOURS AILocalizedStringFromTableInBundle(@"%i hours", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_MINUTE AILocalizedStringFromTableInBundle(@"1 minute", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_MINUTES AILocalizedStringFromTableInBundle(@"%i minutes", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_SECOND AILocalizedStringFromTableInBundle(@"1 second", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_SECONDS AILocalizedStringFromTableInBundle(@"%1.0lf seconds", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)

typedef enum {
    NONE,
    SECONDS,
    AMPM,
    BOTH
} StringType;

@implementation NSDateFormatter (AIDateFormatterAdditions)

+ (NSDateFormatter *)localizedDateFormatter
{
	return [[[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString] 
								   allowNaturalLanguage:NO] autorelease];
}
+ (NSDateFormatter *)localizedShortDateFormatter
{
	return [[[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString] 
								   allowNaturalLanguage:NO] autorelease];
}

+ (NSDateFormatter *)localizedDateFormaterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
    NSString	*format = [self localizedDateFormatStringShowingSeconds:seconds showingAMorPM:showAmPm];
	
	return [[[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO] autorelease];
}

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
    static NSString 	*cache[4] = {nil,nil,nil,nil}; //Cache for the 4 combinations of date string
    static NSString     *oldTimeFormatString = nil;

    NSString            *currentTimeFormatString = [[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString];

    //if the time format string changed, clear the cache, then save the current one
    if (![currentTimeFormatString isEqualToString:oldTimeFormatString]) {
        int i;
        for (i=0;i<4;i++)
            cache[i]=nil;
        
        [oldTimeFormatString release];
        oldTimeFormatString = [currentTimeFormatString retain];
    }
    
    StringType		type;
    
    //Determine the type of string requested
    if (!seconds && !showAmPm) type = NONE;
    else if (seconds && !showAmPm) type = SECONDS;
    else if (!seconds & showAmPm) type = AMPM;
    else type = BOTH;

    //Check the cache for this string, return if found
    if (cache[type]) {
        return cache[type];
    }

    //use system-wide defaults for date format
    NSMutableString *localizedDateFormatString = [currentTimeFormatString mutableCopy];

    if (!showAmPm) { 
        //potentially could use stringForKey:NSAMPMDesignation as space isn't always the separator between time and %p
        [localizedDateFormatString replaceOccurrencesOfString:@" %p" 
                                                withString:@"" 
                                                options:NSLiteralSearch 
                                                range:NSMakeRange(0,[localizedDateFormatString length])];
    }

    if (!seconds) {
        int secondSeparatorIndex = [localizedDateFormatString rangeOfString:@"%S" options:NSBackwardsSearch].location;
        
        if ( (secondSeparatorIndex != NSNotFound) && (secondSeparatorIndex > 0) ) {
            NSString *secondsSeparator = [localizedDateFormatString substringWithRange:NSMakeRange(secondSeparatorIndex-1,1)];
            [localizedDateFormatString replaceOccurrencesOfString:[NSString stringWithFormat:@"%@%@",secondsSeparator,@"%S"] 
                                                withString:@""
                                                options:NSLiteralSearch
                                                range:NSMakeRange(0,[localizedDateFormatString length])];
        }
    }

    //Cache the result
    cache[type] = [localizedDateFormatString retain];

    return [localizedDateFormatString autorelease];
}




+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate
{
    return ([self stringForTimeIntervalSinceDate:inDate showingSeconds:YES abbreviated:NO]);
}

/*!
 *@brief format time for the interval since the given date
 *
 *@param inDate Date which starts the interval
 *@param showSeconds switch to determine if seconds should be shown
 *@param abbreviate switch to chose if w/d/h/ or weeks/days/hours/minutes is used to indicate the unit
 *
 *@result a localized NSString conaining the Interval in weeks, days, hours or minutes (the largest usable)
 */
 
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate;
{
    return [self stringForTimeInterval:[[NSDate date] timeIntervalSinceDate:inDate]
						showingSeconds:showSeconds
						   abbreviated:abbreviate
						  approximated:NO];
}


/*!
 *@brief format time for the interval between two dates
 *
 *@param firstDate first date of the interval
 *@param secondDate second date of the interval
 *
 *@result a localized NSString conaining the Interval in weeks, days, hours or minutes (the largest usable)
 */
 
+ (NSString *)stringForApproximateTimeIntervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate
{
	return  [self stringForTimeInterval:[firstDate timeIntervalSinceDate:secondDate]
						 showingSeconds:NO
							abbreviated:NO
						   approximated:YES];
}

/*!
 *@brief format time for an interval
 *
 *@param interval NSTimeInterval to format
 *@param abbreviate switch to chose if w/d/h/ or weeks/days/hours/minutes is used to indicate the unit
 *
 *@result a localized NSString conaining the Interval in weeks, days, hours or minutes (the largest usable)
 */
 
+ (NSString *)stringForApproximateTimeInterval:(NSTimeInterval)interval abbreviated:(BOOL)abbreviate
{
	return  [self stringForTimeInterval:interval
						 showingSeconds:NO
							abbreviated:abbreviate
						   approximated:YES];
}

/*!
 *@brief format time for an interval
 *
 *@param interval NSTimeInterval to format
 *
 *@result a localized NSString conaining the interval in weeks, days, hours and minutes
 */
 
+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval
{
	return  [self stringForTimeInterval:interval
						 showingSeconds:NO
							abbreviated:NO
						   approximated:NO];
}

/*!
 *@brief format time for an interval
 *
 *
 *
 *@param interval NSTimeInterval to format
 *@param showSeconds switch to determine if seconds should be shown
 *@param abbreviate switch to chose if w/d/h/ or weeks/days/hours/minutes is used to indicate the unit
 *@param approximate switch to chose if all parts should be shown or only the largest available part
 *
 *@result a localized NSString conaining the Interval formated according to the switches
 */ 

+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate approximated:(BOOL)approximate
{
	NSString		*timeString = nil;
	NSTimeInterval	workInterval = interval;
    int				weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0; 
	NSString		*weeksString = nil, *daysString = nil, *hoursString = nil, *minutesString = nil, *secondsString = nil;

	//Weeks
	weeks = (int)((workInterval / 86400) / 7);
	workInterval -= weeks * 86400 * 7;

	//Days
	if (workInterval) {
		days = (int)(workInterval / 86400);
		workInterval -= days * 86400;
	}
	
	//Hours
    if (workInterval) {
        hours = (int)(workInterval / 3600);
        workInterval -= hours * 3600;
    }
	
	//Minutes
    if (workInterval) {
        minutes = (int)(workInterval / 60);
        workInterval -= minutes * 60;
    }
	
	//Seconds
    if (workInterval) {
        seconds = (int)(interval / 60);
    }
	
	//build the strings for the parts
	if (abbreviate) {
		//Note: after checking with a linguistics student, it appears that we're fine leaving it as w, h, etc... rather than localizing.
		weeksString		= [NSString stringWithFormat: @"%iw",weeks];
		daysString		= [NSString stringWithFormat: @"%id",days];
		hoursString		= [NSString stringWithFormat: @"%ih",hours];
		minutesString	= [NSString stringWithFormat: @"%im",minutes];
		secondsString	= [NSString stringWithFormat: @"%im",seconds];
	} else {
		weeksString		= (weeks == 1)		? ONE_WEEK		: [NSString stringWithFormat:MULTIPLE_WEEKS, weeks];
		daysString		= (days == 1)		? ONE_DAY		: [NSString stringWithFormat:MULTIPLE_DAYS, days];
		hoursString		= (hours == 1)		? ONE_HOUR		: [NSString stringWithFormat:MULTIPLE_HOURS, hours];
		minutesString	= (minutes == 1)	? ONE_MINUTE	: [NSString stringWithFormat:MULTIPLE_MINUTES, minutes];
		secondsString	= (seconds == 1)	? ONE_SECOND	: [NSString stringWithFormat:MULTIPLE_SECONDS, seconds];
	}
	
	//assamble the parts
	if (approximate) {
		if (weeks)
			timeString = weeksString;
		else if (days)
			timeString = daysString;
		else if (hours)
			timeString = hoursString;
		else if (minutes)
			timeString = minutesString;
		else if (seconds && showSeconds)
			timeString = secondsString;
	} else {
		if (weeks)
			timeString = [NSString stringWithFormat: @"%@ %@ %@ %@", weeksString, daysString, hoursString, minutesString];
		else if (days)
			timeString = [NSString stringWithFormat: @"%@ %@ %@", daysString, hoursString, minutesString];
		else if (hours)
			timeString = [NSString stringWithFormat: @"%@ %@ ", hoursString, minutesString];
		else if (minutes)
			timeString = minutesString;
		
		if (showSeconds) {
			if (timeString)
				timeString = [timeString stringByAppendingFormat: @" %@", secondsString];
			else if (seconds)
				timeString = secondsString;
		}
	}

	return timeString ? timeString : @"";
}

@end
