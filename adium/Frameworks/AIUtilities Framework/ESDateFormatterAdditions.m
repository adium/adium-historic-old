//
//  ESDateFormatterAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDateFormatterAdditions.h"

@implementation NSDateFormatter (ESDateFormatterAdditions)

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
    static NSString *formatString = nil, *formatStringWithSeconds = nil, *formatStringWithAMorPM = nil, *formatStringWithSecondsAndAMorPM = nil, *cacheCheck = nil;
        
    NSString *checkString = [[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString];
    BOOL isCache = [cacheCheck isEqualToString:checkString]; //look for a cached value

    NSString **pointer = nil;
        
    if(!seconds && !showAmPm)
    {
        if(isCache && formatString)
            return formatString;
        else
            pointer = &formatString;
    }
    else if(seconds && !showAmPm)
    {
        if(isCache && formatStringWithSeconds)
            return formatStringWithSeconds;
        else
            pointer = &formatStringWithSeconds;
    }
    else if(!seconds & showAmPm)
    {
        if(isCache && formatStringWithAMorPM)
            return formatStringWithAMorPM;
        else
            pointer = &formatStringWithAMorPM;
    }
    else
    {
        if(isCache && formatStringWithSecondsAndAMorPM)
            return formatStringWithSecondsAndAMorPM;
        else
            pointer = &formatStringWithSecondsAndAMorPM;
    }
    
    if(!isCache)
        cacheCheck = checkString; //save the cache
    
    //use system-wide defaults for date format
    NSMutableString * localizedDateFormatString = [checkString mutableCopy];
    
    if (!showAmPm){ 
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
    
    *pointer = (NSString *)localizedDateFormatString;
    
    NSLog(localizedDateFormatString);
    
    return localizedDateFormatString;
}
@end
