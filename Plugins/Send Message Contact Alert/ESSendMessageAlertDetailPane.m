//
//  ESSendMessageContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//

#import "ESSendMessageAlertDetailPane.h"
#import "ESSendMessageContactAlertPlugin.h"

@interface ESSendMessageAlertDetailPane (PRIVATE)
- (void)setDestinationContact:(AIListContact *)inContact;
@end

@implementation ESSendMessageAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"SendMessageContactAlert");    
}

//Configure the detail view
- (void)viewDidLoad
{
	toContact = nil;
}

//
- (void)viewWillClose
{
	[toContact release]; toContact = nil;
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	AIAccount			*sourceAccount;
	NSAttributedString  *messageText;
	NSString			*destUniqueID;
	AIListObject		*destObject = nil;

	//Attempt to find a saved destination object; if none is found, use the one we were passed
	destUniqueID = [inDetails objectForKey:KEY_MESSAGE_SEND_TO];
	if(destUniqueID) destObject = [[adium contactController] existingListObjectWithUniqueID:destUniqueID];
	if(!destObject) destObject = inObject;
		
	//Configure the destination menu
	[popUp_messageTo setMenu:[[adium contactController] menuOfAllContactsInContainingObject:nil withTarget:self]];
	
	if (destObject && [destObject isKindOfClass:[AIListContact class]]){
		[self setDestinationContact:(AIListContact *)destObject];
	}else{
		[self setDestinationContact:nil];
	}
	
	//Configure the remaining controls
	if(sourceAccount = [[adium accountController] accountWithAccountNumber:[[inDetails objectForKey:KEY_MESSAGE_SEND_FROM] intValue]]){
		[popUp_messageFrom selectItemWithRepresentedObject:sourceAccount];
	}
	
	if(messageText = [NSAttributedString stringWithData:[inDetails objectForKey:KEY_MESSAGE_SEND_MESSAGE]]){
		[[textView_message textStorage] setAttributedString:messageText];
	}else{
		[textView_message setString:@""];
	}

	[button_useAnotherAccount setState:[[inDetails objectForKey:KEY_MESSAGE_OTHER_ACCOUNT] boolValue]];
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	return([NSDictionary dictionaryWithObjectsAndKeys:
		[toContact internalObjectID], KEY_MESSAGE_SEND_TO,
		[[[popUp_messageFrom selectedItem] representedObject] internalObjectID], KEY_MESSAGE_SEND_FROM,
		[NSNumber numberWithBool:[button_useAnotherAccount state]], KEY_MESSAGE_OTHER_ACCOUNT,
		[[textView_message textStorage] dataRepresentation], KEY_MESSAGE_SEND_MESSAGE,
		nil]);
}

//Destination contact was selected from menu
- (void)selectContact:(id)sender
{
	AIListObject *listObject;

	if ((listObject = [sender representedObject]) &&
		[listObject isKindOfClass:[AIListContact class]]){
		[self setDestinationContact:(AIListContact *)listObject];
	}
}

//Set our destination contact
- (void)setDestinationContact:(AIListContact *)inContact
{
	if(inContact != toContact){
		NSMenuItem	*firstMenuItem;
		AIAccount	*preferredAccount;
		
		[toContact release]; toContact = [inContact retain];
		
		//NSPopUpButton doesn't handle submenus well at all. We put a blank menu item at the top of our
		//menu when we created it. We can now change its attributes to affect the way the unclicked button
		//displays.
		firstMenuItem = (NSMenuItem *)[[popUp_messageTo menu] itemAtIndex:0];
		[firstMenuItem setTitle:([toContact isKindOfClass:[AIMetaContact class]] ?
								 [toContact displayName] :
								 [toContact formattedUID])];
		[firstMenuItem setImage:[AIUserIcons menuUserIconForObject:toContact]];
		[popUp_messageTo selectItemAtIndex:0];
		
		//Update 'from' menu
		[popUp_messageFrom setMenu:[[adium accountController] menuOfAccountsForSendingContentType:CONTENT_MESSAGE_TYPE
																					 toListObject:toContact
																					   withTarget:self
																				   includeOffline:YES]];

		//Select preferred account
		preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																							   toContact:toContact];
		if(preferredAccount) [popUp_messageFrom selectItemWithRepresentedObject:preferredAccount];

	}
}

//Source account was selected from menu
- (void)selectAccount:(id)sender
{
	//Empty
}

@end
