/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@implementation AILogToGroup

//A group of logs to an specific user
- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo
{
    [super init];
    
    path = [inPath retain];
    from = [inFrom retain];
    to = [inTo retain];
    logArray = nil;
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [path release];
    [to release];
    [from release];
    [logArray release];
    
    [super dealloc];
}

//
- (NSString *)to
{
    return(to);
}

//Returns all of our logs
- (NSArray *)logArray
{
    if(!logArray){
	NSEnumerator    *enumerator;
	NSString	*fileName;
	NSString	*fullPath;
	
	//
	logArray = [[NSMutableArray alloc] init];
	
	//
	fullPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:path];
	enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:fullPath] objectEnumerator];
	while((fileName = [enumerator nextObject])){
	    AILog   *log = [[AILog alloc] initWithPath:[path stringByAppendingPathComponent:fileName]
						  from:from
						    to:to
						  date:[AILog dateFromFileName:fileName]];
	    [logArray addObject:log];
	    [log release];
	}
    }
    
    return(logArray);
}


@end
