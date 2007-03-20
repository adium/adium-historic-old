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
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
                                                     source:[sourcePath stringByDeletingLastPathComponent]
                                                destination:@""
                                                      files:[NSArray arrayWithObject:[sourcePath lastPathComponent]]
                                                        tag:NULL];
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

	NSFileManager *manager = [NSFileManager defaultManager];
    BOOL			isDir;
	unsigned		count = 0;

	if (![manager fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir) {
		NSMutableArray	*neededFolders = [[NSMutableArray alloc] init];
		
		do
		{
			[neededFolders addObject:[fullPath lastPathComponent]];
			fullPath = [fullPath stringByDeletingLastPathComponent];
			
		}
		while (![manager fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir);
		
		count = [neededFolders count];
		if (count > 0) {
			short			folderIndex;
			for (folderIndex = count-1; folderIndex >= 0; folderIndex--) {
				fullPath = [fullPath stringByAppendingPathComponent:[neededFolders objectAtIndex:folderIndex]];
				[manager createDirectoryAtPath:fullPath attributes:nil];
			}
		}
		
		[neededFolders release];
	}
	
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

/*!
 * @brief Generate a unique path given a path
 *
 * If nothing exists at the path, the path is returned.
 * If a file or folder with the passed name already exists, a hyphen and a number is added, the number being the 
 * smallest necessary for it to be unique.
 *
 * For example, if ~/Desktop/pr0n.jpg already exists, ~/Desktop/pr0n-1.jpg will be returned, if that file does not
 * exist.  If ~/Desktop/pr0n-1.jpg exists, ~/Desktop/pr0n-2.jpg will be returned, and so on.
 *
 * @result The full unique path
 */
- (NSString *)uniquePathForPath:(NSString *)inPath
{
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSString		*uniquePath = inPath;
	NSString		*basePath = nil, *fileName = nil, *extension = nil;
	BOOL			generatedParts = NO;
	unsigned		uniqueNameCounter = 0;
	
	//Get a unique name if necessary. This could happen if we are sending this folder multiple times.
	while ([defaultManager fileExistsAtPath:uniquePath]) {
		NSString	*uniqueFilename;
		
		if (!generatedParts) {
			basePath = [inPath stringByDeletingLastPathComponent];
			fileName = [[inPath lastPathComponent] stringByDeletingPathExtension];
			extension = [inPath pathExtension];
			
			//If there is no extension, -[NSString pathExtension] returns @""
			if (![extension length]) extension = nil;
			
			generatedParts = YES;
		}
		
		//Get a unique file name
		uniqueFilename = [NSString stringWithFormat:@"%@-%i",fileName,++uniqueNameCounter];
		
		//Put it at the proper path
		uniquePath = [basePath stringByAppendingPathComponent:uniqueFilename];
		
		//Append the extension if there is one
		if (extension) {
			uniquePath = [uniquePath stringByAppendingPathExtension:extension];
		}
	}
	
	return uniquePath;
}


- (NSString *)findFolderOfType:(OSType)type inDomain:(short)domain createFolder:(BOOL)createFolder
{
    CFURLRef folderURL;
    FSRef folderRef;
    OSErr err;
	
    err = FSFindFolder(domain, type, createFolder, &folderRef);
    if (err != noErr)
        return nil;
    
    folderURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &folderRef);
    if (! folderURL)
        return nil;
    
    return [(NSString *)CFURLCopyFileSystemPath(folderURL, kCFURLPOSIXPathStyle) autorelease];
}

- (NSString *)userApplicationSupportFolder
{
    return [self findFolderOfType:kApplicationSupportFolderType inDomain:kUserDomain createFolder:YES];
}

- (NSString *)pathByResolvingAlias:(NSString *)path
{
	NSString *resolvedPath = nil;
	CFURLRef url;

	url = CFURLCreateWithFileSystemPath(/* allocator */ NULL, (CFStringRef)path,
										kCFURLPOSIXPathStyle, /* isDir */ false);
	if (url) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, 
									&targetIsFolder, &wasAliased) == noErr && wasAliased) {
				CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fsRef);
				if (resolvedUrl) {
					resolvedPath = [(NSString*)CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle) autorelease];
					CFRelease(resolvedUrl);
				}
			}
		}
		CFRelease(url);
	}
	
	return (resolvedPath ? resolvedPath : [[path copy] autorelease]);
}

@end
