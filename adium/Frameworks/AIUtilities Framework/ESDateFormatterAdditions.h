//
//  ESDateFormatterAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDateFormatter (ESDateFormatterAdditions)

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm;
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate;
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate abbreviated:(BOOL)abbreviate;

@end
