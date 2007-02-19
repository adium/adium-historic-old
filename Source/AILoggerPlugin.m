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

#import "AILoggerPlugin.h"
#import "AIChatLog.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"
#import "AILogViewerWindowController.h"
#import "AIMDLogViewerWindowController.h"
#import "AIXMLAppender.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
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
#import <AIUtilities/NSCalendarDate+ISO8601Parsing.h>

#import "AILogFileUpgradeWindowController.h"

#import "AdiumSpotlightImporter.h"

#define LOG_INDEX_NAME				@"Logs.index"
#define DIRTY_LOG_ARRAY_NAME		@"DirtyLogs.plist"
#define KEY_LOG_INDEX_VERSION		@"Log Index Version"

#define LOG_INDEX_STATUS_INTERVAL	20      //Interval before updating the log indexing status
#define LOG_CLEAN_SAVE_INTERVAL		500     //Number of logs to index continuously before saving the dirty array and index

#define LOG_VIEWER					AILocalizedString(@"Chat Transcripts Viewer",nil)
#define VIEW_LOGS_WITH_CONTACT		AILocalizedString(@"View Chat Transcripts",nil)

#define	CURRENT_LOG_VERSION			8       //Version of the log index.  Increase this number to reset everyone's index.

#define	LOG_VIEWER_IDENTIFIER		@"LogViewer"

#define XML_LOGGING_NAMESPACE		@"http://purl.org/net/ulf/ns/0.4-02"
#define NEW_LOGFILE_TIMEOUT			600		//10 minutes

#define ENABLE_PROXIMITY_SEARCH		FALSE

@interface AILoggerPlugin (PRIVATE)
- (void)configureMenuItems;
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

- (NSString *)keyForChat:(AIChat *)chat;
- (AIXMLAppender *)existingAppenderForChat:(AIChat *)chat;
- (AIXMLAppender *)appenderForChat:(AIChat *)chat;
- (void)finishClosingAppender:(NSString *)chatKey;
- (void)closeAppenderForChat:(AIChat *)chat;
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

	activeAppenders = [[NSMutableDictionary alloc] init];
	
	xhtmlDecoder = [[AIHTMLDecoder alloc] initWithHeaders:NO
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
	[xhtmlDecoder setGeneratesStrictXHTML:YES];
	[xhtmlDecoder setUsesAttachmentTextEquivalents:YES];
	
	statusTranslation = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"away",@"away",
		@"online",@"return_away",
		@"online",@"online",
		@"offline",@"offline",
		@"idle",@"idle",
		@"available",@"return_idle",
		@"away",@"away_message",
		nil];

	//Setup our preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LOGGING_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_LOGGING];

	//Install the log viewer menu items
	[self configureMenuItems];
	
	//Create a logs directory
	logBasePath = [[[[[adium loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
	[[NSFileManager defaultManager] createDirectoriesForPath:logBasePath];

	//Observe preference changes
	[[adium preferenceController] addObserver:self
								   forKeyPath:PREF_KEYPATH_LOGGER_ENABLE
									  options:NSKeyValueObservingOptionNew
									  context:NULL];
	[self observeValueForKeyPath:PREF_KEYPATH_LOGGER_ENABLE
	                    ofObject:[adium preferenceController]
	                      change:nil
	                     context:NULL];

	//Toolbar item
	NSToolbarItem	*toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:LOG_VIEWER_IDENTIFIER
														  label:AILocalizedString(@"Transcripts",nil)
	                                               paletteLabel:AILocalizedString(@"View Chat Transcripts",nil)
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
	[[adium notificationCenter] addObserver:self
								   selector:@selector(chatWillDelete:)
									   name:ChatLog_WillDelete
									 object:nil];				
}

- (void)uninstallPlugin
{
	[activeAppenders release]; activeAppenders = nil;
	[xhtmlDecoder release]; xhtmlDecoder = nil;
	[statusTranslation release]; statusTranslation = nil;

	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	[[adium notificationCenter] removeObserver:self];
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
			
			[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:nil];			
			[[adium notificationCenter] removeObserver:self name:Chat_WillClose object:nil];

		} else { //Start Logging
			[[adium notificationCenter] addObserver:self 
										   selector:@selector(contentObjectAdded:) 
											   name:Content_ContentObjectAdded 
											 object:nil];
											 
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatOpened:)
											   name:Chat_DidOpen
											 object:nil];
											 
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatClosed:)
											   name:Chat_WillClose
											 object:nil];
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

+ (NSString *)fileNameForLogWithObject:(NSString *)object onDate:(NSDate *)date
{
	NSParameterAssert(date != nil);
	NSParameterAssert(object != nil);
	NSString    *dateString = [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil];
	
	NSAssert2(dateString != nil, @"Date string was invalid for the chatlog for %@ on %@", object, date);
		
	return [NSString stringWithFormat:@"%@ (%@).chatlog", object, dateString];
}

+ (NSString *)fullPathForLogOfChat:(AIChat *)chat onDate:(NSDate *)date
{
	NSString	*objectUID = [chat name];
	AIAccount	*account = [chat account];

	if (!objectUID) objectUID = [[chat listObject] UID];
	objectUID = [objectUID safeFilenameString];

	NSString	*fileName = [self fileNameForLogWithObject:objectUID onDate:date];
	NSString	*absolutePath = [logBasePath stringByAppendingPathComponent:[self relativePathForLogWithObject:objectUID onAccount:account]];
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
        AIListObject	*selectedObject = [[adium interfaceController] selectedListObject];
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
    AIListObject   *selectedObject = [[adium interfaceController] selectedListObject];
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
	AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
	if ([content postProcessContent]) {
		AIChat				*chat = [notification object];

		//Don't log chats for temporary accounts
		if ([[chat account] isTemporary]) return;	
		
		BOOL			dirty = NO;
		NSString		*contentType = [content type];
		NSString		*date = [[[content date] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString];

		if ([contentType isEqualToString:CONTENT_MESSAGE_TYPE]) {
			NSMutableArray *attributeKeys = [NSMutableArray arrayWithObjects:@"sender", @"time", nil];
			NSMutableArray *attributeValues = [NSMutableArray arrayWithObjects:[[content source] UID], date, nil];
			
			if([content isAutoreply])
			{
				[attributeKeys addObject:@"auto"];
				[attributeValues addObject:@"true"];
			}
			
			[[self appenderForChat:chat] addElementWithName:@"message" 
						  escapedContent:[xhtmlDecoder encodeHTML:[content message] imagesPath:nil]
						   attributeKeys:attributeKeys
						 attributeValues:attributeValues];
			dirty = YES;
		} else {
			//XXX: Yucky hack. This is here because we get status and event updates for metas, not for individual contacts. Or something like that.
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
				if ([contentType isEqualToString:CONTENT_STATUS_TYPE]) {
					NSString *translatedStatus = [statusTranslation objectForKey:[(AIContentStatus *)content status]];
					if(translatedStatus == nil)
						AILog(@"AILogger: Don't know how to translate status: %@", [(AIContentStatus *)content status]);
					else {
						[[self appenderForChat:chat] addElementWithName:@"status"
									  escapedContent:([(AIContentStatus *)content loggedMessage] ? [xhtmlDecoder encodeHTML:[(AIContentStatus *)content loggedMessage] imagesPath:nil] : nil)
									   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
									 attributeValues:[NSArray arrayWithObjects:
										 translatedStatus, 
										 [actualObject UID], 
										 date,
										 nil]];
						dirty = YES;
					}

				} else if ([contentType isEqualToString:CONTENT_EVENT_TYPE]) {
					[[self appenderForChat:chat] addElementWithName:@"event"
								  escapedContent:[xhtmlDecoder encodeHTML:[content message] imagesPath:nil]
								   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
								 attributeValues:[NSArray arrayWithObjects:[(AIContentEvent *)content eventType], [[content source] UID], date, nil]];
					dirty = YES;
				}
			}
		}
		//Don't create a new one if not needed
		AIXMLAppender *appender = [self existingAppenderForChat:chat];
		if (dirty && appender)
			[self markLogDirtyAtPath:[appender path] forChat:chat];
	}
}

- (void)chatOpened:(NSNotification *)notification
{
	AIChat	*chat = [notification object];

	//Don't log chats for temporary accounts
	if ([[chat account] isTemporary]) return;	
}

- (void)chatClosed:(NSNotification *)notification
{
	AIChat	*chat = [notification object];

	//Don't log chats for temporary accounts
	if ([[chat account] isTemporary]) return;
	
	//Use this method so we don't create a new appender for chat close events
	AIXMLAppender *appender = [self existingAppenderForChat:chat];
	
	//If there is an appender, add the windowClose event
	if (appender) {
		[appender addElementWithName:@"event"
							 content:nil
					   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
					 attributeValues:[NSArray arrayWithObjects:@"windowClosed", [[chat account] UID], [[[chat dateOpened] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString], nil]];

		[self closeAppenderForChat:chat];

		[self markLogDirtyAtPath:[appender path] forChat:chat];
	}
}

//Ugly method. Shouldn't this notification post an AIChat, not an AIChatLog?
- (void)chatWillDelete:(NSNotification *)notification
{
	AIChatLog *chatLog = [notification object];
	NSString *chatID = [NSString stringWithFormat:@"%@.%@-%@", [chatLog serviceClass], [chatLog from], [chatLog to]];
	AIXMLAppender *appender = [activeAppenders objectForKey:chatID];
	
	if (appender) {
		if ([[appender path] hasSuffix:[chatLog path]]) {
			[NSObject cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(finishClosingAppender:) 
													   object:chatID];
			[self finishClosingAppender:chatID];
		}
	}
}

- (NSString *)keyForChat:(AIChat *)chat
{
	AIAccount *account = [chat account];
	NSString *chatID = [chat isGroupChat] ? [chat name] : [[chat listObject] UID];
	
	return [NSString stringWithFormat:@"%@.%@-%@", [account serviceID], [account UID], chatID];
}

- (AIXMLAppender *)existingAppenderForChat:(AIChat *)chat
{
	//Look up the key for this chat and use it to try to retrieve the appender
	return [activeAppenders objectForKey:[self keyForChat:chat]];	
}

- (AIXMLAppender *)appenderForChat:(AIChat *)chat
{
	//Check if there is already an appender for this chat
	AIXMLAppender	*appender = [self existingAppenderForChat:chat];

	if (appender) {
		//Ensure a timeout isn't set for closing the appender, since we're now using it
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(finishClosingAppender:) 
												   object:[self keyForChat:chat]];
	} else {
		//If there isn't already an appender, create a new one and add it to the dictionary
		NSDate			*chatDate = [chat dateOpened];
		NSString		*fullPath = [AILoggerPlugin fullPathForLogOfChat:chat onDate:chatDate];

		appender = [AIXMLAppender documentWithPath:fullPath];
		[appender initializeDocumentWithRootElementName:@"chat"
										  attributeKeys:[NSArray arrayWithObjects:@"xmlns", @"account", @"service", nil]
										attributeValues:[NSArray arrayWithObjects:
											XML_LOGGING_NAMESPACE,
											[[chat account] UID],
											[[chat account] serviceID],
											nil]];
		
		//Add the window opened event now
		[appender addElementWithName:@"event"
					 content:nil
			   attributeKeys:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
			 attributeValues:[NSArray arrayWithObjects:@"windowOpened", [[chat account] UID], [[chatDate dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString], nil]];

		[activeAppenders setObject:appender forKey:[self keyForChat:chat]];
		
		[self markLogDirtyAtPath:[appender path] forChat:chat];
	}
	
	return appender;
}

- (void)closeAppenderForChat:(AIChat *)chat
{
	//Create a new timer to fire after the timeout period, which will close the appender
	NSString *chatKey = [self keyForChat:chat];
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(finishClosingAppender:) 
											   object:chatKey];
	[self performSelector:@selector(finishClosingAppender:) 
			   withObject:chatKey
			   afterDelay:NEW_LOGFILE_TIMEOUT];
}

- (void)finishClosingAppender:(NSString *)chatKey
{
	//Remove the appender, closing its file descriptor upon dealloc
	[activeAppenders removeObjectForKey:chatKey];
}


//Display a warning to the user that logging failed, and disable logging to prevent additional warnings
//XXX not currently used. We may want to shift these strings for use when xml logging fails, so I'm not removing them -eds
/*
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
*/

#pragma mark Message History

NSCalendarDate* getDateFromPath(NSString *path)
{
	NSRange openParenRange, closeParenRange;

	if ([path hasSuffix:@".chatlog"] && (openParenRange = [path rangeOfString:@"(" options:NSBackwardsSearch]).location != NSNotFound) {
		openParenRange = NSMakeRange(openParenRange.location, [path length] - openParenRange.location);
		if ((closeParenRange = [path rangeOfString:@")" options:0 range:openParenRange]).location != NSNotFound) {
			//Add and subtract one to remove the parenthesis
			NSString *dateString = [path substringWithRange:NSMakeRange(openParenRange.location + 1, (closeParenRange.location - openParenRange.location))];
			NSCalendarDate *date = [NSCalendarDate calendarDateWithString:dateString timeSeparator:'.'];
			return date;
		}
	}
	return nil;
}

int sortPaths(NSString *path1, NSString *path2, void *context)
{
	NSCalendarDate *date1 = getDateFromPath(path1);
	NSCalendarDate *date2 = getDateFromPath(path2);
	
	if(!date1 && !date2)
		return NSOrderedSame;
	else if (date1 && date2)
		return [date2 compare:date1];
	else
		return date2 ? NSOrderedDescending : NSOrderedAscending;
}

+ (NSArray *)sortedArrayOfLogFilesForChat:(AIChat *)chat
{
	NSString *baseLogPath = [[self fullPathForLogOfChat:chat onDate:[NSDate date]] stringByDeletingLastPathComponent];
	NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath:baseLogPath];	
	if (files) {
		return [files sortedArrayUsingFunction:&sortPaths context:NULL];
	}
	return nil;
}

#pragma mark Upgrade code
- (void)upgradeLogExtensions
{
	if (![[[adium preferenceController] preferenceForKey:@"Log Extensions Updated" group:PREF_GROUP_LOGGING] boolValue]) {
		/* This could all be a simple NSDirectoryEnumerator call on basePath, but we wouldn't be able to show progress,
		* and this could take a bit.
		*/
		NSFileManager	*defaultManager = [NSFileManager defaultManager];
		NSArray			*accountFolders = [defaultManager directoryContentsAtPath:logBasePath];
		NSEnumerator	*accountFolderEnumerator = [accountFolders objectEnumerator];
		NSString		*accountFolderName;
		
		NSMutableSet	*pathsToContactFolders = [NSMutableSet set];
		while ((accountFolderName = [accountFolderEnumerator nextObject])) {
			NSString		*contactBasePath = [logBasePath stringByAppendingPathComponent:accountFolderName];
			NSArray			*contactFolders = [defaultManager directoryContentsAtPath:contactBasePath];
			
			NSEnumerator	*contactFolderEnumerator = [contactFolders objectEnumerator];
			NSString		*contactFolderName;
			
			while ((contactFolderName = [contactFolderEnumerator nextObject])) {
				[pathsToContactFolders addObject:[contactBasePath stringByAppendingPathComponent:contactFolderName]];
			}
		}
		
		unsigned		contactsToProcess = [pathsToContactFolders count];
		unsigned		processed = 0;
		
		if (contactsToProcess) {
			AILogFileUpgradeWindowController *upgradeWindowController;
			
			upgradeWindowController = [[AILogFileUpgradeWindowController alloc] initWithWindowNibName:@"LogFileUpgrade"];
			[[upgradeWindowController window] makeKeyAndOrderFront:nil];

			NSEnumerator	*pathsToContactFoldersEnumerator = [pathsToContactFolders objectEnumerator];
			NSString		*pathToContactFolder;
			while ((pathToContactFolder = [pathsToContactFoldersEnumerator nextObject])) {
				NSDirectoryEnumerator *enumerator = [defaultManager enumeratorAtPath:pathToContactFolder];
				NSString	*file;
				
				while ((file = [enumerator nextObject])) {
					if (([[file pathExtension] isEqualToString:@"html"]) ||
						([[file pathExtension] isEqualToString:@"adiumLog"]) ||
						(([[file pathExtension] isEqualToString:@"bak"]) && ([file hasSuffix:@".html.bak"] || 
																			 [file hasSuffix:@".adiumLog.bak"]))) {
						NSString *fullFile = [pathToContactFolder stringByAppendingPathComponent:file];
						NSString *newFile = [[fullFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"AdiumHTMLLog"];
						
						[defaultManager movePath:fullFile
										  toPath:newFile
										 handler:self];
					}
				}
				
				processed++;
				[upgradeWindowController setProgress:(processed*100.0)/contactsToProcess];
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

/*!
 * @brief Initialize log indexing
 */
- (void)initLogIndexing
{
	//Load the list of logs that need re-indexing
	[self loadDirtyLogArray];
}

/*!
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

	//Load the contentIndex immediately; this will clear dirtyLogArray if necessary
	[self logContentIndex];

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
	
	if (![chat integerStatusObjectForKey:dirtyKey]) {
		//Add to dirty array (Lock to ensure that no one changes its content while we are)
		[dirtyLogLock lock];
		if (path != nil) {
			if (!dirtyLogArray) dirtyLogArray = [[NSMutableArray alloc] init];

			if (![dirtyLogArray containsObject:path]) {
				[dirtyLogArray addObject:path];
			}
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

- (void)markLogDirtyAtPath:(NSString *)path
{
	if(!path) return;
	[dirtyLogLock lock];
	if (!dirtyLogArray) dirtyLogArray = [[NSMutableArray alloc] init];

	if (![dirtyLogArray containsObject:path]) {
		[dirtyLogArray addObject:path];
	}
	[dirtyLogLock unlock];	
}

//Get the current status of indexing.  Returns NO if indexing is not occuring
- (BOOL)getIndexingProgress:(int *)indexNumber outOf:(int *)total
{
	//logsIndexed + 1 is the log we are currently indexing
	if (indexNumber) *indexNumber = (logsIndexed + 1 <= logsToIndex) ? logsIndexed + 1 : logsToIndex;
	if (total) *total = logsToIndex;
	return (logsToIndex > 0);
}


//Log index ------------------------------------------------------------------------------------------------------------
//Search kit index used to searching log content
#pragma mark Log Index
/*!
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
		AILog(@"Opened index %x from %@",newIndex,logIndexPathURL);
    }
    if (!newIndex) {
		NSDictionary *textAnalysisProperties;
		
		if ([NSApp isOnTigerOrBetter]) {
			textAnalysisProperties = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:0], kSKMaximumTerms,
				[NSNumber numberWithInt:2], kSKMinTermLength,
#if ENABLE_PROXIMITY_SEARCH
				kCFBooleanTrue, kSKProximityIndexing, 
#endif
				nil];

		} else {
			textAnalysisProperties = nil;
		}

		//Create the index if one doesn't exist
		[[NSFileManager defaultManager] createDirectoriesForPath:[logIndexPath stringByDeletingLastPathComponent]];
		
		newIndex = SKIndexCreateWithURL((CFURLRef)logIndexPathURL,
										(CFStringRef)@"Content", 
										kSKIndexInverted,
										(CFDictionaryRef)textAnalysisProperties);
		AILog(@"Created a new log index %x at %@ with textAnalysisProperties %@",newIndex,logIndexPathURL,textAnalysisProperties);
		//Clear the dirty log array in case it was loaded (this can happen if the user mucks with the cache directory)
		[[NSFileManager defaultManager] removeFileAtPath:[self _dirtyLogArrayPath] handler:NULL];
		[dirtyLogArray release]; dirtyLogArray = nil;
    }

	return newIndex;
}

- (void)releaseIndex:(SKIndexRef)inIndex
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	CFRelease(inIndex);
	[pool release];
}

//Close the log index
- (void)closeLogIndex
{
	[logAccessLock lock];
	if (index_Content) {
		[NSThread detachNewThreadSelector:@selector(releaseIndex:)
								 toTarget:self
							   withObject:(id)index_Content];
		index_Content = nil;
	}
	[logAccessLock unlock];
}

//Delete the log index
- (void)resetLogIndex
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self _logIndexPath]]) {
		[[NSFileManager defaultManager] removeFileAtPath:[self _logIndexPath] handler:NULL];
	}	

	if ([[NSFileManager defaultManager] fileExistsAtPath:[self _dirtyLogArrayPath]]) {
		[[NSFileManager defaultManager] removeFileAtPath:[self _dirtyLogArrayPath] handler:NULL];
	}
}

//Path of log index file
- (NSString *)_logIndexPath
{
    return [[adium cachesPath] stringByAppendingPathComponent:LOG_INDEX_NAME];
}


//Dirty Log Array ------------------------------------------------------------------------------------------------------
//Stores the absolute paths of logs that need to be re-indexed
#pragma mark Dirty Log Array
//Load the dirty log array
- (void)loadDirtyLogArray
{
	if (!dirtyLogArray) {
		int logVersion = [[[adium preferenceController] preferenceForKey:KEY_LOG_INDEX_VERSION
																   group:PREF_GROUP_LOGGING] intValue];

		//If the log version has changed, we reset the index and don't load the dirty array (So all the logs are marked dirty)
		if (logVersion >= CURRENT_LOG_VERSION) {
			[dirtyLogLock lock];
			dirtyLogArray = [[NSMutableArray alloc] initWithContentsOfFile:[self _dirtyLogArrayPath]];
			[dirtyLogLock unlock];
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

    [indexingThreadLock lock];
    suspendDirtyArraySave = YES;    //Prevent saving of the dirty array until we're finished building it
    
    //Create a fresh dirty log array
    [dirtyLogLock lock];
    [dirtyLogArray release]; dirtyLogArray = [[NSMutableArray alloc] init];
    [dirtyLogLock unlock];
	
    //Process each from folder
    fromEnumerator = [[[[NSFileManager defaultManager] directoryContentsAtPath:logBasePath] objectEnumerator] retain];
    while ((fromName = [[fromEnumerator nextObject] retain])) {
		fromGroup = [[AILogFromGroup alloc] initWithPath:fromName fromUID:fromName serviceClass:nil];

		//Walk through every 'to' group
		toEnumerator = [[[fromGroup toGroupArray] objectEnumerator] retain];
		while ((toGroup = [[toEnumerator nextObject] retain])) {
			//Walk through every log
			logEnumerator = [toGroup logEnumerator];
			while ((theLog = [logEnumerator nextObject])) {
				//Add this log's path to our dirty array.  The dirty array is guarded with a lock
				//since it will be accessed from outside this thread as well
				[dirtyLogLock lock];
				if (theLog != nil) {
					[dirtyLogArray addObject:[logBasePath stringByAppendingPathComponent:[theLog path]]];
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
	
	AILog(@"Finished dritying all logs");
	
    //Save the dirty array we just built
	[self _saveDirtyLogArray];
	suspendDirtyArraySave = NO; //Re-allow saving of the dirty array
    
    //Begin cleaning the logs (If the log viewer is open)
    if (!stopIndexingThreads && [LogViewerWindowControllerClass existingWindowController]) {
		[self cleanDirtyLogs];
    }
    
    [indexingThreadLock unlock];
    [pool release];
}

/*!
 * @brief Index all dirty logs
 *
 * Indexing will occur on a thread
 */
- (void)cleanDirtyLogs
{
	//Do nothing if we're paused
	if (logIndexingPauses) return;

    //Reset the cleaning progress
    [dirtyLogLock lock];
    logsToIndex = [dirtyLogArray count];
    [dirtyLogLock unlock];
    logsIndexed = 0;
	AILog(@"cleanDirtyLogs: logsToIndex is %i",logsToIndex);
	if (logsToIndex > 0) {
		[NSThread detachNewThreadSelector:@selector(_cleanDirtyLogsThread:) toTarget:self withObject:(id)[self logContentIndex]];
	}
}

- (void)didCleanDirtyLogs
{
	//Update our progress
	logsToIndex = 0;
	[[LogViewerWindowControllerClass existingWindowController] logIndexingProgressUpdate];
	
	//Clear the dirty status of all open chats so they will be marked dirty if they receive another message
	NSEnumerator *enumerator = [[[adium chatController] openChats] objectEnumerator];
	AIChat		 *chat;
	
	while ((chat = [enumerator nextObject])) {
		NSString *existingAppenderPath = [[self existingAppenderForChat:chat] path];
		if (existingAppenderPath) {
			NSString *dirtyKey = [@"LogIsDirty_" stringByAppendingString:existingAppenderPath];
			
			if ([chat integerStatusObjectForKey:dirtyKey]) {
				[chat setStatusObject:nil
							   forKey:dirtyKey
							   notify:NotifyNever];
			}
		}
	}
}

- (void)pauseIndexing
{
	if (logsToIndex) {
		[self stopIndexingThreads];
		logsToIndex = 0;
		logIndexingPauses++;
		AILog(@"Pausing %i",logIndexingPauses);
	}
}

- (void)resumeIndexing
{
	if (logIndexingPauses)
		logIndexingPauses--;
	AILog(@"Told to resume; log indexing paauses is now %i",logIndexingPauses);
	if (logIndexingPauses == 0) {
		stopIndexingThreads = NO;
		[self cleanDirtyLogs];
	}
}

- (void)_cleanDirtyLogsThread:(SKIndexRef)searchIndex
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

	//Ensure log indexing (in an old thread) isn't already going on and just waiting to stop
	[indexingThreadLock lock]; [indexingThreadLock unlock];

	//If it was going on, we can just cancel
	if (logsToIndex == 0) {
		AILog(@"Nothing to clean!");
		[self performSelectorOnMainThread:@selector(didCleanDirtyLogs)
							   withObject:nil
							waitUntilDone:NO];
		[pool release];
		return;
	}

    [indexingThreadLock lock];

    //Start cleaning (If we're still supposed to go)
    if (!stopIndexingThreads) {
		UInt32	lastUpdate = TickCount();
		int		unsavedChanges = 0;

		AILog(@"Cleaning %i dirty logs", [dirtyLogArray count]);

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
				
				document = SKDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:logPath]);
				if (document) {
					/* We _could_ use SKIndexAddDocument() and depend on our Spotlight plugin for importing.
					 * However, this has three problems:
					 *	1. Slower, especially to start initial indexing, which is the most common use case since the log viewer
					 *	   indexes recently-modified ("dirty") logs when it opens.
					 *  2. Sometimes logs don't appear to be associated with the right URI type and therefore don't get indexed.
					 *  3. On 10.3, this means that logs' markup is indexed in addition to their text, which is undesireable.
					 */
					CFStringRef documentText = CopyTextContentForFile(NULL, (CFStringRef)logPath);
					if (documentText) {
						SKIndexAddDocumentWithText(searchIndex,
												   document,
												   documentText,
												   YES);
						CFRelease(documentText);
					}
					CFRelease(document);
				} else {
					NSLog(@"Could not create document for %@ [%@]",logPath,[NSURL fileURLWithPath:logPath]);
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

		[logAccessLock lock];
		SKIndexFlush(searchIndex);
		AILog(@"After cleaning dirty logs, the search index has a max ID of %i and a count of %i",
			  SKIndexGetMaximumDocumentID(searchIndex),
			  SKIndexGetDocumentCount(searchIndex));
		[logAccessLock unlock];

		[self performSelectorOnMainThread:@selector(didCleanDirtyLogs)
							   withObject:nil
							waitUntilDone:NO];
    }

	[indexingThreadLock unlock];

    [pool release];
}

- (NSLock *)logAccessLock
{
	return logAccessLock;
}

- (void)_removePathsFromIndexThread:(NSDictionary *)userInfo
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

	[indexingThreadLock lock];

	SKIndexRef logSearchIndex = (SKIndexRef)[userInfo objectForKey:@"SKIndexRef"];
	NSEnumerator *enumerator = [[userInfo objectForKey:@"Paths"] objectEnumerator];
	NSString	 *logPath;
	
	while ((logPath = [enumerator nextObject])) {
		SKDocumentRef document = SKDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:logPath]);
		if (document) {
			SKIndexRemoveDocument(logSearchIndex, document);
			CFRelease(document);
		}
	}

	[indexingThreadLock unlock];

	[pool release];
}

- (void)removePathsFromIndex:(NSSet *)paths
{
	[NSThread detachNewThreadSelector:@selector(_removePathsFromIndexThread:)
							 toTarget:self
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   (id)[self logContentIndex], @"SKIndexRef",
							   paths, @"Paths",
							   nil]];
}


@end


