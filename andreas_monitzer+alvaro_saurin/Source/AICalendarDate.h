//
//  AICalendarDate.h
//  Adium
//
//  Created by Evan Schoenberg on 7/31/06.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	AIDayGranularity = 0,
	AISecondGranularity
} AICalendarDateGranularity;

@interface AICalendarDate : NSCalendarDate {
	AICalendarDateGranularity granularity;
}

- (void)setGranularity:(AICalendarDateGranularity)inGranularity;
- (AICalendarDateGranularity)granularity;

@end
