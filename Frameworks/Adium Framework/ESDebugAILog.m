/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ESDebugAILog.h"
#import "ESDebugController.h"
#include <stdarg.h>

/*!
 * @brief Adium debug log function
 *
 * Prints a message to the Adium debug window, which is only enabled in Debug and Development builds.  
 * In Deployment builds, this function is replaced by a #define which is just a comment, so there is no cost to
 * deployment to use it.
 *
 * @param format A printf-style format string
 * @param ... 0 or more arguments to the format string
 */
#ifdef DEBUG_BUILD
void AILog (NSString *format, ...) {
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
#else
void AILog (NSString *format, ...) {};
#endif
