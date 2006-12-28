//
//  AIContentEventTest.m
//  Adium
//
//  Created by David Smith on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIContentEventTest.h"


@implementation AIContentEventTest

- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		 autoreply:(BOOL)inAutoReply
{
    if ((self = [super initWithChat:inChat source:inSource destination:inDest date:inDate message:inMessage])) {
		timer = [[NSTimer scheduledTimerWithTimeInterval:2.5f
												 target:self
											   selector:@selector(update:)
											   userInfo:nil
												repeats:YES] retain];
		percent = 0;
	}
	
    return self;
}

- (void) update:(NSNotification *)not
{
	percent++;
	[[adium notificationCenter] postNotificationName:@"ZOMGTEST" object:self];
}

- (NSString *)getState
{
	return [NSString stringWithFormat:@"%d", percent];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if(![super isSelectorExcludedFromWebScript:aSelector]) return NO;
	if(aSelector == @selector(getState)) return NO;
	return YES;
}

@end
