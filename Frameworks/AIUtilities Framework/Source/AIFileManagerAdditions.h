//
//  AIFileManagerAdditions.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 23 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * @category NSFileManager(AIFileManagerAdditions)
 * @brief Additions to <tt>NSFileManager</tt> for trashing files and creating directories
 */
@interface NSFileManager (AIFileManagerAdditions)
/*
 * @brief Move a file or directory to the trash
 *
 * sourcePath does not need to be tildeExpanded; it will be expanded if necessary.
 * @param sourcePath Path to the file or directory to trash
 * @result YES if trashing was successful or the file already does not exist; NO if it failed
 */
- (BOOL)trashFileAtPath:(NSString *)sourcePath;

/*
 * @brief Create all directories for a path
 *
 * Like <b>mkdir -p</b>, create the specified directory if it does not exist and create all intermediate directories as needed.
 * @param fullPath Path to be created
 * @result YES if one or more directories were created
 */
- (BOOL)createDirectoriesForPath:(NSString *)fullPath;

/*
 * @brief Delete or trash all files in a directory starting with <b>prefix</b>
 *
 * The files must begin with characters matching <b>prefix</b> exactly; the comparison is case sensitive.
 * @param dirPath The directory in which to search
 * @param prefix The prefix for which to look, case sensitively
 * @param moveToTrash If YES, move the files to the trash. If NO, delete them permanently.
 */
- (void)removeFilesInDirectory:(NSString *)dirPath withPrefix:(NSString *)prefix movingToTrash:(BOOL)moveToTrash;
@end
