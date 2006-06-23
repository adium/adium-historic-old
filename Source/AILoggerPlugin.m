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

#import "AIChatLog.h"
#import "AIContactController.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"
#import "AILogViewerWindowController.h"
#import "AIMDLogViewerWindowController.h"
#import "AIContentController.h"
#import "AILoggerPlugin.h"
#import "AILoginController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "AIToolbarController.h"
#import "AIXMLAppender.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/NSCalendarDate+ISO8601Unparsing.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>

#import "AILogFileUpgradeWindowController.h"

#import "AdiumSpotlightImporter.h"

#define LOG_INDEX_NAME				@"Logs.index"
#define DIRTY_LOG_ARRAY_NAME		@"DirtyLogs.plist"
#define KEY_LOG_INDEX_VERSION		@"Log Index Version"

#define LOG_INDEX_STATUS_INTERVAL	20      //Interval before updating the log indexing status
#define LOG_CLEAN_SAVE_INTERVAL		500     //Number of logs to index continuously before saving the dirty array and index

#define LOG_VIEWER					AILocalizedString(@"Previous Conversations Viewer",nil)
#define VIEW_LOGS_WITH_CONTACT		AILocalizedString(@"View Previous Conversations",nil)

#define	CURRENT_LOG_VERSION			4       //Version of the log index.  Increase this number to reset everyones index.

#define	LOG_VIEWER_IDENTIFIER		@"LogViewer"

#ifdef XML_LOGGING
#define XML_LOGGING_VERSION			@"0.4"
#define NEW_LOGFILE_TIMEOUT			600		//10 minutes
#endif

@interface AILoggerPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)configureMenuItems;
- (NSString *)stringForContentMessage:(AIContentMessage *)inContent;
- (NSString *)stringForContentStatus:(AIContentStatus *)inContent;
- (NSString  *)_writeMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(NSString *)object onDate:(NSDate *)date;
- (void)displayErrorAndDisableLogging;
- (SKIndexRef)createLogIndex;
- (void)closeLogIndex;
- (void)resetLogIndex;
- (NSString *)_logIndexPath;
- (void)loadDirtyLogArray;
- (void)_saveDirtyLogArray;
- (NSString *)_dirtyLogArrayPath;
- (void)_dirtyAllLogsThread;
- (void)_cleanDirtyLogsThread;

- (void)upgradeLogExtensions;

#ifdef XML_LOGGING
- (NSString *)keyForChat:(AIChat *)chat;
- (AIXMLAppender *)appenderForChat:(AIChat *)chat;
- (void)closeAppenderForChat:(AIChat *)chat;
#endif
@end

static NSString     *logBasePath = nil;     //The base directory of all logs
Class LogViewerWindowControllerClass = NULL;
@implementation AILoggerPlugin

//
- (void)installPlugin
{
	LogViewerWindowControllerClass = ([NSApp isOnTigerOrBetter] ?
									  [AIMDLogViewerWindowController class] :
									  [AILogViewerWindowController class]);

    //Init
	observingContent = NO;

	AIPreferenceController *preferenceController = [adium preferenceController];

	#ifdef XML_LOGGING
	activeAppenders = [[NSMutableDictionary alloc] init];
	activeTimers = [[NSMutableDictionary alloc] init];
	
	HTMLDecoder = [[AIHTMLDecoder alloc] initWithHeaders:NO
												 fontTags:YES
											closeFontTags:YES
												colorTags:YES
												styleTags:YES
										   encodeNonASCII:YES
											 encodeSpaces:NO
										attachmentsAsText:YES
								onlyIncludeOutgoingImages:NO
										   simpleTagsOnly:NO
										   bodyBackground:NO];
	
	#endif
	
	//Setup our preferences
	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:LOGGING_DEFAULT_PREFS 
	                              forClass:[self class]] 
	                              forGroup:PREF_GROUP_LOGGING];

	//Install the log viewer menu items
	[self configureMenuItems];
	
	//Create a logs directory
	logBasePath = [[[[[adium loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
	[[NSFileManager defaultManager] createDirectoriesForPath:logBasePath];

	//Observe preference changes
	AIPreferenceController *prefController = [adium preferenceController];
	[prefController addObserver:self
	                 forKeyPath:PREF_KEYPATH_LOGGER_ENABLE
	                    options:NSKeyValueObservingOptionNew
	                    context:NULL];
	[self observeValueForKeyPath:PREF_KEYPATH_LOGGER_ENABLE
	                    ofObject:prefController
	                      change:nil
	                     context:NULL];

	//Toolbar item
	NSToolbarItem	*toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:LOG_VIEWER_IDENTIFIER
														  label:AILocalizedString(@"Logs",nil)
	                                               paletteLabel:AILocalizedString(@"View Logs",nil)
	                                                    toolTip:AILocalizedString(@"View previous conversations with this contact or chat",nil)
	                                                     target:self
	                                            settingSelector:@selector(setImage:)
	                                                itemContent:[NSImage imageNamed:@"LogViewer" forClass:[self class]]
	                                                     action:@selector(showLogViewerToSelectedContact:)
	                                                       menu:nil];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];

	dirtyLogArray = nil;
	index_Content = nil;
	stopIndexingThreads = NO;
	suspendDirtyArraySave = NO;		
	indexingThreadLock = [[NSLock alloc] init];
	dirtyLogLock = [[NSLock alloc] init];
	logAccessLock = [[NSLock alloc] init];
	
	//Init index searching
	[self initLogIndexing];
	
	[self upgradeLogExtensions];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(showLogNotification:)
									   name:Adium_ShowLogAtPath
									 object:nil];
}

- (void)uninstallPlugin
{
	#ifdef XML_LOGGING
	[activeAppenders release];
	[activeTimers release];
	[HTMLDecoder release];
	#endif
	[[adium preferenceController] removeObserver:self forKeyPath:PREF_KEYPATH_LOGGER_ENABLE];
}

//Update for the new preferences
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	BOOL	newLogValue;
	logHTML = YES;

	//Start/Stop logging
	newLogValue = [[object valueForKeyPath:keyPath] boolValue];
	if (newLogValue != observingContent) {
		observingContent = newLogValue;
				
		if (!observingContent) { //Stop Logging
			[[adium notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];
			
			#ifdef XML_LOGGING
			[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:nil];			
			[[adium notificationCenter] removeObserver:self name:Chat_WillClose object:nil];			
			#endif

		} else { //Start Logging
			[[adium notificationCenter] addObserver:self 
										   selector:@selector(contentObjectAdded:) 
											   name:Content_ContentObjectAdded 
											 object:nil];
											 
			#ifdef XML_LOGGING
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatOpened:)
											   name:Chat_DidOpen
											 object:nil];
											 
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatClosed:)
											   name:Chat_WillClose
											 object:nil];
			#endif	

		}
	}
}


//Logging Paths --------------------------------------------------------------------------------------------------------
+ (NSString *)logBasePath
{
	return logBasePath;
}

//Returns the RELATIVE path to the folder where the log should be written
+ (NSString *)relativePathForLogWithObject:(NSString *)object onAccount:(AIAccount *)account
{	
	return [NSString stringWithFormat:@"%@.%@/%@", [account serviceID], [[account UID] safeFilenameString], object];
}

+ (NSString *)imagesPathForContentObject:(AIContentObject *)contentObject
{
	AIChat		*chat = [contentObject chat];
	NSString	*object = [chat name];
	if (!object) object = [[chat listObject] UID];

	//Get the log path and name
	object = [object safeFilenameString];
	
	NSString *relativePath = [AILoggerPlugin relativePathForLogWithObject:object onAccount:[chat account]];
	NSString *fullPath = [AILoggerPlugin fullPathOfLogAtRelativePath:relativePath];

	NSString	*dateString = [[contentObject date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];

	return ([fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@)", object, dateString]]);
}


#ifdef XML_LOGGING
+ (NSString *)fileNameForLogWithObject:(NSString *)object onDate:(NSDate *)date
{
	NSString    *dateString = [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil];
	return [NSString stringWithFormat:@"%@ (%@).chatlog", object, dateString];
}
#endif

//Returns the file name for the log (plaintext logging is deprecated)
+ (NSString *)fileNameForLogWithObject:(NSString *)object onDate:(NSDate *)date plainText:(BOOL)plainText
{
#ifdef XML_LOGGING
	return [self fileNameForLogWithObject:object onDate:date];
#else
	NSString	*dateString = [date descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
	NSString	*extension = (plainText ? @"adiumLog" : @"AdiumHTMLLog");
	
	return [NSString stringWithFormat:@"%@ (%@).%@", object, dateString, extension];
#endif
}

//Takes the RELATIVE path to a log, and returns a FULL path
+ (NSString *)fullPathOfLogAtRelativePath:(NSString *)relativePath
{
	return [[self logBasePath] stringByAppendingPathComponent:relativePath];
}


+ (NSString *)fullPathForLogOfChat:(AIChat *)chat onDate:(NSDate *)date
{
	NSString	*objectUID = [chat name];
	AIAccount	*account = [chat account];

	if (!objectUID) objectUID = [[chat listObject] UID];
	objectUID = [objectUID safeFilenameString];

#ifdef XML_LOGGING
	NSString	*fileName = [self fileNameForLogWithObject:objectUID onDate:date];
#else
	NSString	*fileName = [self fileNameForLogWithObject:objectUID onDate:date plainText:NO];
#endif
	NSString	*relativePath = [self relativePathForLogWithObject:objectUID onAccount:account];
	NSString	*absolutePath = [self fullPathOfLogAtRelativePath:relativePath];
	NSString	*fullPath = [absolutePath stringByAppendingPathComponent:fileName];

	return fullPath;
}

//Menu Items -----------------------------------------------------------------------------------------------------------
#pragma mark Menu Items
//Configure the log viewer menu items
- (void)configureMenuItems
{
    logViewerMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:LOG_VIEWER 
																			  target:self
																			  action:@selector(showLogViewer:)
																	   keyEquivalent:@"L"] autorelease];
    [[adium menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxiliary];

    viewContactLogsMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_LOGS_WITH_CONTACT
																					target:self
																					action:@selector(showLogViewerToSelectedContact:) 
																			 keyEquivalent:@"l"] autorelease];
    [[adium menuController] addMenuItem:viewContactLogsMenuItem toLocation:LOC_Contact_Info];

    viewContactLogsContextMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_LOGS_WITH_CONTACT
																						   target:self
																						   action:@selector(showLogViewerToSelectedContextContact:) 
																					keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:viewContactLogsContextMenuItem toLocation:Context_Contact_Manage];
}

//Enable/Disable our view log menus
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if (menuItem == viewContactLogsMenuItem) {
        AIListObject	*selectedObject = [[adium contactController] selectedListObject];
		return selectedObject && [selectedObject isKindOfClass:[AIListContact class]];

    } else if (menuItem == viewContactLogsContextMenuItem) {
        AIListObject	*selectedObject = [[adium menuController] currentContextMenuObject];		
		return selectedObject && [selectedObject isKindOfClass:[AIListContact class]];
		
    }
	
    return YES;
}

/*!
 * @brief Show the log viewer for no contact
 *
 * Invoked from the Window menu
 */
- (void)showLogViewer:(id)sender
{
    [LogViewerWindowControllerClass openForContact:nil  
										 plugin:self];	
}

/*!
 * @brief Show the log viewer, displaying only the selected contact's logs
 *
 * Invoked from the Contact menu
 */
- (void)showLogViewerToSelectedContact:(id)sender
{
    AIListObject   *selectedObject = [[adium contactController] selectedListObject];
    [LogViewerWindowControllerClass openForContact:([selectedObject isKindOfClass:[AIListContact class]] ?
												 (AIListContact *)selectedObject : 
												 nil)  
										 plugin:self];
}

- (void)showLogViewerForLogAtPath:(NSString *)inPath
{
	[LogViewerWindowControllerClass openLogAtPath:inPath plugin:self];
}

- (void)showLogNotification:(NSNotification *)inNotification
{
	[self showLogViewerForLogAtPath:[inNotification object]];
}

/*!
 * @brief Show the log viewer, displaying only the selected contact's logs
 *
 * Invoked from a contextual menu
 */
- (void)showLogViewerToSelectedContextContact:(id)sender
{
	AIListObject* object = [[adium menuController] currentContextMenuObject];
	if ([object isKindOfClass:[AIListContact class]]) {
		[NSApp activateIgnoringOtherApps:YES];
		[[[LogViewerWindowControllerClass openForContact:(AIListContact *)object plugin:self] window]
									 makeKeyAndOrderFront:nil];
	}
}


//Logging --------------------------------------------------------------------------------------------------------------
#pragma mark Logging
//Log any content that is sent or received
- (void)contentObjectAdded:(NSNotification *)notification
{
#ifdef XML_LOGGING	
	AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
	if ([content postProcessContent]) {
		AIChat				*chat = [notification object];

		//Don't log chats for temporary accounts
		if ([[chat account] isTemporary]) return;	
							
		AIXMLAppender *appender = [self appenderForChat:chat];
		
		if ([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
			[appender addElementWithName:@"message" 
								 content:[HTMLDecoder encodeHTML:[content message] imagesPath:nil]
						   attributeKeys:[NSArray arrayWithObjects:@"sender", @"time", nil]
						 attributeValues:[NSArray arrayWithObjects:[[content source] UID], [[NSCalendarDate date] ISO8601DateString], nil]];
		} else if ([[content type] isEqualToString:CONTENT_STATUS_TYPE]) {
			/*
			 * Oh. My. God. This is the ugliest thing I have ever seen in my life. Why do we have to do this?! We are
			 * notified of status changes by meta contact, not the actual contact. We have to search the chat for the
			 * acutal contact we're looking for. This makes me want to cry.
			 */
			AIListObject	*retardedMetaObject = [content source];
			AIListObject	*actualObject = nil;
			AIListContact	*participatingListObject = nil;
			
			NSEnumerator	*enumerator = [[chat participatingListObjects] objectEnumerator];
			
			while ((participatingListObject = [enumerator nextObject])) {
				if ([participatingListObject parentContact] == retardedMetaObject) {
					actualObject = participatingListObject;
					break;
				}
			}
			
			//If we can't find it for some reason, we probably shouldn't attempt logging.
			if (actualObject) {
				[appender addElementWithName:@"status"
									 content:[HTMLDecoder encodeHTML:[content message] imagesPath:nil]
							   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
							 attributeValues:[NSArray arrayWithObjects:
								 [(AIContentStatus *)content status], 
								 [actualObject UID], 
								 [[NSCalendarDate date] ISO8601DateString],
								 nil]];
			}
		}
	}
#else
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
	if ([content postProcessContent]) {
		AIChat				*chat = [notification object];

		//Don't log chats for temporary accounts
		if ([[chat account] isTemporary]) return;

		NSString			*logString = nil;

		//Generate a plaintext string for this content
		if ([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
			logString = [self stringForContentMessage:(AIContentMessage *)content];
		} else if ([[content type] isEqualToString:CONTENT_STATUS_TYPE]) {
			logString = [self stringForContentStatus:(AIContentStatus *)content];
		}

		//Log the string, and flag the log as dirty
		if (logString) {
			NSString	*relativePath;
			NSString	*objectUID = [chat name];
			if (!objectUID) objectUID = [[chat listObject] UID];

			relativePath = [self _writeMessage:logString
								betweenAccount:[chat account] 
									 andObject:objectUID
										onDate:[content date]];
			
			[self markLogDirtyAtPath:relativePath forChat:chat];
		}
	}
#endif
}

#ifdef XML_LOGGING
- (void)chatOpened:(NSNotification *)notification
{
	AIChat	*chat = [notification object];

	//Don't log chats for temporary accounts
	if ([[chat account] isTemporary]) return;
	
	AIXMLAppender *appender = [self appenderForChat:chat];

	[appender addElementWithName:@"event"
						 content:nil
				   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
				 attributeValues:[NSArray arrayWithObjects:@"windowOpened", [[chat account] UID], [[NSCalendarDate date] ISO8601DateString], nil]];

}

- (void)chatClosed:(NSNotification *)notification
{
	AIChat	*chat = [notification object];

	//Don't log chats for temporary accounts
	if ([[chat account] isTemporary]) return;

	AIXMLAppender *appender = [self appenderForChat:chat];

	[appender addElementWithName:@"event"
						 content:nil
				   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
				 attributeValues:[NSArray arrayWithObjects:@"windowClosed", [[chat account] UID], [[NSCalendarDate date] ISO8601DateString], nil]];

	[self closeAppenderForChat:chat];
}

- (NSString *)keyForChat:(AIChat *)chat
{
	AIAccount *account = [chat account];
	NSString *chatID = [chat isGroupChat] ? [chat name] : [[chat listObject] UID];
	
	return [NSString stringWithFormat:@"%@.%@-%@", [account serviceID], [account UID], chatID];
}

- (AIXMLAppender *)appenderForChat:(AIChat *)chat
{
	//Look up the key for this chat and use it to try to retrieve the appender
	NSString *chatKey = [self keyForChat:chat];
	AIXMLAppender *appender = [activeAppenders objectForKey:chatKey];
	
	//If there's already an appender for this chat, we need to invalidate the timer to close it, since we're using it now
	if (appender) {
		[[activeTimers objectForKey:chatKey] invalidate];
		[activeTimers removeObjectForKey:chatKey];
	//Otherwise, create a new appender and add it to the dictionary
	} else {
		NSDate		*date = [chat dateOpened];
		NSString	*fullPath = [AILoggerPlugin fullPathForLogOfChat:chat onDate:date];

		appender = [AIXMLAppender documentWithPath:fullPath];
		[appender initializeDocumentWithRootElementName:@"chat"
										  attributeKeys:[NSArray arrayWithObjects:@"account", @"service", @"version", nil]
										attributeValues:[NSArray arrayWithObjects:
											[[chat account] UID],
											[[chat account] serviceID],
											XML_LOGGING_VERSION,
											nil]];
		[activeAppenders setObject:appender forKey:chatKey];
	}
	
	return appender;
}

- (void)closeAppenderForChat:(AIChat *)chat
{
	//Create a new timer to fire after the timeout period, which will close the appender
	NSString *chatKey = [self keyForChat:chat];
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:NEW_LOGFILE_TIMEOUT 
													  target:self 
													selector:@selector(finishClosingAppender:) 
													userInfo:chatKey
													 repeats:NO];
	//Add it to the activeTimers dictionary
	[activeTimers setObject:timer forKey:chatKey];
}

- (void)finishClosingAppender:(NSTimer *)timer
{
	//Remove the appender, closing its file descriptor upon dealloc
	[activeAppenders removeObjectForKey:[timer userInfo]];
	//Remove the timer, it's invalid anyway and not very useful
	[activeTimers removeObjectForKey:[timer userInfo]];
}

#endif

//Generate a plain-text string representing a content message
#define AUTOREPLY AILocalizedString(@" (Autoreply)",nil)
- (NSString *)stringForContentMessage:(AIContentMessage *)content
{
	NSString		*date = [[content date] descriptionWithCalendarFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:YES
																													 showingAMorPM:YES]
																 timeZone:nil
																   locale:nil];
	NSAttributedString      *message = [content message];
	AIListObject			*source = [content source];
	NSString				*logString = nil;

	if (date && message && source) {
		if (logHTML) {
			logString = [NSString stringWithFormat:@"<div class=\"%@\"><span class=\"timestamp\">%@</span> <span class=\"sender\">%@%@: </span><pre class=\"message\">%@</pre></div>\n",
				([content isOutgoing] ? @"send" : @"receive"), 
				date,
				[source UID], 
				([content isAutoreply] ? AUTOREPLY : @""),
				[AIHTMLDecoder encodeHTML:message
								  headers:NO 
								 fontTags:NO 
					   includingColorTags:NO
							closeFontTags:NO 
								styleTags:YES
			   closeStyleTagsOnFontChange:YES
						   encodeNonASCII:YES
							 encodeSpaces:NO
							   imagesPath:[AILoggerPlugin imagesPathForContentObject:content]
						attachmentsAsText:NO 
				onlyIncludeOutgoingImages:YES 
						   simpleTagsOnly:NO
						   bodyBackground:NO]];
		} else {
			logString = [NSString stringWithFormat:@"(%@) %@%@: %@\n",
				date,
				[source UID],
				([content isAutoreply] ? AUTOREPLY : @""),
				[message string]];
		}
	}

	return logString;
}

//Generate a plain-text string representing a status message
- (NSString *)stringForContentStatus:(AIContentStatus *)content
{
	NSString		*date = [[content date] descriptionWithCalendarFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:YES
																													 showingAMorPM:YES]
																 timeZone:nil
																   locale:nil];
	NSString		*message = [[content message] string];
	NSString		*logString = nil;

	if (date && message) {
		if (logHTML) {
			logString = [NSString stringWithFormat:@"<div class=\"status\">%@ (%@)</div>\n", message, date];
		} else {
			logString = [NSString stringWithFormat:@"<%@ (%@)>\n", message, date];
		}
	}

	return logString;
}

//Write a plain-text string to the correct log file.  Returns a RELATIVE path to the log.
- (NSString  *)_writeMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(NSString *)object onDate:(NSDate *)date
{
    NSString	*relativePath;
    NSString    *fullPath;
    NSString	*fileName;
    FILE		*file;

	//Get the log path and name
	object = [object safeFilenameString];

	fileName = [AILoggerPlugin fileNameForLogWithObject:object onDate:date plainText:!logHTML];
	relativePath = [AILoggerPlugin relativePathForLogWithObject:object onAccount:account];
	fullPath = [AILoggerPlugin fullPathOfLogAtRelativePath:relativePath];

    //Create a directory for this log (if one doesn't exist)
    [[NSFileManager defaultManager] createDirectoriesForPath:fullPath];

    //Append the new content (We use fopen/fputs/fclose for max speed)
    file = fopen([[fullPath stringByAppendingPathComponent:fileName] fileSystemRepresentation], "a");
	if (file) {
		if (ftell(file) == 0) {
			//If we just created a new file, insert the UTF8 bom identifier so it will open properly
			const unichar bom = 0xFEFF;
			NSString *bomString = [[NSString alloc] initWithCharacters:&bom length:1];
			fputs([bomString UTF8String], file);
			[bomString release];
		}
		fputs([message UTF8String], file);
		fclose(file);

	} else {
		[self displayErrorAndDisableLogging];
	}

	//Return a RELATIVE path to the log
    return [relativePath stringByAppendingPathComponent:fileName];
}

//Display a warning to the user that logging failed, and disable logging to prevent additional warnings
- (void)displayErrorAndDisableLogging
{
	NSRunAlertPanel(AILocalizedString(@"Unable to write log", nil),
					[NSString stringWithFormat:
						AILocalizedString(@"Adium was unable to write the log file for this conversation. Please ensure you have appropriate file permissions to write to your log directory (%@) for and then re-enable logging in the General preferences.", nil), logBasePath],
					AILocalizedString(@"OK", nil), nil, nil);

	//Disable logging
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
}


#pragma mark Upgrade code
- (void)upgradeLogExtensions
{
	if (![[[adium preferenceController] preferenceForKey:@"Log Extensions Updated" group:PREF_GROUP_LOGGING] boolValue]) {
		/* This could all be a simple NSDirectEnumerator call on basePath, but we wouldn't be able to show progress,
		* and this could take a bit.
		*/
		NSString		*accountBasePath = [AILoggerPlugin logBasePath];
		NSFileManager	*defaultManager = [NSFileManager defaultManager];
		NSArray			*accountFolders = [defaultManager directoryContentsAtPath:accountBasePath];
		NSEnumerator	*accountFolderEnumerator = [accountFolders objectEnumerator];
		NSString		*accountFolderName;
		
		NSMutableSet	*logBasePaths = [NSMutableSet set];
		while ((accountFolderName = [accountFolderEnumerator nextObject])) {
			NSString		*contactBasePath = [accountBasePath stringByAppendingPathComponent:accountFolderName];
			NSArray			*contactFolders = [defaultManager directoryContentsAtPath:contactBasePath];
			
			NSEnumerator	*contactFolderEnumerator = [contactFolders objectEnumerator];
			NSString		*contactFolderName;
			
			while ((contactFolderName = [contactFolderEnumerator nextObject])) {
				NSString			  *logBasePath = [contactBasePath stringByAppendingPathComponent:contactFolderName];
				[logBasePaths addObject:logBasePath];
			}
		}
		
		unsigned		contactsToProcess = [logBasePaths count];
		unsigned		processed = 0;
		
		if (contactsToProcess) {
			AILogFileUpgradeWindowController *upgradeWindowController;
			
			upgradeWindowController = [[AILogFileUpgradeWindowController alloc] initWithWindowNibName:@"LogFileUpgrade"];
			[[upgradeWindowController window] makeKeyAndOrderFront:nil];

			NSEnumerator	*logBasePathEnumerator = [logBasePaths objectEnumerator];
			NSString		*logBasePath;
			while ((logBasePath = [logBasePathEnumerator nextObject])) {
				NSDirectoryEnumerator *enumerator = [defaultManager enumeratorAtPath:logBasePath];
				NSString	*file;
				
				while ((file = [enumerator nextObject])) {
					if (([[file pathExtension] isEqualToString:@"html"]) ||
						([[file pathExtension] isEqualToString:@"adiumLog"]) ||
						(([[file pathExtension] isEqualToString:@"bak"]) && ([file hasSuffix:@".html.bak"] || 
																			 [file hasSuffix:@".adiumLog.bak"]))) {
						NSString *fullFile = [logBasePath stringByAppendingPathComponent:file];
						NSString *newFile = [[fullFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"AdiumHTMLLog"];
						
						[defaultManager movePath:fullFile
										  toPath:newFile
										 handler:self];
					}
				}
				
				processed++;
				[upgradeWindowController setProgress:(processed*100.0)/contactsToProcess];
				NSLog(@"%f%% complete...", ((processed*100.0)/contactsToProcess));
			}
			
			[upgradeWindowController close];
			[upgradeWindowController release];
		}
		
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:@"Log Extensions Updated"
											  group:PREF_GROUP_LOGGING];
	}
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo
{
	NSLog(@"Error: %@",errorInfo);
	
	return NO;
}

//Log Indexing ---------------------------------------------------------------------------------------------------------
#pragma mark Log Indexing
/***** Everything below this point is related to log index generation and access ****/

/* For the log content searching, we are required to re-index a log whenever it changes.  The solution below to
 * this problem is along the lines of:
 *		- Keep an array of logs that need to be re-indexed
 *		- Whenever a log is changed, add it to this array
 *		- When the log viewer is opened, re-index all the logs in the array
 */

/*
 * @brief Initialize log indexing
 */
- (void)initLogIndexing
{
	//Load the list of logs that need re-indexing
	[self loadDirtyLogArray];
}

/*
 * @brief Prepare the log index for searching.
 *
 * Must call before attempting to use the logSearchIndex.
 */
- (void)prepareLogContentSearching
{
    /* Load the index and start indexing to make it current
	 * If we're going to need to re-index all our logs from scratch, it will make
	 * things faster if we start with a fresh log index as well.
	 */
	if (!dirtyLogArray) {
		[self resetLogIndex];
	}
	
	stopIndexingThreads = NO;
	if (!dirtyLogArray) {
		[self dirtyAllLogs];
	} else {
		[self cleanDirtyLogs];
	}
}

//Close down and clean up the log index  (Call when finished using the logSearchIndex)
- (void)cleanUpLogContentSearching
{
	[self stopIndexingThreads];
	[self closeLogIndex];
}

//Returns the Search Kit index for log content searching
- (SKIndexRef)logContentIndex
{
	SKIndexRef	returnIndex;

	[logAccessLock lock];
	if (!index_Content) index_Content = [self createLogIndex];
	returnIndex = (SKIndexRef)[[(NSObject *)index_Content retain] autorelease];
	[logAccessLock unlock];

	return returnIndex;
}

//Mark a log as needing a re-index
- (void)markLogDirtyAtPath:(NSString *)path forChat:(AIChat *)chat
{
	NSString    *dirtyKey = [@"LogIsDirty_" stringByAppendingString:path];
	
	if (dirtyLogArray && ![chat integerStatusObjectForKey:dirtyKey]) {
		//Add to dirty array (Lock to ensure that no one changes its content while we are)
		[dirtyLogLock lock];
		if (path != nil) {
			[dirtyLogArray addObject:path];
		}
		[dirtyLogLock unlock];
		
		//Save the dirty array immedientally
		[self _saveDirtyLogArray];
		
		//Flag the chat with 'LogIsDirty' for this filename.  On the next message we can quickly check this flag.
		[chat setStatusObject:[NSNumber numberWithBool:YES]
					   forKey:dirtyKey
					   notify:NotifyNever];
	}	
}

//Get the current status of indexing.  Returns NO is indexing is not occuring
- (BOOL)getIndexingProgress:(int *)complete outOf:(int *)total
{
	*complete = logsIndexed;
	*total = logsToIndex;
	return logsToIndex != 0;
}


//Log index ------------------------------------------------------------------------------------------------------------
//Search kit index used to searching log content
#pragma mark Log Index
/*
 * @brief Create the log index
 *
 * Should be called within logAccessLock being locked
 */
- (SKIndexRef)createLogIndex
{
    NSString    *logIndexPath = [self _logIndexPath];
    NSURL       *logIndexPathURL = [NSURL fileURLWithPath:logIndexPath];
	SKIndexRef	newIndex = NULL;

    if ([[NSFileManager defaultManager] fileExistsAtPath:logIndexPath]) {
		newIndex = SKIndexOpenWithURL((CFURLRef)logIndexPathURL, (CFStringRef)@"Content", true);
    }
    if (!newIndex) {
		NSDictionary *textAnalysisProperties = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:0], kSKMaximumTerms,
			kCFBooleanTrue, kSKProximityIndexing, 
			nil];

		//Create the index if one doesn't exist
		[[NSFileManager defaultManager] createDirectoriesForPath:[logIndexPath stringByDeletingLastPathComponent]];
		
		newIndex = SKIndexCreateWithURL((CFURLRef)logIndexPathURL,
										(CFStringRef)@"Content", 
										kSKIndexInverted,
										(CFDictionaryRef)textAnalysisProperties);
    }
	
	return newIndex;
}

//Close the log index
- (void)closeLogIndex
{
	[logAccessLock lock];
    if (index_Content) CFRelease(index_Content);
    index_Content = nil;
	[logAccessLock unlock];
}

//Delete the log index
- (void)resetLogIndex
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self _logIndexPath]]) {
		[[NSFileManager defaultManager] trashFileAtPath:[self _logIndexPath]];
	}	

	if ([[NSFileManager defaultManager] fileExistsAtPath:[self _dirtyLogArrayPath]]) {
		[[NSFileManager defaultManager] trashFileAtPath:[self _dirtyLogArrayPath]];
	}
}

//Path of log index file
- (NSString *)_logIndexPath
{
    return [[adium cachesPath] stringByAppendingPathComponent:LOG_INDEX_NAME];
}


//Dirty Log Array ------------------------------------------------------------------------------------------------------
//Stores the relative paths of logs that need to be re-indexed
#pragma mark Dirty Log Array
//Load the dirty log array
- (void)loadDirtyLogArray
{
	if (!dirtyLogArray) {
		int logVersion = [[[adium preferenceController] preferenceForKey:KEY_LOG_INDEX_VERSION
																   group:PREF_GROUP_LOGGING] intValue];

		//If the log version has changed, we reset the index and don't load the dirty array (So all the logs are marked dirty)
		if (logVersion >= CURRENT_LOG_VERSION) {
			dirtyLogArray = [[NSArray arrayWithContentsOfFile:[self _dirtyLogArrayPath]] mutableCopy];
		} else {
			[self resetLogIndex];
			[[adium preferenceController] setPreference:[NSNumber numberWithInt:CURRENT_LOG_VERSION]
                                                             forKey:KEY_LOG_INDEX_VERSION
                                                              group:PREF_GROUP_LOGGING];
		}
	}
}

//Save the dirty lod array
- (void)_saveDirtyLogArray
{
    if (dirtyLogArray && !suspendDirtyArraySave) {
		[dirtyLogLock lock];
		[dirtyLogArray writeToFile:[self _dirtyLogArrayPath] atomically:NO];
		[dirtyLogLock unlock];
    }
}

//Path of the dirty log array file
- (NSString *)_dirtyLogArrayPath
{
    return [[adium cachesPath] stringByAppendingPathComponent:DIRTY_LOG_ARRAY_NAME];
}


//Threaded Indexing ----------------------------------------------------------------------------------------------------
#pragma mark Threaded Indexing
//Stop any indexing related threads
- (void)stopIndexingThreads
{
    //Let any indexing threads know it's time to stop, and wait for them to finish.
    stopIndexingThreads = YES;
}

//The following methods will be run in a separate thread to avoid blocking the interface during index operations
//THREAD: Flag every log as dirty (Do this when there is no log index)
- (void)dirtyAllLogs
{
    //Reset and rebuild the dirty array
    [dirtyLogArray release]; dirtyLogArray = [[NSMutableArray alloc] init];
	//[self _dirtyAllLogsThread];
	[NSThread detachNewThreadSelector:@selector(_dirtyAllLogsThread) toTarget:self withObject:nil];
}
- (void)_dirtyAllLogsThread
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    NSEnumerator		*fromEnumerator, *toEnumerator, *logEnumerator;
    NSString			*fromName;
    AILogFromGroup		*fromGroup = nil;
    AILogToGroup		*toGroup;
    AIChatLog			*theLog;    

    [indexingThreadLock lock];      //Prevent anything from closing until this thread is complete.
    suspendDirtyArraySave = YES;    //Prevent saving of the dirty array until we're finished building it
    
    //Create a fresh dirty log array
    [dirtyLogLock lock];
    [dirtyLogArray release]; dirtyLogArray = [[NSMutableArray alloc] init];
    [dirtyLogLock unlock];
	
    //Process each from folder
    fromEnumerator = [[[[NSFileManager defaultManager] directoryContentsAtPath:[AILoggerPlugin logBasePath]] objectEnumerator] retain];
    while ((fromName = [[fromEnumerator nextObject] retain])) {
		fromGroup = [[AILogFromGroup alloc] initWithPath:fromName fromUID:fromName serviceClass:nil];

		//Walk through every 'to' group
		toEnumerator = [[[fromGroup toGroupArray] objectEnumerator] retain];
		while (!stopIndexingThreads && (toGroup = [[toEnumerator nextObject] retain])) {
			//Walk through every log
			logEnumerator = [toGroup logEnumerator];
			while ((theLog = [logEnumerator nextObject]) && !stopIndexingThreads) {
				//Add this log's path to our dirty array.  The dirty array is guarded with a lock
				//since it will be accessed from outside this thread as well
				[dirtyLogLock lock];
				if (theLog != nil) {
					[dirtyLogArray addObject:[theLog path]];
				}
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
    if (!stopIndexingThreads) {
		[self _saveDirtyLogArray];
		suspendDirtyArraySave = NO; //Re-allow saving of the dirty array
    }
    
    //Begin cleaning the logs (If the log viewer is open)
    if ([LogViewerWindowControllerClass existingWindowController]) {
		[self cleanDirtyLogs];
    }
    
    [indexingThreadLock unlock];
    [pool release];
}

/*
 * @brief Index all dirty logs
 *
 * Indexing will occur on a thread
 */
- (void)cleanDirtyLogs
{
    //Reset the cleaning progress
    [dirtyLogLock lock];
    logsToIndex = [dirtyLogArray count];
    [dirtyLogLock unlock];
    logsIndexed = 0;

	[NSThread detachNewThreadSelector:@selector(_cleanDirtyLogsThread:) toTarget:self withObject:(id)[self logContentIndex]];
}
- (void)_cleanDirtyLogsThread:(SKIndexRef)searchIndex
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

	//Ensure log indexing (in an old thread) isn't already going on and just waiting to stop
	[indexingThreadLock lock]; [indexingThreadLock unlock];
	
    [indexingThreadLock lock];     //Prevent anything from closing until this thread is complete.

    //Start cleaning (If we're still supposed to go)
    if (!stopIndexingThreads) {
		UInt32	lastUpdate = TickCount();
		int		unsavedChanges = 0;

		//Scan until we're done or told to stop
		while (!stopIndexingThreads) {
			NSString	*logPath = nil;
			
			//Get the next dirty log
			[dirtyLogLock lock];
			if ([dirtyLogArray count]) {
				logPath = [[[dirtyLogArray lastObject] retain] autorelease]; //retain to prevent deallocation when removing from the array
				[dirtyLogArray removeLastObject];
			}
			[dirtyLogLock unlock];

			if (logPath) {
				SKDocumentRef   document;
				
				//Re-index the log
				NSString            *fullPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:logPath];

				document = SKDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:fullPath]);
				if (document) {
					/* We _could_ use SKIndexAddDocument() and depend on our Spotlight plugin for importing.
					 * However, this has three problems:
					 *	1. Slower, especially to start initial indexing, which is the most common use case since the log viewer
					 *	   indexes recently-modified ("dirty") logs when it opens.
					 *  2. Sometimes logs don't appear to be associated with the right URI type and therefore don't get indexed.
					 *  3. On 10.3, this means that logs' markup is indexed in addition to their text, which is undesireable.
					 */
					CFStringRef documentText = CopyTextContentForFile(NULL, (CFStringRef)fullPath);
					if (documentText) {
						SKIndexAddDocumentWithText(searchIndex,
												   document,
												   documentText,
												   YES);
						CFRelease(documentText);
					}
					CFRelease(document);
				} else {
					NSLog(@"Could not create document for %@ [%@]",fullPath,[NSURL fileURLWithPath:fullPath]);
				}
				
				//Update our progress
				logsIndexed++;
				if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_INDEX_STATUS_INTERVAL) {
					[[LogViewerWindowControllerClass existingWindowController]
                                            performSelectorOnMainThread:@selector(logIndexingProgressUpdate) 
                                                             withObject:nil
                                                          waitUntilDone:NO];
					lastUpdate = TickCount();
				}
				
				//Save the dirty array
				if (unsavedChanges++ > LOG_CLEAN_SAVE_INTERVAL) {
					[self _saveDirtyLogArray];

					unsavedChanges = 0;

					//Flush ram
					[pool release]; pool = [[NSAutoreleasePool alloc] init];
				}
				
			} else {
				break; //Exit when we run out of logs
			}
		}
		
		//Save the slimmed down dirty log array
		if (unsavedChanges) {
			[self _saveDirtyLogArray];
		}

		//Update our progress
		if (!stopIndexingThreads) {
			logsToIndex = 0;
			[[LogViewerWindowControllerClass existingWindowController] performSelectorOnMainThread:@selector(logIndexingProgressUpdate) 
																						withObject:nil
																					 waitUntilDone:NO];
		}
    }

	[indexingThreadLock unlock];

    [pool release];
}

- (NSLock *)logAccessLock
{
	return logAccessLock;
}

@end


