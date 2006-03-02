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

static BOOL scandate(const char *sample, unsigned long *outyear,
	unsigned long *outmonth, unsigned long *outdate);

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
    if (!logDict) {
		NSEnumerator    *enumerator;
		NSString	*fileName;
		NSString	*fullPath;
		
		//
		logDict = [[NSMutableDictionary alloc] init];
		
		//Retrieve any logs we've already loaded
		if (partialLogDict) {
			[logDict addEntriesFromDictionary:partialLogDict];
			[partialLogDict release]; partialLogDict = nil;
		}
		
		fullPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:path];
		enumerator = [[defaultManager directoryContentsAtPath:fullPath] objectEnumerator];
		while ((fileName = [enumerator nextObject])) {
			NSString		*relativeLogPath = [path stringByAppendingPathComponent:fileName];
			
			if (![logDict objectForKey:relativeLogPath]) {
				AIChatLog	*theLog;
				
				if ((theLog = [self _logAtRelativeLogPath:relativeLogPath fileName:fileName])) {
					[logDict setObject:theLog
								forKey:relativeLogPath];
				}
			}
		}
    }
	
    return logDict;
}

- (AIChatLog *)_logAtRelativeLogPath:(NSString *)relativeLogPath fileName:(NSString *)fileName
{
	NSDate			*date;
	AIChatLog		*theLog = nil;
	NSDictionary	*fileAttributes = [defaultManager fileAttributesAtPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:relativeLogPath]
															  traverseLink:NO];

	//If we are given a filename and it's invalid, abort
	if (fileName && (([fileName characterAtIndex:0] == '.') ||
					!([[fileAttributes fileType] isEqualToString:NSFileTypeRegular]))) {
		return nil;
	}

	//Create & add the log
	if ((date = [fileAttributes fileModificationDate])) {
		NSDate	*fileNameDate = [[self class] dateFromFileName:(fileName ? fileName : [relativeLogPath lastPathComponent])];
		
		NSTimeInterval dateTimeIntervalSinceFileNameDate = [date timeIntervalSinceDate:fileNameDate];

		if (dateTimeIntervalSinceFileNameDate < 0) {
			//Date is earlier than the filename date; simply use the fileNameDate. 
			//This is clearly a misrepresentation; the date on which the log was written according to Adium
			//will be more accurate.
			date = fileNameDate;
		} else if (dateTimeIntervalSinceFileNameDate >= 86400) {
			//Date is more than a day after the filename date, which will always start at 00:00:00
			//Set up this date as being 11:59:59 on the filename date, so it is later than other logs on that date
			//but still shows the correct start date
			date = [NSDate dateWithTimeIntervalSinceReferenceDate:([fileNameDate timeIntervalSinceReferenceDate] + 86399)];
		}

		theLog = [[[AIChatLog alloc] initWithPath:relativeLogPath
											 from:from
											   to:to
									 serviceClass:serviceClass
											 date:date] autorelease];
	}
	
	return theLog;
}

- (AIChatLog *)logAtPath:(NSString *)inPath
{
	AIChatLog	*theLog;
	
	if (logDict) {
		//Use the full dictionary if we have it
		theLog = [logDict objectForKey:inPath];
		
	} else {
		//Otherwise, use the partialLog dictionary, adding to it if necessary
		if (!partialLogDict) partialLogDict = [[NSMutableDictionary alloc] init];
		
		if (!(theLog = [partialLogDict objectForKey:inPath])) {
			theLog = [self _logAtRelativeLogPath:inPath fileName:nil];
			if (theLog) {
				[partialLogDict setObject:theLog forKey:inPath];
			}
		}
	}

	return theLog;
}

//Given an Adium log file name, return an NSCalendarDate with year, month, and day specified
+ (NSCalendarDate *)dateFromFileName:(NSString *)fileName
{
	unsigned long   year = 0;
	unsigned long   month = 0;
	unsigned long   day = 0;
	
	if (scandate([fileName UTF8String], &year, &month, &day)) {
		if (year && month && day) {
			return [NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone defaultTimeZone]];
		}
	}

	return nil;
}

@end

//Scan an Adium date string, supahfast C style
static BOOL scandate(const char *sample, unsigned long *outyear,
	unsigned long *outmonth, unsigned long *outdate)
{
	BOOL success = YES;
	unsigned long component;
    //read three numbers, starting after:
	
	//a space...
	while (*sample != ' ') {
    	if (!*sample) {
    		success = NO;
    		goto fail;
		} else {
			++sample;
		}
    }

	//...followed by a (
	while (*sample != '(') {
    	if (!*sample) {
    		success = NO;
    		goto fail;
		} else {
			++sample;
		}
    }

	//current character is a '(' now, so skip over it.
    ++sample; //start with the next character

    /*get the year*/ {
		while (*sample && (*sample < '0' || *sample > '9')) ++sample;
		if (!*sample) {
			success = NO;
			goto fail;
		}
		component = strtoul(sample, (char **)&sample, 10);
		if (outyear) *outyear = component;
    }
    
    /*get the month*/ {
		while (*sample && (*sample < '0' || *sample > '9')) ++sample;
		if (!*sample) {
			success = NO;
			goto fail;
		}
		component = strtoul(sample, (char **)&sample, 10);
		if (outmonth) *outmonth = component;
    }
    
    /*get the date*/ {
		while (*sample && (*sample < '0' || *sample > '9')) ++sample;
		if (!*sample) {
			success = NO;
			goto fail;
		}
		component = strtoul(sample, (char **)&sample, 10);
		if (outdate) *outdate = component;
    }

fail:
	return success;
}
