/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIStringAdditions.h"
#include <sys/types.h>
#include <unistd.h>

@implementation NSFileManager (AIFileManagerAdditions)

- (BOOL)isFileVaultEnabled
{
	NSString *homeFolder = NSHomeDirectory();
	NSString *homeFolderVolume = [homeFolder volumePath];
	return [homeFolder isEqualToString:homeFolderVolume];
}

//Move the target file to the trash
- (BOOL)trashFileAtPath:(NSString *)sourcePath
{
    NSParameterAssert(sourcePath != nil && [sourcePath length] != 0);
	
	if ([self fileExistsAtPath:sourcePath]) {
		NSString	*destPath;

		NSString	*fileName = [sourcePath lastPathComponent];
		NSString	*sourceVolume = [sourcePath volumePath];

		if ([sourceVolume isEqualToString:@"/"]) {
			//the file is on the startup disk.
			//use the trash in home.
			//example: /Users/boredzo/.Trash
			destPath = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
		} else {
			//the file is not on the startup disk.
			//use the trash on the disk the file is on.
			//example: /Volumes/Repository/.Trashes/501
			NSNumber *UIDnum = [NSNumber numberWithUnsignedInt:getuid()];
			destPath = [[sourceVolume stringByAppendingPathComponent:@".Trashes"] stringByAppendingPathComponent:[UIDnum stringValue]];
		}
		destPath = [destPath stringByAppendingPathComponent:fileName];

		//Move it to whichever Trash
		if (![[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil]) {
			//The move operation failed.  A folder with that name probably already exists in the trash.
			//So let's try appending some random characters to the end of the file name.
			NSString *destPathWithRandom = [destPath stringByAppendingString:[NSString randomStringOfLength:6]];
			
			if (![[NSFileManager defaultManager] movePath:sourcePath toPath:destPathWithRandom handler:nil]) {
				NSLog(@"Attempt to trash '%@' failed (full path: %@; full Trash path: %@).", fileName, sourcePath, destPath);
				return NO;
			}
			destPath = destPathWithRandom;
		}

		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		[workspace noteFileSystemChanged:sourcePath];
		[workspace noteFileSystemChanged:destPath];
	}		

	return YES;
}

- (void)removeFilesInDirectory:(NSString *)dirPath withPrefix:(NSString *)prefix movingToTrash:(BOOL)moveToTrash
{
	NSEnumerator	*enumerator;
	NSString		*fileName;
	
	dirPath = [dirPath stringByExpandingTildeInPath];
	
	enumerator = [[self directoryContentsAtPath:dirPath] objectEnumerator];
	while ((fileName = [enumerator nextObject])) {
		if ([fileName hasPrefix:prefix]) {
			NSString	*path = [dirPath stringByAppendingPathComponent:fileName];
			
			if (moveToTrash) {
				[self trashFileAtPath:path];
			} else {
				[self removeFileAtPath:path handler:nil];
			}
		}
	}	
}

//Creates all the folders specified in 'fullPath' (if they don't exist). Returns YES if any directories were created.
- (BOOL)createDirectoriesForPath:(NSString *)fullPath
{
    NSParameterAssert(fullPath != nil && [fullPath length] != 0);

    BOOL			isDir;
    NSMutableArray	*neededFolders = [[NSMutableArray alloc] init];
    unsigned		count;
	
    while (![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir) {
        [neededFolders addObject:[fullPath lastPathComponent]];
        fullPath = [fullPath stringByDeletingLastPathComponent];
    }
	
	
	count = [neededFolders count];
	if (count) {
		NSFileManager	*defaultManager = [NSFileManager defaultManager];
		short			folderIndex;
		for (folderIndex = count-1; folderIndex >= 0; folderIndex--) {
			fullPath = [fullPath stringByAppendingPathComponent:[neededFolders objectAtIndex:folderIndex]];
			[defaultManager createDirectoryAtPath:fullPath attributes:nil];
		}
	}
	
    [neededFolders release];
	
	return (count > 0);
}

#pragma mark -

//returns the pathname passed in if it exists on disk (test -e). Doesn't care whether the path is a file or a directory.
- (NSString *)pathIfExists:(NSString *)path
{
	BOOL exists = [self fileExistsAtPath:path];
	if (!exists) path = nil;
	return path;
}

//returns the pathname passed in if it exists on disk as a directory (test -d).
- (NSString *)pathIfDirectory:(NSString *)path
{
	BOOL  isDir = NO;
	BOOL exists = ([self fileExistsAtPath:path isDirectory:&isDir] && isDir);
	if (!exists) path = nil;
	return path;
}

//returns the pathname passed in if it exists on disk as a non-directory (test ! -d).
- (NSString *)pathIfNotDirectory:(NSString *)path
{
	BOOL  isDir = NO;
	BOOL exists = ([self fileExistsAtPath:path isDirectory:&isDir] && !isDir);
	if (!exists) path = nil;
	return path;
}

@end
