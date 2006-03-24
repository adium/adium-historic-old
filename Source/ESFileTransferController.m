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

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIMenuController.h"
#import "AIToolbarController.h"
#import "ESContactAlertsController.h"
#import "ESFileTransferController.h"
#import "ESFileTransferPreferences.h"
#import "ESFileTransferProgressWindowController.h"
#import "ESFileTransferRequestPromptController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIExceptionHandlingUtilities.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIWindowController.h>

#define SEND_FILE					AILocalizedString(@"Send File",nil)
#define SEND_FILE_WITH_ELLIPSIS		[SEND_FILE stringByAppendingEllipsis]
#define CONTACT						AILocalizedString(@"Contact",nil)

#define	SEND_FILE_IDENTIFIER		@"SendFile"

#define	FILE_TRANSFER_DEFAULT_PREFS	@"FileTransferPrefs"

#define SAFE_FILE_EXTENSIONS_SET	[NSSet setWithObjects:@"jpg",@"jpeg",@"gif",@"png",@"tif",@"tiff",@"psd",@"pdf",@"txt",@"rtf",@"html",@"htm",@"swf",@"mp3",@"wma",@"wmv",@"ogg",@"ogm",@"mov",@"mpg",@"mpeg",@"m1v",@"m2v",@"mp4",@"avi",@"vob",@"avi",@"asx",@"asf",@"pls",@"m3u",@"rmp",@"aif",@"aiff",@"aifc",@"wav",@"wave",@"m4a",@"m4p",@"m4b",@"dmg",@"udif",@"ndif",@"dart",@"sparseimage",@"cdr",@"dvdr",@"iso",@"img",@"toast",@"rar",@"sit",@"sitx",@"bin",@"hqx",@"zip",@"gz",@"tgz",@"tar",@"bz",@"bz2",@"tbz",@"z",@"taz",@"uu",@"uue",@"colloquytranscript",@"torrent",@"AdiumIcon",@"AdiumSoundset",@"AdiumEmoticon",@"AdiumMessageStyle",nil]

static ESFileTransferPreferences *preferences;

@interface ESFileTransferController (PRIVATE)
- (void)configureFileTransferProgressWindow;
- (void)showProgressWindow:(id)sender;
- (void)showProgressWindowIfNotOpen:(id)sender;

- (void)_finishReceiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer localFilename:(NSString *)localFilename;

- (BOOL)shouldOpenCompleteFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer;
@end

@implementation ESFileTransferController

//init
- (id)init
{
	if ((self = [super init])) {
		fileTransferArray = [[NSMutableArray alloc] init];
		safeFileExtensions = nil;
	}
	
	return self;
}

- (void)controllerDidLoad
{
    //Add our get info contextual menu item
    menuItem_sendFileContext = [[NSMenuItem alloc] initWithTitle:SEND_FILE_WITH_ELLIPSIS
														  target:self action:@selector(contextualMenuSendFile:)
												   keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_sendFileContext toLocation:Context_Contact_Action];
	
	//Register the events we generate
	ESContactAlertsController *contactAlertsController = [adium contactAlertsController];
	[contactAlertsController registerEventID:FILE_TRANSFER_REQUEST withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_BEGAN withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_CANCELLED withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_COMPLETE withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	
    //Install the Send File menu item
	menuItem_sendFile = [[NSMenuItem alloc] initWithTitle:SEND_FILE_WITH_ELLIPSIS
												   target:self action:@selector(sendFileToSelectedContact:)
											keyEquivalent:@"F"];
	[menuItem_sendFile setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
	[[adium menuController] addMenuItem:menuItem_sendFile toLocation:LOC_Contact_Action];
	
	//Add our "Send File" toolbar item
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SEND_FILE_IDENTIFIER
														  label:SEND_FILE
												   paletteLabel:SEND_FILE
														toolTip:AILocalizedString(@"Send a file",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"sendfile" forClass:[self class]]
														 action:@selector(sendFileToSelectedContact:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
	
	AIPreferenceController *preferenceController = [adium preferenceController];
    //Register our default preferences
    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:FILE_TRANSFER_DEFAULT_PREFS
																forClass:[self class]] 
								  forGroup:PREF_GROUP_FILE_TRANSFER];
    
    //Observe pref changes
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_FILE_TRANSFER];
	preferences = [[ESFileTransferPreferences preferencePane] retain];
	
	//Set up the file transfer progress window
	[self configureFileTransferProgressWindow];
}

- (void)controllerWillClose
{
    [[adium preferenceController] unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[super dealloc];
	
	[safeFileExtensions release]; safeFileExtensions = nil;
	[fileTransferArray release]; fileTransferArray = nil;
}

#pragma mark Access to file transfer objects
- (ESFileTransfer *)newFileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(FileTransferType)t
{
	ESFileTransfer *fileTransfer;
	
	fileTransfer = [ESFileTransfer fileTransferWithContact:inContact
												forAccount:inAccount
													  type:t];
	[fileTransferArray addObject:fileTransfer];
	[fileTransfer setStatus:Not_Started_FileTransfer];

	//Wait until the next run loop to inform observers of the new file transfer object;
	//this way the code which requested a new ESFileTransfer has time to configure it before we
	//dispaly information to the user
	[[adium notificationCenter] performSelector:@selector(postNotificationName:object:)
									 withObject:FileTransfer_NewFileTransfer 
									 withObject:fileTransfer
									 afterDelay:0.0001];

	return fileTransfer;
}

- (NSArray *)fileTransferArray
{
	return fileTransferArray;
}

//Remove a file transfer from our array.
- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer
{
	[fileTransferArray removeObject:fileTransfer];
}

#pragma mark Sending and receiving
//Sent by an account when it gets a request for us to receive a file; prompt the user for a save location
- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer
{
	AIListContact		*listContact = [fileTransfer contact];
	NSString			*localFilename = nil;

	[fileTransfer setFileTransferType:Incoming_FileTransfer];

	[[adium contactAlertsController] generateEvent:FILE_TRANSFER_REQUEST
									 forListObject:listContact
										  userInfo:fileTransfer
					  previouslyPerformedActionIDs:nil];

	if ((autoAcceptType == AutoAccept_All) ||
	   ((autoAcceptType == AutoAccept_FromContactList) && (![listContact isStranger]))) {
		NSString	*preferredDownloadFolder = [[adium preferenceController] userPreferredDownloadFolder];
		NSString	*remoteFilename = [fileTransfer remoteFilename];
		
		//If we should autoaccept, determine the local filename  and proceed to accept the request
		localFilename = [preferredDownloadFolder stringByAppendingPathComponent:remoteFilename];
		
		[self _finishReceiveRequestForFileTransfer:fileTransfer
									 localFilename:[[NSFileManager defaultManager] uniquePathForPath:localFilename]];
			
	} else {
		//Prompt to accept/deny
		[ESFileTransferRequestPromptController displayPromptForFileTransfer:fileTransfer
															notifyingTarget:self
																   selector:@selector(_finishReceiveRequestForFileTransfer:localFilename:)];
	}
}

/*!
 * @brief Finish the receive request process
 *
 * Called by either ESFileTransferRequestPromptController or self, this method is the last step in accepting or
 * refusing a request to be sent a file.
 *
 * @param fileTransfer The file transfer in question
 * @param localFilename Full path at which to save the file.  If anything exists at this path it will be overwritten without further confirmation.  Pass nil to deny the transfer.
 */
- (void)_finishReceiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer localFilename:(NSString *)localFilename
{	
	if (localFilename) {
		[fileTransfer setLocalFilename:localFilename];
		[fileTransfer setStatus:Accepted_FileTransfer];

		[(AIAccount<AIAccount_Files> *)[fileTransfer account] acceptFileTransferRequest:fileTransfer];
		
		if (showProgressWindow) {
			[self showProgressWindowIfNotOpen:nil];
		}
		
	} else {
		[(AIAccount<AIAccount_Files> *)[fileTransfer account] rejectFileReceiveRequest:fileTransfer];
		[fileTransfer setStatus:Cancelled_Local_FileTransfer];
	}	
}

//Prompt the user for the file to send via an Open File dialogue
- (void)requestForSendingFileToListContact:(AIListContact *)listContact
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:[NSString stringWithFormat:AILocalizedString(@"Send File to %@",nil),[listContact displayName]]];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:YES];

	if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
		NSEnumerator *enumerator = [[openPanel filenames] objectEnumerator];
		NSString	 *filePath;

		while ((filePath = [enumerator nextObject])) {
			[self sendFile:filePath toListContact:listContact];
		}
	}
}

- (NSString *)pathToArchiveOfFolder:(NSString *)inPath
{
	NSString		*pathToArchive = nil;
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSString		*tmpDir;

	//Desired folder: /private/tmp/$UID/`uuidgen`
	tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	if (tmpDir) {
		NSString	*launchPath = [[[@"/" stringByAppendingPathComponent:@"usr"] stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:@"zip"];

		//Proceed only if /usr/bin/zip exists
		if ([defaultManager fileExistsAtPath:launchPath]) {
			NSString	*folderName = [inPath lastPathComponent];
			NSArray		*arguments;
			NSTask		*zipTask;
			
			BOOL		success = NO;

			//Ensure our temporary directory exists [it never will the first time this method is called]
			[defaultManager createDirectoryAtPath:tmpDir attributes:nil];

			pathToArchive = [[NSFileManager defaultManager] uniquePathForPath:[tmpDir stringByAppendingPathComponent:[folderName stringByAppendingPathExtension:@"zip"]]];

			arguments = [NSArray arrayWithObjects:
				@"-r", //we'll want to store recursively
				@"-1", //use the fastest level of compression that isn't storage; the user can compress manually to do better
				@"-q", //shhh!
				pathToArchive,   //output to our destination name
				folderName, //store the folder
				nil];
			
			zipTask = [[NSTask alloc] init];
			[zipTask setLaunchPath:launchPath];
			[zipTask setArguments:arguments];
			[zipTask setCurrentDirectoryPath:[inPath stringByDeletingLastPathComponent]];
			
			AI_DURING
				[zipTask launch];
				[zipTask waitUntilExit];
				success = ([zipTask terminationStatus] == 0);
			AI_HANDLER
				/* No exception handler needed */
			AI_ENDHANDLER
			[zipTask release];
				
			if (!success) pathToArchive = nil;
		}
	}

	return pathToArchive;
}

//Initiate sending a file at a specified path to listContact
- (void)sendFile:(NSString *)inPath toListContact:(AIListContact *)listContact
{
	AIAccount		*account;
	ESFileTransfer	*fileTransfer;
	
	if ((account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_FILE_TRANSFER_TYPE
																		  toContact:listContact])) {
		NSFileManager	*defaultManager = [NSFileManager defaultManager];
		BOOL			isDir;
		
		//Set up a fileTransfer object
		fileTransfer = [self newFileTransferWithContact:listContact
											 forAccount:account
												   type:Outgoing_FileTransfer];
		

		if ([defaultManager fileExistsAtPath:inPath isDirectory:&isDir]) {
			//If we get a directory, compress it first (this could be specified on a per-account basis later if we have services supporting folder transfer)
			if (isDir) {
				inPath = [self pathToArchiveOfFolder:inPath];
			}
			
			if (inPath) {
				[fileTransfer setLocalFilename:inPath];
				[fileTransfer setSize:[[[defaultManager fileAttributesAtPath:inPath
																traverseLink:YES] objectForKey:NSFileSize] longValue]];
				
				//The fileTransfer object should now have everything the account needs to begin transferring
				[(AIAccount<AIAccount_Files> *)account beginSendOfFileTransfer:fileTransfer];
				
				if (showProgressWindow) {
					[self showProgressWindowIfNotOpen:nil];
				}
			}
		}
	}
}

//Menu or context menu item for sending a file was selected - possible only when a listContact is selected
- (IBAction)sendFileToSelectedContact:(id)sender
{
	//Get the "selected" list object (contact list or message window)
	AIListObject	*selectedObject;
	AIListContact   *listContact = nil;
	
	selectedObject = [[adium contactController] selectedListObject];
	if ([selectedObject isKindOfClass:[AIListContact class]]) {
		listContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}
	
	if (listContact) {
		[self requestForSendingFileToListContact:listContact];
	}
}
//Prompt for a new contact with the current tab's name
- (IBAction)contextualMenuSendFile:(id)sender
{
	AIListObject	*selectedObject = [[adium menuController] currentContextMenuObject];
	AIListContact   *listContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																			  forListContact:(AIListContact *)selectedObject];
	
	[NSApp activateIgnoringOtherApps:YES];
	[self requestForSendingFileToListContact:listContact];
}

#pragma mark Status updates
- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(FileTransferStatus)status
{
	switch (status) {
		case Checksumming_Filetransfer:
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_CHECKSUMMING
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			
			if (showProgressWindow) {
				[self showProgressWindowIfNotOpen:nil];
			}	
			break;

		case Accepted_FileTransfer:
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_BEGAN
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];

			if (showProgressWindow) {
				[self showProgressWindowIfNotOpen:nil];
			}
			
			break;
		case Complete_FileTransfer:
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_COMPLETE
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			
			//The file is complete; if we are supposed to automatically open safe files and this is one, open it
			if ([self shouldOpenCompleteFileTransfer:fileTransfer]) { 
				[fileTransfer openFile];
			}
			
			if (autoClearCompletedTransfers) {
				[ESFileTransferProgressWindowController removeFileTransfer:fileTransfer];
				[self _removeFileTransfer:fileTransfer];
			}
			break;
		case Cancelled_Remote_FileTransfer:
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_CANCELLED
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			break;
		case Failed_FileTransfer:
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_FAILED
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			break;
		default:
			break;
	}
}

- (BOOL)shouldOpenCompleteFileTransfer:(ESFileTransfer *)fileTransfer
{
	BOOL	shouldOpen = NO;
	
	if (autoOpenSafe &&
	   ([fileTransfer fileTransferType] == Incoming_FileTransfer)) {
		
		if (!safeFileExtensions) safeFileExtensions = [SAFE_FILE_EXTENSIONS_SET retain];		

		shouldOpen = [safeFileExtensions containsObject:[[[fileTransfer localFilename] pathExtension] lowercaseString]];
	}

	return shouldOpen;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListContact   *listContact = nil;
	
    if (menuItem == menuItem_sendFile) {
        AIListObject	*selectedObject = [[adium contactController] selectedListObject];
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]) {
			listContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		return listContact != nil;
		
	} else if (menuItem == menuItem_sendFileContext) {
		AIListObject	*selectedObject = [[adium menuController] currentContextMenuObject];
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]) {
			listContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		return listContact != nil;
		
    } else if (menuItem == menuItem_showFileTransferProgress) {
		return YES;
	}

    return YES;
}

/*
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	AIListContact   *listContact = nil;
	
	AIListObject	*selectedObject = [[adium contactController] selectedListObject];
	if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]) {
		listContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}

    return listContact != nil;
}
*/
#pragma mark File transfer progress window
- (void)configureFileTransferProgressWindow
{
	//Add the File Transfer Progress window menuItem
	menuItem_showFileTransferProgress = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"File Transfers",nil)
																   target:self 
																   action:@selector(showProgressWindow:)
															keyEquivalent:@"l"];
	[menuItem_showFileTransferProgress setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	[[adium menuController] addMenuItem:menuItem_showFileTransferProgress toLocation:LOC_Window_Auxiliary];
}

//Show the file transfer progress window
- (void)showProgressWindow:(id)sender
{
	[ESFileTransferProgressWindowController showFileTransferProgressWindow];
}

- (void)showProgressWindowIfNotOpen:(id)sender
{
	[ESFileTransferProgressWindowController showFileTransferProgressWindowIfNotOpen];	
}

#pragma mark Preferences
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	autoAcceptType = [[prefDict objectForKey:KEY_FT_AUTO_ACCEPT] intValue];
	autoOpenSafe = [[prefDict objectForKey:KEY_FT_AUTO_OPEN_SAFE] boolValue];
	autoClearCompletedTransfers = [[prefDict objectForKey:KEY_FT_AUTO_CLEAR_COMPLETED] boolValue];
	
	//If we created a safe file extensions set and no longer need it, desroy it
	if (!autoOpenSafe && safeFileExtensions) {
		[safeFileExtensions release]; safeFileExtensions = nil;
	}
	
	showProgressWindow = [[prefDict objectForKey:KEY_FT_SHOW_PROGRESS_WINDOW] boolValue];
}

#pragma mark AIEventHandler

- (NSString *)shortDescriptionForEventID:(NSString *)eventID { return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
		description = AILocalizedString(@"File transfer requested",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
		description = AILocalizedString(@"File is checksummed before sending",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
		description = AILocalizedString(@"File transfer begins",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
		description = AILocalizedString(@"File transfer cancelled by the other side",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
		description = AILocalizedString(@"File transfer completed successfully",nil);
	} else {		
		description = @"";	
	}
	
	return description;
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
//XXX-fix this for the above comment.
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
		description = @"File Transfer Request";
	} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
		description = @"File Checksumming for Sending";
	} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
		description = @"File Transfer Began";
	} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
		description = @"File Transfer cancelled Remotely";
	} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
		description = @"File Transfer Complete";
	} else {		
		description = @"";	
	}
	
	return description;
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{	
	NSString	*description;
	
	if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
		description = AILocalizedString(@"When a file transfer is requested",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
		description = AILocalizedString(@"When a file is checksummed prior to sending",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
		description = AILocalizedString(@"When a file transfer begins",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
		description = AILocalizedString(@"When a file transfer is cancelled remotely",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
		description = AILocalizedString(@"When a file transfer is completed successfully",nil);
	} else {		
		description = @"";	
	}

	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	NSString		*displayName, *displayFilename;
	ESFileTransfer	*fileTransfer;

	NSParameterAssert([userInfo isKindOfClass:[ESFileTransfer class]]);
	fileTransfer = (ESFileTransfer *)userInfo;
	
	displayName = [listObject displayName];
	displayFilename = [fileTransfer displayFilename];
	
	if (includeSubject) {
		NSString	*format = nil;
		
		if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
			//Should only happen for an incoming transfer
			format = AILocalizedString(@"%@ requests to send you %@",nil);
			
		} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"%@ began sending you %@",nil);
			} else {
				format = AILocalizedString(@"%@ began receiving %@",nil);	
			}
		} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
			format = AILocalizedString(@"%@ cancelled the transfer of %@",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"%@ sent you %@",nil);
			} else {
				format = AILocalizedString(@"%@ received %@",nil);	
			}
		}
		
		if (format) {
			description = [NSString stringWithFormat:format,displayName,displayFilename];
		}
	} else {
		NSString	*format = nil;
		
		if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
			//Should only happen for an incoming transfer
			format = AILocalizedString(@"requests to send you %@",nil);
			
		} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"began sending you %@",nil);
			} else {
				format = AILocalizedString(@"began receiving %@",nil);	
			}
		} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
			format = AILocalizedString(@"cancelled the transfer of %@",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"sent you %@",nil);
			} else {
				format = AILocalizedString(@"received %@",nil);	
			}
		}
		
		if (format) {
			description = [NSString stringWithFormat:format,displayFilename];
		}		
	}

	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [[NSImage imageNamed:@"pref-ft" forClass:[self class]] retain];
	return eventImage;
}

#pragma mark Strings for sizes

#define	ZERO_BYTES			AILocalizedString(@"Zero bytes", "no file size")

- (NSString *)stringForSize:(unsigned long long)inSize
{
	NSString *ret = nil;
	
	if ( inSize == 0. ) ret = ZERO_BYTES;
	else if ( inSize > 0. && inSize < 1024. ) ret = [NSString stringWithFormat:AILocalizedString( @"%lu bytes", "file size measured in bytes" ), inSize];
	else if ( inSize >= 1024. && inSize < pow( 1024., 2. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.1f KB", "file size measured in kilobytes" ), ( inSize / 1024. )];
	else if ( inSize >= pow( 1024., 2. ) && inSize < pow( 1024., 3. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.2f MB", "file size measured in megabytes" ), ( inSize / pow( 1024., 2. ) )];
	else if ( inSize >= pow( 1024., 3. ) && inSize < pow( 1024., 4. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.3f GB", "file size measured in gigabytes" ), ( inSize / pow( 1024., 3. ) )];
	else if ( inSize >= pow( 1024., 4. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.4f TB", "file size measured in terabytes" ), ( inSize / pow( 1024., 4. ) )];
	
	if (!ret) ret = ZERO_BYTES;
	
	return ret;
}

- (NSString *)stringForSize:(unsigned long long)inSize of:(unsigned long long)totalSize ofString:(NSString *)totalSizeString
{
	NSString *ret = nil;
	
	if ( inSize == 0. ) {
		ret = ZERO_BYTES;
	} else if ( inSize > 0. && inSize < 1024. ) {
		if ( totalSize > 0. && totalSize < 1024. ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%lu of %lu bytes", "file sizes both measured in bytes" ), inSize, totalSize];
			
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%lu bytes of %@", "file size measured in bytes out of some other measurement" ), inSize, totalSizeString];
			
		}
	} else if ( inSize >= 1024. && inSize < pow( 1024., 2. ) ) {
		if ( totalSize >= 1024. && totalSize < pow( 1024., 2. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.1f of %.1f KB", "file sizes both measured in kilobytes" ), ( inSize / 1024. ), ( totalSize / 1024. )];
			
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.1f KB of %@", "file size measured in kilobytes out of some other measurement" ), ( inSize / 1024. ), totalSizeString];
		}
	}
	else if ( inSize >= pow( 1024., 2. ) && inSize < pow( 1024., 3. ) ) {
		if ( totalSize >= pow( 1024., 2. ) && totalSize < pow( 1024., 3. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.2f of %.2f MB", "file sizes both measured in megabytes" ), ( inSize / pow( 1024., 2. ) ), ( totalSize / pow( 1024., 2. ) )];
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.2f MB of %@", "file size measured in megabytes out of some other measurement" ), ( inSize / pow( 1024., 2. ) ), totalSizeString];	
		}
	}
	else if ( inSize >= pow( 1024., 3. ) && inSize < pow( 1024., 4. ) ) {
		if ( totalSize >= pow( 1024., 3. ) && totalSize < pow( 1024., 4. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.3f of %.3f GB", "file sizes both measured in gigabytes" ), ( inSize / pow( 1024., 3. ) ), ( totalSize / pow( 1024., 3. ) )];
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.3f GB of %@", "file size measured in gigabytes out of some other measurement" ), ( inSize / pow( 1024., 3. ) ), totalSizeString];
			
		}
	}
	else if ( inSize >= pow( 1024., 4. ) ) {
		if ( totalSize >= pow( 1024., 4. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.4f of %.4f TB", "file sizes both measured in terabytes" ), ( inSize / pow( 1024., 4. ) ),  ( totalSize / pow( 1024., 4. ) )];
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.4f TB of %@", "file size measured in terabytes out of some other measurement" ), ( inSize / pow( 1024., 4. ) ), totalSizeString];			
		}
	}
	
	if (!ret) ret = ZERO_BYTES;
	
	return ret;
}

@end
