//
//  ESFileTransferController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//  $Id$

#import "ESFileTransferController.h"

#define SEND_FILE_TO_CONTACT	AILocalizedString(@"Send File To %@",nil)
#define SEND_FILE				AILocalizedString(@"Send File",nil)
#define CONTACT					AILocalizedString(@"Contact",nil)

#define	SEND_FILE_IDENTIFIER	@"SendFile"

@implementation ESFileTransferController
//init and close
- (void)initController
{
    //Install the Get Info menu item
	sendFileMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,CONTACT]
												  target:self action:@selector(sendFileToSelectedContact:)
										   keyEquivalent:@"F"];
	[sendFileMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
	[[owner menuController] addMenuItem:sendFileMenuItem toLocation:LOC_Contact_Action];
	
    //Add our get info contextual menu item
    sendFileContextMenuItem = [[NSMenuItem alloc] initWithTitle:SEND_FILE
														 target:self action:@selector(contextualMenuSendFile:)
												  keyEquivalent:@""];
	[[owner menuController] addContextualMenuItem:sendFileContextMenuItem toLocation:Context_Contact_Action];
	
	//Register the events we generate
	[[owner contactAlertsController] registerEventID:FILE_TRANSFER_REQUEST withHandler:self globalOnly:YES];
	[[owner contactAlertsController] registerEventID:FILE_TRANSFER_BEGAN withHandler:self globalOnly:YES];
	[[owner contactAlertsController] registerEventID:FILE_TRANSFER_CANCELED withHandler:self globalOnly:YES];
	[[owner contactAlertsController] registerEventID:FILE_TRANSFER_COMPLETE withHandler:self globalOnly:YES];
	
	//Add our toolbar item
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
    [[owner toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

- (void)closeController
{
    
}

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer
{
	NSSavePanel		*savePanel = [NSSavePanel savePanel];	
	NSString		*defaultName = [fileTransfer remoteFilename];
	
	[savePanel setTitle:[NSString stringWithFormat:@"Receive File from %@",[[fileTransfer contact] displayName]]];

	[[owner contactAlertsController] generateEvent:FILE_TRANSFER_REQUEST
									 forListObject:[fileTransfer contact] 
										  userInfo:fileTransfer];
	
	if ([savePanel runModalForDirectory:nil file:defaultName] == NSFileHandlingPanelOKButton) {
		[fileTransfer setLocalFilename:[savePanel filename]];
		[(AIAccount<AIAccount_Files> *)[fileTransfer account] acceptFileTransferRequest:fileTransfer];
	} else {
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

- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact
{
	AIAccount *account = [[owner accountController] preferredAccountForSendingContentType:FILE_TRANSFER_TYPE
																				toContact:listContact];
	if (account) {

		//Set up a fileTransfer object
		ESFileTransfer *fileTransfer = [ESFileTransfer fileTransferWithContact:listContact
																	forAccount:account];
		[fileTransfer setLocalFilename:inFile];
		[fileTransfer setType:Outgoing_FileTransfer];
		
		//The fileTransfer object should now have everything the account needs to begin transferring
		[(AIAccount<AIAccount_Files> *)account beginSendOfFileTransfer:fileTransfer];
	}
}

- (void)beganFileTransfer:(ESFileTransfer *)fileTransfer
{
    NSLog(@"began a file transfer...");
	[[owner contactAlertsController] generateEvent:FILE_TRANSFER_BEGAN
									 forListObject:[fileTransfer contact] 
										  userInfo:fileTransfer];
}

- (void)transferCanceledRemotely:(ESFileTransfer *)fileTransfer
{
	[[owner contactAlertsController] generateEvent:FILE_TRANSFER_CANCELED
									 forListObject:[fileTransfer contact] 
										  userInfo:fileTransfer];
	
	[self transferCanceled:fileTransfer];
}

- (void)transferCanceled:(ESFileTransfer *)fileTransfer
{
    NSLog(@"canceled a file transfer...");	
}

- (void)transferComplete:(ESFileTransfer *)fileTransfer
{
	AILog(@"Transfer complete!");
	NSLog(@"Transfer complete!");

	[[owner contactAlertsController] generateEvent:FILE_TRANSFER_COMPLETE
									 forListObject:[fileTransfer contact] 
										  userInfo:fileTransfer];
}
//Menu or context menu item for sending a file was selected - possible only when a listContact is selected
- (IBAction)sendFileToSelectedContact:(id)sender
{
	//Get the "selected" list object (contact list or message window)
	AIListObject	*selectedObject;
	AIListContact   *listContact = nil;
	
	selectedObject = [[owner contactController] selectedListObject];
	if ([selectedObject isKindOfClass:[AIListContact class]]){
		listContact = [[owner contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}
	
	if(listContact){
		[self requestForSendingFileToListContact:listContact];
	}
}
//Prompt for a new contact with the current tab's name
- (IBAction)contextualMenuSendFile:(id)sender
{
	AIListObject	*selectedObject = [[owner menuController] contactualMenuContact];
	AIListContact   *listContact = [[owner contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																			  forListContact:(AIListContact *)selectedObject];
	
	[NSApp activateIgnoringOtherApps:YES];
	[self requestForSendingFileToListContact:listContact];
}

/*
- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSDictionary		*objects = [inToolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];
	
    BOOL			enabled = (object && [object isKindOfClass:[AIListContact class]]);
	
    [inToolbarItem setEnabled:enabled];
	//    return(enabled);
    return(YES);
}
*/

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListContact   *listContact = nil;
	
    if(menuItem == sendFileMenuItem){
        AIListObject	*selectedObject = [[owner contactController] selectedListObject];
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
			listContact = [[owner contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		[menuItem setTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,(listContact ? [selectedObject displayName] : CONTACT)]];

	}else if(menuItem == sendFileContextMenuItem){
		AIListObject	*selectedObject = [[owner menuController] contactualMenuContact];
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
			listContact = [[owner contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
    }
	
    return(listContact != nil);
}

#warning Evan: Why is this not getting called? (And do we want it to be?)
- (BOOL)validateToolBarItem:(NSToolbarItem *)theItem
{
	AIListContact   *listContact = nil;
	
	AIListObject	*selectedObject = [[owner contactController] selectedListObject];
	if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
		listContact = [[owner contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}
	NSLog(@"validating %@ gives %@",theItem,listContact);
    return(listContact != nil);
}

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
