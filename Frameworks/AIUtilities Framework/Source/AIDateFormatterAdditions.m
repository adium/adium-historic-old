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

+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate;
{
    NSMutableString *theString = [[[NSMutableString alloc] init] autorelease];
    
    double seconds = [[NSDate date] timeIntervalSinceDate:inDate];
    int days = 0, hours = 0, minutes = 0; 
	
	//Days
    days = (int)(seconds / 86400);
    seconds -= days * 86400;
	
	//Hours
    if (seconds) {
        hours = (int)(seconds / 3600);
        seconds -= hours * 3600;
    }
	
	//Minutes
    if (seconds) {
        minutes = (int)(seconds / 60);
        seconds -= minutes * 60;
    }
		
    if (abbreviate) {
        if (days)
            [theString appendString:[NSString stringWithFormat:@"%id ",days]];
        if (hours)
            [theString appendString:[NSString stringWithFormat:@"%ih ",hours]];
        if (minutes)
            [theString appendString:[NSString stringWithFormat:@"%im ",minutes]];
        if (showSeconds && seconds)
            [theString appendString:[NSString stringWithFormat:@"%%lfs ",seconds]];
        
        //Return the string without the final space
        if ([theString length] > 1) {
            [theString deleteCharactersInRange:NSMakeRange(([theString length]-1), 1)];
		}

    } else {
        if (days >= 1) {
			if (days == 1) {
				[theString appendString:ONE_DAY];
			} else {
				[theString appendString:[NSString stringWithFormat:MULTIPLE_DAYS, days]];
			}
			
			[theString appendString:@", "];
		}

		if (hours >= 1) {
			if (hours == 1) {
				[theString appendString:ONE_HOUR];
			} else {
				[theString appendString:[NSString stringWithFormat:MULTIPLE_HOURS, hours]];
			}
			
			[theString appendString:@", "];
		}

		if (minutes >= 1) {
			if (minutes == 1) {
				[theString appendString:ONE_MINUTE];
			} else {
				[theString appendString:[NSString stringWithFormat:MULTIPLE_MINUTES, minutes]];
			}
			
			[theString appendString:@", "];
		}

		//Don't show seconds if we showed days; that's just ridiculous.
		if (showSeconds && (seconds >= 1) && (days == 0)) {
			if (seconds == 1) {
				[theString appendString:ONE_SECOND];
			} else {
				[theString appendString:[NSString stringWithFormat:MULTIPLE_SECONDS, seconds]];
			}

			[theString appendString:@", "];
		}

        //Return the string without the final comma and space
        if ([theString length] > 2) {
            [theString deleteCharactersInRange:NSMakeRange(([theString length]-2), 2)];
		}
    }
    
    return theString;
}


//Returns a string representation of the interval between two dates
+ (NSString *)stringForApproximateTimeIntervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate
{
	NSString	*timeString = nil;
	double		seconds = [firstDate timeIntervalSinceDate:secondDate];
    int			weeks = 0, days = 0, hours = 0, minutes = 0; 

	//Weeks
	weeks = (int)((seconds / 86400) / 7);
	seconds -= (weeks * 86400 * 7);

	//Days
	if (seconds) {
		days = (int)(seconds / 86400);
		seconds -= days * 86400;
	}
	
	//Hours
    if (seconds) {
        hours = (int)(seconds / 3600);
        seconds -= hours * 3600;
    }
	
	//Minutes
    if (seconds) {
        minutes = (int)(seconds / 60);
        seconds -= minutes * 60;
    }

	if (weeks >= 1) {
		if (weeks == 1) {
			timeString = ONE_WEEK;
		} else {
			timeString = [NSString stringWithFormat:MULTIPLE_WEEKS, weeks];
		}
	}
	
	if (!timeString && (days >= 1)) {
		if (days == 1) {
			timeString = ONE_DAY;
		} else {
			timeString = [NSString stringWithFormat:MULTIPLE_DAYS, days];
		}
	}
	
	if (!timeString && (hours >= 1)) {
		if (hours == 1) {
			timeString = ONE_HOUR;
		} else {
			timeString = [NSString stringWithFormat:MULTIPLE_HOURS, hours];
		}
	}

	//If we get here, display either 1 minute or some number of minutes (approximate, we don't want to go into seconds)
	if (!timeString) {
		if (minutes > 1) {
			timeString = [NSString stringWithFormat:MULTIPLE_MINUTES, minutes];
		} else {
			timeString = ONE_MINUTE;
		}
	}

	return (timeString ? timeString : @"");
}


@end
