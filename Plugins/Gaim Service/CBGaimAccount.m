//
//  CBGaimAccount.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import "CBGaimAccount.h"

#define NO_GROUP						@"__NoGroup__"
#define ACCOUNT_IMAGE_CACHE_PATH		@"~/Library/Caches/Adium"

#define AUTO_RECONNECT_DELAY		2.0	//Delay in seconds
#define RECONNECTION_ATTEMPTS		4

#define	PREF_GROUP_ALIASES			@"Aliases"		//Preference group to store aliases in

@interface CBGaimAccount (PRIVATE)
- (void)connect;
- (void)disconnect;

- (void)setBuddyImageFromFilename:(char *)imageFilename;
- (NSString *)_userIconCachePath;
- (void)_setInstantMessagesWithContact:(AIListContact *)contact enabled:(BOOL)enable;

- (NSString *)_mapIncomingGroupName:(NSString *)name;
- (NSString *)_mapOutgoingGroupName:(NSString *)name;

- (NSString *)displayServiceIDForUID:(NSString *)aUID;

//- (void)_updateAllEventsForBuddy:(GaimBuddy*)buddy;
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact silently:(BOOL)silent;
- (void)setTypingFlagOfChat:(AIChat *)inChat to:(NSNumber *)typingState;
- (void)_updateAway:(AIListContact *)theContact toAway:(BOOL)newAway;

- (AIChat*)_openChatWithContact:(AIListContact *)contact andConversation:(GaimConversation*)conv;

- (void)_receivedMessage:(NSString *)message inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date;
- (NSString *)_processGaimImagesInString:(NSString *)inString;
- (NSString *)_handleFileSendsWithinMessage:(NSString *)encodedMessage toContact:(AIListContact *)listContact;
- (NSString *)_messageImageCachePathForID:(int)imageID;

- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;

- (void)displayError:(NSString *)errorDesc;
- (NSNumber *)shouldCheckMail;

- (void)updateStatusForKey:(NSString *)key immediately:(BOOL)immediately;

@end

@implementation CBGaimAccount

static BOOL didInitSSL = NO;

static SLGaimCocoaAdapter *gaimThread = nil;

// The GaimAccount currently associated with this Adium account
- (GaimAccount*)gaimAccount
{
	//Create a gaim account if one does not already exist
	if (!account) {
		[self createNewGaimAccount];
		GaimDebug (@"%x: created GaimAccount 0x%x with UID %@, protocolPlugin %s", [NSRunLoop currentRunLoop],account, [self UID], [self protocolPlugin]);
	}
	
    return account;
}

- (SLGaimCocoaAdapter *)gaimThread
{
	return gaimThread;
}

- (void)initSSL
{
	if (!didInitSSL) {
		didInitSSL = gaim_init_ssl_gnutls_plugin();
	}
}

// Subclasses must override this
- (const char*)protocolPlugin { return NULL; }

// Contacts ------------------------------------------------------------------------------------------------
#pragma mark Contacts
/*- (void)accountNewBuddy:(NSValue *)buddyValue
{

}*/

- (oneway void)newContact:(AIListContact *)theContact
{
	
}

- (oneway void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName
{
	if(groupName && [groupName isEqualToString:@GAIM_ORPHANS_GROUP_NAME]){
		[theContact setRemoteGroupName:nil];
	}else if(groupName && [groupName length] != 0){
		[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
	}else{
		[theContact setRemoteGroupName:[self _mapIncomingGroupName:nil]];
	}
	
	[self gotGroupForContact:theContact];
}

- (oneway void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias
{
	BOOL changes = NO;
	BOOL displayNameChanges = NO;

	//Insert the new display name
	if([[gaimAlias compactedString] isEqualToString:[[theContact UID] compactedString]]){
		//Remove any display name we'd previously placed
		if([theContact statusObjectForKey:@"Server Display Name"]){
			[theContact setStatusObject:nil
								 forKey:@"Server Display Name"
								 notify:NO];
			
			[[theContact displayArrayForKey:@"Display Name" create:NO] setObject:nil withOwner:self];
			displayNameChanges = YES;
		}
		if(![gaimAlias isEqualToString:[theContact formattedUID]]){
			[theContact setStatusObject:gaimAlias
								 forKey:@"FormattedUID"
								 notify:NO];
			changes = YES;
		}
		
	}else{

		//This is the server display name.  Set it as such.
		if(![gaimAlias isEqualToString:[theContact statusObjectForKey:@"Server Display Name"]]){
			//Set the server display name status object as the full display name
			[theContact setStatusObject:gaimAlias
								 forKey:@"Server Display Name"
								 notify:NO];
			
			changes = YES;
		}
		
		//Use it either as the status message or the display name.
		if ([self useDisplayNameAsStatusMessage]){
			if (![[theContact stringFromAttributedStringStatusObjectForKey:@"StatusMessage"] isEqualToString:gaimAlias]){
				[theContact setStatusObject:[[[NSAttributedString alloc] initWithString:gaimAlias] autorelease]
									 forKey:@"StatusMessage" 
									 notify:NO];
				
				changes = YES;
			}
			
		}else{
			[[theContact displayArrayForKey:@"Display Name"] setObject:gaimAlias
															 withOwner:self
														 priorityLevel:Lowest_Priority];
			displayNameChanges = YES;
		}
	}

	if(changes || displayNameChanges){
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];

		if (displayNameChanges){
			//Notify of display name changes
			[[adium contactController] listObjectAttributesChanged:theContact
													  modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
			
#warning There must be a cleaner way to do this alias stuff!  This works for now
			//Request an alias change
			[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
													  object:theContact
													userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																						 forKey:@"Notify"]];
		}
	}
}

- (BOOL)useDisplayNameAsStatusMessage
{
	return NO;
}

- (oneway void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
}		


//Signed online
- (oneway void)updateSignon:(AIListContact *)theContact withData:(void *)data
{
	NSNumber *contactOnlineStatus = [theContact statusObjectForKey:@"Online"];
	if(!contactOnlineStatus || ([contactOnlineStatus boolValue] != YES)){
		[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
		[self _setInstantMessagesWithContact:theContact enabled:YES];
		
		if(!silentAndDelayed){
			[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed On" notify:NO];
			[theContact setStatusObject:nil forKey:@"Signed Off" notify:NO];
			[theContact setStatusObject:nil forKey:@"Signed On" afterDelay:15];
		}

		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

//Signed offline
- (oneway void)updateSignoff:(AIListContact *)theContact withData:(void *)data
{
	NSNumber *contactOnlineStatus = [theContact statusObjectForKey:@"Online"];
	if(contactOnlineStatus && ([contactOnlineStatus boolValue] != NO)){
		[self _setInstantMessagesWithContact:theContact enabled:NO];
		
		if(!silentAndDelayed){
			[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed Off" notify:NO];
			[theContact setStatusObject:nil forKey:@"Signed On" notify:NO];			
			[theContact setStatusObject:nil forKey:@"Signed Off" afterDelay:15];
		}

		//Will also apply any changes applied above, so no need to call notifyOfChangedStatusSilently 
		[self removeAllStatusFlagsFromContact:theContact silently:silentAndDelayed];
	}
}

//Signon Time
- (oneway void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate
{	
	if (signonDate) {
		//Set the signon time
		[theContact setStatusObject:signonDate
							 forKey:@"Signon Date"
							 notify:NO];
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

//Away and away return
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data
{
	[self _updateAway:theContact toAway:YES];
}

- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data
{
	[self _updateAway:theContact toAway:NO];
}

- (void)_updateAway:(AIListContact *)theContact toAway:(BOOL)newAway
{
	NSNumber *storedValue = [theContact statusObjectForKey:@"Away"];
	if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
		[theContact setStatusObject:(newAway ? [NSNumber numberWithBool:YES] : nil) forKey:@"Away" notify:NO];
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

//Idletime
- (void)updateIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate
{
	NSDate *currentIdleDate = [theContact statusObjectForKey:@"IdleSince"];

	if ((idleSinceDate && !currentIdleDate) ||
		(!idleSinceDate && currentIdleDate) ||
		([idleSinceDate compare:currentIdleDate] != NSOrderedSame)){
		
		[theContact setStatusObject:idleSinceDate
							 forKey:@"IdleSince"
							 notify:NO];
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

//Evil level (warning level)
- (oneway void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber
{
	//Set the warning level or clear it if it's now 0.
	int evil = [evilNumber intValue];
	NSNumber *currentWarningLevel = [theContact statusObjectForKey:@"Warning"];

	if (evil > 0){
		if (!currentWarningLevel || ([currentWarningLevel intValue] != evil)) {
			[theContact setStatusObject:evilNumber
								 forKey:@"Warning"
								 notify:NO];
			//Apply any changes
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		}
	}else{
		if (currentWarningLevel) {
			[theContact setStatusObject:nil
								 forKey:@"Warning" 
								 notify:NO];
			//Apply any changes
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];

		}
	}
}   

//Buddy Icon
- (oneway void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData
{
	if (userIconData){
		//Observers get a single shot at utilizing the user icon data in its raw form
		[theContact setStatusObject:userIconData forKey:@"UserIconData" notify:NO];
		
		//Set the User Icon as an NSImage
		NSImage *userIcon = [[NSImage alloc] initWithData:userIconData];
		[theContact setStatusObject:userIcon forKey:KEY_USER_ICON notify:NO];
		[userIcon release];
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		
		//Clear the UserIconData
		[theContact setStatusObject:nil forKey:@"UserIconData" notify:NO];
	}
}

- (oneway void)updateUserInfo:(AIListContact *)theContact withData:(NSString *)userInfoString
{
	NSString *oldUserInfoString = [theContact statusObjectForKey:@"TextProfileString"];
	
	if (userInfoString && [userInfoString length]) {
		if (![userInfoString isEqualToString:oldUserInfoString]) {
			
			[theContact setStatusObject:userInfoString
								 forKey:@"TextProfileString" 
								 notify:NO];
			[theContact setStatusObject:[AIHTMLDecoder decodeHTML:userInfoString]
								 forKey:@"TextProfile" 
								 notify:NO];
		}
	} else if (oldUserInfoString) {
		[theContact setStatusObject:nil forKey:@"TextProfileString" notify:NO];
		[theContact setStatusObject:nil forKey:@"TextProfile" notify:NO];	
	}	
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (oneway void)removeContact:(AIListContact *)theContact
{
	if(theContact){
		[theContact setRemoteGroupName:nil];
		[self removeAllStatusFlagsFromContact:theContact silently:YES];
	}
}

/*
- (void)_updateAllEventsForBuddy:(GaimBuddy*)buddy
{	
	//Set their online/available state
	if (GAIM_BUDDY_IS_ONLINE(buddy)) {
		[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_SIGNON];
	} else {
		[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_SIGNOFF];
	}
	
	[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_SIGNON_TIME];
	[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_AWAY];	
	[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_IDLE];	
	[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_EVIL];
	[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_ICON];
	[self accountUpdateBuddy:buddy forEvent:GAIM_BUDDY_MISCELLANEOUS];	
}
*/

//To allow root level buddies on protocols which don't support them, we map any buddies in a group
//named after this account's UID to the root group.  These functions handle the mapping.  Group names should
//be filtered through incoming before being sent to Adium - and group names from Adium should be filtered through
//outgoing before being used.
- (NSString *)_mapIncomingGroupName:(NSString *)name
{
	if(!name || ([[name compactedString] caseInsensitiveCompare:[self UID]] == 0)){
		return(ADIUM_ROOT_GROUP_NAME);
	}else{
		return(name);
	}
}
- (NSString *)_mapOutgoingGroupName:(NSString *)name
{
	if([[name compactedString] caseInsensitiveCompare:ADIUM_ROOT_GROUP_NAME] == 0){
		return([self UID]);
	}else{
		return(name);
	}
}

//Update the status of a contact (Request their profile)
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{	
    //Request profile
    if ([[inContact numberStatusObjectForKey:@"Online"] boolValue]){
		[gaimThread getInfoFor:[inContact UID] onAccount:self];
    }
}

- (oneway void)requestAddContactWithUID:(NSString *)contactUID
{
	[[adium contactController] requestAddContactWithUID:contactUID
												service:[self _serviceForUID:contactUID]];
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	return([self service]);
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
	
	while(object = [enumerator nextObject]){
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
	
	while(object = [enumerator nextObject]){
		[gaimThread addUID:[object UID] onAccount:self toGroup:groupName];
		
		//Add it to Adium's list
		[object setRemoteGroupName:[inGroup UID]]; //Use the non-mapped group name locally
	}
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSString		*groupName = [self _mapOutgoingGroupName:[group UID]];
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	//Move the objects to it
	enumerator = [objects objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([listObject isKindOfClass:[AIListGroup class]]){
			//Since no protocol here supports nesting, a group move is really a re-name
			
		}else{
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
	
	while(contact = [enumerator nextObject]){
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
    return([[self statusObjectForKey:@"Online"] boolValue]);
}

//Chats ------------------------------------------------------------
#pragma mark Chats

//Add a new chat - this will ultimately call -(BOOL)openChat:(AIChat *)chat below.
- (oneway void)addChat:(AIChat *)chat
{
	//Correctly enable/disable the chat
	[chat setStatusObject:[NSNumber numberWithBool:YES]
				   forKey:@"Enabled" 
				   notify:YES];
	
	//Track
	[chatDict setObject:chat forKey:[chat uniqueChatID]];
	
	//Open the chat
	[[adium contentController] openChat:chat];
}

//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{
	//Correctly enable/disable the chat
	[chat setStatusObject:[NSNumber numberWithBool:YES]
				   forKey:@"Enabled" 
				   notify:YES];
	
	//Track
	[chatDict setObject:chat forKey:[chat uniqueChatID]];

	//Inform gaim that we have opened this chat
	[gaimThread openChat:chat onAccount:self];
	
	//Created the chat successfully
	return(YES);
}

- (BOOL)closeChat:(AIChat*)chat
{
	[gaimThread closeChat:chat];
	
	//Be sure any remaining typing flag is cleared as the chat closes
	[self setTypingFlagOfChat:chat to:nil];
	
	[chatDict removeObjectForKey:[chat uniqueChatID]];
	
    return YES;
}

- (AIChat *)mainThreadChatWithContact:(AIListContact *)contact
{
	AIChat *chat;
	
	//First, make sure the chat is created
	[[adium contentController] mainPerformSelector:@selector(chatWithContact:)
										withObject:contact
									 waitUntilDone:YES];
		
	//Now return the existing chat
	chat = [[adium contentController] existingChatWithContact:contact];

	return chat;
}

- (AIChat *)mainThreadChatWithName:(NSString *)name
{
	AIChat *chat;

	/*
	 First, make sure the chat is created - we will get here from a call in which Gaim has already
	 created the GaimConversation, so there's no need for a chatCreationInfo dictionary.
	 */
	
	[[adium contentController] mainPerformSelector:@selector(chatWithName:onAccount:chatCreationInfo:)
										withObject:name
										withObject:self
										withObject:nil
									 waitUntilDone:YES];
	
	//Now return the existing chat
	chat = [[adium contentController] existingChatWithName:name onAccount:self];
	
	return chat;
}

//Typing update in an IM
- (oneway void)typingUpdateForIMChat:(AIChat *)chat typing:(NSNumber *)typingState
{
	[self setTypingFlagOfChat:chat
						   to:typingState];
}

//Multiuser chat update
- (oneway void)convUpdateForChat:(AIChat *)chat type:(NSNumber *)type
{
	
}

- (oneway void)updateForChat:(AIChat *)chat type:(NSNumber *)type
{
	AIChatUpdateType	updateType = [type intValue];
	NSString			*key = nil;
	switch (updateType){
		case AIChatTimedOut:
			if ([self displayConversationTimedOut]){
				key = KEY_CHAT_TIMED_OUT;
			}
			break;
			
		case AIChatClosedWindow:
			if ([self displayConversationClosed]){
				key = KEY_CHAT_CLOSED_WINDOW;
			}
			break;
	}
	
	if (key){
		[chat setStatusObject:[NSNumber numberWithBool:YES] forKey:key notify:YES];
		[chat setStatusObject:nil forKey:key notify:NotifyNever];
		
	}
}

- (oneway void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{
	GaimMessageFlags		flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	AIListContact			*sourceContact;
	
	if ((flags & GAIM_MESSAGE_SEND) != 0) {
        // gaim is telling us that our message was sent successfully. Some day, we should avoid claiming it was
		// until we get this notification.
        return;
    }

	sourceContact = (AIListContact*) [chat listObject];
	
	//Clear the typing flag of the chat since a message was just received
	[self setTypingFlagOfChat:chat to:nil];
	
	GaimDebug (@"receivedIMChatMessage: Received %@ from %@",[messageDict objectForKey:@"Message"],[sourceContact UID]);

	[self _receivedMessage:[messageDict objectForKey:@"Message"]
					inChat:chat 
		   fromListContact:sourceContact 
					 flags:flags
					  date:[messageDict objectForKey:@"Date"]];
}

- (oneway void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{	
	GaimMessageFlags	flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	NSString			*source = [messageDict objectForKey:@"Source"];

	if ((flags & GAIM_MESSAGE_SEND) != 0){
		/*
		 * TODO
		 * gaim is telling us that our message was sent successfully. Some
		 * day, we should avoid claiming it was until we get this
		 * notification.
		 */
		return;
	}
	
	//We display the message locally when it is sent.  If the protocol sends the message back to us, we should
	//simply ignore it (MSN does this when a display name is set, for example).
	if (![source isEqualToString:[self UID]]){
		AIListContact		*sourceContact = [self _contactWithUID:source];
		
		GaimDebug (@"receivedMultiChatMessage: Received %@ from %@ in %@",[messageDict objectForKey:@"Message"],[sourceContact UID],[chat name]);
		
		[self _receivedMessage:[messageDict objectForKey:@"Message"]
						inChat:chat 
			   fromListContact:sourceContact 
						 flags:flags
						  date:[messageDict objectForKey:@"Date"]];
	}
}

- (void)_receivedMessage:(NSString *)message inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date
{		
	AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
														   withSource:sourceContact
														  destination:self
																 date:date
															  message:[AIHTMLDecoder decodeHTML:message]
															autoreply:(flags & GAIM_MESSAGE_AUTO_RESP) != 0];
	
	[[adium contentController] receiveContentObject:messageObject];
}

#pragma mark GaimConversation User Lists
- (oneway void)addUser:(NSString *)contactName toChat:(AIChat *)chat
{
	if (chat){
		AIListContact *contact = [self _contactWithUID:contactName];
		
		if (!namesAreCaseSensitive){
			[contact setStatusObject:contactName forKey:@"FormattedUID" notify:YES];
		}
		
		[chat addParticipatingListObject:contact];
		
		NSLog(@"added user %@ in conversation %@",contactName,[chat name]);
	}	
}
- (void)accountConvAddedUsers:(GList *)users inConversation:(GaimConversation *)conv
{
	NSLog(@"added a whole list!");
}
- (oneway void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat
{
	if (chat){
		if (!namesAreCaseSensitive){
			contactName = [contactName compactedString];
		}
		
		AIListContact *contact = [[adium contactController] existingContactWithService:service
																			   account:self
																				   UID:contactName];
		
		[chat removeParticipatingListObject:contact];
		
		NSLog(@"removed user %@ in conversation %@",contactName,[chat name]);
	}	
}
- (void)accountConvRemovedUsers:(GList *)users inConversation:(GaimConversation *)conv
{
	NSLog(@"removed a whole list!");
}

/*********************/
/* AIAccount_Content */
/*********************/
#pragma mark Content
- (BOOL)sendContentObject:(AIContentObject*)object
{
    BOOL            sent = NO;
	
	if (gaim_account_is_connected(account)) {
		if([[object type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
			AIContentMessage	*contentMessage = (AIContentMessage*)object;
			AIChat				*chat = [contentMessage chat];
			NSAttributedString  *message = [contentMessage message];
			NSString			*encodedMessage;
			
			//Grab the list object (which may be null if this isn't a chat with a particular listObject)
			AIListObject		*listObject = [chat listObject];
			//Use GaimConvImFlags for now; multiuser chats will end up ignoring this
			GaimConvImFlags		flags = ([contentMessage isAutoreply] ? GAIM_CONV_IM_AUTO_RESP : 0);
			
			//If this connection doesn't support new lines, send all lines before newlines as separate messages
			if (account->gc->flags & GAIM_CONNECTION_NO_NEWLINES) {
				NSRange		endlineRange;
				NSRange		returnRange;
				
				while (((endlineRange = [[message string] rangeOfString:@"\n"]).location) != NSNotFound ||
					   ((returnRange = [[message string] rangeOfString:@"\r"]).location) != NSNotFound){
					
					//Use whichever endline character is found first
					NSRange	operativeRange = ((endlineRange.location < returnRange.location) ? endlineRange : returnRange);
					
					if (operativeRange.location > 0){
						NSAttributedString  *thisPart;
						
						thisPart = [message attributedSubstringFromRange:NSMakeRange(0,operativeRange.location-1)];
						encodedMessage = [self encodedAttributedString:thisPart
														 forListObject:listObject
														contentMessage:contentMessage];
						if (encodedMessage){
							//Check for the AdiumFT tag indicating an embedded file transfer.
							//Only deal with scanning deeper if it's found.
							if ([encodedMessage rangeOfString:@"<AdiumFT "
													  options:NSCaseInsensitiveSearch].location != NSNotFound){
								encodedMessage = [self _handleFileSendsWithinMessage:encodedMessage
																		   toContact:(AIListContact *)[chat listObject]];
							}
							[gaimThread sendEncodedMessage:encodedMessage
										   originalMessage:[thisPart string]
											   fromAccount:self
													inChat:chat
												 withFlags:flags];
							sent = YES;
						}
					}
					
					message = [message attributedSubstringFromRange:NSMakeRange(operativeRange.location+operativeRange.length,[[message string] length]-operativeRange.location)];
				}
				
			}
			
			if ([message length]){
				encodedMessage = [self encodedAttributedString:message
												 forListObject:listObject
												contentMessage:contentMessage];
				if (encodedMessage){
					//Check for the AdiumFT tag indicating an embedded file transfer.
					//Only deal with scanning deeper if it's found.
					if ([encodedMessage rangeOfString:@"<AdiumFT "
											  options:NSCaseInsensitiveSearch].location != NSNotFound){
						encodedMessage = [self _handleFileSendsWithinMessage:encodedMessage
																   toContact:(AIListContact *)[chat listObject]];
					}
					[gaimThread sendEncodedMessage:encodedMessage
								   originalMessage:[message string]
									   fromAccount:self
											inChat:chat
										 withFlags:flags];
					sent = YES;
				}
			}
		} else if([[object type] isEqualToString:CONTENT_TYPING_TYPE]){
			AIContentTyping *contentTyping = (AIContentTyping*)object;
			AIChat *chat = [contentTyping chat];
			
			[gaimThread sendTyping:[contentTyping typingState] inChat:chat];
			
			sent = YES;
		}
	}
	
    return(sent);
}

//Return YES if we're available for sending the specified content or will be soon (are currently connecting).
//If inListObject is nil, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
    BOOL	weAreOnline = [self online];
	
    if([inType isEqualToString:CONTENT_MESSAGE_TYPE]){
        if((weAreOnline && (inContact == nil || [inContact online])) ||
		   ([self integerStatusObjectForKey:@"Connecting"])){ 
			return(YES);
        }
    }else if (([inType isEqualToString:FILE_TRANSFER_TYPE]) && ([self conformsToProtocol:@protocol(AIAccount_Files)])){
		if(weAreOnline){
			if(inContact){
				if([inContact online]){
					return([self allowFileTransferWithListObject:inContact]);
				}
			}else{
				return(YES);
			}
       }	
	}
	
    return(NO);
}

- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	return YES;
}

- (NSString *)_handleFileSendsWithinMessage:(NSString *)inString toContact:(AIListContact *)listContact
{
	if (listContact){
		NSScanner			*scanner;
		NSCharacterSet		*tagCharStart, *tagEnd, *absoluteTagEnd;
		NSString			*chunkString;
		NSMutableString		*processedString;
		
		tagCharStart = [NSCharacterSet characterSetWithCharactersInString:@"<"];
		tagEnd = [NSCharacterSet characterSetWithCharactersInString:@" >"];
		absoluteTagEnd = [NSCharacterSet characterSetWithCharactersInString:@">"];
		
		scanner = [NSScanner scannerWithString:inString];
		[scanner setCaseSensitive:NO];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
		
		processedString = [[NSMutableString alloc] init];
		
		//Parse the HTML
		while(![scanner isAtEnd]){
			//Find an HTML IMG tag
			if([scanner scanUpToString:@"<AdiumFT" intoString:&chunkString]){
				[processedString appendString:chunkString];
			}
			
			//Process the tag
			if([scanner scanCharactersFromSet:tagCharStart intoString:nil]){ //If a tag wasn't found, we don't process.
																			 //            unsigned scanLocation = [scanner scanLocation]; //Remember our location (if this is an invalid tag we'll need to move back)
				
				//Get the tag itself
				if([scanner scanUpToCharactersFromSet:tagEnd intoString:&chunkString]){
					
					if([chunkString caseInsensitiveCompare:@"AdiumFT"] == 0){
						if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
							
							//Extract the file we wish to send
							NSDictionary	*imgArguments = [AIHTMLDecoder parseArguments:chunkString];
							NSString		*filePath = [imgArguments objectForKey:@"src"];
							
							//Send the file
							[[adium fileTransferController] sendFile:filePath toListContact:listContact];
						}
					}
					
					if (![scanner isAtEnd]){
						[scanner setScanLocation:[scanner scanLocation]+1];
					}
				}
			}
		}
		
		return ([processedString autorelease]);
	}else{
		NSLog(@"Sending a file to a chat.  Are you insane?");
		return (inString);
	}
}

// **XXX** Not used at present. Do we want to?
- (BOOL)shouldSendAutoresponsesWhileAway
{
	if (account && account->gc){
		return (account->gc->flags & GAIM_CONNECTION_AUTO_RESP);
	}
	
	return NO;
}

/*********************/
/* AIAccount_Privacy */
/*********************/
#pragma mark Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
    if (type == PRIVACY_PERMIT)
        return (gaim_privacy_permit_add(account,[[inObject UID] UTF8String],FALSE));
    else
        return (gaim_privacy_deny_add(account,[[inObject UID] UTF8String],FALSE));
}
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
    if (type == PRIVACY_PERMIT)
        return (gaim_privacy_permit_remove(account,[[inObject UID] UTF8String],FALSE));
    else
        return (gaim_privacy_deny_remove(account,[[inObject UID] UTF8String],FALSE));
}
-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type
{
	return (type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray);
}

-(oneway void)privacyPermitListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_PERMIT added:sourceUID];
}
-(oneway void)privacyDenyListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_DENY added:sourceUID];
}

-(void)accountPrivacyList:(PRIVACY_TYPE)type added:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]){
		//Get our contact
		AIListContact   *contact = [self _contactWithUID:sourceUID];
		
		[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) addObject:contact];
	}
}

-(oneway void)privacyPermitListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_PERMIT removed:sourceUID];
}
-(oneway void)privacyDenyListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:PRIVACY_DENY removed:sourceUID];
}

-(void)accountPrivacyList:(PRIVACY_TYPE)type removed:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]){
		if (!namesAreCaseSensitive){
			sourceUID = [sourceUID compactedString];
		}
		
		//Get our contact, which must already exist for us to care about its removal
		AIListContact   *contact = [[adium contactController] existingContactWithService:service
																				 account:self
																					 UID:sourceUID];
		
		if (contact){
			[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) removeObject:contact];
		}
	}
}

-(void)setPrivacyOptions:(PRIVACY_OPTION)option
{
    account->perm_deny = option;
    serv_set_permit_deny(gaim_account_get_connection(account));
}

/*****************************************************/
/* File transfer / AIAccount_Files inherited methods */
/*****************************************************/
#pragma mark File Transfer

//Create a protocol-specific xfer object, set it up as requested, and begin sending
- (void)_beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	GaimXfer *xfer = [self newOutgoingXferForFileTransfer:fileTransfer];
	
	if (xfer){
		//Associate the fileTransfer and the xfer with each other
		[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
		xfer->ui_data = [fileTransfer retain];
		
		//Set the filename
		gaim_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
		gaim_xfer_set_filename(xfer, [[[fileTransfer localFilename] lastPathComponent] UTF8String]);
		
		//request that the transfer begins
		[gaimThread xferRequest:xfer];
		
		//tell the fileTransferController to display appropriately
		[[adium fileTransferController] beganFileTransfer:fileTransfer];
	}
}
//By default, protocols can not create GaimXfer objects
- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	return nil;
}

//The account requested that we received a file.
//Set up the ESFileTransfer and query the fileTransferController for a save location
- (oneway void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer
{
    NSLog(@"file transfer request received");
    [[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

//The account requested that we send a file, but we do not know what file yet.
//Query the fileTransferController for a target file
/*- (void)accountXferSendFileWithXfer:(GaimXfer *)xfer
{
    ESFileTransfer * fileTransfer = [[self createFileTransferObjectForXfer:xfer] retain];
    //prompt the fileTransferController for the target filename
    [[adium fileTransferController] sendRequestForFileTransfer:fileTransfer];
}
*/

/*
- (void)accountXferBeginFileSendWithXfer:(GaimXfer *)xfer
{
    //set up our fileTransfer object
    ESFileTransfer * fileTransfer = [[self createFileTransferObjectForXfer:xfer] retain];
    
    NSString *filename = [filesToSendArray objectAtIndex:0];
    [fileTransfer setLocalFilename:filename];
    [filesToSendArray removeObjectAtIndex:0];
    
    //set the xfer local filename; accepting the file transfer will take care of setting size and such
    //gaim takes responsibility for freeing cFilename at a later date
    char * xferFileName = g_strdup([filename UTF8String]);
    gaim_xfer_set_local_filename(xfer,xferFileName);
    
    //begin transferring the file
    [self acceptFileTransferRequest:fileTransfer];    
}
*/

//Create an ESFileTransfer object from an xfer
- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID
{
	AIListContact   *contact = [self _contactWithUID:destinationUID];
	
    ESFileTransfer * fileTransfer = [ESFileTransfer fileTransferWithContact:contact forAccount:self]; 

    return fileTransfer;
}

//Update an ESFileTransfer object progress
- (oneway void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	float percentDone = [percent floatValue];
    [fileTransfer setPercentDone:percentDone bytesSent:[bytesSent unsignedLongValue]];
	if (percentDone == 1.0){
		[[adium fileTransferController] transferComplete:fileTransfer];
	}
}

//The remote side canceled the transfer, the fool.  Tell the fileTransferController
- (oneway void)fileTransferCanceledRemotely:(ESFileTransfer *)fileTransfer
{
    [[adium fileTransferController] transferCanceled:fileTransfer];
}

- (oneway void)destroyFileTransfer:(ESFileTransfer *)fileTransfer
{
	[fileTransfer release];
}

//Accept a send or receive ESFileTransfer object, beginning the transfer.
//Subsequently inform the fileTransferController that the fun has begun.
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    NSLog(@"accept file transfer");
    GaimXfer * xfer = [[fileTransfer accountData] pointerValue];
    

    GaimXferType xferType = gaim_xfer_get_type(xfer);
    if ( xferType == GAIM_XFER_SEND ) {
        [fileTransfer setType:Outgoing_FileTransfer];   
    } else if ( xferType == GAIM_XFER_RECEIVE ) {
        [fileTransfer setType:Incoming_FileTransfer];
    }
    
    //accept the request
	[gaimThread xferRequestAccepted:xfer withFileName:[fileTransfer localFilename]];
    
	//set the size - must be done after request is accepted?
    [fileTransfer setSize:(xfer->size)];
	
    //tell the fileTransferController to display appropriately
    [[adium fileTransferController] beganFileTransfer:fileTransfer];
}

//User refused a receive request.  Tell gaim, we don't release the ESFileTransfer object since that will happen when the xfer is destroyed
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
	GaimXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[gaimThread xferRequestRejected:xfer];
	}
}

//Account Connectivity -------------------------------------------------------------------------------------------------
#pragma mark Connect
//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	if (!account) {
		//create a gaim account if one does not already exist
		[self createNewGaimAccount];
		GaimDebug (@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
	//We are connecting
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];
	
	//Make sure our settings are correct
	[self configureGaimAccount];
	
	//Configure libgaim's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxy];
}

- (void)continueConnectWithConfiguredProxy
{
	//Set password and connect
	gaim_account_set_password(account, [password UTF8String]);

	GaimDebug (@"Adium: Connect: %@ initiating connection.",[self UID]);

	[gaimThread connectAccount:self];

	GaimDebug (@"Adium: Connect: %@ done initiating connection %x.",[self UID], account->gc);
}


- (void)configureGaimAccount
{
	NSString	*hostName;
	int			portNumber;

	//Host (server)
	hostName = [self host];
	if (hostName && [hostName length]){
		gaim_account_set_string(account, "server", [hostName UTF8String]);
	}
	
	//Port
	portNumber = [self port];
	if (portNumber){
		gaim_account_set_int(account, "port", portNumber);
	}
	
	//E-mail checking
	gaim_account_set_check_mail(account, [[self shouldCheckMail] boolValue]);
	
	//Update a few status keys before we begin connecting.  Libgaim will send these automatically
    [self updateStatusForKey:KEY_USER_ICON];
	
	//We must do the TextProfile immediately so it doesn't try to happen while we are in the middle of connecting
    [self updateStatusForKey:@"TextProfile" immediately:YES];
}

//Configure libgaim's proxy settings using the current system values
- (void)configureAccountProxy
{
	GaimProxyInfo		*proxy_info;
	GaimProxyType		gaimAccountProxyType;
	
	NSNumber			*proxyPref = [self preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	NSString			*host = nil;
	NSString			*proxyUserName = nil;
	NSString			*proxyPassword = nil;
	AdiumGaimProxyType  proxyType;
	int					port = 0;
	
	proxy_info = gaim_proxy_info_new();
	gaim_account_set_proxy_info(account, proxy_info);
	
	proxyType = (proxyPref ? [proxyPref intValue] : Gaim_Proxy_Default_SOCKS5);
	
	if (proxyType == Gaim_Proxy_None){
		//No proxy
		gaim_proxy_info_set_type(proxy_info, GAIM_PROXY_NONE);
		
		[self continueConnectWithConfiguredProxy];
		
	}else if ((proxyType == Gaim_Proxy_Default_SOCKS5) || 
			  (proxyType == Gaim_Proxy_Default_HTTP) || 
			  (proxyType == Gaim_Proxy_Default_SOCKS4)) {
		//Load and use systemwide proxy settings
		NSDictionary *systemProxySettingsDictionary;
		ProxyType adiumProxyType = Proxy_None;
		
		if (proxyType == Gaim_Proxy_Default_SOCKS5){
			gaimAccountProxyType = GAIM_PROXY_SOCKS5;
			adiumProxyType = Proxy_SOCKS5;
			
		}else if (proxyType == Gaim_Proxy_Default_HTTP){
			gaimAccountProxyType = GAIM_PROXY_HTTP;
			adiumProxyType = Proxy_HTTP;
			
		}else if (proxyType == Gaim_Proxy_Default_SOCKS4){
				gaimAccountProxyType = GAIM_PROXY_SOCKS4;
				adiumProxyType = Proxy_SOCKS4;
		}
		
		if((systemProxySettingsDictionary = [ESSystemNetworkDefaults systemProxySettingsDictionaryForType:adiumProxyType])) {
			
			host = [systemProxySettingsDictionary objectForKey:@"Host"];
			port = [[systemProxySettingsDictionary objectForKey:@"Port"] intValue];
			
			proxyUserName = [systemProxySettingsDictionary objectForKey:@"Username"];
			proxyPassword = [systemProxySettingsDictionary objectForKey:@"Password"];
			
		}else{
			//Using system wide defaults, and no proxy of the specified type is set in the system preferences
			gaimAccountProxyType = GAIM_PROXY_NONE;
		}
		
		gaim_proxy_info_set_type(proxy_info, gaimAccountProxyType);
		
		gaim_proxy_info_set_host(proxy_info, (char *)[host UTF8String]);
		gaim_proxy_info_set_port(proxy_info, port);
		
		if (proxyUserName && [proxyUserName length]){
			gaim_proxy_info_set_username(proxy_info, (char *)[proxyUserName UTF8String]);
			if (proxyPassword && [proxyPassword length]){
				gaim_proxy_info_set_password(proxy_info, (char *)[proxyPassword UTF8String]);
			}
		}
		
		GaimDebug (@"Systemwide proxy settings: %i %s:%i %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username);
		
		[self continueConnectWithConfiguredProxy];
		
	}else{
		host = [self preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
		port = [[self preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_PORT group:GROUP_ACCOUNT_STATUS] intValue];
		
		switch (proxyType){
			case Gaim_Proxy_HTTP:
				gaimAccountProxyType = GAIM_PROXY_HTTP;
				break;
			case Gaim_Proxy_SOCKS4:
				gaimAccountProxyType = GAIM_PROXY_SOCKS4;
				break;
			case Gaim_Proxy_SOCKS5:
				gaimAccountProxyType = GAIM_PROXY_SOCKS5;
				break;
			default:
				gaimAccountProxyType = GAIM_PROXY_NONE;
				break;
		}
		
		gaim_proxy_info_set_type(proxy_info, gaimAccountProxyType);
		gaim_proxy_info_set_host(proxy_info, (char *)[host UTF8String]);
		gaim_proxy_info_set_port(proxy_info, port);
		
		//If we need to authenticate, request the password and finish setting up the proxy in gotProxyServerPassword:
		proxyUserName = [self preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
		if (proxyUserName && [proxyUserName length]){
			gaim_proxy_info_set_username(proxy_info, (char *)[proxyUserName UTF8String]);
			
			[[adium accountController] passwordForProxyServer:host 
													 userName:proxyUserName 
											  notifyingTarget:self 
													 selector:@selector(gotProxyServerPassword:)];
		}else{
			
			GaimDebug (@"Adium proxy settings: %i %s:%i",proxy_info->type,proxy_info->host,proxy_info->port);
			[self continueConnectWithConfiguredProxy];
		}
	}
}

//Retried the proxy password from the keychain
- (void)gotProxyServerPassword:(NSString *)inPassword
{
	GaimProxyInfo		*proxy_info = gaim_account_get_proxy_info(account);
	
	if (inPassword){
		gaim_proxy_info_set_password(proxy_info, (char *)[inPassword UTF8String]);
		
		GaimDebug (@"GotPassword: Proxy settings: %i %s:%i %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username);
		
		[self continueConnectWithConfiguredProxy];
	}else{
		gaim_proxy_info_set_username(proxy_info, NULL);
		
		//We are no longer connecting
		[self setStatusObject:nil forKey:@"Connecting" notify:YES];
	}
}

//Sublcasses should override to provide a string for each progress step
- (NSString *)connectionStringForStep:(int)step { return nil; };

//Our account has connected
- (oneway void)accountConnectionConnected
{
    //We are now online
    [self setStatusObject:nil forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];
	
	//Update our away and idle status
	[self updateStatusForKey:@"AwayMessage"];
	[self updateStatusForKey:@"IdleSince"];
	
    //Silence updates
    [self silenceAllContactUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
	
    //Reset reconnection attempts
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;

	//Clear any previous disconnection error
	[lastDisconnectionError release]; lastDisconnectionError = nil;
}

- (oneway void)accountConnectionProgressStep:(NSNumber *)step percentDone:(NSNumber *)connectionProgressPrecent
{
	NSString	*connectionProgressString = [self connectionStringForStep:[step intValue]];

	[self setStatusObject:connectionProgressString forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:connectionProgressPrecent forKey:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];
}

- (void)createNewGaimAccount
{
	//Create a fresh version of the account
    account = gaim_account_new([UID UTF8String], [self protocolPlugin]);
	account->perm_deny = GAIM_PRIVACY_DENY_USERS;
	
    gaim_accounts_add(account);
	
	if (!gaimThread){
		gaimThread = [[SLGaimCocoaAdapter sharedInstance] retain];
	}
	
	[gaimThread addAdiumAccount:self];
}

#pragma mark Disconnect

//Disconnect this account
- (void)disconnect
{
    //We are disconnecting
	if ([[self statusObjectForKey:@"Online"] boolValue] || [[self statusObjectForKey:@"Connecting"] boolValue]){
		[self setStatusObject:nil forKey:@"Connecting" notify:NO];
		[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
		[[adium contactController] delayListObjectNotificationsUntilInactivity];
		
		//Tell libgaim to disconnect
		[gaimThread disconnectAccount:self];
	}
}

//Our account was disconnected, report the error
- (oneway void)accountConnectionReportDisconnect:(NSString *)text
{
	//We receive retained data
	[lastDisconnectionError release]; lastDisconnectionError = [text retain];
	GaimDebug (@"%@ disconnected: %@",[self UID],lastDisconnectionError);
	//We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
	[[adium contactController] delayListObjectNotifications];
	
	//Clear status flags on all contacts
	NSEnumerator    *enumerator = [[[adium contactController] allContactsInGroup:nil
																	   subgroups:YES 
																	   onAccount:self] objectEnumerator];
	AIListContact	*contact;
	
	while (contact = [enumerator nextObject]){
		
		[contact setRemoteGroupName:nil];
		[self removeAllStatusFlagsFromContact:contact silently:YES];
	}
	
	[[adium contactController] endListObjectNotificationsDelay];
	
}

- (oneway void)accountConnectionNotice:(NSString *)connectionNotice
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Connection Notice",[self UID],[service description]]
                                    withDescription:connectionNotice];
}

//Our account has disconnected
- (oneway void)accountConnectionDisconnected
{
	BOOL			connectionIsSuicidal = (account->gc ? account->gc->wants_to_die : NO);

    //We are now offline
	[self setStatusObject:nil forKey:@"Disconnecting" notify:NO];
	[self setStatusObject:nil forKey:@"Connecting" notify:NO];
	[self setStatusObject:nil forKey:@"Online" notify:NO];
	
	//Clear status objects which don't make sense for a disconnected account
	[self setStatusObject:nil forKey:@"StatusMessage" notify:NO];
	[self setStatusObject:nil forKey:@"Away" notify:NO];
	[self setStatusObject:nil forKey:@"TextProfile" notify:NO];
	
	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];
	
	//If we were disconnected unexpectedly, attempt a reconnect. Give subclasses a chance to handle the disconnection error.
	//connectionIsSuicidal == TRUE when Gaim thinks we shouldn't attempt a reconnect.
	if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]/* && lastDisconnectionError*/){
		if (reconnectAttemptsRemaining && 
			[self shouldAttemptReconnectAfterDisconnectionError:lastDisconnectionError] && !(connectionIsSuicidal)) {
			
			[self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY];
			reconnectAttemptsRemaining--;
		}else{
			if (lastDisconnectionError){
				//Display then clear the last disconnection error
				[self displayError:lastDisconnectionError];
				[lastDisconnectionError release]; lastDisconnectionError = nil;
			}
			
			//Reset reconnection attempts
			reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;
		}
	}
}

//By default, always attempt to reconnect.  Subclasses may override this to manage reconnect behavior.
- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	return YES;
}

//Account Status ------------------------------------------------------------------------------------------------------
#pragma mark Account Status
//Status keys this account supports
- (NSArray *)supportedPropertyKeys
{
	static NSArray *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys)
		supportedPropertyKeys = [[NSArray alloc] initWithObjects:
        @"Display Name",
        @"Online",
        @"Offline",
        @"IdleSince",
        @"IdleManuallySet",
        KEY_USER_ICON,
        @"Away",
        @"AwayMessage",
        @"TextProfile",
        KEY_USER_ICON,
        @"DefaultUserIconFilename",
        nil];
	
	return supportedPropertyKeys;
}

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense if we have an account
	if(account){
		GaimDebug (@"Updating status for key: %@",key);

		if([key isEqualToString:@"IdleSince"]){
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			[self setAccountIdleSinceTo:idleSince];
			
		}else if([key isEqualToString:@"AwayMessage"]){
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(setAccountAwayTo:)];
			
		}else if([key isEqualToString:@"TextProfile"]){
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(setAccountProfileTo:)];
			
		}else if([key isEqualToString:KEY_USER_ICON]){
			NSData  *data;

			if(data = [self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
				[self setAccountUserImage:[[[NSImage alloc] initWithData:data] autorelease]];
			}
			
		}
	}
}

- (void)updateStatusForKey:(NSString *)key immediately:(BOOL)immediately
{
	BOOL handled = NO;
	
	if (immediately){
		if([key isEqualToString:@"TextProfile"]){
			[self setAccountProfileTo:[self autoRefreshingOutgoingContentForStatusKey:key]];
			handled = YES;
		}
	}
	
	if (!handled){
		[self updateStatusForKey:key];
	}
}

//Set our idle (Pass nil for no idle)
- (void)setAccountIdleSinceTo:(NSDate *)idleSince
{
	[gaimThread setIdleSinceTo:idleSince onAccount:self];
	
	//We now should update our idle status object
	[self setStatusObject:([idleSince timeIntervalSinceNow] ? idleSince : nil)
				   forKey:@"IdleSince" notify:YES];
}

- (void)setAccountAwayTo:(NSAttributedString *)awayMessage
{
	if(!awayMessage || ![[awayMessage string] isEqualToString:[[self statusObjectForKey:@"StatusMessage"] string]]){
		NSString	*awayHTML = nil;
		
		//Convert the away message to HTML, and pass it to libgaim
		if(awayMessage){
			awayHTML = [self encodedAttributedString:awayMessage forListObject:nil];
		}

		//Set the away serverside
		[gaimThread setAway:awayHTML onAccount:self];

		//We are now away
		[self setStatusObject:[NSNumber numberWithBool:(awayMessage != nil)] forKey:@"Away" notify:YES];
		[self setStatusObject:awayMessage forKey:@"StatusMessage" notify:YES];
	}
}

- (void)setAccountProfileTo:(NSAttributedString *)profile
{
	if(!profile || ![[profile string] isEqualToString:[[self statusObjectForKey:@"TextProfile"] string]]){
		NSString 	*profileHTML = nil;
		
		//Convert the profile to HTML, and pass it to libgaim
		if(profile){
			profileHTML = [self encodedAttributedString:profile forListObject:nil];
		}
		
		[gaimThread setInfo:profileHTML onAccount:self];
		
		GaimDebug (@"updating profile to %@",[profile string]);
		
		//We now have a profile
		[self setStatusObject:profile forKey:@"TextProfile" notify:YES];
	}
}

// *** USER IMAGE
//Set our user image (Pass nil for no image)
- (void)setAccountUserImage:(NSImage *)image
{
	if (account) {
		//Clear the existing icon first
		[gaimThread setBuddyIcon:nil onAccount:self];
		
		//Now pass libgaim the new icon.  Libgaim takes icons as a file, so we save our
		//image to one, and then pass libgaim the path.
		if(image){
			GaimPluginProtocolInfo  *prpl_info = GAIM_PLUGIN_PROTOCOL_INFO(gaim_find_prpl(account->protocol_id));
			GaimDebug (@"Original image of size %f %f",[image size].width,[image size].height);
			if (prpl_info && (prpl_info->icon_spec.format)){
				char					**prpl_formats =  g_strsplit (prpl_info->icon_spec.format,",",0);
				int						i;
				
				NSString				*buddyIconFilename = [self _userIconCachePath];
				NSData					*buddyIconData = nil;
				NSSize					imageSize = [image size];
				BOOL					acceptableSize, prplScales;
				
				/* 
					We need to scale it down if:
				 1) The prpl needs to scale before it sends (?) AND
				 2) The image is larger than the maximum size allowed by the protocol
				 */
				acceptableSize = (prpl_info->icon_spec.min_width <= imageSize.width &&					
								  prpl_info->icon_spec.max_width >= imageSize.width &&
								  prpl_info->icon_spec.min_height <= imageSize.height &&
								  prpl_info->icon_spec.max_height >= imageSize.height);
				prplScales = (prpl_info->icon_spec.scale_rules & GAIM_ICON_SCALE_SEND) || (prpl_info->icon_spec.scale_rules & GAIM_ICON_SCALE_DISPLAY);

				if (prplScales && !acceptableSize){
					//Determine the scaled size
					NSSize  newImageSize = imageSize;
					NSImage *newImage;
					
					if(imageSize.width > prpl_info->icon_spec.max_width)
						newImageSize.width = prpl_info->icon_spec.max_width;
					else if(imageSize.width < prpl_info->icon_spec.min_width)
						newImageSize.width = prpl_info->icon_spec.min_width;
					if(imageSize.height > prpl_info->icon_spec.max_height)
						newImageSize.height = prpl_info->icon_spec.max_height;
					else if(imageSize.height < prpl_info->icon_spec.min_height)
						newImageSize.height = prpl_info->icon_spec.min_height;
					
					//Draw the image, scaled, onto a new image
					newImage = [[[NSImage alloc] initWithSize:newImageSize] autorelease];
					
					[newImage lockFocus];
					[image drawInRect:NSMakeRect(0,0,newImageSize.width,newImageSize.height)
							 fromRect:NSMakeRect(0,0,imageSize.width,imageSize.height)
							operation:NSCompositeCopy
							 fraction:1.0];
					[newImage unlockFocus];
					
					image = newImage;
					GaimDebug (@"Scaled image of size %f %f",newImageSize.width,newImageSize.height);
				}
				
				for (i = 0; prpl_formats[i]; i++) {
					if (strcmp(prpl_formats[i],"png") == 0){
						buddyIconData = [image PNGRepresentation];
						if (buddyIconData)
							break;
						
					}else if ((strcmp(prpl_formats[i],"jpeg") == 0) || (strcmp(prpl_formats[i],"jpg") == 0)){
						buddyIconData = [image JPEGRepresentation];
						if (buddyIconData)
							break;
						
					}else if ((strcmp(prpl_formats[i],"tiff") == 0) || (strcmp(prpl_formats[i],"tif") == 0)){
						buddyIconData = [image TIFFRepresentation];
						if (buddyIconData)
							break;
						
					}else if (strcmp(prpl_formats[i],"bmp") == 0){
						buddyIconData = [image BMPRepresentation];
						if (buddyIconData)
							break;
					}
				}
				
				if([buddyIconData writeToFile:buddyIconFilename atomically:YES]){
					GaimDebug (@"%@ setBuddyIcon:%@ onAccount:%@",gaimThread,buddyIconFilename,self);
					[gaimThread setBuddyIcon:buddyIconFilename onAccount:self];
					
				}else{
					NSLog(@"Error writing file %@",buddyIconFilename);   
				}
				
				//Cleanup
				g_strfreev(prpl_formats);
			}
		}
	}
	
	//We now have an icon
	[self setStatusObject:image forKey:KEY_USER_ICON notify:YES];
}

#pragma mark Group Chat
- (BOOL)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage
{
	[gaimThread inviteContact:contact toChat:chat withMessage:inviteMessage];
	
	return YES;
}

/********************************/
/* AIAccount subclassed methods */
/********************************/
#pragma mark AIAccount Subclassed Methods
- (void)initAccount
{
    chatDict = [[NSMutableDictionary alloc] init];
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;
	lastDisconnectionError = nil;
	
	permittedContactsArray = [[NSMutableArray alloc] init];
	deniedContactsArray = [[NSMutableArray alloc] init];
	
	namesAreCaseSensitive = [[self service] caseSensitive];
	
	//We will create a gaimAccount the first time we attempt to connect
	account = NULL;
    	
    //ensure our user icon cache path exists
	[[NSFileManager defaultManager] createDirectoriesForPath:[ACCOUNT_IMAGE_CACHE_PATH stringByExpandingTildeInPath]];
	
	//Observe preferences changes
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];
}

- (void)dealloc
{	
    [chatDict release];
    [filesToSendArray release];
	
    [super dealloc];
}

- (NSString *)unknownGroupName {
    return (@"Unknown");
}

- (NSDictionary *)defaultProperties { return([NSDictionary dictionary]); }

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [inAttributedString string]; //Default behavior is plain text
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage
{
	return [self encodedAttributedString:inAttributedString forListObject:inListObject];
}

- (void)preferencesChanged:(NSNotification *)notification
{
	NSDictionary	*userInfo = [notification userInfo];
	NSString		*prefGroup = [userInfo objectForKey:@"Group"];
	
	if([prefGroup isEqualToString:PREF_GROUP_ALIASES]){
		AIListObject *listObject = [notification object];
		
		//If the notification object is a listContact belonging to this account, update the serverside information
		if (account &&
			[listObject isKindOfClass:[AIListContact class]] && 
			[(AIListContact *)listObject account] == self &&
			[[userInfo objectForKey:@"Key"] isEqualToString:@"Alias"]){
			
			NSString *alias = [listObject preferenceForKey:@"Alias"
													 group:PREF_GROUP_ALIASES 
									 ignoreInheritedValues:YES];
			
			[gaimThread setAlias:alias forUID:[listObject UID] onAccount:self];
		}
		
	}else if (([notification object] == self) && ([prefGroup isEqualToString:GROUP_ACCOUNT_STATUS])){
		//Update the mail checking setting if the account is already made (if it isn't, we'll set it when it is made)
		if (account){
			[gaimThread setCheckMail:[self shouldCheckMail]
						  forAccount:self];
		}
	}
}

/***************************/
/* Account private methods */
/***************************/
#pragma mark Private
// Removes all the possible status flags from the passed contact
- (void)removeAllStatusFlagsFromContact:(AIListContact *)theContact silently:(BOOL)silent
{
    NSArray			*keyArray = [self contactStatusFlags];
	NSEnumerator	*enumerator = [keyArray objectEnumerator];
	NSString		*key;

	while(key = [enumerator nextObject]){
		[theContact setStatusObject:nil forKey:key notify:NO];
	}
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silent];
}

- (NSArray *)contactStatusFlags
{
	static NSArray *contactStatusFlagsArray = nil;
	
	if (!contactStatusFlagsArray)
		contactStatusFlagsArray = [[NSArray alloc] initWithObjects:@"Online",@"Warning",@"IdleSince",@"Signon Date",@"Away",@"Client",nil];
	
	return contactStatusFlagsArray;
}

- (void)setTypingFlagOfChat:(AIChat *)chat to:(NSNumber *)typingStateNumber
{
    NSNumber *currentValue = [chat statusObjectForKey:KEY_TYPING];

    if((typingStateNumber && !currentValue) ||
	   (!typingStateNumber && currentValue) ||
	   (!([typingStateNumber compare:currentValue] == 0))){
		[chat setStatusObject:typingStateNumber
					   forKey:KEY_TYPING
					   notify:YES];
    }
}


//
- (void)_setInstantMessagesWithContact:(AIListContact *)contact enabled:(BOOL)enable
{
	//The contact's uniqueObjectID and the chat's uniqueChatID will be the same in a one-on-one conversation
	AIChat *chat = [chatDict objectForKey:[contact internalObjectID]];
	if(chat){
		//Enable/disable the chat
		[chat setStatusObject:[NSNumber numberWithBool:enable] 
					   forKey:@"Enabled"
					   notify:YES];
	}
}

- (void)displayError:(NSString *)errorDesc
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Gaim error",[self UID],[[self service] description]]
                                    withDescription:errorDesc];
}

- (NSString *)_userIconCachePath
{    
    NSString    *userIconCacheFilename = [NSString stringWithFormat:@"TEMP-UserIcon_%@_%@", [self internalObjectID], [NSString randomStringOfLength:4]];
    return([[ACCOUNT_IMAGE_CACHE_PATH stringByAppendingPathComponent:userIconCacheFilename] stringByExpandingTildeInPath]);
}

- (AIListContact *)_contactWithUID:(NSString *)inUID
{
	return [super _contactWithUID:inUID];
}

- (AIListContact *)mainThreadContactWithUID:(NSString *)inUID
{
	if (!namesAreCaseSensitive){
		inUID = [inUID compactedString];
	}
	
	[self performSelectorOnMainThread:@selector(_contactWithUID:)
						   withObject:inUID
						waitUntilDone:YES];
	
	AIListContact *contact = [[adium contactController] existingContactWithService:service
																		   account:self
																			   UID:inUID];
	
	return contact;
}

- (NSString *)host{
	NSString *hostKey = [self hostKey];
	return (hostKey ? [self preferenceForKey:hostKey group:GROUP_ACCOUNT_STATUS] : nil); 
}
- (int)port{ 
	NSString *portKey = [self portKey];
	return (portKey ? [[self preferenceForKey:portKey group:GROUP_ACCOUNT_STATUS] intValue] : nil); 
}

- (NSString *)hostKey { return nil; };
- (NSString *)portKey { return nil; };

- (NSNumber *)shouldCheckMail
{
	return ([self preferenceForKey:KEY_ACCOUNT_GAIM_CHECK_MAIL group:GROUP_ACCOUNT_STATUS]);
}

- (BOOL)displayConversationClosed
{
	return NO;
}

- (BOOL)displayConversationTimedOut
{
	return NO;
}


- (NSString *)internalObjectID
{
	return([super internalObjectID]);
}

@end
