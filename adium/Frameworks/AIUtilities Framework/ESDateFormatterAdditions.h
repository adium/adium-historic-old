//
//  ESDateFormatterAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.

@interface NSDateFormatter (ESDateFormatterAdditions)

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm;
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate;
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate;
+ (NSString *)stringForApproximateTimeIntervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate;
@end
