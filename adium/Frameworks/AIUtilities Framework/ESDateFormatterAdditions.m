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
    static NSString     *oldTimeFormatString = nil;

    NSString            *currentTimeFormatString = [[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString];

    //if the time format string changed, clear the cache, then save the current one
    if ([currentTimeFormatString compare:oldTimeFormatString] != 0) {
        int i;
        for (i=0;i<4;i++)
            cache[i]=nil;
        
        [oldTimeFormatString release];
        oldTimeFormatString = [currentTimeFormatString retain];
    }
    
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
    NSMutableString *localizedDateFormatString = [currentTimeFormatString mutableCopy];
    if(!showAmPm){ 
        //potentially could use stringForKey:NSAMPMDesignation as space isn't always the separator between time and %p
        [localizedDateFormatString replaceOccurrencesOfString:@" %p" 
                                                withString:@"" 
                                                options:NSLiteralSearch 
                                                range:NSMakeRange(0,[localizedDateFormatString length])];
    } else if (![NSApp isOnPantherOrBetter]){
        //Jaguar doesn't usually include the " %p" in the localized time string for 12-hour time.  This is dumb.
        NSLog(@"%@",localizedDateFormatString);
        NSRange range = [localizedDateFormatString rangeOfString:@"I"
                                                         options:NSLiteralSearch
                                                           range:NSMakeRange(0,[localizedDateFormatString length])];
        if (range.location != NSNotFound) {
            NSLog(@"12hour time enabled");
            range = [localizedDateFormatString rangeOfString:@"%p"
                                                     options:NSLiteralSearch
                                                       range:NSMakeRange(0,[localizedDateFormatString length])];
            if (range.location == NSNotFound) {
                NSLog(@"append %p");
                [localizedDateFormatString appendString:@" %p"];
            }
        }
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
    return ([self stringForTimeIntervalSinceDate:inDate showingSeconds:YES abbreviated:NO]);
}

+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate;
{
    NSMutableString *theString = [[[NSMutableString alloc] init] autorelease];
    
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
    if (abbreviate) {
        if (days)
            [theString appendString:[NSString stringWithFormat:@"%id ",days,days==1 ? @"":@"s"]];
        if (hours)
            [theString appendString:[NSString stringWithFormat:@"%ih ",hours,hours==1 ? @"":@"s"]];
        if (minutes)
            [theString appendString:[NSString stringWithFormat:@"%im ",minutes,minutes==1 ? @"":@"s"]];
        if (showSeconds && seconds)
            [theString appendString:[NSString stringWithFormat:@"%is ",(int)seconds,seconds==1 ? @"":@"s"]];
        
        //Return the string without the final space
        if ([theString length])
            return ([theString substringToIndex:([theString length]-1)]);
    } else {
        if (days)
            [theString appendString:[NSString stringWithFormat:@"%i day%@, ",days,days==1 ? @"":@"s"]];
        if (hours)
            [theString appendString:[NSString stringWithFormat:@"%i hour%@, ",hours,hours==1 ? @"":@"s"]];
        if (minutes)
            [theString appendString:[NSString stringWithFormat:@"%i minute%@, ",minutes,minutes==1 ? @"":@"s"]];
        if (showSeconds && seconds)
            [theString appendString:[NSString stringWithFormat:@"%i second%@, ",(int)seconds,seconds==1 ? @"":@"s"]];
        
        //Return the string without the final comma and space
        if ([theString length])
            return ([theString substringToIndex:([theString length]-2)]);
    }
    
    return theString;
}
@end
