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
#import "AILogFromGroup.h"
#import "AILogToGroup.h"

@implementation AILogFromGroup

//A group of logs from one of our accounts
- (AILogFromGroup *)initWithPath:(NSString *)inPath from:(NSString *)inFrom
{
    [super init];
    
    path = [inPath retain];
    from = [inFrom retain];
    toGroupArray = nil;
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [path release];
    [from release];
    [toGroupArray release];
    
    [super dealloc];
}

//
- (NSString *)from
{
    return(from);
}

//Returns all of our to groups
- (NSArray *)toGroupArray
{
    //Create our toGroups if necessary
    if(!toGroupArray){
		NSEnumerator    *enumerator;
		NSString	*folderName;
		NSString	*fullPath;
		
		//
		toGroupArray = [[NSMutableArray alloc] init];
		
		//
		fullPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:path];
		enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:fullPath] objectEnumerator];
		while(folderName = [enumerator nextObject]){
			AILogToGroup    *toGroup = nil;
			
			while(!toGroup){
				//#### Why does this alloc fail sometimes? ####
				toGroup = [[AILogToGroup alloc] initWithPath:[path stringByAppendingPathComponent:folderName]
														from:from
														  to:folderName];
				
				//Not sure why, but I've had that alloc fail on me before
				if(toGroup){
					[toGroupArray addObject:toGroup];
				}else{
					NSLog(@"FAILED to alloc toGroup %@, trying again",[path stringByAppendingPathComponent:folderName]);
				}
			}
			
			[toGroup release];
		}
    }
    
    return(toGroupArray);
}

@end
