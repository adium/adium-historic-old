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

- (AIListContact *)contactAssociatedWithBuddy:(GaimBuddy *)buddy;
- (AIListContact *)contactAssociatedWithConversation:(GaimConversation *)conv withBuddy:(GaimBuddy *)buddy;
- (AIListContact *)_contactAssociatedWithBuddy:(GaimBuddy *)buddy usingUID:(NSString *)contactUID;
- (NSString *)displayServiceIDForUID:(NSString *)aUID;

- (void)_updateAllEventsForBuddy:(GaimBuddy*)buddy;
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact;
- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing;

- (AIChat*)_openChatWithContact:(AIListContact *)contact andConversation:(GaimConversation*)conv;

- (void)_receivedMessage:(NSString *)message inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(GaimMessageFlags)flags date:(NSDate *)date;
- (NSString *)_processGaimImagesInString:(NSString *)inString;
- (NSString *)_messageImageCachePathForID:(int)imageID;

- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;

- (void)displayError:(NSString *)errorDesc;
@end

@implementation CBGaimAccount

static BOOL didInitSSL = NO;

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

// Buddies and Contacts ------------------------------------------------------------------------------------------------
#pragma mark Buddies and Contacts
- (void)accountNewBuddy:(NSValue *)buddyValue
{
	[self contactAssociatedWithBuddy:[buddyValue pointerValue]]; //Create a contact and hook it to this buddy
}

- (void)accountUpdateBuddy:(NSValue *)buddyValue
{	
//	if(GAIM_DEBUG) NSLog(@"accountUpdateBuddy: %s",buddy->name);
    GaimBuddy *buddy = [buddyValue pointerValue];
	
    AIListContact           *theContact;
	
    //Get the node's ui_data
    if ((theContact = (AIListContact *)buddy->node.ui_data)){
		//Create the contact if necessary
		//if(!theContact) theContact = [self contactAssociatedWithBuddy:buddy];
		
		//Group changes - gaim buddies start off in no group, so this is an important update for us
		if(![theContact remoteGroupName]){
			GaimGroup *g = gaim_find_buddys_group(buddy);
			if(g && g->name){
				NSString *groupName = [NSString stringWithUTF8String:g->name];
				if(groupName && [groupName length] != 0){
					[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
				}else{
					[theContact setRemoteGroupName:[self _mapIncomingGroupName:nil]];
				}
			}
		}
		
		//Leave here until MSN and other protocols are patched to send a signal when the alias changes, or gaim itself is.
		//gaimAlias - this may be either a distinct name ("Friendly Name" for example) or a formatted UID
		{
			NSString *gaimAlias = [NSString stringWithUTF8String:gaim_get_buddy_alias(buddy)];
			if ([[gaimAlias compactedString] isEqualToString:[theContact UID]]) {
				if (![[theContact statusObjectForKey:@"FormattedUID"] isEqualToString:gaimAlias]) {
					[theContact setStatusObject:gaimAlias
										 forKey:@"FormattedUID"
										 notify:NO];
				}
			} else {
				if (![[theContact statusObjectForKey:@"Server Display Name"] isEqualToString:gaimAlias]) {
					//Set the server display name status object as the full display name
					[theContact setStatusObject:gaimAlias
										 forKey:@"Server Display Name"
										 notify:NO];
					
					//Set a 20-characters-or-less version as the lowest priority display name
					[[theContact displayArrayForKey:@"Display Name"] setObject:[gaimAlias stringWithEllipsisByTruncatingToLength:20]
																	 withOwner:self
																 priorityLevel:Lowest_Priority];
					//notify
					[[adium contactController] listObjectAttributesChanged:theContact
															  modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
				}
			}
		}
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy forEvent:(GaimBuddyEvent)event
{
//	if(GAIM_DEBUG) NSLog(@"accountUpdateBuddy: %s forEvent: %i",buddy->name,event);
    AIListContact           *theContact;
	
    //Get the node's ui_data
    theContact = (AIListContact *)buddy->node.ui_data;
	
	//Create the contact if necessary
    if(!theContact) theContact = [self contactAssociatedWithBuddy:buddy];
	
	switch(event){
		//Online / Offline
		case GAIM_BUDDY_SIGNON: {
			NSNumber *contactOnlineStatus = [theContact statusObjectForKey:@"Online"];
			if(!contactOnlineStatus || ([contactOnlineStatus boolValue] != YES)){
				[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
				[self _setInstantMessagesWithContact:theContact enabled:YES];
				
				if(!silentAndDelayed){
					[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed On" notify:NO];
					[theContact setStatusObject:nil forKey:@"Signed Off" notify:NO];
					[theContact setStatusObject:nil forKey:@"Signed On" afterDelay:15];
				}
				
				/*
				//gaimAlias - this may be either a distinct name ("Friendly Name" for example) or a formatted UID
				{
					NSString *gaimAlias = [NSString stringWithUTF8String:gaim_get_buddy_alias(buddy)];
					if ([[gaimAlias compactedString] isEqualToString:[theContact UID]]) {
						if (![[theContact statusObjectForKey:@"FormattedUID"] isEqualToString:gaimAlias]) {
							[theContact setStatusObject:gaimAlias
												 forKey:@"FormattedUID"
												 notify:NO];
						}
					} else {
						if (![[theContact statusObjectForKey:@"Server Display Name"] isEqualToString:gaimAlias]) {
							//Set the server display name status object as the full display name
							[theContact setStatusObject:gaimAlias
												 forKey:@"Server Display Name"
												 notify:NO];
							
							//Set a 20-characters-or-less version as the lowest priority display name
							[[theContact displayArrayForKey:@"Display Name"] setObject:[gaimAlias stringWithEllipsisByTruncatingToLength:20]
																			 withOwner:self
																		 priorityLevel:Lowest_Priority];
							//notify
							[[adium contactController] listObjectAttributesChanged:self
																	  modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
						}
					}
				}
				 */
			}
		}   break;
		case GAIM_BUDDY_SIGNOFF: {
			NSNumber *contactOnlineStatus = [theContact statusObjectForKey:@"Online"];
			if(!contactOnlineStatus || ([contactOnlineStatus boolValue] != NO)){
				[theContact setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:NO];
				[self _setInstantMessagesWithContact:theContact enabled:NO];
				
				if(!silentAndDelayed){
					[theContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed Off" notify:NO];
					[theContact setStatusObject:nil forKey:@"Signed On" notify:NO];
					[theContact setStatusObject:nil forKey:@"Signed Off" afterDelay:15];
				}
			}
		}   break;
		case GAIM_BUDDY_SIGNON_TIME: {
			if (buddy->signon != 0) {
				//Set the signon time
				[theContact setStatusObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->signon]
										   forKey:@"Signon Date"
										   notify:NO];
			}
		}
			
			//Away status
		case GAIM_BUDDY_AWAY:
		case GAIM_BUDDY_AWAY_RETURN: {
			BOOL newAway = (event == GAIM_BUDDY_AWAY);
			NSNumber *storedValue = [theContact statusObjectForKey:@"Away"];
			if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
				[theContact setStatusObject:[NSNumber numberWithBool:newAway] forKey:@"Away" notify:NO];
			}
		}   break;
			
		//Idletime
		case GAIM_BUDDY_IDLE:
		case GAIM_BUDDY_IDLE_RETURN: {
			NSDate *idleDate = [theContact statusObjectForKey:@"IdleSince"];
			int currentIdle = buddy->idle;
			//NSLog(@"buddy->idle %i",currentIdle);

			if(currentIdle != (int)([idleDate timeIntervalSince1970])){
				//If there is an idle time, or if there was one before, then update
				if ((buddy->idle > 0) || idleDate) {
					[theContact setStatusObject:((currentIdle > 0) ? [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)currentIdle] : nil)
										 forKey:@"IdleSince"
										 notify:NO];
				}
			}
		}   break;
			
		case GAIM_BUDDY_EVIL: {
			//Set the warning level or clear it if it's now 0.
			int evil = buddy->evil;
			NSNumber *currentWarningLevel = [theContact statusObjectForKey:@"Warning"];
			if (evil > 0){
				if (!currentWarningLevel || ([currentWarningLevel intValue] != evil)) {
					[theContact setStatusObject:[NSNumber numberWithInt:evil]
										 forKey:@"Warning"
										 notify:NO];
				}
			}else{
				if (currentWarningLevel) {
					[theContact setStatusObject:nil
										 forKey:@"Warning" 
										 notify:NO];   
				}
			}
		}   break;
			
		//Buddy Icon
		case GAIM_BUDDY_ICON: {
			GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
			if(buddyIcon && (buddyIcon != [[theContact statusObjectForKey:@"BuddyImagePointer"] pointerValue])) {                            
				//save this for convenience
				[theContact setStatusObject:[NSValue valueWithPointer:buddyIcon]
									 forKey:@"BuddyImagePointer"
									 notify:NO];
				
				//set the buddy image
				NSImage *image = [[[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_buddy_icon_get_data(buddyIcon, &(buddyIcon->len))
																			   length:buddyIcon->len]] autorelease];
				[theContact setStatusObject:image forKey:@"UserIcon" notify:NO];
			}
		}   break;
	}
	
	//Apply any changes
	[theContact performSelectorOnMainThread:@selector(notifyOfChangedStatusNumberSilently:)
								 withObject:[NSNumber numberWithBool:silentAndDelayed]
							  waitUntilDone:NO];
}

- (void)accountRemoveBuddy:(NSValue *)buddyValue
{
	GaimBuddy		*buddy = [buddyValue pointerValue];
	if(GAIM_DEBUG) NSLog(@"accountRemoveBuddy: %s",buddy->name);
	AIListContact	*theContact = (AIListContact *)buddy->node.ui_data;
	
    if(theContact){
		[theContact setRemoteGroupName:nil];
		[self removeAllStatusFlagsFromContact:theContact];

		[theContact release];
        buddy->node.ui_data = NULL;
    }
}

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

- (AIListContact *)contactAssociatedWithBuddy:(GaimBuddy *)buddy
{
	return ([self _contactAssociatedWithBuddy:buddy
									 usingUID:[NSString stringWithUTF8String:(buddy->name)]]);
}	

- (AIListContact *)_contactAssociatedWithBuddy:(GaimBuddy *)buddy usingUID:(NSString *)contactUID
{
	NSAssert(buddy != nil,@"contactAssociatedWithBuddy: passed a nil buddy");
	
	AIListContact	*contact = nil;
	
	//If a name was available for the GaimBuddy, create a contact
	if (contactUID){
		//Get our contact
		contact = [self _mainThreadContactWithUID:[contactUID compactedString]];
			
		//Evan: temporary asserts
		NSAssert ([[service handleServiceType] identifier] != nil,@"contactAssociatedWithBuddy: [[service handleServiceType] identifier] was nil");
		NSAssert ([contactUID compactedString] != nil,@"contactAssociatedWithBuddy: [contactUID compactedString] was nil");
		NSAssert (contact != nil,@"contactAssociatedWithBuddy: contact was nil");
		
		//Associate the handle with ui_data and the buddy with our statusDictionary
		buddy->node.ui_data = [contact retain];
		[contact setStatusObject:[NSValue valueWithPointer:buddy] forKey:@"GaimBuddy" notify:NO];
	}
	
	return(contact);
}

- (AIListContact *)_mainThreadContactWithUID:(NSString *)sourceUID
{
	[super performSelectorOnMainThread:@selector(_contactWithUID:)
							withObject:sourceUID
						 waitUntilDone:YES];
	
	AIListContact *contact = [[adium contactController] existingContactWithService:[[service handleServiceType] identifier]
																		 accountID:[self uniqueObjectID]
																			   UID:sourceUID];
	return contact;
}

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
	   gaim_account_is_connected(account)/* && 
	   ([[inContact statusObjectForKey:@"Online"] boolValue])*/){
		serv_get_info(gc, [[inContact UID] UTF8String]);
    }
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
		const char  *buddyUID = [[object UID] UTF8String];
		
		GaimBuddy 	*buddy = gaim_find_buddy(account, buddyUID);
		
		[object setStatusObject:nil forKey:@"GaimBuddy" notify:NO];
		
		//Remove it from Adium's list
		[object setRemoteGroupName:nil];
		
		//Remove this contact from the server-side and gaim-side lists
		serv_remove_buddy(gc, buddyUID, [groupName UTF8String]);
		if (buddy)
			gaim_blist_remove_buddy(buddy);		
	}
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)inGroup
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while(object = [enumerator nextObject]){
		NSString	*groupName = [self _mapOutgoingGroupName:[inGroup UID]];
		
		//Get the group (Create if necessary)
		GaimGroup *group = gaim_find_group([groupName UTF8String]);
		if(group == NULL){
			group = gaim_group_new([[inGroup UID] UTF8String]);
			gaim_blist_add_group(group, NULL);
		}
		
     	//verify the buddy does not already exist, and create it
		GaimBuddy *buddy = gaim_find_buddy(account,[[object UID] UTF8String]);
		if(buddy == NULL){
                        buddy = gaim_buddy_new(account, [[object UID] UTF8String], NULL);
		//}
		
                        //Add the buddy locally to libgaim, and then to the serverside list
                        gaim_blist_add_buddy(buddy, NULL, group, NULL);
                        serv_add_buddy(gc, [[object UID] UTF8String], group);
		
                        //Add it to Adium's list
                        [object setRemoteGroupName:[inGroup UID]]; //Use the non-mapped group name locally
                }
	}
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSString		*groupName = [self _mapOutgoingGroupName:[group UID]];
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	//Get the destionation group (creating if necessary)
	GaimGroup 	*destGroup = gaim_find_group([groupName UTF8String]);
	if(!destGroup) destGroup = gaim_group_new([groupName UTF8String]);
	
	//Move the objects to it
	enumerator = [objects objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([listObject isKindOfClass:[AIListGroup class]]){
			//Since no protocol here supports nesting, a group move is really a re-name
			
		}else{
			//			NSString	*oldGroupName = [self _mapOutgoingGroupName:[listObject remoteGroupName]];
			
			//			NSLog(@"Old %@ ; New %@",oldGroupName,[group UID]);
			
			//Get the gaim buddy and group for this move
			GaimBuddy *buddy = gaim_find_buddy(account,[[listObject UID] UTF8String]);
			GaimGroup *oldGroup = gaim_find_buddys_group(buddy);
			
			//			NSLog(@"%i %i",(oldGroup!=NULL),(buddy!=NULL));
			
			if(buddy){
				if (oldGroup) {
					//Procede to move the buddy gaim-side and locally
					serv_move_buddy(buddy, oldGroup, destGroup);
				} else {
					//The buddy was not in any group before; add the buddy to the desired group
					serv_add_buddy(gc, buddy->name, destGroup);
				}
				
				[listObject setRemoteGroupName:[group UID]]; //Use the non-mapped group name locally
			}
		}		
	}
}

- (void)renameGroup:(AIListGroup *)inGroup to:(NSString *)newName
{
    GaimGroup *group = gaim_find_group([[self _mapOutgoingGroupName:[inGroup UID]] UTF8String]);
	
	//If we don't have a group with this name, just ignore the rename request
    if(group){
		//Rename gaimside
		gaim_blist_rename_group(group, [newName UTF8String]);
		
		/*
		 //These may be necessary:
		 serv_rename_group(gc, group, [newName UTF8String]);     //rename
		 gaim_blist_remove_group(group);                         //remove the old one gaimside
		 */
		
		//We must also update the remote grouping of all our contacts in that group
		NSEnumerator	*enumerator = [[[adium contactController] allContactsInGroup:inGroup subgroups:YES onAccount:self] objectEnumerator];
		AIListContact	*contact;
		
		while(contact = [enumerator nextObject]){
			[contact setRemoteGroupName:newName];
		}
	}
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return([[self statusObjectForKey:@"Online"] boolValue]);
}

// GaimConversations ---------------------------------------------------------------------------------------------------
#pragma mark GaimConversations
- (void)accountConvDestroy:(GaimConversation*)conv
{
    AIChat *chat = (AIChat*) conv->ui_data;
    if (chat) {
        AIListObject *listObject = [chat listObject];
        if(listObject){
			[self setTypingFlagOfContact:(AIListContact *)listObject to:NO];
		}

		[chat release]; conv->ui_data = nil;
    }
}

- (void)addChatConversation:(GaimConversation*)conv
{
	AIChat *chat = (AIChat*) conv->ui_data;
	
	//We expect !chat
	if (!chat){
		chat = [[adium contentController] chatWithName:[NSString stringWithUTF8String:conv->name]
											 onAccount:self
										 initialStatus:[NSDictionary dictionaryWithObject:[NSValue valueWithPointer:conv]
																				   forKey:@"GaimConv"]];
		conv->ui_data = [chat retain];
	}
	
	//Open the chat
	[[adium interfaceController] openChat:chat];
}

- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type
{
    AIChat		*chat = (AIChat*) conv->ui_data;
	switch (gaim_conversation_get_type(conv)) {
		case GAIM_CONV_IM:
		{
			GaimConvIm  *im = gaim_conversation_get_im_data(conv);
			//We don't do anything yet with updates for conversations that aren't IM conversations 
			if (chat && im) {
				AIListContact *listContact = (AIListContact*) [chat listObject];
				NSAssert(listContact != nil, @"Conversation with no one?");
				
				switch (type) {
					case GAIM_CONV_UPDATE_TYPING:
						[self setTypingFlagOfContact:listContact to:(gaim_conv_im_get_typing_state(im) == GAIM_TYPING)];
						break;
					case GAIM_CONV_UPDATE_AWAY:
						//If the conversation update is UPDATE_AWAY, it seems to suppress the typing state being updated
						//Reset gaim's typing tracking, then update to receive a GAIM_CONV_UPDATE_TYPING message
						gaim_conv_im_set_typing_state(im, GAIM_NOT_TYPING);
						gaim_conv_im_update_typing(im);
						break;
					default:
					break;
				}
			}
			break;
		}
		case GAIM_CONV_CHAT:
		{
			break;
		}
	}
}

- (void)receivedIM:(NSDictionary *)messageDict
{
	NSValue					*convValue = [messageDict objectForKey:@"GaimConversation"];
	GaimConversation		*conv = [convValue pointerValue];
	GaimMessageFlags		flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	
	AIChat					*chat = (AIChat*) conv->ui_data;
	AIListContact			*sourceContact;
	GaimConversationType	convType;
	

	if ((flags & GAIM_MESSAGE_SEND) != 0) {
        // gaim is telling us that our message was sent successfully. Some day, we should avoid claiming it was
		// until we get this notification.
        return;
    }
	
	
	sourceContact = (AIListContact*) [chat listObject];
	
	if (!chat) {
		//No chat is associated with the IM conversation
		
		if (!sourceContact) {
			//No sourceContact is available yet
			GaimBuddy 	*buddy;
			GaimGroup   *group;
							
			buddy = gaim_find_buddy(account, conv->name);
			if (!buddy) {
				//No gaim_buddy corresponding to the conv->name is on our list, so create one
				
				buddy = gaim_buddy_new(account, conv->name, NULL);  //create a GaimBuddy
				group = gaim_find_group(_("Orphans"));				//get the GaimGroup
				if (!group) {										//if the group doesn't exist yet
					group = gaim_group_new(_("Orphans"));           //create the GaimGroup
					gaim_blist_add_group(group, NULL);              //add it gaimside
				}
				gaim_blist_add_buddy(buddy, NULL, group, NULL);     //add the buddy to the gaimside list
				
#warning Must add to serverside list to get status updates.  Need to remove when the chat closes or the account disconnects. Possibly want to use some sort of hidden Adium group for this.
				serv_add_buddy(gc, buddy->name, group);				//add it to the serverside list
				
				//Add it to Adium's list
				//[object setRemoteGroupName:[inGroup UID]]; //Use the non-mapped group name locally
			}
			NSAssert(buddy != nil, @"buddy was nil");
			
			sourceContact = [self contactAssociatedWithBuddy:buddy];
			//If creating a contact from the buddy failed, create a contact using the conversation name
			if (!sourceContact){
				sourceContact = [self contactAssociatedWithConversation:conv withBuddy:buddy];
			}
			
			NSAssert(sourceContact != nil, @"accountConvReceivedIM: sourceContact was nil after both tries.");
		}
				
		// Need to start a new chat, associating with the GaimConversation
		chat = [[adium contentController] chatWithContact:sourceContact
											initialStatus:[NSDictionary dictionaryWithObject:convValue
																					  forKey:@"GaimConv"]];		
		//Associate the GaimConversation with the AIChat
		conv->ui_data = [chat retain];
		
	}else{
		NSAssert(sourceContact != nil, @"Existing chat yet no existing handle?");
	}
	
	//Clear the typing flag of the listContact
	[self setTypingFlagOfContact:sourceContact to:NO];
	
	if (GAIM_DEBUG) NSLog(@"Received %@ from %@",[messageDict objectForKey:@"Message"],[sourceContact UID]);
		
	[self _receivedMessage:[messageDict objectForKey:@"Message"]
					inChat:chat 
		   fromListContact:sourceContact 
					 flags:flags
					  date:[messageDict objectForKey:@"Date"]];
}

- (void)receivedChatMessage:(NSDictionary *)messageDict
{	
	NSValue					*convValue = [messageDict objectForKey:@"GaimConversation"];
	GaimConversation		*conv = [convValue pointerValue];
	
	GaimMessageFlags		flags = [[messageDict objectForKey:@"GaimMessageFlags"] intValue];
	AIListContact			*sourceContact = [self _mainThreadContactWithUID:[[messageDict objectForKey:@"Source"] compactedString]];

	AIChat					*chat = (AIChat*) conv->ui_data;
	
	if ((flags & GAIM_MESSAGE_SEND) != 0) {
		/*
		 * TODO
		 * gaim is telling us that our message was sent successfully. Some
		 * day, we should avoid claiming it was until we get this
		 * notification.
		 */
		return;
	}
	
	if (!chat){
		chat = [[adium contentController] chatWithName:[NSString stringWithUTF8String:conv->name]
											 onAccount:self
										 initialStatus:[NSDictionary dictionaryWithObject:convValue
																				   forKey:@"GaimConv"]];
		conv->ui_data = [chat retain];
	}

	if (GAIM_DEBUG) NSLog(@"Chat: Received %@ from %@ in %s",[messageDict objectForKey:@"Message"],[sourceContact UID],conv->name);
		
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
	
	[[adium contentController] addIncomingContentObject:messageObject];
}

- (AIListContact *)contactAssociatedWithConversation:(GaimConversation *)conv withBuddy:(GaimBuddy *)buddy
{
	return ([self _contactAssociatedWithBuddy:buddy 
									 usingUID:[NSString stringWithUTF8String:(conv->name)]]);
}

#pragma mark GaimConversation User Lists
- (void)accountConvAddedUser:(const char *)user inConversation:(GaimConversation *)conv
{
	AIChat			*chat;
	AIListContact   *contact;
	
	chat = (AIChat *)conv->ui_data;
	if (chat){
		NSString	*contactName = [NSString stringWithUTF8String:user];
		contact = [self _mainThreadContactWithUID:[contactName compactedString]];

		[contact setStatusObject:contactName forKey:@"FormattedUID" notify:YES];
		[chat addParticipatingListObject:contact];
	}
	NSLog(@"added user %s in conversation %s (%@)",user,conv->name,conv->ui_data);
}
- (void)accountConvAddedUsers:(GList *)users inConversation:(GaimConversation *)conv
{
	NSLog(@"added a whole list!");
}
- (void)accountConvRemovedUser:(const char *)user inConversation:(GaimConversation *)conv
{
	AIChat			*chat;
	AIListContact   *contact;
	
	chat = (AIChat *)conv->ui_data;
	if (chat){
		NSString	*contactName = [NSString stringWithUTF8String:user];
		contact = [[adium contactController] existingContactWithService:[[service handleServiceType] identifier]
													  accountID:[self uniqueObjectID]
															UID:[contactName compactedString]];
		[chat removeParticipatingListObject:contact];
	}
	NSLog(@"removed user %s in conversation %s (%@)",user,conv->name,conv->ui_data);
}
- (void)accountConvRemovedUsers:(GList *)users inConversation:(GaimConversation *)conv
{
	NSLog(@"removed a whole list!");
}

#pragma mark Chats
//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{	
	//Correctly enable/disable the chat
#warning All opened chats assumed valid until a better system for doing this reliably is figured out.
	[[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
	
	//This is potentially problematic
	AIListObject *listObject = [chat listObject];
//	NSLog(@"listObject is %@",listObject);
	//If a listObject is set for the chat, then it is an IM; otherwise, it is a multiuser chat
	if (listObject) {
		//Associate our chat with the libgaim conversation
		if(![[chat statusDictionary] objectForKey:@"GaimConv"]){
			
			//Evan: Temporary asserts
			NSAssert (listObject != nil, @"openChat: listObject was nil");
			NSAssert ([listObject UID] != nil, @"openChat: [listObject UID] was nil");
			NSAssert ([[listObject UID] UTF8String] != nil, @"openChat: [[listObject UID] UTF8String] was nil");
			
			GaimConversation 	*conv = gaim_conversation_new(GAIM_CONV_IM, [self gaimAccount], [[listObject UID] UTF8String]);
			NSAssert(conv != nil, @"openChat: GAIM_CONV_IM: gaim_conversation_new returned nil");
			
			conv->ui_data = [chat retain];
			[[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
		}
		
		//Track
		[chatDict setObject:chat forKey:[listObject uniqueObjectID]];
	}else{
		//If we opened a chat (rather than having it opened for us via accepting an invitation), we need to create
		//the gaim structures for that chat
		if(![[chat statusDictionary] objectForKey:@"GaimConv"]){
			
			const char *name = [[chat name] UTF8String];
			
			//Look for an existing gaimChat (for now, it had better exist already!)
			GaimChat *gaimChat = gaim_blist_find_chat ([self gaimAccount], name);
			if (!gaimChat){
				NSLog(@"gotta create a chat");
				GHashTable *components;
				GList *tmp;
				GaimGroup *group;
				const char *group_name = _("Chats");
				
				
				//The below is not even close to right.
				components = g_hash_table_new_full(g_str_hash, g_str_equal,
												   g_free, g_free);
				
				/*
				 g_hash_table_replace(components,
									  g_strdup(g_object_get_data(tmp->data, "identifier")),
									  g_strdup_printf("%d",
													  gtk_spin_button_get_value_as_int(tmp->data)));
				 */
				
				gaimChat = gaim_chat_new(account,
										 name,
										 components);
				
				if ((group = gaim_find_group(group_name)) == NULL)
				{
					group = gaim_group_new(group_name);
					gaim_blist_add_group(group, NULL);
				}
				
				if (gaimChat != NULL)
				{
					gaim_blist_add_chat(gaimChat, group, NULL);
					gaim_blist_save();
				}
				
				//Associate our chat with the libgaim conversation
				NSLog(@"associating the gaimconv");
				GaimConversation 	*conv = gaim_conversation_new(GAIM_CONV_CHAT, account, name);
				NSAssert(conv != nil, @"openChat: GAIM_CONV_CHAT: gaim_conversation_new returned nil");
				
				[[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
				conv->ui_data = [chat retain];
			}
		}
		//Track
		[chatDict setObject:chat forKey:[chat name]];
	}
	
	//Created the chat successfully
	return(YES);
}

- (BOOL)closeChat:(AIChat*)chat
{
    GaimConversation *conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
    if (conv){
        gaim_conversation_destroy(conv);
	}
	
    [[chat statusDictionary] removeObjectForKey:@"GaimConv"];
	
#warning Wrong. perhaps use a chat identifier of sorts
	AIListObject	*listObject = [chat listObject];
	if (listObject){
		NSAssert([listObject uniqueObjectID] != nil,@"closeChat: [listObject uniqueObjectID] was nil");
		[chatDict removeObjectForKey:[listObject uniqueObjectID]];
	}else{
		NSString	*name = [chat name];
		if (name){
			[chatDict removeObjectForKey:[chat name]];
		}
	}
	
    return YES;
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
			
			//***NOTE: listObject is probably the wrong thing to use here - won't that mess up multiuser chats?
			AIListObject		*listObject = [chat listObject];
			
			NSString			*body = [self encodedAttributedString:[contentMessage message] forListObject:listObject];
			GaimConversation	*conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
			
			//create a new conv if necessary - this happens, for example, if an existing chat is suddenly our responsibility
			//whereas it previously belonged to another account
			if (conv == NULL) {
				const char			*destination = [[listObject UID] UTF8String];
				
				//***NOTE: need to check if the chat is an IM or a CHAT and handle accordingly
				conv = gaim_conversation_new(GAIM_CONV_IM, account, destination);
				
				//associate the AIChat with the gaim conv
				conv->ui_data = [chat retain];
				[[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
				
				[chatDict setObject:chat forKey:[listObject uniqueObjectID]];                
			}
			
			switch (gaim_conversation_get_type(conv)) {
				case GAIM_CONV_IM:
				{
					const char			*destination = [[listObject UID] UTF8String];
					
					/*[controller sendIMWithGC:gc
								 destination:destination 
										body:[body UTF8String] 
									   flags:([contentMessage autoreply] ? GAIM_CONV_IM_AUTO_RESP : 0)];*/
					
					serv_send_im(gc, destination, [body UTF8String],[contentMessage autoreply] ? GAIM_CONV_IM_AUTO_RESP : 0);
					//gaim_conv_im_send(im, [body UTF8String]);
					sent = YES;
					break;
				}
				case GAIM_CONV_CHAT:
				{
					gaim_conv_chat_send(gaim_conversation_get_chat_data(conv),[body UTF8String]);
					sent = YES;
					break;
				}
			}
		}else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){
			AIContentTyping *ct = (AIContentTyping*)object;
			AIChat *chat = [ct chat];
			GaimConversation *conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
			
			if(conv){
			/*	
				[controller sendTypingWithGC:gaim_conversation_get_gc(conv)
										name:gaim_conversation_get_name(conv)
									   state:([ct typing] ? GAIM_TYPING : GAIM_NOT_TYPING)];
*/
				serv_send_typing(gaim_conversation_get_gc(conv),
								 gaim_conversation_get_name(conv),
								 ([ct typing] ? GAIM_TYPING : GAIM_NOT_TYPING));

				sent = YES;
			}
		}
	}
    return sent;
}

//Return YES if we're available for sending the specified content.
//If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
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

-(void)accountPrivacyList:(PRIVACY_TYPE)type added:(const char *)name
{
	//Get our contact
	NSString		*sourceUID = [NSString stringWithUTF8String:name];
	AIListContact   *contact = [self _mainThreadContactWithUID:[sourceUID compactedString]];
	
	[(type == PRIVACY_PERMIT ? permittedContactsArray : deniedContactsArray) addObject:contact];
}
-(void)accountPrivacyList:(PRIVACY_TYPE)type removed:(const char *)name
{
	//Get our contact, which must already exist for us to care about its removal
	NSString		*sourceUID = [NSString stringWithUTF8String:name];	
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

//The account requested that we received a file.
//Set up the ESFileTransfer and query the fileTransferController for a save location
- (void)accountXferRequestFileReceiveWithXfer:(GaimXfer *)xfer
{
    NSLog(@"file transfer request received");
    ESFileTransfer * fileTransfer = [[self createFileTransferObjectForXfer:xfer] retain];
    
    [fileTransfer setRemoteFilename:[NSString stringWithUTF8String:(xfer->filename)]];
    
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

//Create an ESFileTransfer object from an xfer, associating the xfer with the object and the object with the xfer
- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer
{
    //****
	NSString		*sourceUID = [NSString stringWithUTF8String:(xfer->who)];
	AIListContact   *contact = [self _mainThreadContactWithUID:[sourceUID compactedString]];
	
	
    ESFileTransfer * fileTransfer = [ESFileTransfer fileTransferWithContact:contact forAccount:self]; 

    [fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
    xfer->ui_data = [fileTransfer retain];
    
    return fileTransfer;
}

//Update an ESFileTransfer object progress
- (void)accountXferUpdateProgress:(GaimXfer *)xfer percent:(float)percent
{
	NSLog(@"File Transfer: %f%% complete",percent);
    [(ESFileTransfer *)(xfer->ui_data) setPercentDone:percent bytesSent:(xfer->bytes_sent)];
}

//The remote side canceled the transfer, the fool.  Tell the fileTransferController then destroy the xfer
- (void)accountXferCanceledRemotely:(GaimXfer *)xfer
{
    [[adium fileTransferController] transferCanceled:(ESFileTransfer *)(xfer->ui_data)];
//    gaim_xfer_destroy(xfer);
}

- (void)accountXferDestroy:(GaimXfer *)xfer
{
	[(ESFileTransfer *)xfer->ui_data release];
	xfer->ui_data = nil;
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

	if (GAIM_DEBUG) NSLog(@"Adium: Connect: Initiating connection.");
	[gaimThread connect:self];
	if (GAIM_DEBUG) NSLog(@"Adium: Connect: Done initiating connection.");
}

- (void)performConnect
{
	gc = gaim_account_connect(account);	
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
       // gaim_account_disconnect(account); 

		//		NSArray *array = [NSArray arrayWithObject:[NSValue valueWithPointer:account]];
		[gaimThread disconnect:self];
    }
}
- (void)performDisconnect
{
	gaim_account_disconnect(account);
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
- (void)accountConnectionReportDisconnect:(const char*)text
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
	
	[lastDisconnectionError release]; lastDisconnectionError = [[NSString stringWithUTF8String:text] retain];

	[self accountConnectionDisconnected];
}
- (void)accountConnectionNotice:(const char*)text
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Connection Notice",[self UID],[self serviceID]]
                                    withDescription:[NSString stringWithUTF8String:text]];	
}

//Our account has disconnected (called automatically by gaimServicePlugin)
- (void)accountConnectionDisconnected
{
    NSEnumerator    *enumerator;
    BOOL			connectionIsSuicidal = (gc ? gc->wants_to_die : NO);
	
	//Reset the gaim account (We don't want it tracking anything between sessions)
//    [self resetLibGaimAccount];
	
    //We are now offline
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:YES];
    
/*    //Clear out the GaimConv pointers in the chat statusDictionaries, as they no longer have meaning
    AIChat *chat;
    enumerator = [chatDict objectEnumerator];
    while (chat = [enumerator nextObject]) {
		[self closeChat:chat];
		[[chat statusDictionary] removeObjectForKey:@"GaimConv"];
    }       
    
    //Remove our chat dictionary
//    [chatDict release]; chatDict = [[NSMutableDictionary alloc] init];
*/
    //If we were disconnected unexpectedly, attempt a reconnect. Give subclasses a chance to handle the disconnection error.
	//connectionIsSuicidal == TRUE when Gaim thinks we shouldn't attempt a reconnect.
    if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
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
- (void)accountConnectionConnected
{
    //We are now online
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self performSelectorOnMainThread:@selector(notifyOfChangedStatusNumberSilently:)
								 withObject:[NSNumber numberWithBool:NO]
							  waitUntilDone:YES];    
    //Silence updates
    [self silenceAllHandleUpdatesForInterval:18.0];
	[[adium contactController] performSelectorOnMainThread:@selector(delayListObjectNotificationsUntilInactivity)
												withObject:nil
											 waitUntilDone:YES];

    //Set our initial status
    [self performSelectorOnMainThread:@selector(updateAllStatusKeys)
						   withObject:nil
						waitUntilDone:YES];

    //Reset reconnection attempts
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;

	//Clear any previous disconnection error
	[lastDisconnectionError release]; lastDisconnectionError = nil;
}

- (void)accountConnectionProgressStep:(size_t)step of:(size_t)step_count withText:(const char *)text
{
	[self setStatusObject:[self connectionStringForStep:step] forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:[NSNumber numberWithFloat:((float)step/(float)(step_count-1))] forKey:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self performSelectorOnMainThread:@selector(notifyOfChangedStatusNumberSilently:)
						   withObject:[NSNumber numberWithBool:NO]
						waitUntilDone:YES];
}

//Sublcasses should override to provide a string for each progress step
- (NSString *)connectionStringForStep:(int)step { return nil; };

//Reset the libgaim account, causing it to forget all saved information
//We don't want libgaim keeping track of anything between sessions... we handle all that on our own
/*
- (void)resetLibGaimAccount
{
	//Remove the account - may want to also destroy it?  Just destroying it causes crashes.
	//This will remove any gaimBuddies, account information, etc.
    [(GaimService *)service removeAccount:account];
    gaim_accounts_remove (account); account = NULL;
    gc = NULL;

    [self createNewGaimAccount];
}
*/

- (void)createNewGaimAccount
{
	gaimThread = [[NSConnection rootProxyForConnectionWithRegisteredName:@"GaimThread"
																	host:nil] retain];
	[gaimThread setProtocolForProxy:@protocol(GaimThread)];
	
	//Create a fresh version of the account
    account = gaim_account_new([UID UTF8String], [self protocolPlugin]);
    
	account->perm_deny = GAIM_PRIVACY_DENY_USERS;
	
    gaim_accounts_add(account);
	   
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
			
		} else if ( ([key compare:@"AwayMessage"] == 0) || ([key compare:@"TextProfile"] == 0) ){
			NSAttributedString	*attributedString = nil;
			
			if(data = [self preferenceForKey:key group:GROUP_ACCOUNT_STATUS]){
				attributedString = [NSAttributedString stringWithData:data];
			}
			
			[self updateAttributedStatusString:attributedString forKey:key];
			
		} else if([key compare:@"UserIcon"] == 0) {
			if(data = [self preferenceForKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS]){
				[self setAccountUserImage:[[[NSImage alloc] initWithData:data] autorelease]];
			}
		}
	}
}
- (void)setAttributedStatusString:(NSAttributedString *)attributedString forKey:(NSString *)key
{
	if([[self statusObjectForKey:@"Online"] boolValue]){
		if ([key compare:@"AwayMessage"] == 0){
			[self setAccountAwayTo:attributedString];
		} else if ([key compare:@"TextProfile"] == 0) {
			[self setAccountProfileTo:attributedString];
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

- (void)setAccountProfileTo:(NSAttributedString *)profile
{
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
	return([AIHTMLDecoder encodeHTML:inAttributedString
							 headers:YES
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:NO
						  imagesPath:nil
				   attachmentsAsText:YES]);
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
	[theContact performSelectorOnMainThread:@selector(notifyOfChangedStatusNumberSilently:)
						   withObject:[NSNumber numberWithBool:YES]
						waitUntilDone:NO];
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
		[contact performSelectorOnMainThread:@selector(notifyOfChangedStatusNumberSilently:)
									 withObject:[NSNumber numberWithBool:NO]
								  waitUntilDone:NO];
    }
}


//
- (void)_setInstantMessagesWithContact:(AIListContact *)contact enabled:(BOOL)enable
{
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

@end
