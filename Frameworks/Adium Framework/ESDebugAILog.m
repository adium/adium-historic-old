//
//  ESDebugAILog.m
//  Adium
//
//  Created by Evan Schoenberg on 1/29/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESDebugAILog.h"

#include <stdarg.h>
#import <Foundation/Foundation.h>

/*
 * @brief Adium debug log function
 *
 * Prints a message to the Adium debug window, which is only enabled in Debug and Development builds.  
 * In Deployment builds, this function is replaced by a #define which is just a comment, so there is no cost to
 * deployment to use it.
 *
 * @param format A printf-style format string
 * @param ... 0 or more arguments to the format string
 */
void AILog (NSString *format, ...)
{
	va_list		ap; /* Points to each unamed argument in turn */
	NSString	*actualMessage;
	
	va_start(ap, format); /* Make ap point to the first unnamed argument */
	actualMessage = [[NSString alloc] initWithFormat:format
										   arguments:ap];

	/* Be careful; we should only modify debugLogArray and the windowController's view on the main thread. */
	[[NSClassFromString(@"ESDebugController") sharedDebugController] performSelectorOnMainThread:@selector(addMessage:)
																					  withObject:actualMessage
																				   waitUntilDone:NO];
	
	[actualMessage release];
	va_end(ap); /* clean up when done */
}
