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
#import "AIStatusController.h"
#import "ESGaimJabberAccount.h"
#import "ESGaimJabberAccountViewController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#include <Libgaim/buddy.h>
#include <Libgaim/presence.h>
#include <Libgaim/si.h>

#define DEFAULT_JABBER_HOST @"jabber.org"

@implementation ESGaimJabberAccount

/*!
* @brief The UID will be changed. The account has a chance to perform modifications
 *
 * Upgrade old Jabber accounts stored with the host in a separate key to have the right UID, in the form
 * name@server.org
 *
 * Append @jabber.org to a proposed UID which has no domain name and does not need to be updated.
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	NSString	*correctUID;
	
	if((proposedUID && ([proposedUID length] > 0)) && 
	   ([proposedUID rangeOfString:@"@"].location == NSNotFound)){
		
		NSString	*host;
		//Upgrade code: grab a previously specified Jabber host
		if(host = [self preferenceForKey:@"Jabber:Host" group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES]){
			//Determine our new, full UID
			correctUID = [NSString stringWithFormat:@"%@@%@",proposedUID, host];

			//Clear the preference and then set the UID so we don't perform this upgrade again
			[self setPreference:nil forKey:@"Jabber:Host" group:GROUP_ACCOUNT_STATUS];
			[self setPreference:correctUID forKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
			
			/* Save the accounts after the setting of the UID is complete, since we destroyed the information needed
			 * to do it again. */
			[[adium accountController] performSelector:@selector(saveAccounts)
											withObject:nil
											afterDelay:0];
			
		}else{
			//Append @jabber.org to a Jabber account with no server
			correctUID = [NSString stringWithFormat:@"%@@jabber.org",proposedUID];			
		}
	}else{
		correctUID = proposedUID;
	}

	return correctUID;
}

- (const char*)protocolPlugin
{
	[self initSSL];

	static BOOL				didInitJabber = NO;
	if (!didInitJabber) didInitJabber = gaim_init_jabber_plugin();
    return "prpl-jabber";
}

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys){
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	NSString	*connectServer;
	BOOL		forceOldSSL, useTLS, allowPlaintext;
	
	//'Connect via' server (nil by default)
	if ((connectServer = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS])){
		gaim_account_set_string(account, "connect_server", [connectServer UTF8String]);
	}
	
	//Force old SSL usage? (off by default)
	forceOldSSL = [[self preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "old_ssl", forceOldSSL);

	//Allow TLS useage? (on by default)
	useTLS = [[self preferenceForKey:KEY_JABBER_USE_TLS group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "use_tls", useTLS);

	//Allow plaintext authorization over an unencrypted connection? Gaim will prompt if this is NO and is needed.
	allowPlaintext = [[self preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "auth_plain_in_clear", allowPlaintext);
}

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];
	
	NSString	*resource, *userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	/*
	 * Gaim stores the username in the format username@server/resource.  We need to pass it a username in this format
	 * createNewGaimAccount gets called on every connect, so we need to make sure we don't append the information more
	 * than once.
	 * The user should put the username in username@server format, which is common for Jabber. If the user does
	 * not specify the server, use jabber.org.
	 */

	serverAppendedToUID = ([UID rangeOfString:@"@"].location != NSNotFound);

	if (serverAppendedToUID){
		userNameWithHost = UID;
	}else{
		userNameWithHost = [NSString stringWithFormat:@"%@@jabber.org",UID];
	}

	resource = [self preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
	completeUserName = [NSString stringWithFormat:@"%@/%@",userNameWithHost,resource];

	AILog(@"Jabber user name: \"%@\"",completeUserName);
	gaim_account_set_username(account, [completeUserName UTF8String]);
}

/*!
* @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 *
 * Rather than having a separate server field, Jabber uses the servername after the user name.
 * username@server.org
 */
- (NSString *)host
{
	int location = [UID rangeOfString:@"@"].location;
	if((location != NSNotFound) && (location + 1 < [UID length])){
		return [UID substringFromIndex:(location + 1)];
	}else{
		return DEFAULT_JABBER_HOST;
	}
}

#pragma mark Status

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return([AIHTMLDecoder encodeHTML:inAttributedString
							 headers:YES
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:NO
						encodeSpaces:NO
						  imagesPath:nil
				   attachmentsAsText:YES
	  attachmentImagesOnlyForSending:YES
					  simpleTagsOnly:NO
					  bodyBackground:NO]);
}

- (NSString *)_UIDForAddingObject:(AIListContact *)object
{
	NSString	*objectUID = [object UID];
	NSString	*properUID;
	
	if ([objectUID rangeOfString:@"@"].location != NSNotFound){
		properUID = objectUID;
	}else{
		properUID = [NSString stringWithFormat:@"%@@%@",objectUID,[self host]];
	}
	
	return([properUID lowercaseString]);
}

- (NSString *)unknownGroupName {
    return (AILocalizedString(@"Roster","Roster - the Jabber default group"));
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step) {
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data",nil);
			break;			
		case 3:
			return AILocalizedString(@"Authenticating",nil);
			break;
		case 5:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 6:
			return AILocalizedString(@"Authenticating",nil);
			break;
	}
	return nil;
}

- (void)accountConnectionConnected
{
	[super accountConnectionConnected];
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldReconnect = YES;
	
	if (disconnectionError){
		if ([disconnectionError rangeOfString:@"401"].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"Stream Error"].location != NSNotFound){
			shouldReconnect = NO;
		}else if ([disconnectionError rangeOfString:@"requires plaintext authentication over an unencrypted stream"].location != NSNotFound){
			shouldReconnect = NO;			
		}
	}
	
	return shouldReconnect;
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)){
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
		
		return jabber_outgoing_xfer_new(account->gc,destsn);
	}
	
	return nil;
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

#pragma mark Status Messages
- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	if (gaim_account_is_connected(account)){
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		GaimBuddy   *buddy;
		JabberBuddy *jb;
		
		if ((buddy = gaim_find_buddy(account, uidUTF8String)) &&
			(jb = jabber_buddy_find(account->gc->proto_data, uidUTF8String, FALSE))){	
			
			//Retrieve the current status string
			NSString		*statusName = nil;
			NSString		*statusMessage = nil;
			AIStatusType	statusType = ((buddy->uc & UC_UNAVAILABLE) ? AIAwayStatusType : AIAvailableStatusType);
			
			//Get the custom jabber status message if one is set
			const char		*msg = jabber_buddy_get_status_msg(jb);
			if(msg){
				statusMessage = [NSString stringWithUTF8String:msg];
			}else{
				//If no custom status message, use the preset possibilities
				switch(buddy->uc){
					case JABBER_STATE_CHAT:
						statusName = STATUS_NAME_FREE_FOR_CHAT;
						statusMessage = STATUS_DESCRIPTION_FREE_FOR_CHAT;
						break;						
					case JABBER_STATE_XA:
						statusName = STATUS_NAME_EXTENDED_AWAY;
						statusMessage = STATUS_DESCRIPTION_EXTENDED_AWAY;
						break;
						
					case JABBER_STATE_DND:
						statusName = STATUS_NAME_DND;
						statusMessage = STATUS_DESCRIPTION_DND;
						break;
						
				}
			}
			
			[theContact setStatusWithName:statusName
							   statusType:statusType
							statusMessage:(statusMessage ?
										   [[[NSAttributedString alloc] initWithString:statusMessage] autorelease]:
										   nil)
								   notify:NotifyLater];
			
			//Apply the change
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		}
	}
}

- (void)_updateAwayOfContact:(AIListContact *)theContact toAway:(BOOL)newAway
{
	[self updateStatusMessage:theContact];
}

- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data
{
	[self updateStatusMessage:theContact];
}
- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data
{
	[self updateStatusMessage:theContact];	
}

#pragma mark Menu items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if(strcmp(label, "Un-hide From") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Un-hide From %@",nil),[inContact formattedUID]]);
	}if(strcmp(label, "Temporarily Hide From") == 0){
			return([NSString stringWithFormat:AILocalizedString(@"Temporarily Hide From %@",nil),[inContact formattedUID]]);
	}else if(strcmp(label, "Unsubscribe") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Unsubscribe %@",nil),[inContact formattedUID]]);
	}else if(strcmp(label, "(Re-)Request authorization") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]]);
	}
	
	return([super titleForContactMenuLabel:label forContact:inContact]);
}

#pragma mark Multiuser chat

//Multiuser chats come in with just the contact's name as contactName, but we want to actually do it right.
- (oneway void)addUser:(NSString *)contactName toChat:(AIChat *)chat
{
	if (chat){
		NSString	*chatNameWithServer = [chat name];
		NSString	*chatParticipantName = [NSString stringWithFormat:@"%@/%@",chatNameWithServer,contactName];

		AIListContact *contact = [self contactWithUID:chatParticipantName];

		[contact setStatusObject:contactName forKey:@"FormattedUID" notify:YES];
		
		[chat addParticipatingListObject:contact];
		
		GaimDebug (@"Jabber: added user %@ to chat %@",chatParticipantName,chatNameWithServer);
	}	
}

- (oneway void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat
{
	if (chat){
		NSString	*chatNameWithServer = [chat name];
		NSString	*chatParticipantName = [NSString stringWithFormat:@"%@/%@",chatNameWithServer,contactName];
		
		AIListContact *contact = [self contactWithUID:chatParticipantName];
		
		[chat removeParticipatingListObject:contact];
		
		GaimDebug (@"Jabber: removed user %@ to chat %@",chatParticipantName,chatNameWithServer);
	}	
}

#pragma mark Status
/*!
 * @brief Return the gaim status type to be used for a status
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status equivalent
 * @param statusMessage A pointer to the statusMessage.  Set *statusMessage to nil if it should not be used directly for this status.
 *
 * @result The gaim status equivalent
 */
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	NSString		*statusName = [statusState statusName];
	NSString		*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;
	
	switch(statusType){
		case AIAvailableStatusType:
		{
			if(([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) ||
			   ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_FREE_FOR_CHAT] == NSOrderedSame))
				gaimStatusType = "Chatty";
			break;
		}
			
		case AIAwayStatusType:
		{
			if(([statusName isEqualToString:STATUS_NAME_DND]) ||
			   ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_DND] == NSOrderedSame))
				gaimStatusType = "Do Not Disturb";
			else if (([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_EXTENDED_AWAY] == NSOrderedSame))
				gaimStatusType = "Extended Away";
			
			break;
		}
			
		case AIInvisibleStatusType:
			gaimStatusType = "Invisible";
			break;
	}
	
	/* Jabber supports status messages along with the status types, so let our message stay */
	
	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* XXX All Jabber account actions depend upon adiumGaimRequestFields */
	return(nil);
}

@end