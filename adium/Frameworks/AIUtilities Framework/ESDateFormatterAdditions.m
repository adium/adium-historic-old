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
    //use system-wide defaults for date format
    NSMutableString * localizedDateFormatString = [[[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString] mutableCopy];
    
    if (!showAmPm){ 
        //potentially could use stringForKey:NSAMPMDesignation is space isn't always the separator between time and %p
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

    return localizedDateFormatString;
}
@end
