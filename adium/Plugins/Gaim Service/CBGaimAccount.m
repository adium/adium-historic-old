//
//  CBGaimAccount.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

//evands note: may want to use a mutableOwnerArray inside chat statusDictionary properties
//so that we can have multiple gaim accounts in the same chat.

#import "CBGaimAccount.h"
#import "CBGaimServicePlugin.h"
#import "GaimService.h"

#define NO_GROUP						@"__NoGroup__"
#define ACCOUNT_IMAGE_CACHE_PATH		@"~/Library/Caches/Adium"
#define USER_ICON_CACHE_NAME			@"UserIcon_%@"
#define MESSAGE_IMAGE_CACHE_NAME		@"Image_%@_%i"

#define AUTO_RECONNECT_DELAY		2.0	//Delay in seconds
#define RECONNECTION_ATTEMPTS		4

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
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact;
- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing;
- (void)_updateAway:(AIListContact *)theContact toAway:(BOOL)newAway;

- (AIChat*)_openChatWithContact:(AIListContact *)contact andConversation:(GaimConversation*)conv;

- (void)_receivedMessage:(NSString *)message inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date;
- (NSString *)_processGaimImagesInString:(NSString *)inString;
- (NSString *)_messageImageCachePathForID:(int)imageID;

- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;

- (void)displayError:(NSString *)errorDesc;

@end

@implementation CBGaimAccount

static BOOL didInitSSL = NO;

static id<GaimThread> gaimThread = nil;

+ (void)setGaimThread:(SLGaimCocoaAdapter *)sender
{
	NSLog(@"## setGaimThread: ",[sender description]);
	gaimThread = [sender retain];
}



// The GaimAccount currently associated with this Adium account
- (GaimAccount*)gaimAccount
{
	//Create a gaim account if one does not already exist
	if (!account) {
		[self createNewGaimAccount];
		if (GAIM_DEBUG) NSLog(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
    return account;
}

- (void)initSSL
{
	if (!didInitSSL) didInitSSL = gaim_init_ssl_gnutls_plugin();	
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
	if(groupName && [groupName length] != 0){
		[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
	}else{
		[theContact setRemoteGroupName:[self _mapIncomingGroupName:nil]];
	}
}

- (oneway void)updateContact:(AIListContact *)theContact
{
//	if(GAIM_DEBUG) NSLog(@"accountUpdateBuddy: %s",buddy->name);
//    GaimBuddy *buddy = [[theContact statusObjectForKey:@"GaimBuddy"] pointerValue];
	
	//Leave here until MSN and other protocols are patched to send a signal when the alias changes, or gaim itself is.
	//gaimAlias - this may be either a distinct name ("Friendly Name" for example) or a formatted UID
}


- (oneway void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias
{
	
	if ([[gaimAlias compactedString] isEqualToString:[[theContact UID] compactedString]]) {
		if (![gaimAlias isEqualToString:[theContact formattedUID]]){
			[theContact setStatusObject:gaimAlias
								 forKey:@"FormattedUID"
								 notify:NO];
			
			//Apply any changes
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		}
	} else {
		if (![gaimAlias isEqualToString:[theContact statusObjectForKey:@"Server Display Name"]]){
			//Set the server display name status object as the full display name
			[theContact setStatusObject:gaimAlias
								 forKey:@"Server Display Name"
								 notify:NO];
			
			//Set a 25-characters-or-less version as the lowest priority display name
			[[theContact displayArrayForKey:@"Display Name"] setObject:[gaimAlias stringWithEllipsisByTruncatingToLength:25]
															 withOwner:self
														 priorityLevel:Lowest_Priority];
			//Notify
			[[adium contactController] listObjectAttributesChanged:theContact
													  modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
			
			//Apply any changes
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		}
	}
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
	if(!contactOnlineStatus || ([contactOnlineStatus boolValue] != NO)){
		[theContact setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:NO];
		[self _setInstantMessagesWithContact:theContact enabled:NO];
		
		if(!silentAndDelayed){
			[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed Off" notify:NO];
			[theContact setStatusObject:nil forKey:@"Signed On" notify:NO];			
			[theContact setStatusObject:nil forKey:@"Signed Off" afterDelay:15];
		}

		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}
//Signon Time
- (oneway void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate
{
	if (signonDate) {
		//Set the signon time
		[theContact setStatusObject:[[signonDate copy] autorelease]
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
		[theContact setStatusObject:[NSNumber numberWithBool:newAway] forKey:@"Away" notify:NO];
		
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
		([idleSinceDate compare:currentIdleDate] != 0)){
		
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
	NSImage *userIcon = [[NSImage alloc] initWithData:userIconData];
	[theContact setStatusObject:userIcon forKey:@"UserIcon" notify:NO];
	[userIcon release];
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (oneway void)removeContact:(AIListContact *)theContact
{
	if(theContact){
		[theContact setRemoteGroupName:nil];
		[self removeAllStatusFlagsFromContact:theContact];
		
		[theContact release];
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
    if(gc && 
	   gaim_account_is_connected(account) && 
	   ([[inContact statusObjectForKey:@"Online"] boolValue])){
		serv_get_info(gc, [[inContact UID] UTF8String]);
    }
}

- (oneway void)requestAddContactWithUID:(NSString *)contactUID
{
	[[adium contactController] requestAddContactWithUID:UID serviceID:[self serviceID]];
}

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
	//Open the chat
	[[adium interfaceController] openChat:chat];
}

//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{	
	//Correctly enable/disable the chat
#warning All opened chats assumed valid until a better system for doing this reliably is figured out.
	[[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
	
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
	AIListObject	*listObject = [chat listObject];
	if (listObject){
		[self setTypingFlagOfContact:(AIListContact *)listObject to:NO];
	}		
	
	[chatDict removeObjectForKey:[chat uniqueChatID]];
	
    return YES;
}

- (AIChat *)chatWithContact:(AIListContact *)contact
{
	return [[adium contentController] chatWithContact:contact
										initialStatus:nil];
}

- (AIChat *)chatWithName:(NSString *)name
{
	AIChat *chat;
	
	chat = [[adium contentController] chatWithName:name
										 onAccount:self
									 initialStatus:nil];
	
	return chat;
}

//Typing update in an IM
- (oneway void)typingUpdateForIMChat:(AIChat *)chat typing:(NSNumber *)typing
{
	[self setTypingFlagOfContact:(AIListContact*)[chat listObject]
							  to:[typing boolValue]];
}

//Multiuser chat update
- (oneway void)updateForChat:(AIChat *)chat type:(NSNumber *)type
{
	
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
	
	//Clear the typing flag of the listContact
	[self setTypingFlagOfContact:sourceContact to:NO];
	
	if (GAIM_DEBUG) NSLog(@"Received %@ from %@",[messageDict objectForKey:@"Message"],[sourceContact UID]);

	[self _receivedMessage:[messageDict objectForKey:@"Message"]
					inChat:chat 
		   fromListContact:sourceContact 
					 flags:flags
					  date:[messageDict objectForKey:@"Date"]];
}

- (oneway void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{	
	GaimMessageFlags		flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	AIListContact			*sourceContact = [self _contactWithUID:[[messageDict objectForKey:@"Source"] compactedString]];

	if ((flags & GAIM_MESSAGE_SEND) != 0) {
		/*
		 * TODO
		 * gaim is telling us that our message was sent successfully. Some
		 * day, we should avoid claiming it was until we get this
		 * notification.
		 */
		return;
	}
	
	if (GAIM_DEBUG) NSLog(@"Chat: Received %@ from %@ in %s",[messageDict objectForKey:@"Message"],[sourceContact UID],[chat name]);
		
	[self _receivedMessage:[messageDict objectForKey:@"Message"]
					inChat:chat 
		   fromListContact:sourceContact 
					 flags:flags
					  date:[messageDict objectForKey:@"Date"]];
}

- (void)_receivedMessage:(NSString *)message inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date
{		
	if ((flags & GAIM_MESSAGE_IMAGES) != 0) {
		message = [self _processGaimImagesInString:message];
	}
	
	AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
														   withSource:sourceContact
														  destination:self
																 date:date
															  message:[AIHTMLDecoder decodeHTML:message]
															autoreply:(flags & GAIM_MESSAGE_AUTO_RESP) != 0];
	
	[[adium contentController] receiveContentObject:messageObject];
}

/* XXX - No longer used, apparently
- (AIListContact *)contactAssociatedWithConversation:(GaimConversation *)conv withBuddy:(GaimBuddy *)buddy
{
	return ([self _contactAssociatedWithBuddy:buddy 
									 usingUID:[NSString stringWithUTF8String:(conv->name)]]);
}
*/

#pragma mark GaimConversation User Lists
- (oneway void)addUser:(NSString *)contactName toChat:(AIChat *)chat
{
	if (chat){
		AIListContact *contact = [self _contactWithUID:[contactName compactedString]];
		
		[contact setStatusObject:contactName forKey:@"FormattedUID" notify:YES];
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
		AIListContact *contact = [[adium contactController] existingContactWithService:[[service handleServiceType] identifier]
																			 accountID:[self uniqueObjectID]
																				   UID:[contactName compactedString]];
		
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
	
	if (gc && account && gaim_account_is_connected(account)) {
		if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0) {
			AIContentMessage	*contentMessage = (AIContentMessage*)object;
			AIChat				*chat = [contentMessage chat];
			NSAttributedString  *message = [contentMessage message];
			NSString			*encodedMessage;
			
			//Grab the list object (which may be null if this isn't a chat with a particular listObject)
			AIListObject		*listObject = [chat listObject];
			//Use GaimConvImFlags for now; multiuser chats will end up ignoring this
			GaimConvImFlags		flags = ([contentMessage isAutoreply] ? GAIM_CONV_IM_AUTO_RESP : 0);
			
			//If this connection doesn't support new lines, send all lines before newlines as separate messages
			if (gc && (gc->flags & GAIM_CONNECTION_NO_NEWLINES)) {
				NSRange		endlineRange;
				NSRange		returnRange;
				
				while (((endlineRange = [[message string] rangeOfString:@"\n"]).location) != NSNotFound ||
					   ((returnRange = [[message string] rangeOfString:@"\r"]).location) != NSNotFound){
					
					//Use whichever endline character is found first
					NSRange				operativeRange = (endlineRange.location < returnRange.location) ? endlineRange : returnRange;
					
					if (operativeRange.location > 0){
						NSAttributedString  *thisPart;
						
						thisPart = [message attributedSubstringFromRange:NSMakeRange(0,operativeRange.location-1)];
						encodedMessage = [self encodedAttributedString:thisPart forListObject:listObject];								
						[gaimThread sendMessage:encodedMessage fromAccount:self inChat:chat withFlags:flags];
					}
					
					message = [message attributedSubstringFromRange:NSMakeRange(operativeRange.location+operativeRange.length,[[message string] length]-operativeRange.location)];
				}
				
			}
			
			if ([message length]){
				encodedMessage = [self encodedAttributedString:message forListObject:listObject];
				[gaimThread sendMessage:encodedMessage fromAccount:self inChat:chat withFlags:flags];
			}
			
			sent = YES;			

		}else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){
			AIContentTyping *contentTyping = (AIContentTyping*)object;
			AIChat *chat = [contentTyping chat];
			
			[gaimThread sendTyping:[contentTyping typing] inChat:chat];

				sent = YES;
		}
	}
    return sent;
}

//Return YES if we're available for sending the specified content.
//If inListObject is nil, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    BOOL	weAreOnline = [[self statusObjectForKey:@"Online"] boolValue];
	
    if([inType isEqualToString:CONTENT_MESSAGE_TYPE]){
        if(weAreOnline && (inListObject == nil || [[inListObject statusObjectForKey:@"Online"] boolValue])){ 
			return(YES);
        }
    }else if (([inType isEqualToString:FILE_TRANSFER_TYPE]) && ([self conformsToProtocol:@protocol(AIAccount_Files)])){
		if(weAreOnline && (inListObject == nil || [[inListObject statusObjectForKey:@"Online"] boolValue])){ 
			return(YES);
        }	
	}
	
    return(NO);
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
	//Get our contact
	AIListContact   *contact = [self _contactWithUID:[sourceUID compactedString]];
	
	[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) addObject:contact];
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
	//Get our contact, which must already exist for us to care about its removal
	AIListContact   *contact = [[adium contactController] existingContactWithService:[[service handleServiceType] identifier]
																		   accountID:[self uniqueObjectID]
																				 UID:[sourceUID compactedString]];
	
	if (contact){
		[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) removeObject:contact];
	}
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
		//gaim will free filename when necessary
		char *filename = g_strdup([[fileTransfer localFilename] UTF8String]);
		
		//Associate the fileTransfer and the xfer with each other
		[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
		xfer->ui_data = [fileTransfer retain];
		
		//Set the filename
		gaim_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
		
		//request that the transfer begins
		gaim_xfer_request(xfer);
		
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
	AIListContact   *contact = [self _contactWithUID:[destinationUID compactedString]];
	
    ESFileTransfer * fileTransfer = [ESFileTransfer fileTransferWithContact:contact forAccount:self]; 

    return fileTransfer;
}

//Update an ESFileTransfer object progress
- (oneway void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	NSLog(@"File Transfer: %f%% complete",[percent floatValue]);
    [fileTransfer setPercentDone:[percent floatValue] bytesSent:[bytesSent floatValue]];
}

//The remote side canceled the transfer, the fool.  Tell the fileTransferController then destroy the xfer
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
    
    //gaim takes responsibility for freeing cFilename at a later date
    char * xferFileName = g_strdup([[fileTransfer localFilename] UTF8String]);
    gaim_xfer_set_local_filename(xfer,xferFileName);
    
    //set the size - must be done after request is accepted?
    [fileTransfer setSize:(xfer->size)];
    
    GaimXferType xferType = gaim_xfer_get_type(xfer);
    if ( xferType == GAIM_XFER_SEND ) {
        [fileTransfer setType:Outgoing_FileTransfer];   
    } else if ( xferType == GAIM_XFER_RECEIVE ) {
        [fileTransfer setType:Incoming_FileTransfer];
    }
    
    //accept the request
    gaim_xfer_request_accepted(xfer, xferFileName);
    
    //tell the fileTransferController to display appropriately
    [[adium fileTransferController] beganFileTransfer:fileTransfer];
}

//User refused a receive request.  Tell gaim, then release the ESFileTransfer object
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    gaim_xfer_request_denied((GaimXfer *)[[fileTransfer accountData] pointerValue]);
    [fileTransfer release];
}

//Account Connectivity -------------------------------------------------------------------------------------------------
#pragma mark Account Connectivity
//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	if (!account) {
		//create a gaim account if one does not already exist
		[self createNewGaimAccount];
		if (GAIM_DEBUG) NSLog(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
	//We are connecting
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];
	
	//Configure libgaim's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxy];
}

- (void)continueConnectWithConfiguredProxy
{
	//Set password and connect
	gaim_account_set_password(account, [password UTF8String]);

	if (GAIM_DEBUG) NSLog(@"Adium: Connect: %@ initiating connection.",[self UID]);

	[gaimThread connectAccount:self];

/*	while (!gc){
		gc = gaim_account_get_connection(account);
		//if (!gc) NSLog(@"no gc, retrying");
	}
*/
	if (GAIM_DEBUG) NSLog(@"Adium: Connect: %@ done initiating connection %x.",[self UID], gc);
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
	
	proxyType = (proxyPref ? [proxyPref intValue] : Gaim_Proxy_Default);
	
	if (proxyType == Gaim_Proxy_None){
		//No proxy
		gaim_proxy_info_set_type(proxy_info, GAIM_PROXY_NONE);
		
		[self continueConnectWithConfiguredProxy];
		
	}else if (proxyType == Gaim_Proxy_Default) {
		//Load and use systemwide proxy settings
		NSDictionary *systemSOCKSSettingsDictionary;
		
		if((systemSOCKSSettingsDictionary = [(GaimService *)service systemSOCKSSettingsDictionary])) {
			gaimAccountProxyType = GAIM_PROXY_SOCKS5;
			
			host = [systemSOCKSSettingsDictionary objectForKey:@"Host"];
			port = [[systemSOCKSSettingsDictionary objectForKey:@"Port"] intValue];
			
			proxyUserName = [systemSOCKSSettingsDictionary objectForKey:@"Username"];
			proxyPassword = [systemSOCKSSettingsDictionary objectForKey:@"Password"];
			
		}else{
			//Using system wide defaults, and no SOCKS proxy is set in the system preferences
			gaimAccountProxyType = GAIM_PROXY_NONE;
		}
		
		gaim_proxy_info_set_type(proxy_info, gaimAccountProxyType);
		
		gaim_proxy_info_set_host(proxy_info, (char *)[host UTF8String]);
		gaim_proxy_info_set_port(proxy_info, port);
		
		gaim_proxy_info_set_username(proxy_info, (char *)[proxyUserName UTF8String]);
		gaim_proxy_info_set_password(proxy_info, (char *)[proxyPassword UTF8String]);
		
		if (GAIM_DEBUG) NSLog(@"Systemwide proxy settings: %i %s:%i %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username);
		
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
			
			if (GAIM_DEBUG) NSLog(@"Adium proxy settings: %i %s:%i",proxy_info->type,proxy_info->host,proxy_info->port);
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
		
		if (GAIM_DEBUG) NSLog(@"GotPassword: Proxy settings: %i %s:%i %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username);
		
		[self continueConnectWithConfiguredProxy];
	}else{
		gaim_proxy_info_set_username(proxy_info, NULL);
		
		//We are no longer connecting
		[self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
	}
}

//Disconnect this account
- (void)disconnect
{
    //We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];

    //Tell libgaim to disconnect
    if(gaim_account_is_connected(account)){
		[gaimThread disconnectAccount:self];
    }
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

/*****************************/
/* accountConnection methods */
/*****************************/
//Our account was disconnected, report the error
- (oneway void)accountConnectionReportDisconnect:(NSString *)text
{
	//We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
	[[adium contactController] delayListObjectNotifications];
	
	//Clear status flags on all contacts
	NSEnumerator    *enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:self] objectEnumerator];
	AIListContact	*contact;
	
	while (contact = [enumerator nextObject]){
/*	//Remove all gaim buddies (which will call accountRemoveBuddy for each one)
		GaimBuddy *buddy;
		
		buddy = [[contact statusObjectForKey:@"GaimBuddy"] pointerValue];
		if (buddy){
			gaim_blist_remove_buddy(buddy);
		}
		*/
		[contact setRemoteGroupName:nil];
		[self removeAllStatusFlagsFromContact:contact];
	}
	
	[[adium contactController] endListObjectNotificationDelay];
	
	[lastDisconnectionError release]; lastDisconnectionError = [text retain];
}

- (oneway void)accountConnectionNotice:(NSString *)connectionNotice
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Connection Notice",[self UID],[self serviceID]]
                                    withDescription:connectionNotice];	
}

//Our account has disconnected (called automatically by gaimServicePlugin)
- (oneway void)accountConnectionDisconnected
{
	NSEnumerator    *enumerator;
	BOOL			connectionIsSuicidal = (gc ? gc->wants_to_die : NO);
	
    //We are now offline
	[self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:YES];
	[self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
	[self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:YES];

	//We no longer have a connection
	gc = NULL;
	
    //If we were disconnected unexpectedly, attempt a reconnect. Give subclasses a chance to handle the disconnection error.
	//connectionIsSuicidal == TRUE when Gaim thinks we shouldn't attempt a reconnect.
	if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue] && lastDisconnectionError){
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


//Our account has connected (called automatically by gaimServicePlugin)
- (oneway void)accountConnectionConnected
{
    //We are now online
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressPercent" notify:NO];	

	gc = gaim_account_get_connection(account);
	
	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];
	
    //Silence updates
    [self silenceAllHandleUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];

    //Set our initial status
    [self updateAllStatusKeys];

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

//Sublcasses should override to provide a string for each progress step
- (NSString *)connectionStringForStep:(int)step { return nil; };

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
	   
	[(GaimService *)service addAccount:self forGaimAccountPointer:account];	

	[self configureGaimAccountForConnect];
}


- (void)configureGaimAccountForConnect
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
        @"UserIcon",
        @"Away",
        @"AwayMessage",
        @"TextProfile",
        @"UserIcon",
        @"DefaultUserIconFilename",
        nil];
	
	return supportedPropertyKeys;
}

//Update all our status keys
- (void)updateAllStatusKeys
{
    [self updateStatusForKey:@"IdleSince"];
    [self updateStatusForKey:@"TextProfile"];
    [self updateStatusForKey:@"AwayMessage"];
    [self updateStatusForKey:@"UserIcon"];
}

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];

    //Now look at keys which only make sense while online
	if([[self statusObjectForKey:@"Online"] boolValue]){
		NSData  *data;
		
		if([key compare:@"IdleSince"] == 0){
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			[self setAccountIdleTo:(idleSince != nil ? -[idleSince timeIntervalSinceNow] : nil)];
			
		}else if([key compare:@"AwayMessage"] == 0){
			[self setAccountAwayTo:[self autoRefreshingOutgoingContentForStatusKey:key]];
			
		}else if([key compare:@"TextProfile"] == 0){
			[self setAccountProfileTo:[self autoRefreshingOutgoingContentForStatusKey:key]];
			
		}else if([key compare:@"UserIcon"] == 0){
			if(data = [self preferenceForKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS]){
				[self setAccountUserImage:[[[NSImage alloc] initWithData:data] autorelease]];
			}
			
		}
	}
}

//Set our idle (Pass nil for no idle)
- (void)setAccountIdleTo:(NSTimeInterval)idle
{
	//Even if we're setting a non-zero idle time, set it to zero first.
	//Some clients ignore idle time changes unless it moves to/from 0.
	serv_set_idle(gc, 0);
	if(idle) serv_set_idle(gc, idle);

	//We are now idle
	[self setStatusObject:(idle ? [NSDate dateWithTimeIntervalSinceNow:-idle] : nil)
				   forKey:@"IdleSince" notify:YES];
}

- (void)setAccountAwayTo:(NSAttributedString *)awayMessage
{
	if(!awayMessage || [[awayMessage string] compare:[[self statusObjectForKey:@"StatusMessage"] string]] != 0){
		char	*awayHTML = nil;
		
		//Convert the away message to HTML, and pass it to libgaim
		if(awayMessage){
			awayHTML = (char *)[[self encodedAttributedString:awayMessage forListObject:nil] UTF8String];
		}
		if (gc && account) {
			//Status Changes: We could use "Invisible" instead of GAIM_AWAY_CUSTOM for invisibility...
			serv_set_away(gc, GAIM_AWAY_CUSTOM, awayHTML);
		}
		
		//We are now away
		[self setStatusObject:[NSNumber numberWithBool:(awayMessage != nil)] forKey:@"Away" notify:YES];
		[self setStatusObject:awayMessage forKey:@"StatusMessage" notify:YES];
	}
}

- (void)setAccountProfileTo:(NSAttributedString *)profile
{
	if(!profile || [[profile string] compare:[[self statusObjectForKey:@"TextProfile"] string]] != 0){
		char 	*profileHTML = nil;
		
		//Convert the profile to HTML, and pass it to libgaim
		if(profile){
			profileHTML = (char *)[[self encodedAttributedString:profile forListObject:nil] UTF8String];
		}
		if (gc && account)
			serv_set_info(gc, profileHTML);
		
		if (GAIM_DEBUG) NSLog(@"updating profile to %@",[profile string]);
		
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
		gaim_account_set_buddy_icon(account, nil);
		
		//Now pass libgaim the new icon.  Libgaim takes icons as a file, so we save our
		//image to one, and then pass libgaim the path.
		if(image){          
			NSData 		*data = [image JPEGRepresentation];
			NSString    *buddyImageFilename = [self _userIconCachePath];
			
			if([data writeToFile:buddyImageFilename atomically:YES]){
				if (account)
					gaim_account_set_buddy_icon(account, [buddyImageFilename UTF8String]);
			}else{
				NSLog(@"Error writing file %@",buddyImageFilename);   
			}
		}
	}
	
	//We now have an icon
	[self setStatusObject:image forKey:@"UserIcon" notify:YES];
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
	
	//We will create a gaimAccount the first time we attempt to connect
	account = NULL;
	//gc will be set once we are connecting
    gc = NULL;
    	
    //ensure our user icon cache path exists
    [AIFileUtilities createDirectory:[ACCOUNT_IMAGE_CACHE_PATH stringByExpandingTildeInPath]];
	
	insideDealloc = NO;
}

- (void)dealloc
{
	//Protections are needed since removeAccount will remove us from the service account dict which will release us
	//which will call dealloc which will... and halcyon and on and on.
	[self retain];
	if (!insideDealloc) {
		insideDealloc = YES;
		[(GaimService *)service removeAccount:account];
	}
    [self autorelease];
	
    [chatDict release];
    [filesToSendArray release];
	
    [super dealloc];
}

- (NSString *)accountDescription {
    return [self uniqueObjectID];
}

- (NSString *)unknownGroupName {
    return (@"Unknown");
}

- (NSDictionary *)defaultProperties { return([NSDictionary dictionary]); }

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	if (gc->flags & GAIM_CONNECTION_HTML){
		return([AIHTMLDecoder encodeHTML:inAttributedString
								 headers:YES
								fontTags:YES
					  includingColorTags:YES
						   closeFontTags:YES
							   styleTags:YES
			  closeStyleTagsOnFontChange:YES
						  encodeNonASCII:NO
							  imagesPath:nil
					   attachmentsAsText:YES
							  simpleTagsOnly:NO]);
	}else{
		return [inAttributedString string];
	}
}

/***************************/
/* Account private methods */
/***************************/
#pragma mark Private
// Removes all the possible status flags from the passed contact
- (void)removeAllStatusFlagsFromContact:(AIListContact *)theContact
{
    NSArray			*keyArray = [self contactStatusFlags];
	NSEnumerator	*enumerator = [keyArray objectEnumerator];
	NSString		*key;

	while(key = [enumerator nextObject]){
		[theContact setStatusObject:nil forKey:key notify:NO];
	}
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:YES];
}

- (NSArray *)contactStatusFlags
{
	static NSArray *contactStatusFlagsArray = nil;
	
	if (!contactStatusFlagsArray)
		contactStatusFlagsArray = [[NSArray alloc] initWithObjects:@"Online",@"Warning",@"IdleSince",@"Signon Date",@"Away",@"Client",nil];
	
	return contactStatusFlagsArray;
}

- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing
{
    BOOL currentValue = [[contact statusObjectForKey:@"Typing"] boolValue];
	
    if(typing != currentValue){
		[contact setStatusObject:[NSNumber numberWithBool:typing]
						  forKey:@"Typing"
						  notify:NO];
		[contact notifyOfChangedStatusSilently:NO];
    }
}


//
- (void)_setInstantMessagesWithContact:(AIListContact *)contact enabled:(BOOL)enable
{
	//The contact's uniqueObjectID and the chat's uniqueChatID will be the same in a one-on-one conversation
	AIChat *chat = [chatDict objectForKey:[contact uniqueObjectID]];
	if(chat){
		//Enable/disable the chat
		[[chat statusDictionary] setObject:[NSNumber numberWithBool:enable] forKey:@"Enabled"];
		
		//Notify
		[[adium notificationCenter] postNotificationName:Content_ChatStatusChanged
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObject:
												[NSArray arrayWithObject:@"Enabled"] forKey:@"Keys"]];            
	}
}

- (void)displayError:(NSString *)errorDesc
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Gaim error",[self UID],[self serviceID]]
                                    withDescription:errorDesc];
}

- (NSString *)_processGaimImagesInString:(NSString *)inString
{
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*newString;
	
    int imageID;
	
    //set up
	newString = [[NSMutableString alloc] init];
	
    scanner = [NSScanner scannerWithString:inString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	//A gaim image tag takes the form <IMG ID="12"></IMG> where 12 is the reference for use in GaimStoredImage* gaim_imgstore_get(int)	 
    
	//Parse the incoming HTML
    while(![scanner isAtEnd]){
		
		//Find the beginning of a gaim IMG ID tag
		if ([scanner scanUpToString:@"<IMG ID=\"" intoString:&chunkString]) {
			[newString appendString:chunkString];
		}
		
		if ([scanner scanString:@"<IMG ID=\"" intoString:nil]) {
			
			//Get the image ID from the tag
			[scanner scanInt:&imageID];
			
			//Scan up to ">
			[scanner scanString:@"\">" intoString:nil];
			
			//Get the image, then write it out as a png
			GaimStoredImage		*gaimImage = gaim_imgstore_get(imageID);
			NSString			*imagePath = [self _messageImageCachePathForID:imageID];
			
			//First make an NSImage, then request a TIFFRepresentation to avoid an obscure bug in the PNG writing routines
			//Exception: PNG writer requires compacted components (bits/component * components/pixel = bits/pixel)
			NSImage				*image = [[NSImage alloc] initWithData:[NSData dataWithBytes:gaimImage->data 
																					  length:gaimImage->size]];
			NSData				*imageTIFFData = [image TIFFRepresentation];
			NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:imageTIFFData];
            
			//If writing the PNG file is successful, write an <IMG SRC="filepath"> tag to our string
            if ([[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:imagePath atomically:YES]){
				[newString appendString:[NSString stringWithFormat:@"<IMG SRC=\"%@\">",imagePath]];
			}
			
			[image release];
		}
	}
	
	return ([newString autorelease]);
}

- (NSString *)_userIconCachePath
{    
    NSString    *userIconCacheFilename = [NSString stringWithFormat:USER_ICON_CACHE_NAME, [self uniqueObjectID]];
    return([[ACCOUNT_IMAGE_CACHE_PATH stringByAppendingPathComponent:userIconCacheFilename] stringByExpandingTildeInPath]);
}

- (NSString *)_messageImageCachePathForID:(int)imageID
{
    NSString    *messageImageCacheFilename = [NSString stringWithFormat:MESSAGE_IMAGE_CACHE_NAME, [self uniqueObjectID], imageID];
    return([[[ACCOUNT_IMAGE_CACHE_PATH stringByAppendingPathComponent:messageImageCacheFilename] stringByAppendingPathExtension:@"png"] stringByExpandingTildeInPath]);	
}

- (AIListContact *)_contactWithUID:(NSString *)inUID
{
	return [super _contactWithUID:inUID];
}

@end
