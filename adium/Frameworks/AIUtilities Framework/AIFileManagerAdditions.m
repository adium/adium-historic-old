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

#import "AIFileManagerAdditions.h"

#define PATH_TRASH			@"~/.Trash"		//Path to the trash

@implementation NSFileManager (AIFileManagerAdditions)

//Move the target file to the trash
- (BOOL)trashFileAtPath:(NSString *)sourcePath
{
    NSParameterAssert(sourcePath != nil && [sourcePath length] != 0);

	if([self fileExistsAtPath:sourcePath]){
		NSString	*fileName;
		NSString	*destPath;
		
		//Create the destination path for this file (a folder with the same name in the user's trash)
		fileName = [sourcePath lastPathComponent];
		destPath = [[PATH_TRASH stringByAppendingPathComponent:fileName] stringByExpandingTildeInPath];
		
		//Move it to the trash
		if(![[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil]){
			//The move operation failed.  A folder with that name probably already exists in the trash
			//So let's try appending some random characters to the end of the file name
			destPath = [destPath stringByAppendingString:[NSString randomStringOfLength:6]];
			
			if(![[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil]){
				NSLog(@"Attempt to trash '%@' failed (%@).",fileName, sourcePath);
				return(NO);
			}
		}
	}		

	return(YES);
}

//Creates all the folders specified in 'fullPath' (if they don't exist)
- (void)createDirectoriesForPath:(NSString *)fullPath
{
    NSParameterAssert(fullPath != nil && [fullPath length] != 0);

    BOOL			isDir;
    NSMutableArray	*neededFolders = [[NSMutableArray alloc] init];
    short			folder;
	
    while(![[NSFileManager defaultManager]fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir){
        [neededFolders addObject:[fullPath lastPathComponent]];
        fullPath = [fullPath stringByDeletingLastPathComponent];
    }
	
    for(folder = [neededFolders count]-1;folder >= 0;folder--){
        fullPath = [fullPath stringByAppendingPathComponent:[neededFolders objectAtIndex:folder]];
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath attributes:nil];
    }
	
    [neededFolders release];
}

@end
