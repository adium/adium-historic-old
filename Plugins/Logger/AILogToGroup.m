/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AILog.h"

#define OLD_SUFFIX  @".adiumLog.html"

@interface AILogToGroup (PRIVATE)
- (NSDictionary *)logDict;
- (AILog *)_logAtRelativeLogPath:(NSString *)relativeLogPath fileName:(NSString *)fileName;
@end

@implementation AILogToGroup

//A group of logs to an specific user
- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass
{
    [super init];
    
    path = [inPath retain];
    from = [inFrom retain];
    to = [inTo retain];
	serviceClass = [inServiceClass retain];
	logDict = nil;
	partialLogDict = nil;
	
	defaultManager = [[NSFileManager defaultManager] retain];

    return(self);
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
    return(to);
}

- (NSString *)path
{
	return(path);
}

//Returns an enumerator for all of our logs
- (NSEnumerator *)logEnumerator
{
	return [[self logDict] objectEnumerator];
}

- (NSDictionary *)logDict
{
    if(!logDict){
		NSEnumerator    *enumerator;
		NSString	*fileName;
		NSString	*fullPath;
		
		//
		logDict = [[NSMutableDictionary alloc] init];
		
		//Retrieve any logs we've already loaded
		if (partialLogDict){
			[logDict addEntriesFromDictionary:partialLogDict];
			[partialLogDict release]; partialLogDict = nil;
		}
		
		fullPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:path];
		enumerator = [[defaultManager directoryContentsAtPath:fullPath] objectEnumerator];
		while(fileName = [enumerator nextObject]){
			NSString		*relativeLogPath = [path stringByAppendingPathComponent:fileName];
			
			if (![logDict objectForKey:relativeLogPath]){
				AILog	*theLog;
				
				if (theLog = [self _logAtRelativeLogPath:relativeLogPath fileName:fileName]){
					[logDict setObject:theLog
								forKey:relativeLogPath];
				}
			}
		}
    }
	
    return(logDict);
}

- (AILog *)_logAtRelativeLogPath:(NSString *)relativeLogPath fileName:(NSString *)fileName
{
	NSDate			*date;
	AILog			*theLog = nil;
	NSDictionary	*fileAttributes = [defaultManager fileAttributesAtPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:relativeLogPath]
															  traverseLink:NO];

	//If we are given a filename and it's invalid, abort
	if(fileName && (([fileName characterAtIndex:0] == '.') ||
					!([[fileAttributes fileType] isEqualToString:NSFileTypeRegular]))){
		return(nil);
	}
	
	//Temprary Code.  This can be removed once everyone who ran the alpha has opened their log viewer :)
	//
	//Rename Adium 2.0 alpha logs.  Logs saved after the format change and before this viewer use
	//the filename format: adam_(2003|11|16).adiumLog.html
	//
	//We want to convert these to: adam (2003|11|16).html
	//
	if([fileName hasSuffix:OLD_SUFFIX]){
		NSString    *filePath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:path];
		NSString    *newName;
		NSRange     underRange = [fileName rangeOfString:@"_"];
		
		//Remove the .adiumLog and the '_'
		newName = [NSString stringWithFormat:@"%@.html",[fileName substringToIndex:([fileName length] - [OLD_SUFFIX length])]];
		newName = [NSString stringWithFormat:@"%@ %@",[newName substringToIndex:underRange.location], [newName substringFromIndex:underRange.location+1]];
		
		//Rename
		[[NSFileManager defaultManager] movePath:[filePath stringByAppendingPathComponent:fileName]
										  toPath:[filePath stringByAppendingPathComponent:newName]
										 handler:nil];
		fileName = newName;
	}
	
	//Create & add the log

	if(date = [fileAttributes fileModificationDate]){
		/*
		 60*60*24*7*8 = 4838400 seconds = 2 months ago or earlier: 
		 Don't trust the modification date in case we're using a restore-from-backup log folder; we don't want all those
		 old logs to have the same date.
		 
		 Don't trust the modification date if it's in the future.
		 */
		NSTimeInterval dateTimeIntervalSinceNow = [date timeIntervalSinceNow];
		if ((dateTimeIntervalSinceNow < -4838400) || (dateTimeIntervalSinceNow > 0)){
			date = [AILog dateFromFileName:(fileName ?
											fileName :
											[relativeLogPath lastPathComponent])];
		}
		
		theLog = [[[AILog allocWithZone:nil] initWithPath:relativeLogPath
													 from:from
													   to:to
											 serviceClass:serviceClass
													 date:date] autorelease];
	}
	
	return(theLog);
}

- (AILog *)logAtPath:(NSString *)inPath
{
	AILog	*theLog;
	
	if (logDict){
		//Use the full dictionary if we have it
		theLog = [logDict objectForKey:inPath];
		
	}else{
		//Otherwise, use the partialLog dictionary, adding to it if necessary
		if (!partialLogDict) partialLogDict = [[NSMutableDictionary alloc] init];
		
		if (!(theLog = [partialLogDict objectForKey:inPath])){
			theLog = [self _logAtRelativeLogPath:inPath fileName:nil];
			if (theLog){
				[partialLogDict setObject:theLog forKey:inPath];
			}
		}
	}

	return(theLog);
}

@end
