//
//  AIFileManagerAdditions.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 23 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (AIFileManagerAdditions)
- (BOOL)trashFileAtPath:(NSString *)sourcePath;
- (void)createDirectoriesForPath:(NSString *)fullPath;
- (void)removeFilesInDirectory:(NSString *)dirPath withPrefix:(NSString *)prefix movingToTrash:(BOOL)moveToTrash;
@end
