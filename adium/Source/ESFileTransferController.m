//
//  ESFileTransferController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//  $Id: ESFileTransferController.m,v 1.8 2004/03/17 04:33:24 evands Exp $

#import "ESFileTransferController.h"

#define SEND_FILE_TO_CONTACT	AILocalizedString(@"Send File To %@...",nil)
#define SEND_FILE				AILocalizedString(@"Send File",nil)
#define CONTACT					AILocalizedString(@"Contact",nil)

@implementation ESFileTransferController
//init and close
- (void)initController
{
    //Install the Get Info menu item
	sendFileMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,CONTACT]
												  target:self action:@selector(menuSendFile:)
										   keyEquivalent:@"F"];
	[sendFileMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
//	[[owner menuController] addMenuItem:sendFileMenuItem toLocation:LOC_Contact_Action];
	
    //Add our get info contextual menu item
    sendFileContextMenuItem = [[NSMenuItem alloc] initWithTitle:SEND_FILE
														 target:self action:@selector(menuSendFile:)
												  keyEquivalent:@""];
//  [[owner menuController] addContextualMenuItem:sendFileContextMenuItem toLocation:Context_Contact_Action];
	
}

- (void)closeController
{
    
}

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:@"Receive File"];
	
	NSString * defaultName = [fileTransfer remoteFilename];
	
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
	[openPanel setTitle:@"Send File"];
	
	if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
		[self sendFile:[openPanel filename] toListContact:listContact];
	}
}

- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact
{
	AIAccount *account = [[owner accountController] preferredAccountForSendingContentType:FILE_TRANSFER_TYPE
																			 toListObject:listContact];
	if (account) {

		//Set up a fileTransfer object
		ESFileTransfer *fileTransfer = [[ESFileTransfer fileTransferWithContact:listContact
																	 forAccount:account] retain];
		[fileTransfer setLocalFilename:inFile];
		[fileTransfer setType:Outgoing_FileTransfer];
		
		//The fileTransfer object should now have everything the account needs to begin transferring
		[(AIAccount<AIAccount_Files> *)account beginSendOfFileTransfer:fileTransfer];
	}
}

- (void)beganFileTransfer:(ESFileTransfer *)fileTransfer
{
    NSLog(@"began a file transfer...");
}

- (void)transferCanceled:(ESFileTransfer *)fileTransfer
{
    NSLog(@"canceled a file transfer...");
}

//Menu or context menu item for sending a file was selected
- (IBAction)menuSendFile:(id)sender
{
	//Get the "selected" list object (that is, the first responder which returns a listObject)
	AIListObject	*object = [[owner contactController] selectedListObject];	
	[self requestForSendingFileToListContact:(AIListContact *)object];
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
    BOOL valid = YES;
	
    if(menuItem == sendFileMenuItem){
        AIListObject	*selectedObject = [[owner contactController] selectedListObject];
		
        if(selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
            [menuItem setTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,[selectedObject displayName]]];
        }else{
            [menuItem setTitle:[NSString stringWithFormat:SEND_FILE_TO_CONTACT,CONTACT]];
            valid = NO;
        }
    }else if(menuItem == sendFileContextMenuItem){
        AIListContact	*selectedContact = [[owner menuController] contactualMenuContact];
        if ( !(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]) )
            valid = NO;
    }
    return(valid);
}

@end
