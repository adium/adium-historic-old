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

#define PATH_LOGS		@"/Logs"
#define LOGGING_DEFAULT_PREFS       @"LoggingDefaults"
#define PREF_GROUP_LOGGING	@"Logging"
#define KEY_LOGGER_ENABLE	@"Enable Logging"
#define	KEY_LOGGER_HTML		@"Enable HTML Logging"

@class AILoggerPreferences, AILoggerAdvancedPreferences;

@interface AILoggerPlugin : AIPlugin {
    AILoggerPreferences		*preferences;
    
    //Current logging settings
    BOOL		    observingContent;
    BOOL		    logIndexingEnabled; //Does this system support log indexing?
    BOOL			logHTML;
	
    //Log viewer menu items
    NSMenuItem		    *logViewerMenuItem;
    NSMenuItem		    *viewContactLogsMenuItem;
    NSMenuItem		    *viewContactLogsContextMenuItem;

    //Log content search index
    SKIndexRef		    index_Content;      

    //Dirty all information (First build of the dirty cache)
    NSLock		    *indexingThreadLock;    //Locked when a dirty all or clean thread is running
    BOOL		    stopIndexingThreads;    //Set to YES to abort a dirty all or clean
    BOOL		    suspendDirtyArraySave;  //YES to prevent saving of the dirty index
    
    //Array of dirty logs / Logs that need re-indexing.  (Locked access)
    NSMutableArray	    *dirtyLogArray;
    NSLock		    *dirtyLogLock;
    
    //Indexing progress
    int			    logsToIndex;
    int			    logsIndexed;
    
}

+ (NSString *)logBasePath;
+ (NSString *)logPathWithAccount:(AIAccount *)account andObject:(NSString *)object;
- (void)initLogIndexing;
- (void)prepareLogContentSearching;
- (SKIndexRef)logContentIndex;
- (void)cleanUpLogContentSearching;
- (BOOL)getIndexingProgress:(int *)complete outOf:(int *)total;
- (void)markChatLogAsDirty:(AIChat *)chat atPath:(NSString *)path;

@end

