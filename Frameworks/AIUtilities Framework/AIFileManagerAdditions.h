//
//  AIFileManagerAdditions.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 23 2003.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (AIFileManagerAdditions)
- (BOOL)trashFileAtPath:(NSString *)sourcePath;
- (void)createDirectoriesForPath:(NSString *)fullPath;
- (void)removeFilesInDirectory:(NSString *)dirPath withPrefix:(NSString *)prefix movingToTrash:(BOOL)moveToTrash;
@end
