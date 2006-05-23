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

#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AIChatLog.h"

@interface AILogToGroup (PRIVATE)
- (NSDictionary *)logDict;
- (AIChatLog *)_logAtRelativeLogPath:(NSString *)relativeLogPath fileName:(NSString *)fileName;
+ (NSCalendarDate *)dateFromFileName:(NSString *)fileName;
@end

@implementation AILogToGroup

//A group of logs to an specific user
- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass
{
    if ((self = [super init]))
	{
		path = [inPath retain];
		from = [inFrom retain];
		to = [inTo retain];
		serviceClass = [inServiceClass retain];
		logDict = nil;
		partialLogDict = nil;
		
		defaultManager = [[NSFileManager defaultManager] retain];
	}

    return self;
}

//Dealloc
- (void)dealloc
{
    [path release];
    [to release];
    [from release];
    [serviceClass release];
	[logDict release];
	[partialLogDict release];
	
	[defaultManager release];
	
    [super dealloc];
}

//
- (NSString *)to
{
    return to;
}

- (NSString *)path
{
	return path;
}

//Returns an enumerator for all of our logs
- (NSEnumerator *)logEnumerator
{
	return [[self logDict] objectEnumerator];
}

- (NSDictionary *)logDict
{
	@synchronized(self) {
		if (!logDict) {
			NSEnumerator    *enumerator;
			NSString		*fileName;
			NSString		*logBasePath, *fullPath;
			
			//
			logDict = [[NSMutableDictionary alloc] init];
			
			//Retrieve any logs we've already loaded
			if (partialLogDict) {
				[logDict addEntriesFromDictionary:partialLogDict];
				[partialLogDict release]; partialLogDict = nil;
			}
			
			logBasePath = [AILoggerPlugin logBasePath];
			fullPath = [logBasePath stringByAppendingPathComponent:path];
			enumerator = [[defaultManager directoryContentsAtPath:fullPath] objectEnumerator];
			while ((fileName = [enumerator nextObject])) {			
				if (![fileName hasPrefix:@"."]) {
					NSString	*relativeLogPath = [path stringByAppendingPathComponent:fileName];
					BOOL		isDir;
					
					if (![logDict objectForKey:relativeLogPath] &&
						([defaultManager fileExistsAtPath:[logBasePath stringByAppendingPathComponent:relativeLogPath] isDirectory:&isDir] &&
						 !isDir)) {
						AIChatLog	*theLog;
						
						theLog = [[AIChatLog alloc] initWithPath:relativeLogPath
															from:from
															  to:to
													serviceClass:serviceClass];
						if (theLog) {
							[logDict setObject:theLog
										forKey:relativeLogPath];
						} else {
							NSLog(@"Class %@: Couldn't make for %@ %@ %@ %@",NSStringFromClass([AIChatLog class]),relativeLogPath,from,to,serviceClass);
						}	
						[theLog release];
					}
				}
			}
		}
	}
	
    return logDict;
}

/*
 * @brief Get an AIChatLog within this AILogToGroup
 *
 * @param inPath A _relative_ path of the form SERVICE.ACCOUNT_NAME/TO_NAME/LogName.Extension
 *
 * @result The AIChatLog, from the cache if possible
 */
- (AIChatLog *)logAtPath:(NSString *)inPath
{
	AIChatLog	*theLog;

	@synchronized(self) {
		if (logDict) {
			//Use the full dictionary if we have it
			theLog = [logDict objectForKey:inPath];
			
		} else {
			//Otherwise, use the partialLog dictionary, adding to it if necessary
			if (!partialLogDict) partialLogDict = [[NSMutableDictionary alloc] init];
			
			if (!(theLog = [partialLogDict objectForKey:inPath])) {
				AIChatLog	*theLog;
				
				theLog = [[AIChatLog alloc] initWithPath:inPath
													from:from
													  to:to
											serviceClass:serviceClass];
				[partialLogDict setObject:theLog
								   forKey:inPath];
				[theLog release];
			}
		}
	}
	return theLog;
}

@end
