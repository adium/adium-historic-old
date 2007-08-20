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

#import "CBPurpleAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIWindowController.h>
#import <Adium/AIEmoticon.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AISystemNetworkDefaults.h>
#import "ESiTunesPlugin.h"
#import "AMPurpleTuneTooltip.h"

#import "adiumPurpleRequest.h"

#import "ESMSNService.h" //why oh why must the superclass know about MSN specific things!?

#define NO_GROUP						@"__NoGroup__"

#define AUTO_RECONNECT_DELAY		2.0	//Delay in seconds
#define RECONNECTION_ATTEMPTS		4

#define	PREF_GROUP_ALIASES			@"Aliases"		//Preference group to store aliases in
#define NEW_ACCOUNT_DISPLAY_TEXT		AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

@interface CBPurpleAccount (PRIVATE)
- (NSString *)_mapIncomingGroupName:(NSString *)name;
- (NSString *)_mapOutgoingGroupName:(NSString *)name;

- (void)setTypingFlagOfChat:(AIChat *)inChat to:(NSNumber *)typingState;

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date;
- (void)_sentMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat toDestinationListContact:(AIListContact *)destinationContact flags:(PurpleMessageFlags)flags date:(NSDate *)date;
- (NSString *)_messageImageCachePathForID:(int)imageID;

- (ESFileTransfer *)createFileTransferObjectForXfer:(PurpleXfer *)xfer;

- (void)displayError:(NSString *)errorDesc;
- (NSNumber *)shouldCheckMail;

- (void)configurePurpleAccountNotifyingTarget:(id)target selector:(SEL)selector;
- (void)continueConnectWithConfiguredPurpleAccount;
- (void)continueConnectWithConfiguredProxy;
- (void)continueRegisterWithConfiguredPurpleAccount;

- (void)setAccountProfileTo:(NSAttributedString *)profile configurePurpleAccountContext:(NSInvocation *)inInvocation;

- (void)performAccountMenuAction:(NSMenuItem *)sender;
@end

@implementation CBPurpleAccount

static SLPurpleCocoaAdapter *purpleThread = nil;

// The PurpleAccount currently associated with this Adium account
- (PurpleAccount*)purpleAccount
{
	//Create a purple account if one does not already exist
	if (!account) {
		[self createNewPurpleAccount];
		AILog(@"%x: created PurpleAccount 0x%x with UID %@, protocolPlugin %s", [NSRunLoop currentRunLoop],account, [self UID], [self protocolPlugin]);
	}
	
    return account;
}

- (SLPurpleCocoaAdapter *)purpleThread
{
	return purpleThread;
}

// Subclasses must override this
- (const char*)protocolPlugin { return NULL; }

// Contacts ------------------------------------------------------------------------------------------------
#pragma mark Contacts
- (void)newContact:(AIListContact *)theContact withName:(NSString *)inName
{

}

- (void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName contactName:(NSString *)contactName
{
	//A quick sign on/sign off can leave these messages in the threaded messaging queue... we most definitely don't want
	//to put the contact back into a remote group after signing off, as a ghost will appear. Spooky!
	if ([self online] || [self integerStatusObjectForKey:@"Connecting"]) {
		//When a new contact is created, if we aren't already silent and delayed, set it  a second to cover our initial
		//status updates
		if (!silentAndDelayed) {
			[self silenceAllContactUpdatesForInterval:2.0];
			[[adium contactController] delayListObjectNotificationsUntilInactivity];		
		}

		//If the name we were passed differs from the current formatted UID of the contact, it's itself a formatted UID
		//This is important since we may get an alias ("Evan Schoenberg") from the server but also want the formatted name
		if (![contactName isEqualToString:[theContact formattedUID]] && ![contactName isEqualToString:[theContact UID]]) {
			[theContact setStatusObject:contactName
								 forKey:@"FormattedUID"
								 notify:NotifyLater];
		}

		if (groupName && [groupName isEqualToString:@PURPLE_ORPHANS_GROUP_NAME]) {
			[theContact setRemoteGroupName:AILocalizedString(@"Orphans","Name for the orphans group")];
		} else if (groupName && [groupName length] != 0) {
			[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
		} else {
			AILog(@"Got a nil group for %@",theContact);
		}
		
		[self gotGroupForContact:theContact];
	} else {
		AILog(@"Got %@ for %@ while not online",groupName,theContact);
	}
}

/*!
 * @brief Change the UID of a contact
 *
 * If we're just passed a formatted version of the current UID, don't change the UID but instead use the information
 * as the FormattedUID.  For example, we get sent this when an AIM contact's name formatting changes; we always want
 * to use a lowercase and space-free version for the UID, however.
 */
- (void)renameContact:(AIListContact *)theContact toUID:(NSString *)newUID
{
	//If the name we were passed differs from the current formatted UID of the contact, it's itself a formatted UID
	//This is important since we may get an alias ("Evan Schoenberg") from the server but also want the formatted name
	NSString	*filteredUID = [[self service] filterUID:newUID removeIgnoredCharacters:YES];
	
	if ([filteredUID isEqualToString:[theContact UID]]) {
		[theContact setStatusObject:newUID
							 forKey:@"FormattedUID"
							 notify:NotifyLater];		
	} else {
		[theContact setUID:newUID];		
	}
}

- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)purpleAlias
{
	if (![[purpleAlias compactedString] isEqualToString:[[theContact UID] compactedString]]) {
		//Store this alias as the serverside display name so long as it isn't identical when unformatted to the UID
		[theContact setServersideAlias:purpleAlias
					   asStatusMessage:[self useDisplayNameAsStatusMessage]
							  silently:silentAndDelayed];

	} else {
		//If it's the same characters as the UID, apply it as a formatted UID
		if (![purpleAlias isEqualToString:[theContact formattedUID]] && 
			![purpleAlias isEqualToString:[theContact UID]]) {
			[theContact setFormattedUID:purpleAlias
								 notify:NotifyLater];

			//Apply any changes
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		}
	}
}

- (BOOL)useDisplayNameAsStatusMessage
{
	return NO;
}

- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
}		


//Signed online
- (void)updateSignon:(AIListContact *)theContact withData:(void *)data
{
	[theContact setOnline:YES
				   notify:NotifyLater
				 silently:silentAndDelayed];

	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

//Signed offline
- (void)updateSignoff:(AIListContact *)theContact withData:(void *)data
{
	[theContact setOnline:NO
				   notify:NotifyLater
				 silently:silentAndDelayed];
	
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

//Signon Time
- (void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate
{	
	[theContact setSignonDate:signonDate
					   notify:NotifyLater];
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

/*!
 * @brief Status name to use for a Purple buddy
 */
- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	return nil;
}

/*!
 * @brief Status message for a contact
 */
- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)buddy
{
	PurplePresence		*presence = purple_buddy_get_presence(buddy);
	PurpleStatus		*status = (presence ? purple_presence_get_active_status(presence) : NULL);
	const char			*message = (status ? purple_status_get_attr_string(status, "message") : NULL);
	
	return (message ? [AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String:message]] : nil);
}

/*!
 * @brief Update the status message and away state of the contact
 */
- (void)updateStatusForContact:(AIListContact *)theContact toStatusType:(NSNumber *)statusTypeNumber statusName:(NSString *)statusName statusMessage:(NSAttributedString *)statusMessage
{
	[theContact setStatusWithName:statusName
					   statusType:[statusTypeNumber intValue]
						   notify:NotifyLater];
	[theContact setStatusMessage:statusMessage
						  notify:NotifyLater];
	
	//Apply the change
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

//Idle time
- (void)updateWentIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate
{
	[theContact setIdle:YES sinceDate:idleSinceDate notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}
- (void)updateIdleReturn:(AIListContact *)theContact withData:(void *)data
{
	[theContact setIdle:NO
			  sinceDate:nil
				 notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}
	
//Evil level (warning level)
- (void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber
{
	[theContact setWarningLevel:[evilNumber intValue]
						 notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}   

//Buddy Icon
- (void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData
{
	[theContact setServersideIconData:userIconData
							   notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)updateMobileStatus:(AIListContact *)theContact withData:(BOOL)isMobile
{
	[theContact setIsMobile:isMobile notify:NotifyLater];

	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (NSString *)processedIncomingUserInfo:(NSString *)inString
{
	NSMutableString *returnString = nil;
	if ([inString rangeOfString:@"Purple could not find any information in the user's profile. The user most likely does not exist."].location != NSNotFound) {
		returnString = [[inString mutableCopy] autorelease];
		[returnString replaceOccurrencesOfString:@"Purple could not find any information in the user's profile. The user most likely does not exist."
									  withString:AILocalizedString(@"Adium could not find any information in the user's profile. This may not be a registered name.", "Message shown when a contact's profile can't be found")
										 options:NSLiteralSearch
										   range:NSMakeRange(0, [returnString length])];
	}
	
	return (returnString ? returnString : inString);
}

- (void)updateUserInfo:(AIListContact *)theContact withData:(PurpleNotifyUserInfo *)user_info
{
	char *user_info_text = purple_notify_user_info_get_text_with_newline(user_info, "<BR />");
	NSMutableString *mutablePurpleUserInfo = (user_info_text ? [NSMutableString stringWithUTF8String:user_info_text] : nil);
	g_free(user_info_text);

	//Libpurple may pass us HTML with embedded </html> tags. Yuck. Don't abort when we hit one in AIHTMLDecoder.
	[mutablePurpleUserInfo replaceOccurrencesOfString:@"</html>"
										 withString:@""
											options:(NSCaseInsensitiveSearch | NSLiteralSearch)
											  range:NSMakeRange(0, [mutablePurpleUserInfo length])];

	NSString	*purpleUserInfo = mutablePurpleUserInfo;
	purpleUserInfo = processPurpleImages(purpleUserInfo, self);
	purpleUserInfo = [self processedIncomingUserInfo:purpleUserInfo];

	[theContact setProfile:[AIHTMLDecoder decodeHTML:purpleUserInfo]
					notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

/*!
 * @brief Purple removed a contact from the local blist
 *
 * This can happen in many situations:
 *	- For every contact on an account when the account signs off
 *	- For a contact as it is deleted by the user
 *	- For a contact as it is deleted by Purple (e.g. when Sametime refuses an addition because it is known to be invalid)
 *	- In the middle of the move process as a contact moves from one group to another
 *
 * We need not take any action; we'll be notified of changes by Purple as necessary.
 */
- (void)removeContact:(AIListContact *)theContact
{

}

//To allow root level buddies on protocols which don't support them, we map any buddies in a group
//named after this account's UID to the root group.  These functions handle the mapping.  Group names should
//be filtered through incoming before being sent to Adium - and group names from Adium should be filtered through
//outgoing before being used.
- (NSString *)_mapIncomingGroupName:(NSString *)name
{
	if (!name || ([[name compactedString] caseInsensitiveCompare:[self UID]] == NSOrderedSame)) {
		return ADIUM_ROOT_GROUP_NAME;
	} else {
		return name;
	}
}
- (NSString *)_mapOutgoingGroupName:(NSString *)name
{
	if ([[name compactedString] caseInsensitiveCompare:ADIUM_ROOT_GROUP_NAME] == NSOrderedSame) {
		return [self UID];
	} else {
		return name;
	}
}

//Update the status of a contact (Request their profile)
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
    //Request profile
	[purpleThread getInfoFor:[inContact UID] onAccount:self];
}

- (void)requestAddContactWithUID:(NSString *)contactUID
{
	[[adium contactController] requestAddContactWithUID:contactUID
												service:[self _serviceForUID:contactUID]
												account:self];
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	return [self service];
}

- (void)gotGroupForContact:(AIListContact *)listContact {};

/*********************/
/* AIAccount_Handles */
/*********************/
#pragma mark Contact List Editing

- (void)removeContacts:(NSArray *)objects
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while ((object = [enumerator nextObject])) {
		NSString	*groupName = [self _mapOutgoingGroupName:[object remoteGroupName]];

		//Have the purple thread perform the serverside actions
		[purpleThread removeUID:[object UID] onAccount:self fromGroup:groupName];
		
		//Remove it from Adium's list
		[object setRemoteGroupName:nil];
	}
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	NSString		*groupName = [self _mapOutgoingGroupName:[group UID]];
	
	while ((object = [enumerator nextObject])) {
		[purpleThread addUID:[self _UIDForAddingObject:object] onAccount:self toGroup:groupName];
		
		//Add it to Adium's list
		[object setRemoteGroupName:[group UID]]; //Use the non-mapped group name locally
	}
}

- (NSString *)_UIDForAddingObject:(AIListContact *)object
{
	return [object UID];
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSString		*groupName = [self _mapOutgoingGroupName:[group UID]];
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	//Move the objects to it
	enumerator = [objects objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([listObject isKindOfClass:[AIListGroup class]]) {
			//Since no protocol here supports nesting, a group move is really a re-name
			
		} else {
			//			NSString	*oldGroupName = [self _mapOutgoingGroupName:[listObject remoteGroupName]];
			
			//Tell the purple thread to perform the serverside operation
			[purpleThread moveUID:[listObject UID] onAccount:self toGroup:groupName];

			//Use the non-mapped group name locally
			[listObject setRemoteGroupName:[group UID]];
		}
	}		
}

- (void)renameGroup:(AIListGroup *)inGroup to:(NSString *)newName
{
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];

	//Tell the purple thread to perform the serverside operation	
	[purpleThread renameGroup:groupName onAccount:self to:newName];

	//We must also update the remote grouping of all our contacts in that group
	NSEnumerator	*enumerator = [[[adium contactController] allContactsInObject:inGroup recurse:YES onAccount:self] objectEnumerator];
	AIListContact	*contact;
	
	while ((contact = [enumerator nextObject])) {
		//Evan: should we use groupName or newName here?
		[contact setRemoteGroupName:newName];
	}
}

- (void)deleteGroup:(AIListGroup *)inGroup
{
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];

	[purpleThread deleteGroup:groupName onAccount:self];
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return [self online];
}

- (id)authorizationRequestWithDict:(NSDictionary*)dict {
	return [[[AIObject sharedAdiumInstance] contactController] showAuthorizationRequestWithDict:dict
																					 forAccount:self];
}

- (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict didAuthorize:(BOOL)inDidAuthorize
{
	id		 callback;
	
	//Inform libpurple that the request window closed
	//[ESPurpleRequestAdapter requestCloseWithHandle:inWindowController];
	if (account) {
		purple_account_request_close(inWindowController);
		
		if (inDidAuthorize) {
			callback = [[[infoDict objectForKey:@"authorizeCB"] retain] autorelease];
		} else {
			callback = [[[infoDict objectForKey:@"denyCB"] retain] autorelease];
		}
		
		[purpleThread doAuthRequestCbValue:callback withUserDataValue:[[[infoDict objectForKey:@"userData"] retain] autorelease]];
	}
}

//Chats ------------------------------------------------------------
#pragma mark Chats

/*!
 * @brief Called by Purple code when a chat should be opened by the interface
 *
 * If the user sent an initial message, this will be triggered and have no effect.
 *
 * If a remote user sent an initial message, however, a chat will be created without being opened.  This call is our
 * cue to actually open chat.
 *
 * Another situation in which this is relevant is when we request joining a group chat; the chat should only be actually
 * opened once the server notifies us that we are in the room.
 *
 * This will ultimately call -[CBPurpleAccount openChat:] below if the chat was not previously open.
 */
- (void)addChat:(AIChat *)chat
{
	//Open the chat
	[[adium interfaceController] openChat:chat]; 
}

//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{
	/* The #if 0'd block below causes crashes in msn_tooltip_text() on MSN */
#if 0
	AIListContact	*listContact;
	
	//Obtain the contact's information if it's a stranger
	if ((listContact = [chat listObject]) && ([listContact isStranger])) {
		[self delayedUpdateContactStatus:listContact];
	}
#endif
	
	AILog(@"purple openChat:%@ for %@",chat,[chat uniqueChatID]);

	//Inform purple that we have opened this chat
	[purpleThread openChat:chat onAccount:self];
	
	//Created the chat successfully
	return YES;
}

- (BOOL)closeChat:(AIChat*)chat
{
	[purpleThread closeChat:chat];
	
	//Be sure any remaining typing flag is cleared as the chat closes
	[self setTypingFlagOfChat:chat to:nil];
	AILog(@"purple closeChat:%@",[chat uniqueChatID]);
	
    return YES;
}

- (AIChat *)chatWithContact:(AIListContact *)contact identifier:(id)identifier
{
	AIChat *chat = [[adium chatController] chatWithContact:contact];
	[chat setIdentifier:identifier];

	return chat;
}


- (AIChat *)chatWithName:(NSString *)name identifier:(id)identifier
{
	return [[adium chatController] chatWithName:name identifier:identifier onAccount:self chatCreationInfo:nil];
}

//Typing update in an IM
- (void)typingUpdateForIMChat:(AIChat *)chat typing:(NSNumber *)typingState
{
	[self setTypingFlagOfChat:chat
						   to:typingState];
}

//Multiuser chat update
- (void)convUpdateForChat:(AIChat *)chat type:(NSNumber *)type
{

}
- (void)updateTopic:(NSString *)inTopic forChat:(AIChat *)chat
{
	
}
- (void)updateTitle:(NSString *)inTitle forChat:(AIChat *)chat
{
	[[chat displayArrayForKey:@"Display Name"] setObject:inTitle
											   withOwner:self];
}

- (void)updateForChat:(AIChat *)chat type:(NSNumber *)type
{
	AIChatUpdateType	updateType = [type intValue];
	NSString			*key = nil;
	switch (updateType) {
		case AIChatTimedOut:
		case AIChatClosedWindow:
			break;
	}
	
	if (key) {
		[chat setStatusObject:[NSNumber numberWithBool:YES] forKey:key notify:NotifyNow];
		[chat setStatusObject:nil forKey:key notify:NotifyNever];
		
	}
}

- (void)errorForChat:(AIChat *)chat type:(NSNumber *)type
{
	[chat receivedError:type];
}

- (void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{
	PurpleMessageFlags		flags = [[messageDict objectForKey:@"PurpleMessageFlags"] intValue];
	
	if ((flags & PURPLE_MESSAGE_SEND) != 0) {
        //Purple is telling us that our message was sent successfully.		

		//We can now tell the other side that we're done typing
		//[purpleThread sendTyping:AINotTyping inChat:chat];
    } else {
		NSAttributedString		*attributedMessage;
		AIListContact			*listContact;
		
		listContact = [chat listObject];

		attributedMessage = [[adium contentController] decodedIncomingMessage:[messageDict objectForKey:@"Message"]
																  fromContact:listContact
																	onAccount:self];
		
		//Clear the typing flag of the chat since a message was just received
		[self setTypingFlagOfChat:chat to:nil];
		
		[self _receivedMessage:attributedMessage
						inChat:chat 
			   fromListContact:listContact
						 flags:flags
						  date:[messageDict objectForKey:@"Date"]];
	}
}

- (void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{	
	PurpleMessageFlags	flags = [[messageDict objectForKey:@"PurpleMessageFlags"] intValue];
	NSAttributedString	*attributedMessage = [messageDict objectForKey:@"AttributedMessage"];;
	NSString			*source = [messageDict objectForKey:@"Source"];

	if (source) {
		[self _receivedMessage:attributedMessage
						inChat:chat 
			   fromListContact:[self contactWithUID:source]
						 flags:flags
						  date:[messageDict objectForKey:@"Date"]];
	} else {
		//If we didn't get a listContact, this is a purple status message... display it as such.
#warning need to translate the type here
		[[adium contentController] displayEvent:[attributedMessage string]
										 ofType:@"purple"
										 inChat:chat];
		
	}
}

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date
{
	AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
														   withSource:sourceContact
														  destination:self
																 date:date
															  message:attributedMessage
															autoreply:(flags & PURPLE_MESSAGE_AUTO_RESP) != 0];
	
	[[adium contentController] receiveContentObject:messageObject];
}

/*********************/
/* AIAccount_Content */
/*********************/
#pragma mark Content
- (void)sendTypingObject:(AIContentTyping *)inContentTyping
{
	AIChat *chat = [inContentTyping chat];

	if (![chat isGroupChat]) {
		[purpleThread sendTyping:[inContentTyping typingState] inChat:chat];
	}
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	PurpleMessageFlags		flags = PURPLE_MESSAGE_RAW;
	
	if ([inContentMessage isAutoreply]) {
		flags |= PURPLE_MESSAGE_AUTO_RESP;
	}

	[purpleThread sendEncodedMessage:[inContentMessage encodedMessage]
					   fromAccount:self
							inChat:[inContentMessage chat]
						 withFlags:flags];
	
	return YES;
}

/*!
 * @brief Return the string encoded for sending to a remote contact
 *
 * We return nil if the string turns out to have been a / command.
 */
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	NSString	*encodedString;
	BOOL		didCommand = [purpleThread attemptPurpleCommandOnMessage:[inContentMessage messageString]
														 fromAccount:(AIAccount *)[inContentMessage source]
															  inChat:[inContentMessage chat]];	
	
	encodedString = (didCommand ?
					 nil :
					 [super encodedAttributedStringForSendingContentMessage:inContentMessage]);

	return encodedString;
}

/*!
 * @brief Allow newlines in messages
 *
 * Only IRC doesn't allow newlines out of the built-in prpls... and we don't even support it yet.
 * This method is never called at present.
 */
- (BOOL)allowsNewlinesInMessages
{
	return (account && account->gc && ((account->gc->flags & PURPLE_CONNECTION_NO_NEWLINES) != 0));
}

//Return YES if we're available for sending the specified content or will be soon (are currently connecting).
//If inListObject is nil, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
    BOOL	weAreOnline = [self online];
	
    if ([inType isEqualToString:CONTENT_MESSAGE_TYPE]) {
        if ((weAreOnline && (inContact == nil || [inContact online])) ||
			([self integerStatusObjectForKey:@"Connecting"])) {  //XXX - Why do we lie if we're connecting? -ai
			return YES;
        }
    } else if (([inType isEqualToString:CONTENT_FILE_TRANSFER_TYPE]) && ([self conformsToProtocol:@protocol(AIAccount_Files)])) {
		if (weAreOnline) {
			if (inContact) {
				if ([inContact online]) {
					return [self allowFileTransferWithListObject:inContact];
				}
			} else {
				return YES;
			}
       }	
	}
	
    return NO;
}

- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	PurplePluginProtocolInfo *prpl_info = NULL;

	if (account && account->gc && account->gc->prpl)
		prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(account->gc->prpl);
	
	if (prpl_info && prpl_info->send_file)
		return (!prpl_info->can_receive_file || prpl_info->can_receive_file(account->gc, [[inListObject UID] UTF8String]));
	else
		return NO;
}

- (BOOL)supportsAutoReplies
{
	if (account && account->gc) {
		return ((account->gc->flags & PURPLE_CONNECTION_AUTO_RESP) != 0);
	}
	
	return NO;
}

#pragma mark Custom emoticons
- (void)chat:(AIChat *)inChat isWaitingOnCustomEmoticon:(NSString *)emoticonEquivalent
{
	if(![[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
												  group:PREF_GROUP_MSN_SERVICE] boolValue])
		return;
	AIEmoticon *emoticon;

	//Look for an existing emoticon with this equivalent
	NSEnumerator *enumerator = [[inChat customEmoticons] objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		if ([[emoticon textEquivalents] containsObject:emoticonEquivalent]) break;
	}
	
	if (!emoticon) {
		emoticon = [AIEmoticon emoticonWithIconPath:nil
										equivalents:[NSArray arrayWithObject:emoticonEquivalent]
											   name:emoticonEquivalent
											   pack:nil];
		[inChat addCustomEmoticon:emoticon];			
	}
	
	if (![emoticon path]) {
		[emoticon setPath:[[NSBundle bundleForClass:[CBPurpleAccount class]] pathForResource:@"missing_image"
																					ofType:@"png"]];
	}
}

/*!
 * @brief Return the path at which to save an emoticon
 */
- (NSString *)_emoticonCachePathForEmoticon:(NSString *)emoticonEquivalent type:(AIBitmapImageFileType)fileType inChat:(AIChat *)inChat
{
	static unsigned long long emoticonID = 0;
    NSString    *filename = [NSString stringWithFormat:@"TEMP-CustomEmoticon_%@_%@_%qu.%@",
		[inChat uniqueChatID], emoticonEquivalent, emoticonID++, [NSImage extensionForBitmapImageFileType:fileType]];
    return [[adium cachesPath] stringByAppendingPathComponent:[filename safeFilenameString]];	
}


- (void)chat:(AIChat *)inChat setCustomEmoticon:(NSString *)emoticonEquivalent withImageData:(NSData *)inImageData
{
	if(![[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
												  group:PREF_GROUP_MSN_SERVICE] boolValue])
		return;
	/* XXX Note: If we can set outgoing emoticons, this method needs to be updated to mark emoticons as incoming
	 * and AIEmoticonController needs to be able to handle that.
	 */
	AIEmoticon	*emoticon;

	//Look for an existing emoticon with this equivalent
	NSEnumerator *enumerator = [[inChat customEmoticons] objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		if ([[emoticon textEquivalents] containsObject:emoticonEquivalent]) break;
	}
	
	//Write out our image
	NSString	*path = [self _emoticonCachePathForEmoticon:emoticonEquivalent
													   type:[NSImage fileTypeOfData:inImageData]
													 inChat:inChat];
	[inImageData writeToFile:path
				  atomically:NO];

	if (emoticon) {
		//If we already have an emoticon, just update its path
		[emoticon setPath:path];

	} else {
		emoticon = [AIEmoticon emoticonWithIconPath:path
										equivalents:[NSArray arrayWithObject:emoticonEquivalent]
											   name:emoticonEquivalent
											   pack:nil];
		[inChat addCustomEmoticon:emoticon];
	}
}

- (void)chat:(AIChat *)inChat closedCustomEmoticon:(NSString *)emoticonEquivalent
{
	if(![[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
												  group:PREF_GROUP_MSN_SERVICE] boolValue])
		return;
	AIEmoticon	*emoticon;

	//Look for an existing emoticon with this equivalent
	NSEnumerator *enumerator = [[inChat customEmoticons] objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		if ([[emoticon textEquivalents] containsObject:emoticonEquivalent]) break;
	}
	
	if (emoticon) {
		[[adium notificationCenter] postNotificationName:@"AICustomEmoticonUpdated"
												  object:inChat
												userInfo:[NSDictionary dictionaryWithObject:emoticon
																					 forKey:@"AIEmoticon"]];
	} else {
		//This shouldn't happen; chat:setCustomEmoticon:withImageData: should have already been called.
		emoticon = [AIEmoticon emoticonWithIconPath:nil
										equivalents:[NSArray arrayWithObject:emoticonEquivalent]
											   name:emoticonEquivalent
											   pack:nil];
		NSLog(@"Warning: closed custom emoticon %@ without adding it to the chat", emoticon);
		AILog(@"Warning: closed custom emoticon %@ without adding it to the chat", emoticon);
	}
}

#pragma mark PurpleConversation User Lists
- (NSString *)uidForContactWithUID:(NSString *)inUID inChat:(AIChat *)chat
{
	//No change for the superclass; subclasses may wish to modify it
	return inUID;
}
- (void)addUsersArray:(NSArray *)usersArray
			withFlags:(NSArray *)flagsArray
		   andAliases:(NSArray *)aliasesArray 
		  newArrivals:(NSNumber *)newArrivals
			   toChat:(AIChat *)chat
{
	int			i, count;
	BOOL		isNewArrival = (newArrivals && [newArrivals boolValue]);

	AILog(@"*** %@: addUsersArray:%@ toChat:%@",self,usersArray,chat);

	count = [usersArray count];
	for (i = 0; i < count; i++) {
		NSString				*contactName;
		NSString				*alias;
		AIListContact			*listContact;
		PurpleConvChatBuddyFlags	flags;

		contactName = [usersArray objectAtIndex:i];
		flags = [[flagsArray objectAtIndex:i] intValue];
		alias = [aliasesArray objectAtIndex:i];

		listContact = [self contactWithUID:[self uidForContactWithUID:contactName inChat:chat]];
		[listContact setStatusObject:contactName forKey:@"FormattedUID" notify:NotifyNow];

		if (alias && [alias length]) {
			[listContact setServersideAlias:alias asStatusMessage:NO silently:YES];
		}

		[chat addParticipatingListObject:listContact notify:isNewArrival];
	}
}

- (void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat
{
	AIListContact	*contact;

	if ((chat) && 
		(contact = [self contactWithUID:[self uidForContactWithUID:contactName inChat:chat]])) {
		
		[chat removeObject:contact];
		
		AILog(@"%@ removeUser:%@ fromChat:%@",self,contact,chat);
	} else {
		AILog(@"Could not remove %@ from %@ (contactWithUID: %@)",
			  contactName,chat,[self contactWithUID:[self uidForContactWithUID:contactName inChat:chat]]);
	}
}

- (void)removeUsersArray:(NSArray *)usersArray fromChat:(AIChat *)chat
{
	NSEnumerator	*enumerator = [usersArray objectEnumerator];
	NSString		*contactName;
	while ((contactName = [enumerator nextObject])) {
		[self removeUser:contactName fromChat:chat];
	}
}

/*********************/
/* AIAccount_Privacy */
/*********************/
#pragma mark Privacy
- (BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type
{
    if (type == AIPrivacyTypePermit)
        return (purple_privacy_permit_add(account,[[inObject UID] UTF8String],FALSE));
    else
        return (purple_privacy_deny_add(account,[[inObject UID] UTF8String],FALSE));
}

- (BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type
{
    if (type == AIPrivacyTypePermit)
        return (purple_privacy_permit_remove(account,[[inObject UID] UTF8String],FALSE));
    else
        return (purple_privacy_deny_remove(account,[[inObject UID] UTF8String],FALSE));
}

- (NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type
{
	NSMutableArray	*array = [NSMutableArray array];
	if (account) {
		GSList			*list;
		GSList			*sourceList = ((type == AIPrivacyTypePermit) ? account->permit : account->deny);
		
		for (list = sourceList; (list != NULL); list=list->next) {
			[array addObject:[self contactWithUID:[NSString stringWithUTF8String:(char *)list->data]]];
		}
	}

	return array;
}

- (void)accountPrivacyList:(AIPrivacyType)type added:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]) {
		//Get our contact
		AIListContact   *contact = [self contactWithUID:sourceUID];

		//Update Adium's knowledge of it
		[contact setIsBlocked:((type == AIPrivacyTypeDeny) ? YES : NO) updateList:NO];
	}
}

- (void)privacyPermitListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypePermit added:sourceUID];
}

- (void)privacyDenyListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypeDeny added:sourceUID];
}

- (void)accountPrivacyList:(AIPrivacyType)type removed:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]) {
		if (!namesAreCaseSensitive) {
			sourceUID = [sourceUID compactedString];
		}

		//Get our contact, which must already exist for us to care about its removal
		AIListContact   *contact = [[adium contactController] existingContactWithService:service
																				 account:self
																					 UID:sourceUID];
		
		if (contact) {			
			//Update Adium's knowledge of it
			[contact setIsBlocked:((type == AIPrivacyTypeDeny) ? NO : YES) updateList:NO];
		}
	}
}

- (void)privacyPermitListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypePermit removed:sourceUID];
}

- (void)privacyDenyListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypeDeny removed:sourceUID];
}

- (void)setPrivacyOptions:(AIPrivacyOption)option
{
	if (account && purple_account_get_connection(account)) {
		PurplePrivacyType privacyType;

		switch (option) {
			case AIPrivacyOptionAllowAll:
			default:
				privacyType = PURPLE_PRIVACY_ALLOW_ALL;
				break;
			case AIPrivacyOptionDenyAll:
				privacyType = PURPLE_PRIVACY_DENY_ALL;
				break;
			case AIPrivacyOptionAllowUsers:
				privacyType = PURPLE_PRIVACY_ALLOW_USERS;
				break;
			case AIPrivacyOptionDenyUsers:
				privacyType = PURPLE_PRIVACY_DENY_USERS;
				break;
			case AIPrivacyOptionAllowContactList:
				privacyType = PURPLE_PRIVACY_ALLOW_BUDDYLIST;
				break;
			
		}
		account->perm_deny = privacyType;
		serv_set_permit_deny(purple_account_get_connection(account));
		AILog(@"Set privacy options for %@ (%x %x) to %i",
			  self,account,purple_account_get_connection(account),account->perm_deny);
	} else {
		AILog(@"Couldn't set privacy options for %@ (%x %x)",self,account,purple_account_get_connection(account));
	}
}

- (AIPrivacyOption)privacyOptions
{
	AIPrivacyOption privacyOption = -1;
	
	if (account) {
		PurplePrivacyType privacyType = account->perm_deny;
		
		switch (privacyType) {
			case PURPLE_PRIVACY_ALLOW_ALL:
			default:
				privacyOption = AIPrivacyOptionAllowAll;
				break;
			case PURPLE_PRIVACY_DENY_ALL:
				privacyOption = AIPrivacyOptionDenyAll;
				break;
			case PURPLE_PRIVACY_ALLOW_USERS:
				privacyOption = AIPrivacyOptionAllowUsers;
				break;
			case PURPLE_PRIVACY_DENY_USERS:
				privacyOption = AIPrivacyOptionDenyUsers;
				break;
			case PURPLE_PRIVACY_ALLOW_BUDDYLIST:
				privacyOption = AIPrivacyOptionAllowContactList;
				break;
		}
	}
	AILog(@"%@: privacyOptions are %i",self,privacyOption);
	return privacyOption;
}

/*****************************************************/
/* File transfer / AIAccount_Files inherited methods */
/*****************************************************/
#pragma mark File Transfer
- (BOOL)canSendFolders
{
	return NO;
}

//Create a protocol-specific xfer object, set it up as requested, and begin sending
- (void)_beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	PurpleXfer *xfer = [self newOutgoingXferForFileTransfer:fileTransfer];
	
	if (xfer) {
		//Associate the fileTransfer and the xfer with each other
		[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
		xfer->ui_data = [fileTransfer retain];
		
		//Set the filename
		purple_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
		purple_xfer_set_filename(xfer, [[[fileTransfer localFilename] lastPathComponent] UTF8String]);
		
		/*
		 Request that the transfer begins.
		 We will be asked to accept it via:
			- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
		 below.
		 */
		[purpleThread xferRequest:xfer];
	}
}
//By default, protocols can not create PurpleXfer objects
- (PurpleXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	PurpleXfer				*newPurpleXfer = NULL;

	if (account && purple_account_get_connection(account)) {
		PurplePlugin				*prpl;
		PurplePluginProtocolInfo  *prpl_info = ((prpl = purple_find_prpl(account->protocol_id)) ?
											  PURPLE_PLUGIN_PROTOCOL_INFO(prpl) :
											  NULL);

		if (prpl_info && prpl_info->new_xfer) {
			char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
			newPurpleXfer = (prpl_info->new_xfer)(purple_account_get_connection(account), destsn);
		}
	}

	return newPurpleXfer;
}

/* 
 * @brief The account requested that we received a file.
 *
 * Set up the ESFileTransfer and query the fileTransferController for a save location.
 * 
 */
- (void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	AILog(@"File transfer request received: %@",fileTransfer);
	[[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

//Create an ESFileTransfer object from an xfer
- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID
										 size:(unsigned long long)inSize
							   remoteFilename:(NSString *)remoteFilename
{
	AIListContact   *contact = [self contactWithUID:destinationUID];
    ESFileTransfer	*fileTransfer;
	
	fileTransfer = [[adium fileTransferController] newFileTransferWithContact:contact
																   forAccount:self
																		 type:Unknown_FileTransfer]; 
	[fileTransfer setSize:inSize];
	[fileTransfer setRemoteFilename:remoteFilename];
	
    return fileTransfer;
}

//Update an ESFileTransfer object progress
- (void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	float percentDone = [percent floatValue];
    [fileTransfer setPercentDone:percentDone bytesSent:[bytesSent unsignedLongValue]];
}

//The local side cancelled the transfer.  We probably already have this status set, but set it just in case.
- (void)fileTransferCancelledLocally:(ESFileTransfer *)fileTransfer
{
	if (![fileTransfer isStopped]) {
		[fileTransfer setStatus:Cancelled_Local_FileTransfer];
	}
}

//The remote side cancelled the transfer, the fool. Update our status.
- (void)fileTransferCancelledRemotely:(ESFileTransfer *)fileTransfer
{
	if (![fileTransfer isStopped]) {
		[fileTransfer setStatus:Cancelled_Remote_FileTransfer];
	}
}

- (void)destroyFileTransfer:(ESFileTransfer *)fileTransfer
{
	AILog(@"Destroy file transfer %@",fileTransfer);
	[fileTransfer release];
}

//Accept a send or receive ESFileTransfer object, beginning the transfer.
//Subsequently inform the fileTransferController that the fun has begun.
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    AILog(@"Accepted file transfer %@",fileTransfer);
	
	PurpleXfer		*xfer;
	PurpleXferType	xferType;
	
	xfer = [[fileTransfer accountData] pointerValue];

    xferType = purple_xfer_get_type(xfer);
    if ( xferType == PURPLE_XFER_SEND ) {
        [fileTransfer setFileTransferType:Outgoing_FileTransfer];   
    } else if ( xferType == PURPLE_XFER_RECEIVE ) {
        [fileTransfer setFileTransferType:Incoming_FileTransfer];
		[fileTransfer setSize:(xfer->size)];
    }
    
    //accept the request
	[purpleThread xferRequestAccepted:xfer withFileName:[fileTransfer localFilename]];
    
	//set the size - must be done after request is accepted?

	
	[fileTransfer setStatus:Accepted_FileTransfer];
}

//User refused a receive request.  Tell purple; we don't release the ESFileTransfer object
//since that will happen when the xfer is destroyed.  This will end up calling back on
//- (void)fileTransfercancelledLocally:(ESFileTransfer *)fileTransfer
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
	PurpleXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[purpleThread xferRequestRejected:xfer];
	}
}

//Cancel a file transfer in progress.  Tell purple; we don't release the ESFileTransfer object
//since that will happen when the xfer is destroyed.  This will end up calling back on
//- (void)fileTransfercancelledLocally:(ESFileTransfer *)fileTransfer
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	PurpleXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[purpleThread xferCancel:xfer];
	}	
}

//Account Connectivity -------------------------------------------------------------------------------------------------
#pragma mark Connect
//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	[super connect];
	
	if (!account) {
		//create a purple account if one does not already exist
		[self createNewPurpleAccount];
		AILog(@"created PurpleAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
	//Make sure our settings are correct
	[self configurePurpleAccountNotifyingTarget:self selector:@selector(continueConnectWithConfiguredPurpleAccount)];
}

- (void)continueConnectWithConfiguredPurpleAccount
{
	//Configure libpurple's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxyNotifyingTarget:self selector:@selector(continueConnectWithConfiguredProxy)];
}

- (void)continueConnectWithConfiguredProxy
{
	//Set password and connect
	purple_account_set_password(account, [password UTF8String]);

	//Set our current status state after filtering its statusMessage as appropriate. This will take us online in the process.
	AIStatus	*statusState = [self statusObjectForKey:@"StatusState"];
	if (!statusState || ([statusState statusType] == AIOfflineStatusType)) {
		statusState = [[adium statusController] defaultInitialStatusState];
	}

	AILog(@"Adium: Connect: %@ initiating connection using status state %@ (%@).",[self UID],statusState,
			  [statusState statusMessageString]);

	[self autoRefreshingOutgoingContentForStatusKey:@"StatusState"
										   selector:@selector(gotFilteredStatusMessage:forStatusState:)
											context:statusState];
}


//Make sure our settings are correct; notify target/selector when we're finished
- (void)configurePurpleAccountNotifyingTarget:(id)target selector:(SEL)selector
{
	NSInvocation	*contextInvocation;
	
	//Perform the synchronous configuration activities (subclasses may want to take action in this function)
	[self configurePurpleAccount];
	
	contextInvocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	
	[contextInvocation setTarget:target];
	[contextInvocation setSelector:selector];
	[contextInvocation retainArguments];

	//Set the text profile BEFORE beginning the connect process, to avoid problems with setting it while the
	//connect occurs. Once that's done, contextInvocation will be invoked, continuing the configurePurpleAccount process.
	[self autoRefreshingOutgoingContentForStatusKey:@"TextProfile" 
										   selector:@selector(setAccountProfileTo:configurePurpleAccountContext:)
											context:contextInvocation];
}

//Synchronous purple account configuration activites, always performed after an account is created.
//This is a definite subclassing point so prpls can apply their own account settings.
- (void)configurePurpleAccount
{
	NSString	*hostName;
	int			portNumber;

	//Host (server)
	hostName = [self host];
	if (hostName && [hostName length]) {
		purple_account_set_string(account, "server", [hostName UTF8String]);
	}
	
	//Port
	portNumber = [self port];
	if (portNumber) {
		purple_account_set_int(account, "port", portNumber);
	}
	
	//E-mail checking
	purple_account_set_check_mail(account, [[self shouldCheckMail] boolValue]);
	
	//Update a few status keys before we begin connecting.  Libpurple will send these automatically
    [self updateStatusForKey:KEY_USER_ICON];
}

/*!
 * @brief Configure libpurple's proxy settings using the current system values
 *
 * target/selector are used rather than a hardcoded callback (or getProxyConfigurationNotifyingTarget: directly) because this allows code reuse
 * between the connect and register processes, which are similar in their need for proxy configuration
 */
- (void)configureAccountProxyNotifyingTarget:(id)target selector:(SEL)selector
{
	NSInvocation		*invocation; 

	//Configure the invocation we will use when we are done configuring
	invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:target];
	
	[self getProxyConfigurationNotifyingTarget:self
									  selector:@selector(retrievedProxyConfiguration:context:)
									   context:invocation];
}

/*!
 * @brief Callback for -[self getProxyConfigurationNotifyingTarget:selector:context:]
 */
- (void)retrievedProxyConfiguration:(NSDictionary *)proxyConfig context:(NSInvocation *)invocation
{
	PurpleProxyInfo		*proxy_info;
	
	AdiumProxyType  	proxyType = [[proxyConfig objectForKey:@"AdiumProxyType"] intValue];
	
	proxy_info = purple_proxy_info_new();
	purple_account_set_proxy_info(account, proxy_info);

	PurpleProxyType		purpleAccountProxyType;
	
	switch (proxyType) {
		case Adium_Proxy_HTTP:
		case Adium_Proxy_Default_HTTP:
			purpleAccountProxyType = PURPLE_PROXY_HTTP;
			break;
		case Adium_Proxy_SOCKS4:
		case Adium_Proxy_Default_SOCKS4:
			purpleAccountProxyType = PURPLE_PROXY_SOCKS4;
			break;
		case Adium_Proxy_SOCKS5:
		case Adium_Proxy_Default_SOCKS5:
			purpleAccountProxyType = PURPLE_PROXY_SOCKS5;
			break;
		case Adium_Proxy_None:
		default:
			purpleAccountProxyType = PURPLE_PROXY_NONE;
			break;
	}
	
	purple_proxy_info_set_type(proxy_info, purpleAccountProxyType);

	if (proxyType != Adium_Proxy_None) {
		purple_proxy_info_set_host(proxy_info, (char *)[[proxyConfig objectForKey:@"Host"] UTF8String]);
		purple_proxy_info_set_port(proxy_info, [[proxyConfig objectForKey:@"Port"] intValue]);

		purple_proxy_info_set_username(proxy_info, (char *)[[proxyConfig objectForKey:@"Username"] UTF8String]);
		purple_proxy_info_set_password(proxy_info, (char *)[[proxyConfig objectForKey:@"Password"] UTF8String]);
		
		AILog(@"Connecting with proxy type %i and proxy host %@",proxyType, [proxyConfig objectForKey:@"Host"]);
	}

	[invocation invoke];
}

//Sublcasses should override to provide a string for each progress step
- (NSString *)connectionStringForStep:(int)step { return nil; };

/*!
 * @brief Should the account's status be updated as soon as it is connected?
 *
 * If YES, the StatusState and IdleSince status keys will be told to update as soon as the account connects.
 * This will allow the account to send its status information to the server upon connecting.
 *
 * If this information is already known by the account at the time it connects and further prompting to send it is
 * not desired, return NO.
 *
 * libpurple should already have been told of our status before connecting began.
 */
- (BOOL)updateStatusImmediatelyAfterConnecting
{
	return NO;
}

//Our account has connected
- (void)accountConnectionConnected
{
	AILog(@"************ %@ CONNECTED ***********",[self UID]);
	
	[self didConnect];

	[[adium notificationCenter] addObserver:self
								   selector:@selector(iTunesDidUpdate:)
									   name:Adium_iTunesTrackChangedNotification
									 object:nil];
	//tooltip for tunes
	tunetooltip = [[AMPurpleTuneTooltip alloc] initWithAccount:self];
	[[adium interfaceController] registerContactListTooltipEntry:tunetooltip secondaryEntry:YES];
	
    //Silence updates
    [self silenceAllContactUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
	
    //Reset reconnection attempts
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;

	//Clear any previous disconnection error
	[lastDisconnectionError release]; lastDisconnectionError = nil;
	
	if(deletionDialog)
		[purpleThread unregisterAccount:self];
}

- (void)accountConnectionProgressStep:(NSNumber *)step percentDone:(NSNumber *)connectionProgressPrecent
{
	NSString	*connectionProgressString = [self connectionStringForStep:[step intValue]];

	[self setStatusObject:connectionProgressString forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:connectionProgressPrecent forKey:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];
	
	AILog(@"************ %@ --step-- %i",[self UID],[step intValue]);
}

- (void)accountConnectionStep:(NSString*)msg step:(int)step totalSteps:(int)step_count
{

}

/*!
 * @brief Name to use when creating a PurpleAccount for this CBPurpleAccount
 *
 * By default, we just use the formattedUID.  Subclasses can override this to provide other handling,
 * such as appending @mac.com if necessary for dotMac accounts.
 */
- (const char *)purpleAccountName
{
	return [[self formattedUID] UTF8String];
}

- (void)createNewPurpleAccount
{
	if (!purpleThread) {
		purpleThread = [[SLPurpleCocoaAdapter sharedInstance] retain];	
	}	

	//Create a fresh version of the account
    if ((account = purple_account_new([self purpleAccountName], [self protocolPlugin]))) {
		[purpleThread addAdiumAccount:self];
	} else {
		AILog(@"Unable to create Libpurple account with name %s and protocol plugin %s",
			  [self purpleAccountName], [self protocolPlugin]);
		NSLog(@"Unable to create Libpurple account with name %s and protocol plugin %s",
			  [self purpleAccountName], [self protocolPlugin]);
	}
}

#pragma mark Disconnect

/*!
 * @brief Disconnect this account
 */
- (void)disconnect
{
	if ([self online] || [self integerStatusObjectForKey:@"Connecting"]) {
		//As per AIAccount's documentation, call super's implementation
		[super disconnect];

		[[adium contactController] delayListObjectNotificationsUntilInactivity];

		//Tell libpurple to disconnect
		[purpleThread disconnectAccount:self];
	}
}

/*!
 * @brief Our account was unexpectedly disconnected with an error message
 */
- (void)accountConnectionReportDisconnect:(NSString *)text
{
	//Retain the error message locally for use in -[CBPurpleAccount accountConnectionDisconnected]
	if (lastDisconnectionError != text) {
		[lastDisconnectionError release];
		lastDisconnectionError = [text retain];
	}

	//We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:NotifyNow];
	
	AILog(@"%@ accountConnectionReportDisconnect: %@",self,lastDisconnectionError);
}

- (void)accountConnectionNotice:(NSString *)connectionNotice
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"%@ (%@) : Connection Notice",nil),[self formattedUID],[service description]]
                                    withDescription:connectionNotice];
}


/*!
 * @brief Our account has disconnected
 *
 * This is called after the accoutn disconnects for any reason
 */
- (void)accountConnectionDisconnected
{
	BOOL			connectionIsSuicidal = ((account && account->gc) ? account->gc->wants_to_die : NO);

	//Clear status objects which don't make sense for a disconnected account
	[self setStatusObject:nil forKey:@"TextProfile" notify:NO];

	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];
	
	//If we were disconnected unexpectedly, attempt a reconnect. Give subclasses a chance to handle the disconnection error.
	//connectionIsSuicidal == TRUE when Purple thinks we shouldn't attempt a reconnect.
	if ([self shouldBeOnline] && lastDisconnectionError) {
		if (reconnectAttemptsRemaining && 
			[self shouldAttemptReconnectAfterDisconnectionError:&lastDisconnectionError] && !(connectionIsSuicidal)) {
			AILog(@"%@: Disconnected (%x: \"%@\"): Automatically reconnecting in %0f seconds (%i attempts remaining)",
				  self, (account ? account->gc : NULL), lastDisconnectionError, AUTO_RECONNECT_DELAY, reconnectAttemptsRemaining);
			[self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY];
			reconnectAttemptsRemaining--;
	
		} else {
			if (lastDisconnectionError) {
				//Display then clear the last disconnection error
//				[[adium interfaceController] account:self disconnectedWithError:lastDisconnectionError];

				[self displayError:lastDisconnectionError];

				[lastDisconnectionError release]; lastDisconnectionError = nil;
			}
			
			//Reset reconnection attempts
			reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;
			
			//Clear our desire to be online.
			/*
			[self setPreference:nil
						 forKey:@"Online"
						  group:GROUP_ACCOUNT_STATUS];
			 */
		}
	}
	[[adium interfaceController] unregisterContactListTooltipEntry:tunetooltip secondaryEntry:YES];
	[tunetooltip release];
	tunetooltip = nil;
	[[adium notificationCenter] removeObserver:self
										  name:Adium_iTunesTrackChangedNotification
										object:nil];
	[tuneinfo release];
	tuneinfo = nil;
	//Report that we disconnected
	AILog(@"%@: Telling the core we disconnected", self);
	[self didDisconnect];
	if(willBeDeleted)
		[super alertForAccountDeletion:deletionDialog didReturn:NSAlertDefaultReturn];
}

//By default, always attempt to reconnect.  Subclasses may override this to manage reconnect behavior.
- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	return YES;
}

#pragma mark Registering
- (void)performRegisterWithPassword:(NSString *)inPassword
{
	//Save the new password
	if (password != inPassword) {
		[password release]; password = [inPassword retain];
	}
	
	if (!account) {
		//create a purple account if one does not already exist
		[self createNewPurpleAccount];
		AILog(@"Registering: created PurpleAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
	//We are connecting
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:NotifyNow];
	
	//Make sure our settings are correct
	[self configurePurpleAccountNotifyingTarget:self selector:@selector(continueRegisterWithConfiguredPurpleAccount)];
}

- (void)continueRegisterWithConfiguredProxy
{
	//Set password and connect
	purple_account_set_password(account, [password UTF8String]);
	
	AILog(@"Adium: Register: %@ initiating connection.",[self UID]);
	
	[purpleThread registerAccount:self];
}

- (void)continueRegisterWithConfiguredPurpleAccount
{
	//Configure libpurple's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxyNotifyingTarget:self selector:@selector(continueRegisterWithConfiguredProxy)];
}

- (void)purpleAccountRegistered:(BOOL)success
{
	if (success && [[self service] accountViewController]) {
		NSString *username = (account->username ? [NSString stringWithUTF8String:account->username] : [NSNull null]);
		NSString *pw = (account->password ? [NSString stringWithUTF8String:account->password] : [NSNull null]);

		[[adium notificationCenter] postNotificationName:AIAccountUsernameAndPasswordRegisteredNotification
												  object:self
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													username, @"username",
													pw, @"password",
													nil]];
	}
}

//Account Status ------------------------------------------------------------------------------------------------------
#pragma mark Account Status
//Status keys this account supports
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"IdleSince",
			@"IdleManuallySet",
			@"TextProfile",
			@"DefaultUserIconFilename",
			KEY_ACCOUNT_CHECK_MAIL,
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
		
	}

	return supportedPropertyKeys;
}

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense if we have an account
	if (account) {
		AILog(@"%@: Updating status for key: %@",self, key);

		if ([key isEqualToString:@"IdleSince"]) {
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			[self setAccountIdleSinceTo:idleSince];
							
		} else if ([key isEqualToString:@"TextProfile"]) {
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(setAccountProfileTo:)];
			
		} else if ([key isEqualToString:KEY_USER_ICON]) {
			NSData  *data = [self userIconData];

			[self setAccountUserImageData:data];

		} else if ([key isEqualToString:KEY_ACCOUNT_CHECK_MAIL]) {
			//Update the mail checking setting if the account is already made (if it isn't, we'll set it when it is made)
			if (account) {
				[purpleThread setCheckMail:[self shouldCheckMail]
							  forAccount:self];
			}
		}
	}
}

/*!
 * @brief Return the purple status type to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the purple status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The purple status ID
 */
- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char	*statusID = NULL;
	
	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			statusID = "available";
			break;
		case AIAwayStatusType:
			statusID = "away";
			break;
			
		case AIInvisibleStatusType:
			statusID = "invisible";
			break;
			
		case AIOfflineStatusType:
			statusID = "offline";
			break;
	}
	
	return statusID;
}

- (BOOL)shouldAddMusicalNoteToNowPlayingStatus
{
	return YES;
}

- (BOOL)shouldSetITMSLinkForNowPlayingStatus
{
	return NO;
}

- (BOOL)shouldIncludeNowPlayingInformationInAllStatuses
{
	return NO;
}

- (void)iTunesDidUpdate:(NSNotification*)notification {
	if ([self shouldIncludeNowPlayingInformationInAllStatuses]) {
		[tuneinfo release];
		tuneinfo = [[notification object] retain];
		
		// update info in prpl
		if ([self online])
			[self updateStatusForKey:@"StatusState"];
	}
}

/*!
 * @brief Perform the setting of a status state
 *
 * Sets the account to a passed status state.  The account should set itself to best possible status given the return
 * values of statusState's accessors.  The passed statusMessage has been filtered; it should be used rather than
 * [statusState statusMessage], which returns an unfiltered statusMessage.
 *
 * @param statusState The state to enter
 * @param statusMessage The filtered status message to use.
 */
- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	NSString			*encodedStatusMessage;
	NSMutableDictionary	*arguments = [[NSMutableDictionary alloc] init];

	//Get the purple status type from this class or subclasses, which may also potentially modify or nullify our statusMessage
	const char *statusID = [self purpleStatusIDForStatus:statusState
											 arguments:arguments];

	if (![statusMessage length] &&
		([statusState statusType] == AIAwayStatusType) &&
		([statusState statusName])) {
		/* If we don't have a status message, and the status type is away for a non-default away such as "Do Not Disturb", get a default
		 * description of this away state. This allows, for example, an AIM user to set the "Do Not Disturb" type provided by her ICQ account
		 * and have the away message be set appropriately.
		 */
		statusMessage = [NSAttributedString stringWithString:[[adium statusController] descriptionForStateOfStatus:statusState]];
	}

	if ([statusMessage length]	&& ([statusState specialStatusType] == AINowPlayingSpecialStatusType)) {
		if ([self shouldAddMusicalNoteToNowPlayingStatus]) {
#define MUSICAL_NOTE_AND_SPACE [NSString stringWithUTF8String:"\xe2\x99\xab "]
			NSMutableAttributedString *temporaryStatusMessage;
			temporaryStatusMessage = [[[NSMutableAttributedString alloc] initWithString:MUSICAL_NOTE_AND_SPACE] autorelease];
			[temporaryStatusMessage appendAttributedString:statusMessage];
			
			statusMessage = temporaryStatusMessage;
		}
		
		if ([self shouldSetITMSLinkForNowPlayingStatus]) {
			//Grab the message's subtext, which is the song link if we're using the Current iTunes Track status
			NSString *itmsStoreLink	= [statusMessage attribute:@"AIMessageSubtext" atIndex:0 effectiveRange:NULL];
			if (itmsStoreLink) {
				[arguments setObject:itmsStoreLink
							  forKey:@"itmsurl"];
			}
		}
	}

	if ([self shouldIncludeNowPlayingInformationInAllStatuses]) {
		if (tuneinfo && [[tuneinfo objectForKey:ITUNES_PLAYER_STATE] isEqualToString:@"Playing"]) {
			[arguments setObject:([tuneinfo objectForKey:ITUNES_ARTIST] ? [tuneinfo objectForKey:ITUNES_ARTIST] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ARTIST]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_NAME] ? [tuneinfo objectForKey:ITUNES_NAME] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TITLE]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_ALBUM] ? [tuneinfo objectForKey:ITUNES_ALBUM] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ALBUM]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_GENRE] ? [tuneinfo objectForKey:ITUNES_GENRE] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_GENRE]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_TOTAL_TIME] ? [tuneinfo objectForKey:ITUNES_TOTAL_TIME]:[NSNumber numberWithInt:-1]) forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TIME]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_YEAR] ? [tuneinfo objectForKey:ITUNES_YEAR]:[NSNumber numberWithInt:-1]) forKey:[NSString stringWithUTF8String:PURPLE_TUNE_YEAR]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_STORE_URL] ? [tuneinfo objectForKey:ITUNES_STORE_URL] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_URL]];
		} else {
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ARTIST]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TITLE]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ALBUM]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_GENRE]];
			[arguments setObject:[NSNumber numberWithInt:-1] forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TIME]];
			[arguments setObject:[NSNumber numberWithInt:-1] forKey:[NSString stringWithUTF8String:PURPLE_TUNE_YEAR]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_URL]];
		}
	}

	//Encode the status message if we have one
	encodedStatusMessage = (statusMessage ? 
							[self encodedAttributedString:statusMessage
										   forStatusState:statusState]  :
							nil);
	if (encodedStatusMessage) {
		[arguments setObject:encodedStatusMessage
					  forKey:@"message"];
	}

	[self setStatusState:statusState
				statusID:statusID
				isActive:[NSNumber numberWithBool:YES] /* We're only using exclusive states for now... I hope.  */
			   arguments:arguments];
	
	[arguments release];
}

/*!
 * @brief Perform the actual setting of a state
 *
 * This is called by setStatusState.  It allows subclasses to perform any other behaviors, such as modifying a display
 * name, which are called for by the setting of the state; most of the processing has already been done, however, so
 * most subclasses will not need to implement this.
 *
 * @param statusState The AIStatus which is being set
 * @param statusID The Purple-sepcific statusID we are setting
 * @param isActive An NSNumber with a bool YES if we are activating (going to) the passed state, NO if we are deactivating (going away from) the passed state.
 * @param arguments Purple-specific arguments specified by the account. It must contain only NSString objects and keys.
 */
- (void)setStatusState:(AIStatus *)statusState statusID:(const char *)statusID isActive:(NSNumber *)isActive arguments:(NSMutableDictionary *)arguments
{
	[purpleThread setStatusID:statusID
				   isActive:isActive
				  arguments:arguments
				  onAccount:self];
}

//Set our idle (Pass nil for no idle)
- (void)setAccountIdleSinceTo:(NSDate *)idleSince
{
	[purpleThread setIdleSinceTo:idleSince onAccount:self];
	
	//We now should update our idle status object
	[self setStatusObject:([idleSince timeIntervalSinceNow] ? idleSince : nil)
				   forKey:@"IdleSince"
				   notify:NotifyNow];
}

//Set the profile, then invoke the passed invocation to return control to the target/selector specified
//by a configurePurpleAccountNotifyingTarget:selector: call.
- (void)setAccountProfileTo:(NSAttributedString *)profile configurePurpleAccountContext:(NSInvocation *)inInvocation
{
	[self setAccountProfileTo:profile];
	
	[inInvocation invoke];
}

//Set our profile immediately on the purpleThread
- (void)setAccountProfileTo:(NSAttributedString *)profile
{
	if (!profile || ![[profile string] isEqualToString:[[self statusObjectForKey:@"TextProfile"] string]]) {
		NSString 	*profileHTML = nil;
		
		//Convert the profile to HTML, and pass it to libpurple
		if (profile) {
			profileHTML = [self encodedAttributedString:profile forListObject:nil];
		}
		
		[purpleThread setInfo:profileHTML onAccount:self];
		
		//We now have a profile
		[self setStatusObject:profile forKey:@"TextProfile" notify:NotifyNow];
	}
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image. This resizes and converts the image as needed for our protocol.
 * After setting it with purple, it sets it within Adium; if this is not called, the image will
 * show up neither locally nor remotely.
 */
- (void)setAccountUserImageData:(NSData *)originalData
{
	NSImage	*image =  (originalData ? [[[NSImage alloc] initWithData:originalData] autorelease] : nil);

	if (account) {
		NSSize		imageSize = [image size];
		
		//Clear the existing icon first
		[purpleThread setBuddyIcon:nil onAccount:self];
		
		/* Now pass libpurple the new icon.  Libpurple takes icons as a file, so we save our
		 * image to one, and then pass libpurple the path. Check to be sure our image doesn't have an NSZeroSize size,
		 * which would indicate currupt data */
		if (image && !NSEqualSizes(NSZeroSize, imageSize)) {
			PurplePlugin				*prpl;
			PurplePluginProtocolInfo  *prpl_info = ((prpl = purple_find_prpl(account->protocol_id)) ?
												  PURPLE_PLUGIN_PROTOCOL_INFO(prpl) :
												  NULL);

			AILog(@"Original image of size %f %f",imageSize.width,imageSize.height);

			if (prpl_info && (prpl_info->icon_spec.format)) {
				NSData		*buddyIconData = nil;
				BOOL		smallEnough, prplScales;
				unsigned	i;
				
				/* We need to scale it down if:
				 *	1) The prpl needs to scale before it sends to the server or other buddies AND
				 *	2) The image is larger than the maximum size allowed by the protocol
				 * We ignore the minimum required size, as scaling up just leads to pixellated images.
				 */
				smallEnough =  (prpl_info->icon_spec.max_width >= imageSize.width &&
								prpl_info->icon_spec.max_height >= imageSize.height);
					
				prplScales = (prpl_info->icon_spec.scale_rules & PURPLE_ICON_SCALE_SEND) || (prpl_info->icon_spec.scale_rules & PURPLE_ICON_SCALE_DISPLAY);

#if 1
				if (prplScales && !smallEnough) {
					int width = imageSize.width;
					int height = imageSize.height;
					
					purple_buddy_icon_get_scale_size(&prpl_info->icon_spec, &width, &height);
					//Determine the scaled size.  If it's too big, scale to the largest permissable size
					image = [image imageByScalingToSize:NSMakeSize(width, height)];

					/* Our original data is no longer valid, since we had to scale to a different size */
					originalData = nil;
					AILog(@"%@: Scaled image to size %@", self, NSStringFromSize([image size]));
				}

				if (!buddyIconData) {
					char		**prpl_formats =  g_strsplit(prpl_info->icon_spec.format,",",0);

					//Look for gif first if the image is animated
					NSImageRep	*imageRep = [image bestRepresentationForDevice:nil] ;
					if ([imageRep isKindOfClass:[NSBitmapImageRep class]] &&
						[[(NSBitmapImageRep *)imageRep valueForProperty:NSImageFrameCount] intValue] > 1) {
						
						for (i = 0; prpl_formats[i]; i++) {
							if (strcmp(prpl_formats[i],"gif") == 0) {
								/* Try to use our original data.  If we had to scale, originalData will have been set
								* to nil and we'll continue below to convert the image. */
								AILog(@"l33t script kiddie animated GIF!!111");
								
								buddyIconData = originalData;
								if (buddyIconData)
									break;
							}
						}
					}
					
					if (!buddyIconData) {
						for (i = 0; prpl_formats[i]; i++) {
							if (strcmp(prpl_formats[i],"png") == 0) {
								buddyIconData = [image PNGRepresentation];
								if (buddyIconData)
									break;
								
							} else if ((strcmp(prpl_formats[i],"jpeg") == 0) || (strcmp(prpl_formats[i],"jpg") == 0)) {
								/* OS X 10.4's JPEG representation does much better than 10.3's.  Unfortunately, that also
								* means larger file sizes... which for our only JPEG-based protocol, AIM, means the buddy
								* icon doesn't get sent.  AIM max is 8 kilobytes; 10.4 produces 12 kb images.  0.90 is
								* large indistinguishable from 1.0 anyways.
								*/
								float compressionFactor = 0.9;
								
								buddyIconData = [image JPEGRepresentationWithCompressionFactor:compressionFactor];
								if (buddyIconData)
									break;
								
							} else if ((strcmp(prpl_formats[i],"tiff") == 0) || (strcmp(prpl_formats[i],"tif") == 0)) {
								buddyIconData = [image TIFFRepresentation];
								if (buddyIconData)
									break;
								
							} else if (strcmp(prpl_formats[i],"gif") == 0) {
								buddyIconData = [image GIFRepresentation];
								if (buddyIconData)
									break;
								
							} else if (strcmp(prpl_formats[i],"bmp") == 0) {
								buddyIconData = [image BMPRepresentation];
								if (buddyIconData)
									break;
								
							}						
						}
						
						size_t maxSize = prpl_info->icon_spec.max_filesize;
						if (maxSize > 0 && ([buddyIconData length] > maxSize)) {
							AILog(@"Image %i is larger than %i!",[buddyIconData length],maxSize);
							for (i = 0; prpl_formats[i]; i++) {
								if ((strcmp(prpl_formats[i],"jpeg") == 0) || (strcmp(prpl_formats[i],"jpg") == 0)) {
									for (float compressionFactor = 0.9; compressionFactor > 0.4; compressionFactor -= 0.05) {
										buddyIconData = [image JPEGRepresentationWithCompressionFactor:compressionFactor];
										
										if (buddyIconData && ([buddyIconData length] <= maxSize)) {
											AILog(@"Succeeded getting it down to %i with compressionFactor %f",[buddyIconData length],compressionFactor);
											break;
										}
									}
								}
							}
						}
					}	
					//Cleanup
					g_strfreev(prpl_formats);
				}
#else
				buddyIconData = originalData;
#endif				
				[purpleThread setBuddyIcon:buddyIconData onAccount:self];
			}
		}
	}
	
	//We now have an icon
	[self setStatusObject:image forKey:KEY_USER_ICON notify:NotifyNow];
}

#pragma mark Group Chat
- (BOOL)inviteContact:(AIListContact *)inContact toChat:(AIChat *)inChat withMessage:(NSString *)inviteMessage
{
	[purpleThread inviteContact:inContact toChat:inChat withMessage:inviteMessage];
	
	return YES;
}

#pragma mark Buddy Menu Items
//Action of a dynamically-generated contact menu item
- (void)performContactMenuAction:(NSMenuItem *)sender
{
	NSDictionary		*dict = [sender representedObject];
	
	[purpleThread performContactMenuActionFromDict:dict forAccount:self];
}

/*!
 * @brief Utility method when generating buddy-specific menu items
 *
 * Adds the menu item for act to a growing array of NSMenuItems.  If act has children (a submenu), this method is used recursively
 * to generate the submenu containing each child menu item.
 */
- (void)addMenuItemForMenuAction:(PurpleMenuAction *)act forListContact:(AIListContact *)inContact purpleBuddy:(PurpleBuddy *)buddy toArray:(NSMutableArray *)menuItemArray withServiceIcon:(NSImage *)serviceIcon
{
	NSDictionary	*dict;
	NSMenuItem		*menuItem;
	NSString		*title;
				
	//If titleForContactMenuLabel:forContact: returns nil, we don't add the menuItem
	if (act &&
		act->label &&
		(title = [self titleForContactMenuLabel:act->label
									 forContact:inContact])) { 
		menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																		target:self
																		action:@selector(performContactMenuAction:)
																 keyEquivalent:@""];
		[menuItem setImage:serviceIcon];

		if (act->data) {
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:act->callback],@"PurpleMenuActionCallback",
				/* act->data may be freed by purple_menu_action_free() before we use it, I'm afraid... */
				[NSValue valueWithPointer:act->data],@"PurpleMenuActionData",
				[NSValue valueWithPointer:buddy],@"PurpleBuddy",
				nil];
		} else {
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:act->callback],@"PurpleMenuActionCallback",
				[NSValue valueWithPointer:buddy],@"PurpleBuddy",
				nil];			
		}
		
		[menuItem setRepresentedObject:dict];
		
		//If there is a submenu, generate and set it
		if (act->children) {
			NSMutableArray	*childrenArray = [NSMutableArray array];
			GList			*l, *ll;
			//Add a NSMenuItem for each child
			for (l = ll = act->children; l; l = l->next) {
				[self addMenuItemForMenuAction:(PurpleMenuAction *)l->data
								forListContact:inContact
									 purpleBuddy:buddy
									   toArray:childrenArray
							   withServiceIcon:serviceIcon];
			}
			g_list_free(act->children);

			if ([childrenArray count]) {
				NSEnumerator *enumerator = [childrenArray objectEnumerator];
				NSMenuItem	 *childMenuItem;
				NSMenu		 *submenu = [[NSMenu alloc] init];
				
				while ((childMenuItem = [enumerator nextObject])) {
					[submenu addItem:childMenuItem];
				}
				
				[menuItem setSubmenu:submenu];
				[submenu release];
			}
		}

		[menuItemArray addObject:menuItem];
		[menuItem release];
	}

	purple_menu_action_free(act);
}

//Returns an array of menuItems specific for this contact based on its account and potentially status
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	NSMutableArray			*menuItemArray = nil;

	if (account && purple_account_is_connected(account)) {
		PurplePlugin				*prpl;
		PurplePluginProtocolInfo  *prpl_info = ((prpl = purple_find_prpl(account->protocol_id)) ?
											  PURPLE_PLUGIN_PROTOCOL_INFO(prpl) :
											  NULL);
		GList					*l, *ll;
		PurpleBuddy				*buddy;
		
		//Find the PurpleBuddy
		buddy = purple_find_buddy(account, purple_normalize(account, [[inContact UID] UTF8String]));
		
		if (prpl_info && prpl_info->blist_node_menu && buddy) {
			NSImage	*serviceIcon = [AIServiceIcons serviceIconForService:[self service]
																	type:AIServiceIconSmall
															   direction:AIIconNormal];
			
			menuItemArray = [NSMutableArray array];

			//Add a NSMenuItem for each node action specified by the prpl
			for (l = ll = prpl_info->blist_node_menu((PurpleBlistNode *)buddy); l; l = l->next) {
				[self addMenuItemForMenuAction:(PurpleMenuAction *)l->data
								forListContact:inContact
									 purpleBuddy:buddy
									   toArray:menuItemArray
							   withServiceIcon:serviceIcon];
			}
			g_list_free(ll);
			
			//Don't return an empty array
			if (![menuItemArray count]) menuItemArray = nil;
		}
	}
	
	return menuItemArray;
}

//Subclasses may override to provide a localized label and/or prevent a specified label from being shown
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	return [NSString stringWithUTF8String:label];
}

/*!
* @brief Menu items for the account's actions
 *
 * Returns an array of menu items for account-specific actions.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.  It will only be queried if the account is online.
 * @return NSArray of NSMenuItem instances for this account
 */
- (NSArray *)accountActionMenuItems
{
	NSMutableArray			*menuItemArray = nil;
	
	if (account && purple_account_is_connected(account)) {
		PurplePlugin *plugin = account->gc->prpl;
		
		if (PURPLE_PLUGIN_HAS_ACTIONS(plugin)) {
			GList	*l, *actions;
			
			actions = PURPLE_PLUGIN_ACTIONS(plugin, account->gc);

			//Avoid adding separators between nonexistant items (i.e. items which Purple shows but we don't)
			BOOL	addedAnAction = NO;
			for (l = actions; l; l = l->next) {
				
				if (l->data) {
					PurplePluginAction	*action;
					NSDictionary		*dict;
					NSMenuItem			*menuItem;
					NSString			*title;
					
					action = (PurplePluginAction *) l->data;
					
					//If titleForAccountActionMenuLabel: returns nil, we don't add the menuItem
					if (action &&
						action->label &&
						(title = [self titleForAccountActionMenuLabel:action->label])) {

						action->plugin = plugin;
						action->context = account->gc;

						menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																						 target:self
																						 action:@selector(performAccountMenuAction:)
																				  keyEquivalent:@""] autorelease];
						dict = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSValue valueWithPointer:action->callback], @"PurplePluginActionCallback",
							[NSValue valueWithPointer:action->user_data], @"PurplePluginActionCallbackUserData",
							nil];
						
						[menuItem setRepresentedObject:dict];
						
						if (!menuItemArray) menuItemArray = [NSMutableArray array];
						
						[menuItemArray addObject:menuItem];
						addedAnAction = YES;
					} 
					
					purple_plugin_action_free(action);
					
				} else {
					if (addedAnAction) {
						[menuItemArray addObject:[NSMenuItem separatorItem]];
						addedAnAction = NO;
					}
				}
			} /* end for */
			
			g_list_free(actions);
		}
	}

	return menuItemArray;
}

//Action of a dynamically-generated contact menu item
- (void)performAccountMenuAction:(NSMenuItem *)sender
{
	NSDictionary		*dict = [sender representedObject];

	[purpleThread performAccountMenuActionFromDict:dict forAccount:self];
}

//Subclasses may override to provide a localized label and/or prevent a specified label from being shown
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if ((strcmp(label, "Change Password...") == 0) || (strcmp(label, "Change Password") == 0)) {
		return [[NSString stringWithFormat:AILocalizedString(@"Change Password", "Menu item title for changing the password of an account")] stringByAppendingEllipsis];
	} else {
		return [NSString stringWithUTF8String:label];
	}
}

/********************************/
/* AIAccount subclassed methods */
/********************************/
#pragma mark AIAccount Subclassed Methods
- (void)initAccount
{
	NSDictionary	*defaults = [NSDictionary dictionaryNamed:[NSString stringWithFormat:@"PurpleDefaults%@",[[self service] serviceID]]
													 forClass:[self class]];
	
	if (defaults) {
		[[adium preferenceController] registerDefaults:defaults
											  forGroup:GROUP_ACCOUNT_STATUS
												object:self];
	} else {
		AILog(@"Failed to load defaults for %@",[NSString stringWithFormat:@"PurpleDefaults%@",[[self service] serviceID]]);
	}
	
	//Defaults
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;
	lastDisconnectionError = nil;
	
	permittedContactsArray = [[NSMutableArray alloc] init];
	deniedContactsArray = [[NSMutableArray alloc] init];

	//We will create a purpleAccount the first time we attempt to connect
	account = NULL;

	//Observe preferences changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_ALIASES];
}

/*!
 * @brief The account will be deleted, we should ask the user for confirmation. If the prpl supports it, we can also remove
 * the account from the server (if the user wants us to do that)
 */
- (NSAlert*)alertForAccountDeletion
{
	PurplePlugin *prpl;
	PurplePluginProtocolInfo *prpl_info;
	
	if (!purpleThread) {
		purpleThread = [[SLPurpleCocoaAdapter sharedInstance] retain];	
	}	
	
	prpl = purple_find_prpl([self protocolPlugin]);
	if(!prpl)
		return nil;
	prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(prpl);
	if(!prpl_info)
		return nil;
	if(prpl_info->unregister_user)
		return [NSAlert alertWithMessageText:AILocalizedString(@"Delete Account",nil)
							   defaultButton:AILocalizedString(@"Delete",nil)
							 alternateButton:AILocalizedString(@"Cancel",nil)
								 otherButton:AILocalizedString(@"Delete & Unregister",nil)
				   informativeTextWithFormat:AILocalizedString(@"Delete the account %@? You can also optionally unregister the account on the server if possible.",nil), ([[self formattedUID] length] ? [self formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT)];
	else
		return [super alertForAccountDeletion];
}

- (void)alertForAccountDeletion:(id<AIAccountControllerRemoveConfirmationDialog>)dialog didReturn:(int)returnCode
{
	PurplePlugin *prpl;
	PurplePluginProtocolInfo *prpl_info;
	
	if (!purpleThread) {
		purpleThread = [[SLPurpleCocoaAdapter sharedInstance] retain];	
	}	
	
	prpl = purple_find_prpl([self protocolPlugin]);
	if(!prpl) {
		[super alertForAccountDeletion:dialog didReturn:NSAlertAlternateReturn];
		return;
	}
	prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(prpl);
	if(!prpl_info) {
		[super alertForAccountDeletion:dialog didReturn:NSAlertAlternateReturn];
		return;
	}
	// if the user canceled, we can tell the superclass immediately
	// if the deletion is in fact happening, we first have to unregister and disconnect
	// this is an asynchronous process
	if(prpl_info->unregister_user) {
		switch(returnCode) {
			case NSAlertOtherReturn: // delete & unregister
				deletionDialog = dialog;
				if(!account || !purple_account_is_connected(account)) {
					password = [[[adium accountController] passwordForAccount:self] retain];
					[self connect];
				} else
					[purpleThread unregisterAccount:self];
				// further progress happens in -unregisteredAccount:
				break;
			case NSAlertDefaultReturn: // delete
				willBeDeleted = YES;
				if(!account || !purple_account_is_connected(account)) {
					[super alertForAccountDeletion:dialog didReturn:NSAlertDefaultReturn];
				} else {
					deletionDialog = dialog;
					[self setShouldBeOnline:NO];
					// further progress happens in -accountConnectionDisconnected
				}
				break;
			default: // cancel
				[super alertForAccountDeletion:dialog didReturn:NSAlertAlternateReturn];
		}
	} else {
		switch(returnCode) {
			case NSAlertDefaultReturn:
				willBeDeleted = YES;
				deletionDialog = dialog;
				[self setShouldBeOnline:NO];
				// further progress happens in -accountConnectionDisconnected
				break;
			default:
				[super alertForAccountDeletion:dialog didReturn:returnCode];
		}
	}
}

- (void)unregisteredAccount:(BOOL)success {
	if(success) {
		willBeDeleted = YES;
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(setShouldBeOnline:)]];
		[inv setTarget:self];
		[inv setSelector:@selector(setShouldBeOnline:)];
		static BOOL nope = NO;
		[inv setArgument:&nope atIndex:2];
		[inv performSelector:@selector(invoke) withObject:nil afterDelay:0.0];
		// further progress happens in -accountConnectionDisconnected
	} else {
		[super alertForAccountDeletion:deletionDialog didReturn:NSAlertAlternateReturn];
		deletionDialog = nil;
	}
}

/*!
* @brief The account's UID changed
 */
- (void)didChangeUID
{
	//Only need to take action if we have a created PurpleAccount already
	if (account != NULL) {
		//Remove our current account
		[purpleThread removeAdiumAccount:self];
		
		//Clear the reference to the PurpleAccount... it'll be created when needed
		account = NULL;
	}
}

- (void)dealloc
{	
	[[adium preferenceController] unregisterPreferenceObserver:self];

	[lastDisconnectionError release]; lastDisconnectionError = nil;
		
	[permittedContactsArray release];
	[deniedContactsArray release];
	
    [super dealloc];
}

- (NSString *)unknownGroupName {
    return (@"Unknown");
}

- (NSDictionary *)defaultProperties { return [NSDictionary dictionary]; }

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	return [self encodedAttributedString:inAttributedString forListObject:nil];	
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];

	if ([group isEqualToString:PREF_GROUP_ALIASES]) {
		//If the notification object is a listContact belonging to this account, update the serverside information
		if ((account != nil) && 
			([self shouldSetAliasesServerside]) &&
			([key isEqualToString:@"Alias"])) {

			NSString *alias = [object preferenceForKey:@"Alias"
												 group:PREF_GROUP_ALIASES 
								 ignoreInheritedValues:YES];

			if ([object isKindOfClass:[AIMetaContact class]]) {
				NSEnumerator	*enumerator = [[(AIMetaContact *)object containedObjects] objectEnumerator];
				AIListContact	*containedListContact;
				while ((containedListContact = [enumerator nextObject])) {
					if ([containedListContact account] == self) {
						[purpleThread setAlias:alias forUID:[containedListContact UID] onAccount:self];
					}
				}
				
			} else if ([object isKindOfClass:[AIListContact class]]) {
				if ([(AIListContact *)object account] == self) {
					[purpleThread setAlias:alias forUID:[object UID] onAccount:self];
				}
			}
		}
	}
}

/***************************/
/* Account private methods */
/***************************/
#pragma mark Private
- (void)setTypingFlagOfChat:(AIChat *)chat to:(NSNumber *)typingStateNumber
{
    AITypingState currentTypingState = [chat integerStatusObjectForKey:KEY_TYPING];
	AITypingState newTypingState = [typingStateNumber intValue];

    if (currentTypingState != newTypingState) {
		[chat setStatusObject:(newTypingState ? typingStateNumber : nil)
					   forKey:KEY_TYPING
					   notify:NotifyNow];
    }
}

- (void)displayError:(NSString *)errorDesc
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Error",[self UID],[[self service] shortDescription]]
                                    withDescription:errorDesc];
}

- (NSNumber *)shouldCheckMail
{
	return [self preferenceForKey:KEY_ACCOUNT_CHECK_MAIL group:GROUP_ACCOUNT_STATUS];
}

- (BOOL)shouldSetAliasesServerside
{
	return NO;
}

- (NSString *)internalObjectID
{
	return [super internalObjectID];
}

@end
