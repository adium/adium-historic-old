/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIPlugin.h>

#define PATH_LOGS                       @"/Logs"
#define LOGGING_DEFAULT_PREFS           @"LoggingDefaults"

#define PREF_GROUP_LOGGING              @"Logging"
#define KEY_LOGGER_ENABLE               @"Enable Logging"

#define PREF_KEYPATH_LOGGER_ENABLE		PREF_GROUP_LOGGING @"." KEY_LOGGER_ENABLE

//Uncomment this to enable XML_LOGGING
#define XML_LOGGING

@class AIAccount, AIChat, AILoggerPreferences, AILoggerAdvancedPreferences;

@interface AILoggerPlugin : AIPlugin {
    AILoggerPreferences                 *preferences;
    
    //Current logging settings
    BOOL				observingContent;
    BOOL				logHTML;

#ifdef XML_LOGGING
	NSMutableDictionary					*activeAppenders;
	NSMutableDictionary					*activeTimers;
	
	AIHTMLDecoder						*HTMLDecoder;
	NSDictionary						*statusTranslation;
#endif
	
    //Log viewer menu items
    NSMenuItem                          *logViewerMenuItem;
    NSMenuItem                          *viewContactLogsMenuItem;
    NSMenuItem                          *viewContactLogsContextMenuItem;

    //Log content search index
	BOOL				logIndexingEnabled; //Does this system use log indexing?
    SKIndexRef			index_Content;	

    //Dirty all information (First build of the dirty cache)
    BOOL				stopIndexingThreads;    //Set to YES to abort a dirty all or clean
    BOOL				suspendDirtyArraySave;  //YES to prevent saving of the dirty index	
    NSLock				*indexingThreadLock;	//Locked by the plugin when a dirty all or clean thread is running

	/*
	 Locked by the plugin while the index is being modified.
	 Locked by the logViewerWindowController when content searching is running.
	 */
	NSLock				*logAccessLock;
    
    //Array of dirty logs / Logs that need re-indexing.  (Locked access)
    NSMutableArray                      *dirtyLogArray;
    NSLock				*dirtyLogLock;
    
    //Indexing progress
    int                                 logsToIndex;
    int                                 logsIndexed;
    
}

//Paths
+ (NSString *)logBasePath;
+ (NSString *)relativePathForLogWithObject:(NSString *)object onAccount:(AIAccount *)account;
#ifdef XML_LOGGING
+ (NSString *)fileNameForLogWithObject:(NSString *)object onDate:(NSDate *)date;
#endif
+ (NSString *)fileNameForLogWithObject:(NSString *)object onDate:(NSDate *)date plainText:(BOOL)plainText;
+ (NSString *)fullPathOfLogAtRelativePath:(NSString *)relativePath;

//Log viewer
- (void)showLogViewerToSelectedContact:(id)sender;
- (void)showLogViewerToSelectedContextContact:(id)sender;

//Log indexing
- (void)initLogIndexing;
- (void)prepareLogContentSearching;
- (void)cleanUpLogContentSearching;
- (SKIndexRef)logContentIndex;
- (void)markLogDirtyAtPath:(NSString *)path forChat:(AIChat *)chat;
- (BOOL)getIndexingProgress:(int *)complete outOf:(int *)total;

//
- (void)stopIndexingThreads;
- (void)dirtyAllLogs;
- (void)cleanDirtyLogs;

- (NSLock *)logAccessLock;

@end

