//
//  AICalendarDateAdditions.h
//  AIUtilities.framework
//
//  Created by Peter Hosey on 2007-11-11.
//  Copyright 2007 Adium Team. All rights reserved.
//

@interface NSCalendarDate (AICalendarDateAdditions)

- (NSCalendarDate *)dateByMatchingDSTOfDate:(NSDate *)otherDate;

@end
