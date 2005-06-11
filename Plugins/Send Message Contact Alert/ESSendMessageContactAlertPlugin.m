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
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "ESContactAlertsController.h"
#import "ESSendMessageAlertDetailPane.h"
#import "ESSendMessageContactAlertPlugin.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>

#define SEND_MESSAGE_ALERT_SHORT	AILocalizedString(@"Send a message",nil)
#define SEND_MESSAGE_ALERT_LONG		AILocalizedString(@"Send %@ the message \"%@\"",nil)

@interface ESSendMessageContactAlertPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESSendMessageContactAlertPlugin
- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:@"SendMessage" withHandler:self];
    
    attributes = nil;
}

- (void)uninstallPlugin
{
    [attributes release];
}


//Send Message Alert -----------------------------------------------------------------------------------------------------
#pragma mark Send Message Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(SEND_MESSAGE_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString		*messageText = [[NSAttributedString stringWithData:[details objectForKey:KEY_MESSAGE_SEND_MESSAGE]] string];
	NSString		*destUniqueID = [details objectForKey:KEY_MESSAGE_SEND_TO];
	AIListContact	*contact = nil;

	if (destUniqueID) {
		contact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:destUniqueID];
	}
	
	if (contact && messageText) {
		return([NSString stringWithFormat:SEND_MESSAGE_ALERT_LONG, [contact displayName], messageText]);
	} else {
		return(SEND_MESSAGE_ALERT_SHORT);		
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"MessageAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESSendMessageAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	BOOL					success = NO;
	AIAccount				*account;
	NSString				*destUniqueID;
	AIListContact			*contact = nil;
	BOOL					useAnotherAccount;
		
	//Intended source and dest
	account = [[adium accountController] accountWithInternalObjectID:[details objectForKey:KEY_MESSAGE_SEND_FROM]];
	destUniqueID = [details objectForKey:KEY_MESSAGE_SEND_TO];
	if (destUniqueID) contact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:destUniqueID];

	//Message to send and other options
	useAnotherAccount = [[details objectForKey:KEY_MESSAGE_OTHER_ACCOUNT] boolValue];

	//If we have a contact (and not a meta contact), we need to make sure it's the contact for account, or 
	//availableForSendingContentType: will return NO incorrectly.
	//######### The core should really handle this for us. #########
	if ([contact isKindOfClass:[AIMetaContact class]]) {
		contact = [(AIMetaContact *)contact preferredContactWithService:[account service]];
		
	} else if ([contact isKindOfClass:[AIListContact class]]) {
		contact = [[adium contactController] contactWithService:[contact service]
														account:account 
															UID:[contact UID]];
	}
	
	//If the desired account is not available for sending, ask Adium for the best available account
	if (![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE
														toContact:contact
														onAccount:account]) {
		if (useAnotherAccount) {
			account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			 toContact:contact];
			//Repeat the refinement process using the newly retrieved account
			if ([contact isKindOfClass:[AIMetaContact class]]) {
				contact = [(AIMetaContact *)contact preferredContactWithService:[account service]];
				
			} else if ([contact isKindOfClass:[AIListContact class]]) {
				contact = [[adium contactController] contactWithService:[contact service]
																account:account 
																	UID:[contact UID]];
			}
		} else {
			account = nil;
		}
	}
	
	if (account && contact) {
		//Create and open a chat with this contact
		AIChat					*chat;
		NSAttributedString 		*message;
		
		chat = [[adium chatController] openChatWithContact:contact];
		[[adium interfaceController] setActiveChat:chat];
		
		message = [NSAttributedString stringWithData:[details objectForKey:KEY_MESSAGE_SEND_MESSAGE]];
		
		//Prepare the content object we're sending
		AIContentMessage	*content = [AIContentMessage messageInChat:chat
															withSource:account
														   destination:contact
																  date:nil
															   message:message
															 autoreply:NO];
		
		//Send the content
		success = [[adium contentController] sendContentObject:content];
	}
	
	//Display an error message if the message was not delivered
	if (!success && contact) {
        [[adium interfaceController] handleMessage:AILocalizedString(@"Contact Alert Error",nil)
								   withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to send message to %@.",nil), [contact displayName]]
								   withWindowTitle:@""];
	}
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(YES);
}

@end
