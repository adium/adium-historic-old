//
//  ESFileTransferController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//
//  $Id$

#import "ESFileTransferController.h"
#import "ESFileTransferProgressWindowController.h"
#import "ESFileTransferPreferences.h"

#define SEND_FILE_TO_CONTACT		AILocalizedString(@"Send File To %@",nil)
#define SEND_FILE					AILocalizedString(@"Send File",nil)
#define CONTACT						AILocalizedString(@"Contact",nil)

#define	SEND_FILE_IDENTIFIER		@"SendFile"

#define	FILE_TRANSFER_DEFAULT_PREFS	@"FileTransferPrefs"

#define SAFE_FILE_EXTENSIONS_SET	[NSSet setWithObjects:@"jpg",@"jpeg",@"gif",@"png",@"tif",@"tiff",@"psd",@"pdf",@"txt",@"rtf",@"html",@"htm",@"swf",@"mp3",@"wma",@"wmv",@"ogg",@"ogm",@"mov",@"mpg",@"mpeg",@"m1v",@"m2v",@"mp4",@"avi",@"vob",@"avi",@"asx",@"asf",@"pls",@"m3u",@"rmp",@"aif",@"aiff",@"aifc",@"wav",@"wave",@"m4a",@"m4p",@"m4b",@"dmg",@"udif",@"ndif",@"dart",@"sparseimage",@"cdr",@"dvdr",@"iso",@"img",@"toast",@"rar",@"sit",@"sitx",@"bin",@"hqx",@"zip",@"gz",@"tgz",@"tar",@"bz",@"bz2",@"tbz",@"z",@"taz",@"uu",@"uue",@"colloquytranscript",@"torrent",@"AdiumIcon",@"AdiumSoundset",@"AdiumEmoticon",@"AdiumMessageStyle",nil]

static ESFileTransferPreferences *preferences;

@interface ESFileTransferController (PRIVATE)
- (void)configureFileTransferProgressWindow;
- (void)showProgressWindow:(id)sender;

- (BOOL)shouldOpenCompleteFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer;
@end

@implementation ESFileTransferController
//init and close
- (void)initController
{
	fileTransferArray = [[NSMutableArray alloc] init];
	safeFileExtensions = nil;

    //Add our get info contextual menu item
    menuItem_sendFileContext = [[NSMenuItem alloc] initWithTitle:SEND_FILE
														 target:self action:@selector(contextualMenuSendFile:)
												  keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_sendFileContext toLocation:Context_Contact_Action];
	
	//Register the events we generate
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_REQUEST withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_BEGAN withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_CANCELED withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_COMPLETE withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];

    //Install the Send File menu item
	menuItem_sendFile = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,CONTACT]
												   target:self action:@selector(sendFileToSelectedContact:)
											keyEquivalent:@"F"];
	[menuItem_sendFile setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
	[[adium menuController] addMenuItem:menuItem_sendFile toLocation:LOC_Contact_Action];
	
	//Add our "Send File" toolbar item
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SEND_FILE_IDENTIFIER
														  label:AILocalizedString(@"Send File",nil)
												   paletteLabel:AILocalizedString(@"Send File",nil)
														toolTip:AILocalizedString(@"Send a file",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"sendfile" forClass:[self class]]
														 action:@selector(sendFileToSelectedContact:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
	
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:FILE_TRANSFER_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_FILE_TRANSFER];
    
    //Observe pref changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_FILE_TRANSFER];
	preferences = [[ESFileTransferPreferences preferencePane] retain];

	//Set up the file transfer progress window
	[self configureFileTransferProgressWindow];
}

- (void)closeController
{
    
}

- (void)dealloc
{
	[safeFileExtensions release]; safeFileExtensions = nil;
	[fileTransferArray release]; fileTransferArray = nil;

	[[adium preferenceController] unregisterPreferenceObserver:self];
}

#pragma mark Access to file transfer objects
- (ESFileTransfer *)newFileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount
{
	ESFileTransfer *fileTransfer;
	
	fileTransfer = [ESFileTransfer fileTransferWithContact:inContact
												forAccount:inAccount];
	[fileTransferArray addObject:fileTransfer];
	[fileTransfer setStatus:Not_Started_FileTransfer];

	//Wait until the next run loop to inform observers of the new file transfer object;
	//this way the code which requested a new ESFileTransfer has time to configure it before we
	//dispaly information to the user
	[[adium notificationCenter] performSelector:@selector(postNotificationName:object:)
									 withObject:FileTransfer_NewFileTransfer 
									 withObject:fileTransfer
									 afterDelay:0.0001];

	return(fileTransfer);
}

- (NSArray *)fileTransferArray
{
	return(fileTransferArray);
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
	AIListContact	*listContact = [fileTransfer contact];
	NSString		*defaultName = [fileTransfer remoteFilename];
	NSString		*localFilename = nil;
	
	[[adium contactAlertsController] generateEvent:FILE_TRANSFER_REQUEST
									 forListObject:listContact
										  userInfo:fileTransfer
					  previouslyPerformedActionIDs:nil];

	if((autoAcceptType == AutoAccept_All) ||
	   ((autoAcceptType == AutoAccept_FromContactList) && (![listContact isStranger]))){
		localFilename = [[[adium preferenceController] userPreferredDownloadFolder] stringByAppendingPathComponent:defaultName];
	}else{
		//Prompt to accept/deny
		
		//If(prompt to accept = NSOKButton){
		NSSavePanel		*savePanel = [NSSavePanel savePanel];

		[savePanel setTitle:[NSString stringWithFormat:@"Receive File from %@",[[fileTransfer contact] displayName]]];

		if([savePanel runModalForDirectory:[[adium preferenceController] userPreferredDownloadFolder]
									  file:defaultName] == NSFileHandlingPanelOKButton) {
	
			localFilename = [savePanel filename];
		}
	}

	if(localFilename){
		[fileTransfer setLocalFilename:localFilename];
		[(AIAccount<AIAccount_Files> *)[fileTransfer account] acceptFileTransferRequest:fileTransfer];

		if(showProgressWindow){
			[self showProgressWindow:nil];
		}

	}else{
		[(AIAccount<AIAccount_Files> *)[fileTransfer account] rejectFileReceiveRequest:fileTransfer];        
	}	
}

//Prompt the user for the file to send via an Open File dialogue
- (void)requestForSendingFileToListContact:(AIListContact *)listContact
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:[NSString stringWithFormat:@"Send File to %@",[listContact displayName]]];
	
	if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
		[self sendFile:[openPanel filename] toListContact:listContact];
	}
}

//Initiate sending a file at a specified path to listContact
- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact
{
	AIAccount		*account;
	ESFileTransfer	*fileTransfer;
	
	if (account = [[adium accountController] preferredAccountForSendingContentType:FILE_TRANSFER_TYPE
																		 toContact:listContact]){
		//Set up a fileTransfer object
		fileTransfer = [self newFileTransferWithContact:listContact
											 forAccount:account];
		[fileTransfer setType:Outgoing_FileTransfer];
		[fileTransfer setLocalFilename:inFile];
		[fileTransfer setSize:[[[[NSFileManager defaultManager] fileAttributesAtPath:inFile
																		traverseLink:YES] objectForKey:NSFileSize] longValue]];
			
		//The fileTransfer object should now have everything the account needs to begin transferring
		[(AIAccount<AIAccount_Files> *)account beginSendOfFileTransfer:fileTransfer];
		
		if(showProgressWindow){
			[self showProgressWindow:nil];
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
	if ([selectedObject isKindOfClass:[AIListContact class]]){
		listContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}
	
	if(listContact){
		[self requestForSendingFileToListContact:listContact];
	}
}
//Prompt for a new contact with the current tab's name
- (IBAction)contextualMenuSendFile:(id)sender
{
	AIListObject	*selectedObject = [[adium menuController] contactualMenuObject];
	AIListContact   *listContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																			  forListContact:(AIListContact *)selectedObject];
	
	[NSApp activateIgnoringOtherApps:YES];
	[self requestForSendingFileToListContact:listContact];
}

#pragma mark Status updates
- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(FileTransferStatus)status
{
	switch(status){
		case Accepted_FileTransfer:
		{
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_BEGAN
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];

			if(showProgressWindow){
				[self showProgressWindow:nil];
			}
			
			break;
		}
		case Complete_FileTransfer:
		{		
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_COMPLETE
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			
			//The file is complete; if we are supposed to automatically open safe files and this is one, open it
			if([self shouldOpenCompleteFileTransfer:fileTransfer]){ 
				[fileTransfer openFile];
			}
			
			if(autoClearCompletedTransfers){
				[ESFileTransferProgressWindowController removeFileTransfer:fileTransfer];
				[self _removeFileTransfer:fileTransfer];
			}
			break;
		}
		case Canceled_Remote_FileTransfer:
		{
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_CANCELED
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			break;
		}
		default:
			break;
	}
}

- (BOOL)shouldOpenCompleteFileTransfer:(ESFileTransfer *)fileTransfer
{
	BOOL	shouldOpen = NO;
	
	if(autoOpenSafe &&
	   ([fileTransfer type] == Incoming_FileTransfer)){
		
		if(!safeFileExtensions) safeFileExtensions = [SAFE_FILE_EXTENSIONS_SET retain];		

		shouldOpen = [safeFileExtensions containsObject:[[[fileTransfer localFilename] pathExtension] lowercaseString]];
	}

	return(shouldOpen);
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListContact   *listContact = nil;
	
    if(menuItem == menuItem_sendFile){
        AIListObject	*selectedObject = [[adium contactController] selectedListObject];
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
			listContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		[menuItem setTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,(listContact ? [selectedObject displayName] : CONTACT)]];
		
		return(listContact != nil);
		
	}else if(menuItem == menuItem_sendFileContext){
		AIListObject	*selectedObject = [[adium menuController] contactualMenuObject];
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
			listContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		return(listContact != nil);
		
    }else if(menuItem == menuItem_showFileTransferProgress){
		return(YES);
	}

    return(YES);
}

#warning Evan: Why is this not getting called? (And do we want it to be?)
- (BOOL)validateToolBarItem:(NSToolbarItem *)theItem
{
	AIListContact   *listContact = nil;
	
	AIListObject	*selectedObject = [[adium contactController] selectedListObject];
	if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
		listContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}
	NSLog(@"validating %@ gives %@",theItem,listContact);
    return(listContact != nil);
}

#pragma mark File transfer progress window
- (void)configureFileTransferProgressWindow
{
	//Add the File Transfer Progress window menuItem
	menuItem_showFileTransferProgress = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Show File Transfer Progress",nil)
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

#pragma mark Preferences
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	autoAcceptType = [[prefDict objectForKey:KEY_FT_AUTO_ACCEPT] intValue];
	autoOpenSafe = [[prefDict objectForKey:KEY_FT_AUTO_OPEN_SAFE] boolValue];
	autoClearCompletedTransfers = [[prefDict objectForKey:KEY_FT_AUTO_CLEAR_COMPLETED] boolValue];
	
	//If we created a safe file extensions set and no longer need it, desroy it
	if(!autoOpenSafe && safeFileExtensions){
		[safeFileExtensions release]; safeFileExtensions = nil;
	}
	
	showProgressWindow = [[prefDict objectForKey:KEY_FT_SHOW_PROGRESS_WINDOW] boolValue];
}

#pragma mark AIEventHandler

- (NSString *)shortDescriptionForEventID:(NSString *)eventID { return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:FILE_TRANSFER_REQUEST]){
		description = AILocalizedString(@"File transfer requested",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_BEGAN]){
		description = AILocalizedString(@"File transfer begins",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_CANCELED]){
		description = AILocalizedString(@"File transfer canceled by the other side",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_COMPLETE]){
		description = AILocalizedString(@"File transfer completed successfully",nil);
	}else{		
		description = @"";	
	}
	
	return(description);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:FILE_TRANSFER_REQUEST]){
		description = @"File Transfer Request";
	}else if([eventID isEqualToString:FILE_TRANSFER_BEGAN]){
		description = @"File Transfer Began";
	}else if([eventID isEqualToString:FILE_TRANSFER_CANCELED]){
		description = @"File Transfer Canceled Remotely";
	}else if([eventID isEqualToString:FILE_TRANSFER_COMPLETE]){
		description = @"File Transfer Complete";
	}else{		
		description = @"";	
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{	
	NSString	*description;
	
	if([eventID isEqualToString:FILE_TRANSFER_REQUEST]){
		description = AILocalizedString(@"When a file transfer is requested",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_BEGAN]){
		description = AILocalizedString(@"When a file transfer begins",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_CANCELED]){
		description = AILocalizedString(@"When a file transfer is canceled remotely",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_COMPLETE]){
		description = AILocalizedString(@"When a file transfer is completed successfully",nil);
	}else{		
		description = @"";	
	}

	return(description);
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	NSString		*displayName, *remoteFilename;
	ESFileTransfer	*fileTransfer;

	NSParameterAssert([userInfo isKindOfClass:[ESFileTransfer class]]);
	fileTransfer = (ESFileTransfer *)userInfo;
	
	displayName = [listObject displayName];
	remoteFilename = [fileTransfer remoteFilename];
	
	if(includeSubject){
		NSString	*format = nil;
		
		if([eventID isEqualToString:FILE_TRANSFER_REQUEST]){
			//Should only happen for an incoming transfer
			format = AILocalizedString(@"%@ requests to send you %@",nil);
			
		}else if([eventID isEqualToString:FILE_TRANSFER_BEGAN]){
			if([fileTransfer type] == Incoming_FileTransfer){
				format = AILocalizedString(@"%@ began sending you %@",nil);
			}else{
				format = AILocalizedString(@"%@ began receiving %@",nil);	
			}
		}else if([eventID isEqualToString:FILE_TRANSFER_CANCELED]){
			format = AILocalizedString(@"%@ canceled the transfer of %@",nil);
		}else if([eventID isEqualToString:FILE_TRANSFER_COMPLETE]){
			if([fileTransfer type] == Incoming_FileTransfer){
				format = AILocalizedString(@"%@ sent you %@",nil);
			}else{
				format = AILocalizedString(@"%@ received %@",nil);	
			}
		}
		
		if(format){
			description = [NSString stringWithFormat:format,displayName,remoteFilename];
		}
	}else{
		NSString	*format = nil;
		
		if([eventID isEqualToString:FILE_TRANSFER_REQUEST]){
			//Should only happen for an incoming transfer
			format = AILocalizedString(@"requests to send you %@",nil);
			
		}else if([eventID isEqualToString:FILE_TRANSFER_BEGAN]){
			if([fileTransfer type] == Incoming_FileTransfer){
				format = AILocalizedString(@"began sending you %@",nil);
			}else{
				format = AILocalizedString(@"began receiving %@",nil);	
			}
		}else if([eventID isEqualToString:FILE_TRANSFER_CANCELED]){
			format = AILocalizedString(@"canceled the transfer of %@",nil);
		}else if([eventID isEqualToString:FILE_TRANSFER_COMPLETE]){
			if([fileTransfer type] == Incoming_FileTransfer){
				format = AILocalizedString(@"sent you %@",nil);
			}else{
				format = AILocalizedString(@"received %@",nil);	
			}
		}
		
		if(format){
			description = [NSString stringWithFormat:format,remoteFilename];
		}		
	}

	return(description);
}

@end
