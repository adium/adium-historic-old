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
#import "AIStatusController.h"
#import "AIPreferenceController.h"
#import "CBGaimAccount.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AISystemNetworkDefaults.h>
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

#import "adiumGaimRequest.h"

#define NO_GROUP						@"__NoGroup__"

#define AUTO_RECONNECT_DELAY		2.0	//Delay in seconds
#define RECONNECTION_ATTEMPTS		4

#define	PREF_GROUP_ALIASES			@"Aliases"		//Preference group to store aliases in

@interface CBGaimAccount (PRIVATE)
- (NSString *)_userIconCachePath;
- (NSString *)_emoticonCachePathForChat:(AIChat *)inChat;

- (NSString *)_mapIncomingGroupName:(NSString *)name;
- (NSString *)_mapOutgoingGroupName:(NSString *)name;

- (void)setTypingFlagOfChat:(AIChat *)inChat to:(NSNumber *)typingState;

- (AIChat*)_openChatWithContact:(AIListContact *)contact andConversation:(GaimConversation*)conv;

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date;
- (void)_sentMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat toDestinationListContact:(AIListContact *)destinationContact flags:(GaimMessageFlags)flags date:(NSDate *)date;
- (NSString *)_messageImageCachePathForID:(int)imageID;

- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;

- (void)displayError:(NSString *)errorDesc;
- (NSNumber *)shouldCheckMail;

- (void)updateStatusForKey:(NSString *)key immediately:(BOOL)immediately;

- (void)configureGaimAccountNotifyingTarget:(id)target selector:(SEL)selector;
- (void)continueConnectWithConfiguredGaimAccount;
- (void)continueConnectWithConfiguredProxy;
- (void)gotProxyServerPassword:(NSString *)inPassword context:(NSInvocation *)invocation;
- (void)continueRegisterWithConfiguredGaimAccount;

- (void)setAccountProfileTo:(NSAttributedString *)profile configureGaimAccountContext:(NSInvocation *)inInvocation;

- (void)performAccountMenuAction:(NSMenuItem *)sender;

- (void)enqueueMessage:(AIContentMessage *)inMessage forChat:(AIChat *)inChat;
@end

@implementation CBGaimAccount

static SLGaimCocoaAdapter *gaimThread = nil;

// The GaimAccount currently associated with this Adium account
- (GaimAccount*)gaimAccount
{
	//Create a gaim account if one does not already exist
	if (!account) {
		[self createNewGaimAccount];
		GaimDebug(@"%x: created GaimAccount 0x%x with UID %@, protocolPlugin %s", [NSRunLoop currentRunLoop],account, [self UID], [self protocolPlugin]);
	}
	
    return account;
}

- (SLGaimCocoaAdapter *)gaimThread
{
	return gaimThread;
}

gboolean gaim_init_ssl_openssl_plugin(void);
- (void)initSSL
{
	static BOOL didInitSSL = NO;

	if (!didInitSSL) {
		didInitSSL = gaim_init_ssl_openssl_plugin();
		if (!didInitSSL) {
			NSLog(@"*** Unabled to initialize openssl ***");
			GaimDebug(@"*** Unabled to initialize openssl ***");
		} else {
			GaimDebug(@"+++ Initialized OpenSSL (%x).",gaim_ssl_get_ops());
		}
	}
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

		if (groupName && [groupName isEqualToString:@GAIM_ORPHANS_GROUP_NAME]) {
			[theContact setRemoteGroupName:AILocalizedString(@"Orphans","Name for the orphans group")];
		} else if (groupName && [groupName length] != 0) {
			[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
		} else {
			[theContact setRemoteGroupName:[self _mapIncomingGroupName:nil]];
		}
		
		[self gotGroupForContact:theContact];
	} else {
		GaimDebug(@"Got %@ for %@ while not online",groupName,theContact);
	}
}

/*
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

- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias
{
	if (![[gaimAlias compactedString] isEqualToString:[[theContact UID] compactedString]]) {
		//Store this alias as the serverside display name so long as it isn't identical when unformatted to the UID
		[theContact setServersideAlias:gaimAlias
					   asStatusMessage:[self useDisplayNameAsStatusMessage]
							  silently:silentAndDelayed];

	} else {
		//If it's the same characters as the UID, apply it as a formatted UID
		if (![gaimAlias isEqualToString:[theContact formattedUID]] && 
			![gaimAlias isEqualToString:[theContact UID]]) {
			[theContact setFormattedUID:gaimAlias
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
 * @brief Status name to use for a Gaim buddy
 *
 * Called by SLGaimCocoaAdapter on the gaim thread
 */
- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)buddy
{
	return nil;
}

/*!
 * @brief Status message for a contact
 *
 * Called by SLGaimCocoaAdapter on the gaim thread
 */
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)buddy
{
	GaimPresence	*presence = gaim_buddy_get_presence(buddy);
	GaimStatus		*status = (presence ? gaim_presence_get_active_status(presence) : NULL);
	const char		*message = (status ? gaim_status_get_attr_string(status, "message") : NULL);
	NSString		*messageString = (message ? [NSString stringWithUTF8String:message] : nil);

	NSAttributedString	*statusMessage = nil;

	if (messageString) {
		// We use our own HTML decoder to avoid conflicting with the shared one, since we are running in a thread
		static AIHTMLDecoder	*statusMessageHTMLDecoder = nil;
		if (!statusMessageHTMLDecoder) statusMessageHTMLDecoder = [[AIHTMLDecoder decoder] retain];
	
		statusMessage = [statusMessageHTMLDecoder decodeHTML:messageString];
	}
	
	return statusMessage;
}

/*!
 * @brief Update the status message and away state of the contact
 *
 *  Called by SLGaimCocoaAdapter on the main thread
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

- (void)updateUserInfo:(AIListContact *)theContact withData:(NSString *)userInfoString
{
	[theContact setProfile:[AIHTMLDecoder decodeHTML:userInfoString]
					notify:NotifyLater];
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

/*!
 * @brief Gaim removed a contact from the local blist
 *
 * This can happen in many situations:
 *	- For every contact on an account when the account signs off
 *	- For a contact as it is deleted by the user
 *	- For a contact as it is deleted by Gaim (e.g. when Sametime refuses an addition because it is known to be invalid)
 *	- In the middle of the move process as a contact moves from one group to another
 *
 * We need not take any action; we'll be notified of changes by Gaim as necessary.
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
	[gaimThread getInfoFor:[inContact UID] onAccount:self];
}

- (void)requestAddContactWithUID:(NSString *)contactUID
{
	[[adium contactController] requestAddContactWithUID:contactUID
												service:[self _serviceForUID:contactUID]];
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

		//Have the gaim thread perform the serverside actions
		[gaimThread removeUID:[object UID] onAccount:self fromGroup:groupName];
		
		//Remove it from Adium's list
		[object setRemoteGroupName:nil];
	}
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)inGroup
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];
	
	while ((object = [enumerator nextObject])) {
		[gaimThread addUID:[self _UIDForAddingObject:object] onAccount:self toGroup:groupName];
		
		//Add it to Adium's list
		[object setRemoteGroupName:[inGroup UID]]; //Use the non-mapped group name locally
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
			
			//Tell the gaim thread to perform the serverside operation
			[gaimThread moveUID:[listObject UID] onAccount:self toGroup:groupName];

			//Use the non-mapped group name locally
			[listObject setRemoteGroupName:[group UID]];
		}
	}		
}

- (void)renameGroup:(AIListGroup *)inGroup to:(NSString *)newName
{
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];

	//Tell the gaim thread to perform the serverside operation	
	[gaimThread renameGroup:groupName onAccount:self to:newName];

	//We must also update the remote grouping of all our contacts in that group
	NSEnumerator	*enumerator = [[[adium contactController] allContactsInGroup:inGroup subgroups:YES onAccount:self] objectEnumerator];
	AIListContact	*contact;
	
	while ((contact = [enumerator nextObject])) {
		//Evan: should we use groupName or newName here?
		[contact setRemoteGroupName:newName];
	}
}

- (void)deleteGroup:(AIListGroup *)inGroup
{
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];

	[gaimThread deleteGroup:groupName onAccount:self];
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return [self online];
}

- (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict didAuthorize:(BOOL)inDidAuthorize
{
	id		 callback;
	NSNumber *indexNumber;
	
	//Inform libgaim that the request window closed
	[ESGaimRequestAdapter requestCloseWithHandle:inWindowController];

	if (inDidAuthorize) {
		callback = [[[infoDict objectForKey:@"authorizeCB"] retain] autorelease];
		indexNumber = [NSNumber numberWithInt:0];
	} else {
		callback = [[[infoDict objectForKey:@"denyCB"] retain] autorelease];
		indexNumber = [NSNumber numberWithInt:1];		
	}

	[gaimThread doAuthRequestCbValue:callback
				   withUserDataValue:[[[infoDict objectForKey:@"userData"] retain] autorelease]
				 callBackIndexNumber:indexNumber
					 isInputCallback:[[[infoDict objectForKey:@"isInputCallback"] retain] autorelease]];
}

//Chats ------------------------------------------------------------
#pragma mark Chats

/*
 * @brief Called by Gaim code when a chat should be opened by the interface
 *
 * If the user sent an initial message, this will be triggered and have no effect.
 *
 * If a remote user sent an initial message, however, a chat will be created without being opened.  This call is our
 * cue to actually open chat.
 *
 * Another situation in which this is relevant is when we request joining a group chat; the chat should only be actually
 * opened once the server notifies us that we are in the room.
 *
 * This will ultimately call -[CBGaimAccount openChat:] below if the chat was not previously open.
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
	
	AILog(@"gaim openChat:%@ for %@",chat,[chat uniqueChatID]);

	//Inform gaim that we have opened this chat
	[gaimThread openChat:chat onAccount:self];
	
	//Created the chat successfully
	return YES;
}

- (BOOL)closeChat:(AIChat*)chat
{
	[gaimThread closeChat:chat];
	
	//Be sure any remaining typing flag is cleared as the chat closes
	[self setTypingFlagOfChat:chat to:nil];
	AILog(@"gaim closeChat:%@",[chat uniqueChatID]);
	
    return YES;
}

- (AIChat *)mainThreadChatWithContact:(AIListContact *)contact
{
	AIChat *chat;

	//First, make sure the chat is created
	[[adium chatController] mainPerformSelector:@selector(chatWithContact:)
									 withObject:contact
								  waitUntilDone:YES];

	//Now return the existing chat
	chat = [[adium chatController] existingChatWithContact:contact];

	return chat;
}

- (AIChat *)mainThreadChatWithName:(NSString *)name
{
	AIChat *chat;

	/*
	 First, make sure the chat is created - we will get here from a call in which Gaim has already
	 created the GaimConversation, so there's no need for a chatCreationInfo dictionary.
	 */
	[[adium chatController] mainPerformSelector:@selector(chatWithName:onAccount:chatCreationInfo:)
										withObject:name
										withObject:self
										withObject:nil
									 waitUntilDone:YES];

	//Now return the existing chat
	chat = [[adium chatController] existingChatWithName:name onAccount:self];
	
	return chat;
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
	[chat setStatusObject:type forKey:KEY_CHAT_ERROR notify:NotifyNow];
	[chat setStatusObject:nil forKey:KEY_CHAT_ERROR notify:NotifyNever];
}

- (void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{
	GaimMessageFlags		flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	
	if ((flags & GAIM_MESSAGE_SEND) != 0) {
        //Gaim is telling us that our message was sent successfully.		

		//We can now tell the other side that we're done typing
		//[gaimThread sendTyping:AINotTyping inChat:chat];
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
	GaimMessageFlags		flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	NSAttributedString		*attributedMessage;
	NSDate					*date;
	
	attributedMessage = [messageDict objectForKey:@"AttributedMessage"];
	date = [messageDict objectForKey:@"Date"];
	
	if ((flags & GAIM_MESSAGE_SEND) != 0) {
        //Gaim is telling us that our message was sent successfully.		

		//We can now tell the other side that we're done typing
		//[gaimThread sendTyping:AINotTyping inChat:chat];
		
	} else {
		NSString			*source = [messageDict objectForKey:@"Source"];

		//We display the message locally when it is sent.  If the protocol sends the message back to us, we should
		//simply ignore it (MSN does this when a display name is set, for example).
		if (![source isEqualToString:[self UID]]) {
			AIListContact	*listContact;
			
			//source may be (null) for system messages like topic changes
			listContact = (source ? [self contactWithUID:source] : nil);

			if (listContact) {
				[self _receivedMessage:attributedMessage
								inChat:chat 
					   fromListContact:listContact
								 flags:flags
								  date:date];
			} else {
				//If we didn't get a listContact, this is a gaim status message... display it as such.
				[[adium contentController] displayStatusMessage:[attributedMessage string]
														ofType:@"gaim"
														inChat:chat];

			}
		}
	}
}

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date
{
	AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
														   withSource:sourceContact
														  destination:self
																 date:date
															  message:attributedMessage
															autoreply:(flags & GAIM_MESSAGE_AUTO_RESP) != 0];
	
	if (!customEmoticonWaitingDict ||
		![[[customEmoticonWaitingDict objectForKey:[chat uniqueChatID]] objectForKey:@"WaitingCount"] intValue]) {
		[[adium contentController] receiveContentObject:messageObject];

	} else {
		//If this chat is waiting on a custom emoticon, queue display of the message
		[self enqueueMessage:messageObject forChat:chat];
	}
}

/*********************/
/* AIAccount_Content */
/*********************/
#pragma mark Content
- (BOOL)sendTypingObject:(AIContentTyping *)inContentTyping
{
	AIChat *chat = [inContentTyping chat];

	if (![chat isGroupChat]) {
		[gaimThread sendTyping:[inContentTyping typingState] inChat:chat];
	}

	return YES;
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	GaimMessageFlags		flags = GAIM_MESSAGE_RAW;
	
	if ([inContentMessage isAutoreply]) {
		flags |= GAIM_MESSAGE_AUTO_RESP;
	}

	[gaimThread sendEncodedMessage:[inContentMessage encodedMessage]
					   fromAccount:self
							inChat:[inContentMessage chat]
						 withFlags:flags];
	
	return YES;
}

/*
 * @brief Return the string encoded for sending to a remote contact
 *
 * We return nil if the string turns out to have been a / command.
 */
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	NSString	*encodedString;
	BOOL		didCommand = [gaimThread attemptGaimCommandOnMessage:[inContentMessage messageString]
														 fromAccount:(AIAccount *)[inContentMessage source]
															  inChat:[inContentMessage chat]];	
	
	encodedString = (didCommand ?
					 nil :
					 [super encodedAttributedStringForSendingContentMessage:inContentMessage]);

	return encodedString;
}

/*
 * @brief Allow newlines in messages
 *
 * Only IRC doesn't allow newlines out of the built-in prpls... and we don't even support it yet.
 * This method is never called at present.
 */
- (BOOL)allowsNewlinesInMessages
{
	return (account && account->gc && (account->gc->flags & GAIM_CONNECTION_NO_NEWLINES));
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
    } else if (([inType isEqualToString:FILE_TRANSFER_TYPE]) && ([self conformsToProtocol:@protocol(AIAccount_Files)])) {
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
	return YES;
}

// **XXX** Not used at present. Do we want to?
- (BOOL)shouldSendAutoresponsesWhileAway
{
	if (account && account->gc) {
		return (account->gc->flags & GAIM_CONNECTION_AUTO_RESP);
	}
	
	return NO;
}

#pragma mark Custom emoticons and message queuing
- (void)enqueueMessage:(AIContentMessage *)inMessage forChat:(AIChat *)inChat
{
	NSMutableDictionary *chatDict;
	NSMutableArray		*queuedMessages;

	if (!(chatDict = [customEmoticonWaitingDict objectForKey:[inChat uniqueChatID]])) {
		chatDict = [NSMutableDictionary dictionary];
		[customEmoticonWaitingDict setObject:chatDict
									  forKey:[inChat uniqueChatID]];
	}
	
	if (!(queuedMessages = [chatDict objectForKey:@"QueuedMessages"])) {
		queuedMessages = [NSMutableArray array];
		[chatDict setObject:queuedMessages
					 forKey:@"QueuedMessages"];
	}
	
	[queuedMessages addObject:inMessage];
}

- (void)dequeueWaitingMessagesForChat:(AIChat *)inChat
{
	NSMutableDictionary *chatDict;
	NSMutableArray		*queuedMessages;
	NSEnumerator		*enumerator;
	AIContentMessage	*messageObject;

	chatDict = [customEmoticonWaitingDict objectForKey:[inChat uniqueChatID]];
	queuedMessages = [chatDict objectForKey:@"QueuedMessages"];
	
	enumerator = [queuedMessages objectEnumerator];
	while ((messageObject = [enumerator nextObject])) {
		[[adium contentController] receiveContentObject:messageObject];
	}
}

- (void)chat:(AIChat *)inChat isWaitingOnCustomEmoticon:(NSNumber *)isWaiting
{
	if ([isWaiting boolValue]) {
		NSMutableDictionary *chatDict;
		NSNumber			*waitingNumber;

		if (!customEmoticonWaitingDict) customEmoticonWaitingDict = [[NSMutableDictionary alloc] init];

		if (!(chatDict = [customEmoticonWaitingDict objectForKey:[inChat uniqueChatID]])) {
			chatDict = [NSMutableDictionary dictionary];
			[customEmoticonWaitingDict setObject:chatDict
										  forKey:[inChat uniqueChatID]];
		}
		
		if ((waitingNumber = [chatDict objectForKey:@"WaitingCount"])) {
			waitingNumber = [NSNumber numberWithInt:([waitingNumber intValue] + 1)];
		} else {
			waitingNumber = [NSNumber numberWithInt:1];
		}
		
		[chatDict setObject:waitingNumber
					 forKey:@"WaitingCount"];		
	} else {
		NSMutableDictionary *chatDict;
		NSNumber			*waitingNumber;
		
		chatDict = [customEmoticonWaitingDict objectForKey:[inChat uniqueChatID]];
		waitingNumber = [chatDict objectForKey:@"WaitingCount"];
		
		if ([waitingNumber intValue] > 1) {
			waitingNumber = [NSNumber numberWithInt:([waitingNumber intValue] - 1)];
			[chatDict setObject:waitingNumber
						 forKey:@"WaitingCount"];
		} else {
			//We now are not waiting
			[self dequeueWaitingMessagesForChat:inChat];
			
			//No further need for the dict
			[customEmoticonWaitingDict removeObjectForKey:[inChat uniqueChatID]];
			
			if (![customEmoticonWaitingDict count]) {
				[customEmoticonWaitingDict release]; customEmoticonWaitingDict = nil;
			}
		}
	}
}

- (void)chat:(AIChat *)inChat setCustomEmoticon:(NSString *)emoticonEquivalent withImageData:(NSData *)inImageData
{
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
	NSString	*path = [self _emoticonCachePathForChat:inChat];
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

#pragma mark GaimConversation User Lists
- (void)addUsersArray:(NSArray *)usersArray
			withFlags:(NSArray *)flagsArray
		   andAliases:(NSArray *)aliasesArray 
		  newArrivals:(NSNumber *)newArrivals
			   toChat:(AIChat *)chat
{
	int			i, count;
	BOOL		isNewArrival = (newArrivals && [newArrivals boolValue]);

	GaimDebug(@"*** %@: addUsersArray:%@ toChat:%@",self,usersArray,chat);

	count = [usersArray count];
	for (i = 0; i < count; i++) {
		NSString				*contactName;
		NSString				*alias;
		AIListContact			*listContact;
		GaimConvChatBuddyFlags	flags;

		contactName = [usersArray objectAtIndex:i];
		flags = [[flagsArray objectAtIndex:i] intValue];
		alias = [aliasesArray objectAtIndex:i];

		listContact = [self contactWithUID:contactName];
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
		(contact = [self contactWithUID:contactName])) {
		
		[chat removeParticipatingListObject:contact];
		
		GaimDebug(@"%@ removeUser:%@ fromChat:%@",self,contact,chat);
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
- (BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
    if (type == PRIVACY_PERMIT)
        return (gaim_privacy_permit_add(account,[[inObject UID] UTF8String],FALSE));
    else
        return (gaim_privacy_deny_add(account,[[inObject UID] UTF8String],FALSE));
}

- (BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
    if (type == PRIVACY_PERMIT)
        return (gaim_privacy_permit_remove(account,[[inObject UID] UTF8String],FALSE));
    else
        return (gaim_privacy_deny_remove(account,[[inObject UID] UTF8String],FALSE));
}

- (NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type
{
	return (type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray);
}

- (NSArray *)listObjectIDsOnPrivacyList:(PRIVACY_TYPE)type
{
	NSArray *listObjectArray = [self listObjectsOnPrivacyList:type];
	NSMutableArray *idArray =  [[NSMutableArray alloc] initWithCapacity:[listObjectArray count]];
	NSEnumerator *enumerator = [listObjectArray objectEnumerator];
	AIListObject *object = nil;
	
	while ((object = [enumerator nextObject])) {
		[idArray addObject:[object UID]];
	}
	
	return [idArray autorelease];
}

- (void)privacyPermitListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_PERMIT added:sourceUID];
}

- (void)privacyDenyListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_DENY added:sourceUID];
}

- (void)accountPrivacyList:(PRIVACY_TYPE)type added:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]) {
		//Get our contact
		AIListContact   *contact = [self contactWithUID:sourceUID];
		
		[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) addObject:contact];
	}
}

- (void)privacyPermitListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_PERMIT removed:sourceUID];
}

- (void)privacyDenyListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_DENY removed:sourceUID];
}

- (void)accountPrivacyList:(PRIVACY_TYPE)type removed:(NSString *)sourceUID
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
			[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) removeObject:contact];
		}
	}
}

- (void)setPrivacyOptions:(PRIVACY_OPTION)option
{
	if (account && gaim_account_get_connection(account)) {
		GaimPrivacyType privacyType;

		switch (option) {
			case PRIVACY_ALLOW_ALL:
			default:
				privacyType = GAIM_PRIVACY_ALLOW_ALL;
				break;
			case PRIVACY_DENY_ALL:
				privacyType = GAIM_PRIVACY_DENY_ALL;
				break;
			case PRIVACY_ALLOW_USERS:
				privacyType = GAIM_PRIVACY_ALLOW_USERS;
				break;
			case PRIVACY_DENY_USERS:
				privacyType = GAIM_PRIVACY_DENY_USERS;
				break;
			case PRIVACY_ALLOW_CONTACTLIST:
				privacyType = GAIM_PRIVACY_ALLOW_BUDDYLIST;
				break;
			
		}
		account->perm_deny = privacyType;
		serv_set_permit_deny(gaim_account_get_connection(account));
	} else {
		AILog(@"Couldn't set privacy options for %@ (%x %x)",self,account,gaim_account_get_connection(account));
	}
}

- (PRIVACY_OPTION)privacyOptions
{
	PRIVACY_OPTION privacyOption = -1;
	
	if (account) {
		GaimPrivacyType privacyType = account->perm_deny;
		
		switch (privacyType) {
			case GAIM_PRIVACY_ALLOW_ALL:
			default:
				privacyOption = PRIVACY_ALLOW_ALL;
				break;
			case GAIM_PRIVACY_DENY_ALL:
				privacyOption = PRIVACY_DENY_ALL;
				break;
			case GAIM_PRIVACY_ALLOW_USERS:
				privacyOption = PRIVACY_ALLOW_USERS;
				break;
			case GAIM_PRIVACY_DENY_USERS:
				privacyOption = PRIVACY_DENY_USERS;
				break;
			case GAIM_PRIVACY_ALLOW_BUDDYLIST:
				privacyOption = PRIVACY_ALLOW_CONTACTLIST;
				break;
		}
	}

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
	GaimXfer *xfer = [self newOutgoingXferForFileTransfer:fileTransfer];
	
	if (xfer) {
		//Associate the fileTransfer and the xfer with each other
		[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
		xfer->ui_data = [fileTransfer retain];
		
		//Set the filename
		gaim_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
		gaim_xfer_set_filename(xfer, [[[fileTransfer localFilename] lastPathComponent] UTF8String]);
		
		/*
		 Request that the transfer begins.
		 We will be asked to accept it via:
			- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
		 below.
		 */
		[gaimThread xferRequest:xfer];
	}
}
//By default, protocols can not create GaimXfer objects
- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	GaimPluginProtocolInfo	*prpl_info;
	GaimXfer				*newGaimXfer = NULL;

	if (account && gaim_account_get_connection(account)) {
		GaimConnection *gc = gaim_account_get_connection(account);
		prpl_info = GAIM_PLUGIN_PROTOCOL_INFO(gc->prpl);

		if (prpl_info && prpl_info->new_xfer) {
			char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
			newGaimXfer = (prpl_info->new_xfer)(gc, destsn);
		}
	}

	return newGaimXfer;
}

/* 
 * @brief The account requested that we received a file.
 *
 * Set up the ESFileTransfer and query the fileTransferController for a save location.
 * 
 * @result The window controller for the window prompting the user to take action, or nil if no prompt was shown
 */
- (AIWindowController *)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	GaimDebug(@"File transfer request received: %@",fileTransfer);
	return [[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

- (ESFileTransfer *)_mainThreadNewFileTransferObjectWith:(NSString *)destinationUID
													size:(NSNumber *)inSize
										  remoteFilename:remoteFilename
{
	AIListContact   *contact = [self contactWithUID:destinationUID];
    ESFileTransfer	*fileTransfer;
	
	fileTransfer = [[adium fileTransferController] newFileTransferWithContact:contact
																   forAccount:self]; 
	[fileTransfer setSize:[inSize unsignedLongLongValue]];
	[fileTransfer setRemoteFilename:remoteFilename];

    return fileTransfer;
}
//Create an ESFileTransfer object from an xfer
- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID
										 size:(unsigned long long)inSize
							   remoteFilename:(NSString *)remoteFilename
{
	return [self mainPerformSelector:@selector(_mainThreadNewFileTransferObjectWith:size:remoteFilename:)
						  withObject:destinationUID
						  withObject:[NSNumber numberWithUnsignedLongLong:inSize]
						  withObject:remoteFilename
						 returnValue:YES];
}

//Update an ESFileTransfer object progress
- (void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	float percentDone = [percent floatValue];
    [fileTransfer setPercentDone:percentDone bytesSent:[bytesSent unsignedLongValue]];
}

//The local side canceled the transfer.  We probably already have this status set, but set it just in case.
- (void)fileTransferCanceledLocally:(ESFileTransfer *)fileTransfer
{
	[fileTransfer setStatus:Canceled_Local_FileTransfer];
}

//The remote side canceled the transfer, the fool. Update our status.
- (void)fileTransferCanceledRemotely:(ESFileTransfer *)fileTransfer
{
	[fileTransfer setStatus:Canceled_Remote_FileTransfer];
}

- (void)destroyFileTransfer:(ESFileTransfer *)fileTransfer
{
	GaimDebug(@"Destroy file transfer %@",fileTransfer);
	[fileTransfer release];
}

//Accept a send or receive ESFileTransfer object, beginning the transfer.
//Subsequently inform the fileTransferController that the fun has begun.
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    GaimDebug(@"Accepted file transfer %@",fileTransfer);
	
	GaimXfer		*xfer;
	GaimXferType	xferType;
	
	xfer = [[fileTransfer accountData] pointerValue];

    xferType = gaim_xfer_get_type(xfer);
    if ( xferType == GAIM_XFER_SEND ) {
        [fileTransfer setType:Outgoing_FileTransfer];   
    } else if ( xferType == GAIM_XFER_RECEIVE ) {
        [fileTransfer setType:Incoming_FileTransfer];
		[fileTransfer setSize:(xfer->size)];
    }
    
    //accept the request
	[gaimThread xferRequestAccepted:xfer withFileName:[fileTransfer localFilename]];
    
	//set the size - must be done after request is accepted?

	
	[fileTransfer setStatus:Accepted_FileTransfer];
}

//User refused a receive request.  Tell gaim; we don't release the ESFileTransfer object
//since that will happen when the xfer is destroyed.  This will end up calling back on
//- (void)fileTransferCanceledLocally:(ESFileTransfer *)fileTransfer
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
	GaimXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[gaimThread xferRequestRejected:xfer];
	}
}

//Cancel a file transfer in progress.  Tell gaim; we don't release the ESFileTransfer object
//since that will happen when the xfer is destroyed.  This will end up calling back on
//- (void)fileTransferCanceledLocally:(ESFileTransfer *)fileTransfer
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	GaimXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[gaimThread xferCancel:xfer];
	}	
}

//Account Connectivity -------------------------------------------------------------------------------------------------
#pragma mark Connect
//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	[super connect];
	
	if (!account) {
		//create a gaim account if one does not already exist
		[self createNewGaimAccount];
		GaimDebug(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
	//Make sure our settings are correct
	[self configureGaimAccountNotifyingTarget:self selector:@selector(continueConnectWithConfiguredGaimAccount)];
}

- (void)continueConnectWithConfiguredGaimAccount
{
	//Configure libgaim's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxyNotifyingTarget:self selector:@selector(continueConnectWithConfiguredProxy)];
}

- (void)continueConnectWithConfiguredProxy
{
	//Set password and connect
	gaim_account_set_password(account, [password UTF8String]);

	//Set our current status state after filtering its statusMessage as appropriate. This will take us online in the process.
	AIStatus	*statusState = [self statusObjectForKey:@"StatusState"];
	if (!statusState) {
		statusState = [[adium statusController] defaultInitialStatusState];
	}

	GaimDebug(@"Adium: Connect: %@ initiating connection using status state %@.",[self UID],statusState);

	[self autoRefreshingOutgoingContentForStatusKey:@"StatusState"
										   selector:@selector(gotFilteredStatusMessage:forStatusState:)
											context:statusState];
}


//Make sure our settings are correct; notify target/selector when we're finished
- (void)configureGaimAccountNotifyingTarget:(id)target selector:(SEL)selector
{
	NSInvocation	*contextInvocation;
	
	//Perform the synchronous configuration activities (subclasses may want to take action in this function)
	[self configureGaimAccount];
	
	contextInvocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	
	[contextInvocation setTarget:target];
	[contextInvocation setSelector:selector];
	[contextInvocation retainArguments];

	//Set the text profile BEFORE beginning the connect process, to avoid problems with setting it while the
	//connect occurs. Once that's done, contextInvocation will be invoked, continuing the configureGaimAccount process.
	[self autoRefreshingOutgoingContentForStatusKey:@"TextProfile" 
										   selector:@selector(setAccountProfileTo:configureGaimAccountContext:)
											context:contextInvocation];
}

//Synchronous gaim account configuration activites, always performed after an account is created.
//This is a definite subclassing point so prpls can apply their own account settings.
- (void)configureGaimAccount
{
	NSString	*hostName;
	int			portNumber;

	//Host (server)
	hostName = [self host];
	if (hostName && [hostName length]) {
		gaim_account_set_string(account, "server", [hostName UTF8String]);
	}
	
	//Port
	portNumber = [self port];
	if (portNumber) {
		gaim_account_set_int(account, "port", portNumber);
	}
	
	/*
	 XXX: This is a hack for 0.8. Since we don't have a full privacy UI yet, we automatically set our privacy setting to
	 the best one to use.
	*/
#warning Should we still be doing this in 0.9?
	[gaimThread setDefaultPermitDenyForAccount:self];
	
	//E-mail checking
	gaim_account_set_check_mail(account, [[self shouldCheckMail] boolValue]);
	
	//Update a few status keys before we begin connecting.  Libgaim will send these automatically
    [self updateStatusForKey:KEY_USER_ICON];
}

//Configure libgaim's proxy settings using the current system values
- (void)configureAccountProxyNotifyingTarget:(id)target selector:(SEL)selector
{
	GaimProxyInfo		*proxy_info;
	GaimProxyType		gaimAccountProxyType = GAIM_PROXY_NONE;
	
	NSNumber			*proxyPref = [self preferenceForKey:KEY_ACCOUNT_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	BOOL				proxyEnabled = [[self preferenceForKey:KEY_ACCOUNT_PROXY_ENABLED group:GROUP_ACCOUNT_STATUS] boolValue];

	NSString			*host = nil;
	NSString			*proxyUserName = nil;
	NSString			*proxyPassword = nil;
	AdiumProxyType  	proxyType;
	int					port = 0;
	NSInvocation		*invocation; 
	
	//Configure the invocation we will use when we are done configuring
	invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:target];
		
	proxy_info = gaim_proxy_info_new();
	gaim_account_set_proxy_info(account, proxy_info);
	
	proxyType = (proxyPref ? [proxyPref intValue] : Adium_Proxy_Default_SOCKS5);
	
	if (!proxyEnabled) {
		//No proxy
		gaim_proxy_info_set_type(proxy_info, GAIM_PROXY_NONE);
		GaimDebug(@"Adium: Connect: %@ Connecting with no proxy.",[self UID]);
		[invocation invoke];
		
	} else if ((proxyType == Adium_Proxy_Default_SOCKS5) || 
			  (proxyType == Adium_Proxy_Default_HTTP) || 
			  (proxyType == Adium_Proxy_Default_SOCKS4)) {
		//Load and use systemwide proxy settings
		NSDictionary *systemProxySettingsDictionary;
		ProxyType adiumProxyType = Proxy_None;
		
		if (proxyType == Adium_Proxy_Default_SOCKS5) {
			gaimAccountProxyType = GAIM_PROXY_SOCKS5;
			adiumProxyType = Proxy_SOCKS5;
			
		} else if (proxyType == Adium_Proxy_Default_HTTP) {
			gaimAccountProxyType = GAIM_PROXY_HTTP;
			adiumProxyType = Proxy_HTTP;
			
		} else if (proxyType == Adium_Proxy_Default_SOCKS4) {
				gaimAccountProxyType = GAIM_PROXY_SOCKS4;
				adiumProxyType = Proxy_SOCKS4;
		}
		
		GaimDebug(@"Loading proxy dictionary.");
		
		if ((systemProxySettingsDictionary = [AISystemNetworkDefaults systemProxySettingsDictionaryForType:adiumProxyType])) {

			GaimDebug(@"Retrieved %@",systemProxySettingsDictionary);

			host = [systemProxySettingsDictionary objectForKey:@"Host"];
			port = [[systemProxySettingsDictionary objectForKey:@"Port"] intValue];
			
			proxyUserName = [systemProxySettingsDictionary objectForKey:@"Username"];
			proxyPassword = [systemProxySettingsDictionary objectForKey:@"Password"];
			
		} else {
			//Using system wide defaults, and no proxy of the specified type is set in the system preferences
			gaimAccountProxyType = GAIM_PROXY_NONE;
		}
		
		gaim_proxy_info_set_type(proxy_info, gaimAccountProxyType);
		
		gaim_proxy_info_set_host(proxy_info, (char *)[host UTF8String]);
		gaim_proxy_info_set_port(proxy_info, port);
		
		if (proxyUserName && [proxyUserName length]) {
			gaim_proxy_info_set_username(proxy_info, (char *)[proxyUserName UTF8String]);
			if (proxyPassword && [proxyPassword length]) {
				gaim_proxy_info_set_password(proxy_info, (char *)[proxyPassword UTF8String]);
			}
		}
		
		GaimDebug(@"Systemwide proxy settings: %i %s:%i %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username);
		
		[invocation invoke];

	} else {
		host = [self preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
		port = [[self preferenceForKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS] intValue];
		
		switch (proxyType) {
			case Adium_Proxy_HTTP:
				gaimAccountProxyType = GAIM_PROXY_HTTP;
				break;
			case Adium_Proxy_SOCKS4:
				gaimAccountProxyType = GAIM_PROXY_SOCKS4;
				break;
			case Adium_Proxy_SOCKS5:
				gaimAccountProxyType = GAIM_PROXY_SOCKS5;
				break;
			case Adium_Proxy_Default_HTTP:
			case Adium_Proxy_Default_SOCKS4:
			case Adium_Proxy_Default_SOCKS5:
				gaimAccountProxyType = GAIM_PROXY_NONE;
				break;
		}
		
		gaim_proxy_info_set_type(proxy_info, gaimAccountProxyType);
		gaim_proxy_info_set_host(proxy_info, (char *)[host UTF8String]);
		gaim_proxy_info_set_port(proxy_info, port);
		
		//If we need to authenticate, request the password and finish setting up the proxy in gotProxyServerPassword:context:
		proxyUserName = [self preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
		if (proxyUserName && [proxyUserName length]) {
			gaim_proxy_info_set_username(proxy_info, (char *)[proxyUserName UTF8String]);
			
			[[adium accountController] passwordForProxyServer:host 
													 userName:proxyUserName 
											  notifyingTarget:self 
													 selector:@selector(gotProxyServerPassword:context:)
													  context:invocation];
		} else {
			
			GaimDebug(@"Adium proxy settings: %i %s:%i",proxy_info->type,proxy_info->host,proxy_info->port);
			[invocation invoke];
		}
	}
}

//Retried the proxy password from the keychain
- (void)gotProxyServerPassword:(NSString *)inPassword context:(NSInvocation *)invocation
{
	GaimProxyInfo		*proxy_info = gaim_account_get_proxy_info(account);
	
	if (inPassword) {
		gaim_proxy_info_set_password(proxy_info, (char *)[inPassword UTF8String]);
		
		GaimDebug(@"GotPassword: Proxy settings: %i %s:%i %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username);

		[invocation invoke];

	} else {
		gaim_proxy_info_set_username(proxy_info, NULL);
		
		//We are no longer connecting
		[self setStatusObject:nil forKey:@"Connecting" notify:NotifyNow];
	}
}

//Sublcasses should override to provide a string for each progress step
- (NSString *)connectionStringForStep:(int)step { return nil; };

//Our account has connected
- (void)accountConnectionConnected
{
	AILog(@"************ %@ CONNECTED ***********",[self UID]);
	
	[self didConnect];
	
    //Silence updates
    [self silenceAllContactUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
	
    //Reset reconnection attempts
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;

	//Clear any previous disconnection error
	[lastDisconnectionError release]; lastDisconnectionError = nil;
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

/*
 * @brief Name to use when creating a GaimAccount for this CBGaimAccount
 *
 * By default, we just use the formattedUID.  Subclasses can override this to provide other handling,
 * such as appending @mac.com if necessary for dotMac accounts.
 */
- (const char *)gaimAccountName
{
	return [[self formattedUID] UTF8String];
}

- (void)createNewGaimAccount
{
	if (!gaimThread) {
		gaimThread = [[SLGaimCocoaAdapter sharedInstance] retain];	
	}	

	//Create a fresh version of the account
    account = gaim_account_new([self gaimAccountName], [self protocolPlugin]);
	account->perm_deny = GAIM_PRIVACY_DENY_USERS;

	[gaimThread addAdiumAccount:self];
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

		//Tell libgaim to disconnect
		[gaimThread disconnectAccount:self];
	}
}

/*!
 * @brief Our account was unexpectedly disconnected with an error message
 */
- (void)accountConnectionReportDisconnect:(NSString *)text
{
	//Retain the error message locally for use in -[CBGaimAccount accountConnectionDisconnected]
	if (lastDisconnectionError != text) {
		[lastDisconnectionError release];
		lastDisconnectionError = [text retain];
	}

	//We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:NotifyNow];
	
	GaimDebug(@"%@ reported disconnecting: %@",[self UID],lastDisconnectionError);
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
	//connectionIsSuicidal == TRUE when Gaim thinks we shouldn't attempt a reconnect.
	if ([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]/* && lastDisconnectionError*/) {
		if (reconnectAttemptsRemaining && 
			[self shouldAttemptReconnectAfterDisconnectionError:&lastDisconnectionError] && !(connectionIsSuicidal)) {
			
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
			[self setPreference:nil
						 forKey:@"Online"
						  group:GROUP_ACCOUNT_STATUS];
		}
	}
	
	//Report that we disconnected
	[self didDisconnect];
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
		//create a gaim account if one does not already exist
		[self createNewGaimAccount];
		GaimDebug(@"Registering: created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
	//We are connecting
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:NotifyNow];
	
	//Make sure our settings are correct
	[self configureGaimAccountNotifyingTarget:self selector:@selector(continueRegisterWithConfiguredGaimAccount)];
}

- (void)continueRegisterWithConfiguredProxy
{
	//Set password and connect
	gaim_account_set_password(account, [password UTF8String]);
	
	GaimDebug(@"Adium: Register: %@ initiating connection.",[self UID]);
	
	[gaimThread registerAccount:self];
}

- (void)continueRegisterWithConfiguredGaimAccount
{
	//Configure libgaim's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxyNotifyingTarget:self selector:@selector(continueRegisterWithConfiguredProxy)];
}

//Account Status ------------------------------------------------------------------------------------------------------
#pragma mark Account Status
//Status keys this account supports
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"Online",
			@"Offline",
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
		GaimDebug(@"%@: Updating status for key: %@",self, key);

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
				[gaimThread setCheckMail:[self shouldCheckMail]
							  forAccount:self];
			}
		}
	}
}

/*!
 * @brief Return the gaim status type to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The gaim status ID
 */
- (char *)gaimStatusIDForStatus:(AIStatus *)statusState
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

	//Get the gaim status type from this class or subclasses, which may also potentially modify or nullify our statusMessage
	const char *statusID = [self gaimStatusIDForStatus:statusState
											 arguments:arguments];

	if (!statusMessage && ([statusState statusType] == AIAwayStatusType)) {
		/* If we don't have a status message, and  the status type is away, get a default description of this away state
		 * This allows, for example, an AIM user to set  the "Do Not Disturb" type provided by her ICQ account and have the
		 * away message be set appropriately.
		 */
		statusMessage = [NSAttributedString stringWithString:[[adium statusController] descriptionForStateOfStatus:statusState]];
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
 * @param statusID The Gaim-sepcific statusID we are setting
 * @param isActive An NSNumber with a bool YES if we are activating (going to) the passed state, NO if we are deactivating (going away from) the passed state.
 * @param arguments Gaim-specific arguments specified by the account. It must contain only NSString objects and keys.
 */
- (void)setStatusState:(AIStatus *)statusState statusID:(const char *)statusID isActive:(NSNumber *)isActive arguments:(NSMutableDictionary *)arguments
{
	[gaimThread setStatusID:statusID
				   isActive:isActive
				  arguments:arguments
				  onAccount:self];
}

//Set our idle (Pass nil for no idle)
- (void)setAccountIdleSinceTo:(NSDate *)idleSince
{
	[gaimThread setIdleSinceTo:idleSince onAccount:self];
	
	//We now should update our idle status object
	[self setStatusObject:([idleSince timeIntervalSinceNow] ? idleSince : nil)
				   forKey:@"IdleSince"
				   notify:NotifyNow];
}

//Set the profile, then invoke the passed invocation to return control to the target/selector specified
//by a configureGaimAccountNotifyingTarget:selector: call.
- (void)setAccountProfileTo:(NSAttributedString *)profile configureGaimAccountContext:(NSInvocation *)inInvocation
{
	[self setAccountProfileTo:profile];
	
	[inInvocation invoke];
}

//Set our profile immediately on the gaimThread
- (void)setAccountProfileTo:(NSAttributedString *)profile
{
	if (!profile || ![[profile string] isEqualToString:[[self statusObjectForKey:@"TextProfile"] string]]) {
		NSString 	*profileHTML = nil;
		
		//Convert the profile to HTML, and pass it to libgaim
		if (profile) {
			profileHTML = [self encodedAttributedString:profile forListObject:nil];
		}
		
		[gaimThread setInfo:profileHTML onAccount:self];
		
		//We now have a profile
		[self setStatusObject:profile forKey:@"TextProfile" notify:NotifyNow];
	}
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image. This resizes and converts the image as needed for our protocol.
 * After setting it with gaim, it sets it within Adium; if this is not called, the image will
 * show up neither locally nor remotely.
 */
- (void)setAccountUserImageData:(NSData *)originalData
{
	NSImage	*image =  (originalData ? [[[NSImage alloc] initWithData:originalData] autorelease] : nil);

	if (account) {
		NSSize		imageSize = [image size];
		
		//Clear the existing icon first
		[gaimThread setBuddyIcon:nil onAccount:self];
		
		/* Now pass libgaim the new icon.  Libgaim takes icons as a file, so we save our
		 * image to one, and then pass libgaim the path. Check to be sure our image doesn't have an NSZeroSize size,
		 * which would indicate currupt data */
		if (image && !NSEqualSizes(NSZeroSize, imageSize)) {
			GaimPluginProtocolInfo  *prpl_info = GAIM_PLUGIN_PROTOCOL_INFO(gaim_find_prpl(account->protocol_id));
			GaimDebug(@"Original image of size %f %f",imageSize.width,imageSize.height);
			
			
			if (prpl_info && (prpl_info->icon_spec.format)) {
				NSString	*buddyIconFilename = [self _userIconCachePath];
				NSData		*buddyIconData = nil;
				NSSize		imageSize = [image size];
				BOOL		smallEnough, prplScales;
				unsigned	i;
				
				/* We need to scale it down if:
				 *	1) The prpl needs to scale before it sends to the server or other buddies AND
				 *	2) The image is larger than the maximum size allowed by the protocol
				 * We ignore the minimum required size, as scaling up just leads to pixellated images.
				 */
				smallEnough =  (prpl_info->icon_spec.max_width >= imageSize.width &&
								prpl_info->icon_spec.max_height >= imageSize.height);
					
				prplScales = (prpl_info->icon_spec.scale_rules & GAIM_ICON_SCALE_SEND) || (prpl_info->icon_spec.scale_rules & GAIM_ICON_SCALE_DISPLAY);

				if (prplScales &&  !smallEnough) {
					//Determine the scaled size.  If it's too big, scale to the largest permissable size
					image = [image imageByScalingToSize:NSMakeSize(prpl_info->icon_spec.max_width,
																   prpl_info->icon_spec.max_height)];

					/* Our original data is no longer valid, since we had to scale to a different size */
					originalData = nil;
					GaimDebug(@"Scaled image to size %@",NSStringFromSize([image size]));
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
								GaimDebug(@"l33t script kiddie animated GIF!!111");
								
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
								float compressionFactor = ([NSApp isOnTigerOrBetter] ?
														   0.9 :
														   1.0);
								
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
					}
					
					//Cleanup
					g_strfreev(prpl_formats);
				}
				
				if ([buddyIconData writeToFile:buddyIconFilename atomically:YES]) {
					[gaimThread setBuddyIcon:buddyIconFilename onAccount:self];
					
				} else {
					GaimDebug(@"Error writing file %@",buddyIconFilename);   
				}
			}
		}
	}
	
	//We now have an icon
	[self setStatusObject:image forKey:KEY_USER_ICON notify:NotifyNow];
}

#pragma mark Group Chat
- (BOOL)inviteContact:(AIListContact *)inContact toChat:(AIChat *)inChat withMessage:(NSString *)inviteMessage
{
	[gaimThread inviteContact:inContact toChat:inChat withMessage:inviteMessage];
	
	return YES;
}

#pragma mark Buddy Menu Items
//Action of a dynamically-generated contact menu item
- (void)performContactMenuAction:(NSMenuItem *)sender
{
	NSDictionary		*dict = [sender representedObject];
	
	[gaimThread performContactMenuActionFromDict:dict];
}

/*
 * @brief Utility method when generating buddy-specific menu items
 *
 * Adds the menu item for act to a growing array of NSMenuItems.  If act has children (a submenu), this method is used recursively
 * to generate the submenu containing each child menu item.
 */
- (void)addMenuItemForMenuAction:(GaimMenuAction *)act forListContact:(AIListContact *)inContact gaimBuddy:(GaimBuddy *)buddy toArray:(NSMutableArray *)menuItemArray withServiceIcon:(NSImage *)serviceIcon
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
		dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSValue valueWithPointer:act],@"GaimMenuAction",
			[NSValue valueWithPointer:buddy],@"GaimBuddy",
			nil];
		
		[menuItem setRepresentedObject:dict];
		
		//If there is a submenu, generate and set it
		if (act->children) {
			NSMutableArray	*childrenArray = [NSMutableArray array];
			GList			*l, *ll;
			//Add a NSMenuItem for each child
			for (l = ll = act->children; l; l = l->next) {
				[self addMenuItemForMenuAction:(GaimMenuAction *)l->data
								forListContact:inContact
									 gaimBuddy:buddy
									   toArray:childrenArray
							   withServiceIcon:serviceIcon];
			}
			
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
}

//Returns an array of menuItems specific for this contact based on its account and potentially status
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	NSMutableArray			*menuItemArray = nil;

	if (account && gaim_account_is_connected(account)) {
		GaimPluginProtocolInfo	*prpl_info = GAIM_PLUGIN_PROTOCOL_INFO(account->gc->prpl);
		GList					*l, *ll;
		GaimBuddy				*buddy;
		
		//Find the GaimBuddy
		buddy = gaim_find_buddy(account, gaim_normalize(account, [[inContact UID] UTF8String]));
		
		if (prpl_info && prpl_info->blist_node_menu && buddy) {
			NSImage	*serviceIcon = [AIServiceIcons serviceIconForService:[self service]
																	type:AIServiceIconSmall
															   direction:AIIconNormal];
			
			menuItemArray = [NSMutableArray array];

			//Add a NSMenuItem for each node action specified by the prpl
			for (l = ll = prpl_info->blist_node_menu((GaimBlistNode *)buddy); l; l = l->next) {
				[self addMenuItemForMenuAction:(GaimMenuAction *)l->data
								forListContact:inContact
									 gaimBuddy:buddy
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
	
	if (account && gaim_account_is_connected(account)) {
		GaimPlugin *plugin = account->gc->prpl;
		
		if (GAIM_PLUGIN_HAS_ACTIONS(plugin)) {
			GList	*l, *ll;
			
			//Avoid adding separators between nonexistant items (i.e. items which Gaim shows but we don't)
			BOOL	addedAnAction = NO;
			for (l = ll = GAIM_PLUGIN_ACTIONS(plugin, account->gc); l; l = l->next) {
				
				if (l->data) {
					GaimPluginAction	*action;
					NSDictionary		*dict;
					NSMenuItem			*menuItem;
					NSString			*title;
					
					action = (GaimPluginAction *) l->data;
					
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
						dict = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:action]
														   forKey:@"GaimPluginAction"];
						
						[menuItem setRepresentedObject:dict];
						
						if (!menuItemArray) menuItemArray = [NSMutableArray array];
						
						[menuItemArray addObject:menuItem];
						addedAnAction = YES;
					} else {
						g_free(action);
					}
					
				} else {
					if (addedAnAction) {
						[menuItemArray addObject:[NSMenuItem separatorItem]];
						addedAnAction = NO;
					}
				}
			} /* end for */
			
			g_list_free(ll);
		}
	}

	return menuItemArray;
}

//Action of a dynamically-generated contact menu item
- (void)performAccountMenuAction:(NSMenuItem *)sender
{
	NSDictionary		*dict = [sender representedObject];
	
	[gaimThread performAccountMenuActionFromDict:dict];
}

//Subclasses may override to provide a localized label and/or prevent a specified label from being shown
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if ((strcmp(label, "Change Password...") == 0) || (strcmp(label, "Change Password") == 0)) {
		/* XXX This depends upon an implementation of adiumGaimRequestFields in adiumGaimRequest.m.
		* Enable once that is done. */
		return nil;
	}

	return [NSString stringWithUTF8String:label];
}

/********************************/
/* AIAccount subclassed methods */
/********************************/
#pragma mark AIAccount Subclassed Methods
- (void)initAccount
{
	NSDictionary	*defaults = [NSDictionary dictionaryNamed:[NSString stringWithFormat:@"GaimDefaults%@",[[self service] serviceID]]
													 forClass:[self class]];
	
	if (defaults) {
		[[adium preferenceController] registerDefaults:defaults
											  forGroup:GROUP_ACCOUNT_STATUS
												object:self];
	} else {
		GaimDebug(@"Failed to load defaults for %@",[NSString stringWithFormat:@"GaimDefaults%@",[[self service] serviceID]]);
	}
	
	//Defaults
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;
	lastDisconnectionError = nil;
	
	permittedContactsArray = [[NSMutableArray alloc] init];
	deniedContactsArray = [[NSMutableArray alloc] init];
	
	//We will create a gaimAccount the first time we attempt to connect
	account = NULL;

	//Observe preferences changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_ALIASES];
}

/*!
* @brief The account's UID changed
 */
- (void)didChangeUID
{
	//Only need to take action if we have a created GaimAccount already
	if (account != NULL) {
		//Remove our current account
		[gaimThread removeAdiumAccount:self];
		
		//Clear the reference to the GaimAccount... it'll be created when needed
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
						[gaimThread setAlias:alias forUID:[containedListContact UID] onAccount:self];
					}
				}
				
			} else if ([object isKindOfClass:[AIListContact class]]) {
				if ([(AIListContact *)object account] == self) {
					[gaimThread setAlias:alias forUID:[object UID] onAccount:self];
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

/*
 * @brief Return the path at which to save our own user icon
 *
 * Gaim expects a file path, not data
 */
- (NSString *)_userIconCachePath
{    
    NSString    *userIconCacheFilename = [NSString stringWithFormat:@"TEMP-UserIcon_%@_%@", [self internalObjectID], [NSString randomStringOfLength:4]];
    return [[adium cachesPath] stringByAppendingPathComponent:userIconCacheFilename];
}

/*
 * @brief Return the path at which to save an emoticon
 *
 * We may have data of some type other than JPEG, but providing _some_ file extension means the cached file can easily be opened
 * in an image editor if the user saves the file or checks the cache directory
 */
- (NSString *)_emoticonCachePathForChat:(AIChat *)inChat
{
    NSString    *filename = [NSString stringWithFormat:@"TEMP-CustomEmoticon_%@_%@.jpg", [inChat uniqueChatID], [NSString randomStringOfLength:4]];
    return [[adium cachesPath] stringByAppendingPathComponent:filename];	
}

- (AIListContact *)contactWithUID:(NSString *)inUID
{
	return [super contactWithUID:inUID];
}

- (AIListContact *)mainThreadContactWithUID:(NSString *)inUID
{
	AIListContact	*contact;

	contact = [self mainPerformSelector:@selector(contactWithUID:)
							 withObject:inUID
							returnValue:YES];

	return contact;
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
