//
//  AIFileManagerAdditions.m
//  Adium XCode
//
//  Created by Adam Iser on Tue Dec 23 2003.
//

#import "AIFileManagerAdditions.h"

#define PATH_TRASH			@"~/.Trash"		//Path to the trash

@implementation NSFileManager (AIFileManagerAdditions)

//Move the target file to the trash
- (BOOL)trashFileAtPath:(NSString *)sourcePath
{
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

@end
