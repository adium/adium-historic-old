//
//  ESDateFormatterAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDateFormatterAdditions.h"

typedef enum
{
    NONE,
    SECONDS,
    AMPM,
    BOTH
} StringType;

@implementation NSDateFormatter (ESDateFormatterAdditions)

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
    static NSString 	*cache[4] = {nil,nil,nil,nil}; //Cache for the 4 combinations of date string
    StringType		type;
    
    //Determine the type of string requested
    if(!seconds && !showAmPm) type = NONE;
    else if(seconds && !showAmPm) type = SECONDS;
    else if(!seconds & showAmPm) type = AMPM;
    else type = BOTH;

    //Check the cache for this string, return if found
    if(cache[type]){
        return(cache[type]);
    }

    //use system-wide defaults for date format
    NSMutableString *localizedDateFormatString = [[[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString] mutableCopy];
    if(!showAmPm){ 
        //potentially could use stringForKey:NSAMPMDesignation as space isn't always the separator between time and %p
        [localizedDateFormatString replaceOccurrencesOfString:@" %p" 
                                                withString:@"" 
                                                options:NSLiteralSearch 
                                                range:NSMakeRange(0,[localizedDateFormatString length])];
    }
    if(!seconds){
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

    return([localizedDateFormatString autorelease]);
}

+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate
{
    NSMutableString *theString = [[NSMutableString alloc] init];
    
    double seconds = [[NSDate date] timeIntervalSinceDate:inDate];
    int days = 0, hours = 0, minutes = 0; 
    days = (int)(seconds / 86400);
    seconds -= days * 86400;
    if (seconds) {
        hours = (int)(seconds / 3600);
        seconds -= hours * 3600;
    }
    if (seconds) {
        minutes = (int)(seconds / 60);
        seconds -= minutes * 60;
    }
    if (days)
        [theString appendString:[NSString stringWithFormat:@"%i day%@ ",days,days==1 ? @"":@"s"]];
    if (hours)
        [theString appendString:[NSString stringWithFormat:@"%i hour%@ ",hours,hours==1 ? @"":@"s"]];
    if (minutes)
        [theString appendString:[NSString stringWithFormat:@"%i minute%@ ",minutes,minutes==1 ? @"":@"s"]];
    if (seconds)
        [theString appendString:[NSString stringWithFormat:@"%i second%@ ",(int)seconds,seconds==1 ? @"":@"s"]];
    
    return theString;
}
@end
