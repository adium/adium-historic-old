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
#import "AILogViewerWindowController.h"
#import "AILoggerPreferences.h"
#import "AILog.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"

#define LOG_INDEX_PATH		    @"~/Library/Caches/Adium"
#define LOG_INDEX_NAME		    @"Logs_%@.index"
#define DIRTY_LOG_ARRAY_NAME	    @"DirtyLogs_%@.plist"

#define LOG_INDEX_STATUS_INTERVAL   20      //Interval before updating the log indexing status
#define LOG_CLEAN_SAVE_INTERVAL     500     //Number of logs to index continuiously before saving the dirty array and index

#define LOG_VIEWER	    AILocalizedString(@"Log Viewer",nil)
#define VIEW_CONTACTS_LOGS  AILocalizedString(@"View Contact's Logs",nil)
#define VIEW_LOGS	    AILocalizedString(@"View Logs",nil)

@interface AILoggerPlugin (PRIVATE)
- (NSString  *)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(NSString *)object onDate:(NSDate *)date;
- (void)_markChatLogAsDirty:(AIChat *)chat atPath:(NSString *)path;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_dirtyAllLogsThread;
- (void)_cleanDirtyLogsThread;
- (void)initLogIndexing;
- (NSString *)dirtyLogArrayPath;
- (NSString *)logIndexPath;
- (void)_loadLogIndex;
- (void)_closeLogIndex;
- (void)_saveDirtyLogArray;
- (void)dirtyAllLogs;
- (void)cleanDirtyLogs;
- (void)stopIndexingThreads;
@end

static NSString     *logBasePath = nil;     //The base directory of all logs

@implementation AILoggerPlugin

//
- (void)installPlugin
{
    //Init
    observingContent = NO;
    index_Content = nil;
    stopIndexingThreads = NO;
    suspendDirtyArraySave = NO;
    logIndexingEnabled = NO;
    dirtyLogArray = nil;
    indexingThreadLock = [[NSLock alloc] init];
    dirtyLogLock = [[NSLock alloc] init];

    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LOGGING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LOGGING];
    preferences = [[AILoggerPreferences preferencePane] retain];

    //Install the log viewer menu item
    logViewerMenuItem = [[[NSMenuItem alloc] initWithTitle:LOG_VIEWER target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@"l"] autorelease];
    [[adium menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxiliary];

    //Install the 'view logs' menu item
    viewContactLogsMenuItem = [[[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_LOGS target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@"L"] autorelease];
    [[adium menuController] addMenuItem:viewContactLogsMenuItem toLocation:LOC_Contact_Manage];

    //Install a 'view logs' contextual menu item
    viewContactLogsContextMenuItem = [[[NSMenuItem alloc] initWithTitle:VIEW_LOGS target:self action:@selector(showLogViewerToSelectedContextContact:) keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:viewContactLogsContextMenuItem toLocation:Context_Contact_Manage];
    
    //Create a logs directory
    logBasePath = [[[[[adium loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
    [AIFileUtilities createDirectory:logBasePath];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //Init index searching
    if([NSApp isOnPantherOrBetter]) [self initLogIndexing];
}

//Update for the new preferences
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_LOGGING] == 0){
        NSDictionary    *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];
        BOOL            newLogValue;
		
		logHTML = [[preferenceDict objectForKey:KEY_LOGGER_HTML] boolValue];
		
        //Start/Stop logging
        newLogValue = [[preferenceDict objectForKey:KEY_LOGGER_ENABLE] boolValue];
        if(newLogValue != observingContent){
            observingContent = newLogValue;

            if(!observingContent){ //Stop Logging
                [[adium notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];

            }else{ //Start Logging
                [[adium notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];
                
            }
        }
    }
}

//Base location of logs (we use partial paths everywhere to cut down memory usage)
+ (NSString *)logBasePath
{
    return(logBasePath);
}

+ (NSString *)logPathWithAccount:(AIAccount *)account andObject:(NSString *)object
{
    return [[logBasePath stringByAppendingPathComponent:[account uniqueObjectID]] stringByAppendingPathComponent:object];
}

//Enable/Disable our view log menus
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;

    if(menuItem == viewContactLogsMenuItem){
        AIListObject	*selectedObject = [[adium contactController] selectedListObject];

        if(selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
            [viewContactLogsMenuItem setTitle:[NSString stringWithFormat:@"View %@'s Logs",[selectedObject displayName]]];
        }else{
            [viewContactLogsMenuItem setTitle:@"View Contact's Logs"];
            valid = NO;
        }
    }else if(menuItem == viewContactLogsContextMenuItem){
        AIListContact	*selectedContact = [[adium menuController] contactualMenuContact];
        if ( !(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]) )
              valid = NO;
    }
    return(valid);
}

//Show the log viewer, displaying the selected contact's logs
- (void)showLogViewerToSelectedContact:(id)sender
{
    AIListObject   *selectedObject = [[adium contactController] selectedListObject];
    [AILogViewerWindowController openForContact:([selectedObject isKindOfClass:[AIListContact class]] ? (AIListContact *)selectedObject : nil)
										 plugin:self];
}

//Show the log viewer, displaying the selected contact's logs
- (void)showLogViewerToSelectedContextContact:(id)sender
{
    [AILogViewerWindowController openForContact:[[adium menuController] contactualMenuContact] plugin:self];
}

//
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];
    AIChat		*chat = [notification object];
    AIAccount		*account = [chat account];
	
    NSAttributedString	*message = nil;
    NSString		*object = nil;
    AIListObject	*source = nil;
    NSDate			*date = nil;
    NSString		*dateString = nil;
    NSString		*logMessage = nil;

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
		date        = [content date];
		dateString  = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
	
		object      = [[chat statusDictionary] objectForKey:@"DisplayName"];
		if(!object) object = [[chat listObject] UID];
	
		source      = [content source];
		message     = [[content message] safeString];

        if(source){
			if(logHTML) {
				NSString *imagesDirectory = [NSString stringWithFormat:@"%@ (%@) images", object, [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];
				NSString *imagesPath = [[AILoggerPlugin logPathWithAccount:account andObject:object] stringByAppendingPathComponent:imagesDirectory];
			
				logMessage = [NSString stringWithFormat:@"<div class=\"%@\"><span class=\"timestamp\">%@</span> <span class=\"sender\">%@: </span><pre class=\"message\">%@</pre></div>\n",
					([content isOutgoing] ? @"send" : @"receive"),
					dateString,
					[source UID],
					[AIHTMLDecoder encodeHTML:message headers:NO fontTags:NO closeFontTags:NO 
									styleTags:YES closeStyleTagsOnFontChange:YES
									encodeNonASCII:YES imagesPath:imagesPath]];
			} else {
				logMessage = [NSString stringWithFormat:@"(%@) %@: %@\n", dateString, [source UID], [message string]];
			}
		}

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
	
		date        = [content date];
        dateString  = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
        object      = [[chat statusDictionary] objectForKey:@"DisplayName"];
           
		if(!object) object = [[chat listObject] UID];
		
		source      = [content source];
        message     = [content message];

        if(source){
			if(logHTML) {
				logMessage = [NSString stringWithFormat:@"<div class=\"status\">%@ (%@)</div>\n", message, dateString];
			} else {
				logMessage = [NSString stringWithFormat:@"<%@ (%@)>\n", message, dateString];
			}
		}
    }

    //Log the message and flag it for re-indexing
    if(logMessage != nil){
	[self markChatLogAsDirty:chat
			  atPath:[self _addMessage:logMessage betweenAccount:account andObject:object onDate:date]];
    }
    
}

//Add a message to the specified log file
- (NSString  *)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(NSString *)object onDate:(NSDate *)date
{
    NSString	*logPath;
    NSString	*logFileName;
    NSString    *logFullPath;
    FILE		*file;

    //Create path to log file (.../Logs/ServiceID.AccountUID/HandleUID/HandleUID (YY|MM|DD).adiumLog)
    logPath = [AILoggerPlugin logPathWithAccount:account andObject:object];
    
	if(logHTML) {
		logFileName = [NSString stringWithFormat:@"%@ (%@).html", object, [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];
    } else {
		logFileName = [NSString stringWithFormat:@"%@ (%@).adiumLog", object, [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];
	}
	
    //Create a directory for this log (if one doesn't exist)
    [AIFileUtilities createDirectory:logPath];

    //Append the new content (We use fopen/fputs/fclose for max speed)
    logFullPath = [logPath stringByAppendingPathComponent:[logFileName safeFilenameString]];
    file = fopen([logFullPath fileSystemRepresentation], "a");
	if(!file)
	{
		NSLog(@"Unable to write %@: %d",logFullPath,errno);
		NSRunAlertPanel(@"Unable to write log",
						[NSString stringWithFormat:@"Adium was unable to write the log file for this conversation. Please check your log directory (%@) and then reenable logging in the Message preferences.",logBasePath],
						@"OK",nil,nil);
		//Disable logging
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
	}
	else
	{
		if (ftell(file) == 0) {
			const unichar bom = 0xFEFF;
			NSString *bomString = [[NSString alloc] initWithCharacters:&bom length:1];
			fputs([bomString UTF8String], file);
			[bomString release];
		}
		fputs([message UTF8String], file);
		fclose(file);
	}
 
    return(logFullPath);
}


//Log Indexing ------------------------------------------------------------------------------------------------------------------------
/* For the log content searching, we are required to re-index a log whenever it changes.  The solution below to
this problem is along the lines of:
- Keep an array of logs that need to be re-indexed
- Whenever a log is changed, add it to this array
- When the log viewer is opened, re-index all the logs in the array
*/
//Init log indexing
- (void)initLogIndexing
{
    //Load the list of logs that need re-indexing
    logIndexingEnabled = YES;
    dirtyLogArray = [[NSArray arrayWithContentsOfFile:[self dirtyLogArrayPath]] mutableCopy];
}

//Prepare the log index for searching.  Must call before attempting to use the logSearchIndex 
- (void)prepareLogContentSearching
{
    //If we're going to need to re-index all our logs from scratch, it will make
    //things faster if we start with a fresh log index as well.
    if(!dirtyLogArray){
		if([[NSFileManager defaultManager] fileExistsAtPath:[self logIndexPath]]){
			if(![[NSFileManager defaultManager] trashFileAtPath:[self logIndexPath]]){
				NSLog(@"Failed to delete log index.");
			}
		}	
    }
    
    //Load the index and start indexing to make it current
    if(logIndexingEnabled){
	[self _loadLogIndex];
	stopIndexingThreads = NO;
	if(!dirtyLogArray){
	    [self dirtyAllLogs];
	}else{
	    [self cleanDirtyLogs];
	}
    }
}

//Returns the Search Kit index for log content searching
- (SKIndexRef)logContentIndex
{
    if(logIndexingEnabled){
	SKIndexFlush(index_Content); //Flush the index before returning to ensure everything is up to date
	return(index_Content);
    }else{
	return(nil);
    }
}

//Close down and clean up the log index.  Call when finished using the logSearchIndex
- (void)cleanUpLogContentSearching
{
    if(logIndexingEnabled){
	[self stopIndexingThreads];
	[self _closeLogIndex];
    }
}

//Get the current status of indexing.  Returns NO is indexing is not occuring
- (BOOL)getIndexingProgress:(int *)complete outOf:(int *)total
{
    if(logIndexingEnabled){
	*complete = logsIndexed;
	*total = logsToIndex;
	return(logsToIndex != 0);
    }else{
	return(NO);
    }
}

//Mark a log as needing a re-index
- (void)markChatLogAsDirty:(AIChat *)chat atPath:(NSString *)path
{
    if(logIndexingEnabled){
	NSString    *dirtyKey = [@"LogIsDirty_" stringByAppendingString:path];
	
	if(dirtyLogArray && ![[[chat statusDictionary] objectForKey:dirtyKey] boolValue]){
	    //Add to dirty array (Lock to ensure that no one changes its content while we are)
	    [dirtyLogLock lock];
	    [dirtyLogArray addObject:path];
	    [dirtyLogLock unlock];
	    
	    //Save the dirty array immedientally
	    [self _saveDirtyLogArray];
	    
	    //Flag the chat with 'LogIsDirty' for this filename.  On the next message we can quickly check this flag.
	    [[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:dirtyKey];
	    [[adium notificationCenter] postNotificationName:Content_ChatStatusChanged object:chat userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"LogIsDirty"] forKey:@"Keys"]];
	}	
    }
}

//Load the log search index from disk
- (void)_loadLogIndex
{
    NSString    *logIndexPath = [self logIndexPath];
    NSURL       *logIndexPathURL = [NSURL fileURLWithPath:logIndexPath];

    //Load the log index (creating if necessary)
    if([[NSFileManager defaultManager] fileExistsAtPath:logIndexPath]){
	index_Content = SKIndexOpenWithURL((CFURLRef)logIndexPathURL, (CFStringRef)@"Content", true);
    }
    if(!index_Content){
	[AIFileUtilities createDirectory:[logIndexPath stringByDeletingLastPathComponent]];
	index_Content = SKIndexCreateWithURL((CFURLRef)logIndexPathURL, (CFStringRef)@"Content", kSKIndexVector, NULL);
    }
}

//Close and clean up the log search index
- (void)_closeLogIndex
{
    //Close the search index
    if(index_Content) CFRelease(index_Content);
    index_Content = nil;
}

//Save the array of dirty logs.  We always want to call this after making changes so nothing is de-synced by a crash.
- (void)_saveDirtyLogArray
{
    if(dirtyLogArray && !suspendDirtyArraySave){
	[dirtyLogLock lock];
	[dirtyLogArray writeToFile:[self dirtyLogArrayPath] atomically:NO];
	[dirtyLogLock unlock];
    }
}

//Path to the dirty log array file
- (NSString *)dirtyLogArrayPath
{
    NSString    *dirtyLogFileName = [NSString stringWithFormat:DIRTY_LOG_ARRAY_NAME, [[adium loginController] currentUser]];
    return([[LOG_INDEX_PATH stringByAppendingPathComponent:dirtyLogFileName] stringByExpandingTildeInPath]);
}

//Path to the log index file
- (NSString *)logIndexPath
{
    NSString    *logIndexFileName = [NSString stringWithFormat:LOG_INDEX_NAME,[[adium loginController] currentUser]];
    return([[LOG_INDEX_PATH stringByAppendingPathComponent:logIndexFileName] stringByExpandingTildeInPath]);
}


//Threaded index code ------------------------------------------------------------
//Stop any indexing related threads
- (void)stopIndexingThreads
{
    //Let any indexing threads know it's time to stop, and wait for them to finish.
    stopIndexingThreads = YES;
    [indexingThreadLock lock]; [indexingThreadLock unlock];
}

//The following methods will be run in a separate thread to avoid blocking the interface during index operations
//THREAD: Flag every log as dirty (Do this when there is no log index)
- (void)dirtyAllLogs
{
    //Reset and rebuild the dirty array
    [dirtyLogArray release]; dirtyLogArray = [[NSMutableArray alloc] init];
    [NSThread detachNewThreadSelector:@selector(_dirtyAllLogsThread) toTarget:self withObject:nil];
}
- (void)_dirtyAllLogsThread
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    NSEnumerator	*fromEnumerator, *toEnumerator, *logEnumerator;
    NSString		*fromName;
    AILogFromGroup      *fromGroup;
    AILogToGroup	*toGroup;
    AILog		*log;
    
    [indexingThreadLock lock];      //Prevent anything from closing until this thread is complete.
    suspendDirtyArraySave = YES;    //Prevent saving of the dirty array until we're finished building it
    
    //Create a fresh dirty log array
    [dirtyLogLock lock];
    [dirtyLogArray release]; dirtyLogArray = [[NSMutableArray alloc] init];
    [dirtyLogLock unlock];

    //Process each from folder
    fromEnumerator = [[[[NSFileManager defaultManager] directoryContentsAtPath:[AILoggerPlugin logBasePath]] objectEnumerator] retain];
    while((fromName = [[fromEnumerator nextObject] retain])){
	fromGroup = [[AILogFromGroup alloc] initWithPath:fromName from:fromName];

	//Walk through every 'to' group
	toEnumerator = [[[fromGroup toGroupArray] objectEnumerator] retain];
	while(!stopIndexingThreads && (toGroup = [[toEnumerator nextObject] retain])){
	    //Walk through every log
	    logEnumerator = [[toGroup logArray] objectEnumerator];
	    while((log = [logEnumerator nextObject]) && !stopIndexingThreads){
		//Add this log's path to our dirty array.  The dirty array is guared with a lock
		//since it will be access from outside this thread as well
		[dirtyLogLock lock];
		[dirtyLogArray addObject:[log path]];
		[dirtyLogLock unlock];
	    }
	    
	    //Flush our pool
	    [pool release]; pool = [[NSAutoreleasePool alloc] init];
	    
	    [toGroup release];
	}
	[toEnumerator release];
	
	[fromGroup release];
	[fromName release];
    }
    [fromEnumerator release];

    //Save the dirty array we just built
    if(!stopIndexingThreads){
	[self _saveDirtyLogArray];
	suspendDirtyArraySave = NO; //Re-allow saving of the dirty array
    }
    
    //Begin cleaning the logs (If the log viewer is open)
    if([AILogViewerWindowController existingWindowController]){
	[self cleanDirtyLogs];
    }
    
    [indexingThreadLock unlock];
    [pool release];
}

//THREAD: Index all dirty logs
- (void)cleanDirtyLogs
{
    //Reset the cleaning progress
    [dirtyLogLock lock];
    logsToIndex = [dirtyLogArray count];
    [dirtyLogLock unlock];
    logsIndexed = 0;

    [NSThread detachNewThreadSelector:@selector(_cleanDirtyLogsThread) toTarget:self withObject:nil];
}
- (void)_cleanDirtyLogsThread
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

    [indexingThreadLock lock];     //Prevent anything from closing until this thread is complete.

    //Start cleaning (If we're still supposed to go)
    if(!stopIndexingThreads){
	UInt32		lastUpdate = TickCount();
	int		unsavedChanges = 0;

	//Scan until we're done or told to stop
	while(!stopIndexingThreads){
	    NSString	*logPath = nil;
	    
	    //Get the next dirty log
	    [dirtyLogLock lock];
	    if([dirtyLogArray count]){
		logPath = [[[dirtyLogArray lastObject] retain] autorelease]; //retain to prevent deallocation when removing from the array
		[dirtyLogArray removeLastObject];
	    }
	    [dirtyLogLock unlock];
	    
	    if(logPath){
		NSString	    *fullPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:logPath];
		SKDocumentRef       document;
		    
		//Re-index the log
		//What we should do here is the following:
		//document = SKDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:logPath]);
		//SKIndexAddDocument(index_Content, document, NULL, YES);
		//
		//However, it seems that (10.3.1) SKDocumentCreateWithURL has a pretty serious memory leak.  It works just
		//as well to use SKDocumentCreate and set the document's name to the path, so we can do that as an alternative:
		document = SKDocumentCreate((CFStringRef)@"file", NULL, (CFStringRef)logPath);
		SKIndexAddDocumentWithText(index_Content, document, (CFStringRef)[NSString stringWithContentsOfFile:fullPath], YES);
		CFRelease(document);

		//Update our progress
		logsIndexed++;
		if(lastUpdate == 0 || TickCount() > lastUpdate + LOG_INDEX_STATUS_INTERVAL){
		    [[AILogViewerWindowController existingWindowController] performSelectorOnMainThread:@selector(updateProgressDisplay) withObject:nil waitUntilDone:NO];
		    lastUpdate = TickCount();
		}
		
		//Save the dirty array
		if(unsavedChanges++ > LOG_CLEAN_SAVE_INTERVAL){
		    [self _saveDirtyLogArray];
		    SKIndexFlush(index_Content);
		    unsavedChanges = 0;
		    
		    //Flush ram
		    [pool release]; pool = [[NSAutoreleasePool alloc] init];
		}
		
	    }else{
		break; //Exit when we run out of logs
	    }
	}
	
	//Save the slimmed down dirty log array
	[self _saveDirtyLogArray];
	SKIndexFlush(index_Content);
	
	//Update our progress
	logsToIndex = 0;
	[[AILogViewerWindowController existingWindowController] performSelectorOnMainThread:@selector(updateProgressDisplay) withObject:nil waitUntilDone:NO];
    }
    
    [indexingThreadLock unlock];
    [pool release];
}

@end


