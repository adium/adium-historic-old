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
#import "ESSendMessageAlertDetailPane.h"
#import "ESSendMessageContactAlertPlugin.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIUserIcons.h>

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
	
	[label_To setStringValue:AILocalizedString(@"To:",nil)];
	[label_From setStringValue:AILocalizedString(@"From:",nil)];	
	[label_Message setStringValue:AILocalizedString(@"Message:",nil)];

	[button_useAnotherAccount setTitle:AILocalizedString(@"Use another account if necessary",nil)];
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
	if(sourceAccount = [[adium accountController] accountWithInternalObjectID:[inDetails objectForKey:KEY_MESSAGE_SEND_FROM]]){
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
		
		[self detailsForHeaderChanged];
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
