//
//  ESDebugController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/27/04.
//

#import "ESDebugController.h"

@interface ESDebugController (PRIVATE)
- (void)addMessage:(NSString *)actualMessage;
@end

@implementation ESDebugController

//Called via the AILog #define declaraed in AIAdium.h, takes a format string with a variable number of arguments
- (void)adiumDebug:(NSString *)message, ...
{
	va_list		ap; /* points to each unamed arg in turn */
	NSString	*actualMessage;
	
	va_start(ap, message); /* make ap point to 1st unnamed arg */
	actualMessage = [[NSString alloc] initWithFormat:message
										   arguments:ap];
	
	[self addMessage:actualMessage];
	
	[actualMessage release];
	va_end(ap); /* clean up when done */
}

- (void)addMessage:(NSString *)actualMessage
{
	NSLog(actualMessage);
}

@end
