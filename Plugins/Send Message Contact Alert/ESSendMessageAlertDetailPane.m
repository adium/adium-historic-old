//
//  ESSendMessageContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//

#import "ESSendMessageAlertDetailPane.h"
#import "ESSendMessageContactAlertPlugin.h"

@interface ESSendMessageAlertDetailPane (PRIVATE)
- (void)setDestinationListObject:(AIListObject *)inObject;
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
	NSString		*destUniqueID;
	AIListContact	*destContact = nil;

	//Attempt to find the destination object
	destUniqueID = [inDetails objectForKey:KEY_MESSAGE_SEND_TO];
	if(destUniqueID) destContact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:destUniqueID];

	//Configure the destination menu
	[popUp_messageTo setMenu:[[adium contactController] menuOfAllContactsInGroup:nil withTarget:self]];
	[self setDestinationListObject:(destContact ? destContact : inObject)];
	
	//Configure the remaining controls
	AIAccount *sourceAccount = [[adium accountController] accountWithObjectID:[inDetails objectForKey:KEY_MESSAGE_SEND_FROM]];
	if(sourceAccount){
		[popUp_messageFrom selectItemWithRepresentedObject:sourceAccount];
	}
	NSAttributedString  *messageText = [NSAttributedString stringWithData:[inDetails objectForKey:KEY_MESSAGE_SEND_MESSAGE]];
	if(messageText){
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
	[self setDestinationListObject:[sender representedObject]];	
}

//Set our destination contact
- (void)setDestinationContact:(AIListContact *)inContact
{
	if(inContact != toContact){
		[toContact release]; toContact = [inContact retain];
		[popUp_messageTo setTitle:[toContact displayName]];
		
		//Update 'from' menu
		[popUp_messageFrom setMenu:[[adium accountController] menuOfAccountsForSendingContentType:CONTENT_MESSAGE_TYPE
																						toContact:toContact
																					   withTarget:self
																				   includeOffline:YES]];

		//Select preferred account
		AIAccount	*preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
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
