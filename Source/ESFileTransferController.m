//
//  ESFileTransferController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//  $Id$

#import "ESFileTransferController.h"
#import "ESFileTransferProgressWindowController.h"

#define SEND_FILE_TO_CONTACT		AILocalizedString(@"Send File To %@",nil)
#define SEND_FILE					AILocalizedString(@"Send File",nil)
#define CONTACT						AILocalizedString(@"Contact",nil)

#define	SEND_FILE_IDENTIFIER		@"SendFile"

#define	PREF_GROUP_FILE_TRANSFER	@"FileTransfer"
#define	FILE_TRANSFER_DEFAULT_PREFS	@"FileTransferPrefs"

@interface ESFileTransferController (PRIVATE)
- (void)configureFileTransferProgressWindow;
- (void)showFileTransferProgress:(id)sender;
- (NSString *)userPreferredDownloadFolder;
@end

@implementation ESFileTransferController
//init and close
- (void)initController
{
	fileTransferArray = [[NSMutableArray alloc] init];
	
    //Install the Send File menu item
	menuItem_sendFile = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,CONTACT]
												  target:self action:@selector(sendFileToSelectedContact:)
										   keyEquivalent:@"F"];
	[menuItem_sendFile setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
	[[adium menuController] addMenuItem:menuItem_sendFile toLocation:LOC_Contact_Action];
	
    //Add our get info contextual menu item
    menuItem_sendFileContext = [[NSMenuItem alloc] initWithTitle:SEND_FILE
														 target:self action:@selector(contextualMenuSendFile:)
												  keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_sendFileContext toLocation:Context_Contact_Action];
	
	//Register the events we generate
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_REQUEST withHandler:self globalOnly:YES];
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_BEGAN withHandler:self globalOnly:YES];
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_CANCELED withHandler:self globalOnly:YES];
	[[adium contactAlertsController] registerEventID:FILE_TRANSFER_COMPLETE withHandler:self globalOnly:YES];
	
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
//	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
	
	[self configureFileTransferProgressWindow];
}

- (void)closeController
{
    
}

#pragma mark Access to file transfer objects
- (ESFileTransfer *)newFileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount
{
	ESFileTransfer *fileTransfer;
	
	fileTransfer = [ESFileTransfer fileTransferWithContact:inContact
												forAccount:inAccount];
	[fileTransferArray addObject:fileTransfer];
	[fileTransfer setStatus:Not_Started_FileTransfer];
	
	[[adium notificationCenter] postNotificationName:FileTransfer_NewFileTransfer object:fileTransfer];
	
	return(fileTransfer);
}

- (NSArray *)fileTransferArray
{
	return(fileTransferArray);
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
										  userInfo:fileTransfer];
#warning PREFERENCE
	if(TRUE /* (Autoaccept all transfers) || ((autoAccept transfers contacts on list) && (![listContact isStranger]))*/){
		localFilename = [[self userPreferredDownloadFolder] stringByAppendingPathComponent:defaultName];
	}else{
		NSSavePanel		*savePanel = [NSSavePanel savePanel];

		[savePanel setTitle:[NSString stringWithFormat:@"Receive File from %@",[[fileTransfer contact] displayName]]];

		if([savePanel runModalForDirectory:[self userPreferredDownloadFolder]
									  file:defaultName] == NSFileHandlingPanelOKButton) {
	
			localFilename = [savePanel filename];
		}
	}

	if(localFilename){
		[fileTransfer setLocalFilename:localFilename];
		[(AIAccount<AIAccount_Files> *)[fileTransfer account] acceptFileTransferRequest:fileTransfer];

		[self showFileTransferProgress:nil];

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
		
		[self showFileTransferProgress:nil];
	}
}

#pragma mark Status updates
- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(FileTransferStatus)status
{
	switch(status){
		case Accepted_FileTransfer:
		{
			AILog(@"accepted a file transfer...");
			NSLog(@"accepted a file transfer...");
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_BEGAN
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer];
			
			[self showFileTransferProgress:nil];
			break;
		}
		case Complete_FileTransfer:
		{		
			AILog(@"Transfer complete!");
			NSLog(@"Transfer complete!");
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_COMPLETE
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer];
			break;
		}
		case Canceled_Remote_FileTransfer:
		{
			[[adium contactAlertsController] generateEvent:FILE_TRANSFER_CANCELED
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer];
			break;
		}
		default:
			break;
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
	AIListObject	*selectedObject = [[adium menuController] contactualMenuContact];
	AIListContact   *listContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																			  forListContact:(AIListContact *)selectedObject];
	
	[NSApp activateIgnoringOtherApps:YES];
	[self requestForSendingFileToListContact:listContact];
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
		AIListObject	*selectedObject = [[adium menuController] contactualMenuContact];
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
																   action:@selector(showFileTransferProgress:)
															keyEquivalent:@"L"];
	[menuItem_showFileTransferProgress setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask | NSShiftKeyMask)];
	[[adium menuController] addMenuItem:menuItem_showFileTransferProgress toLocation:LOC_Window_Auxiliary];
	
	//Add the toolbar buttons for the window	
/*
	[self addFTProgressToolbarItemWithIdentifier:@"FTProgressPause"
										   label:AILocalizedString(@"Pause",nil)
									paletteLabel:AILocalizedString(@"Pause / Resume",nil)
										 toolTip:AILocalizedString(@"Pause / Resume",nil)
									  imageNamed:@"pause"
										  action:@selector(pauseOrResume:)];
*/
}

//Show the file transfer progress window
- (void)showFileTransferProgress:(id)sender
{
	[ESFileTransferProgressWindowController showFileTransferProgressWindow];
}

//Do we even need toolbar buttons in a window like this?
- (void)addFTProgressToolbarItemWithIdentifier:(NSString *)identifier
										 label:(NSString *)label
								  paletteLabel:(NSString *)paletteLabel
									   toolTip:(NSString *)toolTip
									imageNamed:(NSString *)imageName
										action:(SEL)action
{
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:identifier
														  label:label
												   paletteLabel:paletteLabel
														toolTip:toolTip
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:imageName forClass:[self class]]
														 action:action
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"FTProgress"];
}

#pragma mark Default download location

- (NSString *) userPreferredDownloadFolder {
	OSStatus err = noErr;
	ICInstance inst = NULL;
	ICFileSpec folder;
	unsigned long length = kICFileSpecHeaderSize;
	FSRef ref;
	unsigned char path[1024];
	
	memset( path, 0, 1024 ); //clear path's memory range
	
	if( ( err = ICStart( &inst, 'AdiM' ) ) != noErr )
		goto finish;
	
	ICGetPref( inst, kICDownloadFolder, NULL, &folder, &length );
	ICStop( inst );
	
	if( ( err = FSpMakeFSRef( &folder.fss, &ref ) ) != noErr )
		goto finish;
	
	if( ( err = FSRefMakePath( &ref, path, 1024 ) ) != noErr )
		goto finish;
	
finish:
		
	if( ! strlen( path ) )
		return [@"~/Desktop" stringByExpandingTildeInPath];
	
	return [NSString stringWithUTF8String:path];
}

- (void) setUserPreferredDownloadFolder:(NSString *) path {
	OSStatus err = noErr;
	ICInstance inst = NULL;
	ICFileSpec *dir = NULL;
	FSRef ref;
	AliasHandle alias;
	unsigned long length = 0;
	
	if( ( err = FSPathMakeRef( [path UTF8String], &ref, NULL ) ) != noErr )
		return;
	
	if( ( err = FSNewAliasMinimal( &ref, &alias ) ) != noErr )
 		return;
	
	length = ( kICFileSpecHeaderSize + GetHandleSize( (Handle) alias ) );
	dir = malloc( length );
	memset( dir, 0, length );
	
	if( ( err = FSGetCatalogInfo( &ref, kFSCatInfoNone, NULL, NULL, &dir -> fss, NULL ) ) != noErr )
		return;
	
	memcpy( &dir -> alias, *alias, length - kICFileSpecHeaderSize );
	
	if( ( err = ICStart( &inst, 'AdiM' ) ) != noErr )
		return;
	
	ICSetPref( inst, kICDownloadFolder, NULL, dir, length );
	ICStop( inst );
	
	free( dir );
	DisposeHandle( (Handle) alias );
}

#pragma mark AIEventHandler

- (NSString *)shortDescriptionForEventID:(NSString *)eventID { return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:FILE_TRANSFER_REQUEST]){
		description = AILocalizedString(@"File Transfer Request",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_BEGAN]){
		description = AILocalizedString(@"File Transfer Began",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_CANCELED]){
		description = AILocalizedString(@"File Transfer Canceled Remotely",nil);
	}else if([eventID isEqualToString:FILE_TRANSFER_COMPLETE]){
		description = AILocalizedString(@"File Transfer Complete",nil);
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

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject { return @""; }

@end
