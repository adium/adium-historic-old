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

#define NO_GROUP						@"__NoGroup__"
#define ACCOUNT_IMAGE_CACHE_PATH	@"~/Library/Caches/Adium"
#define USER_ICON_CACHE_NAME			@"UserIcon_%@"
#define MESSAGE_IMAGE_CACHE_NAME		@"Image_%@_%i"

#define AUTO_RECONNECT_DELAY		2.0	//Delay in seconds
#define RECONNECTION_ATTEMPTS		4

@interface CBGaimAccount (PRIVATE)
- (void)displayError:(NSString *)errorDesc;
- (void)setBuddyImageFromFilename:(char *)imageFilename;
- (void)signonTimerExpired:(NSTimer*)timer;
- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;
- (void)connect;
- (void)disconnect;
- (NSString *)_userIconCachePath;
- (NSString *)_messageImageCachePathForID:(int)imageID;
- (AIListContact *)contactAssociatedWithBuddy:(GaimBuddy *)buddy;
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact;
- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing;
- (AIChat*)_openChatWithContact:(AIListContact *)contact andConversation:(GaimConversation*)conv;
- (NSString *)_processGaimImagesInString:(NSString *)inString;
- (NSString *)_mapIncomingGroupName:(NSString *)name;
- (NSString *)_mapOutgoingGroupName:(NSString *)name;
- (void)_updateAllEventsForBuddy:(GaimBuddy*)buddy;
@end

@implementation CBGaimAccount

// The GaimAccount associated with this Adium account
- (GaimAccount*)gaimAccount
{
    return account;
}

// Subclasses must override this
- (const char*)protocolPlugin { return NULL; }

//
- (void)_setInstantMessagesWithContact:(AIListContact *)contact enabled:(BOOL)enable
{
	AIChat *chat = [chatDict objectForKey:[contact UID]];
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


/************************/
/* accountBlist methods */
/************************/
#pragma mark GaimBuddies
- (void)accountNewBuddy:(GaimBuddy*)buddy
{
//	if(GAIM_DEBUG) NSLog(@"new: %s",buddy->name);
	[self contactAssociatedWithBuddy:buddy]; //Create a contact and hook it to this buddy
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy
{	
	if(GAIM_DEBUG) NSLog(@"accountUpdateBuddy: %s",buddy->name);
    
    /*int                     online;*/
	
    AIListContact           *theContact;
	
    //Get the node's ui_data
    theContact = (AIListContact *)buddy->node.ui_data;
	
	//Create the contact if necessary
    //if(!theContact) theContact = [self contactAssociatedWithBuddy:buddy];

		
    //Group changes - gaim buddies start off in no group, so this is an important update for us
    if(theContact && ![theContact remoteGroupName]){
        GaimGroup *g = gaim_find_buddys_group(buddy);
		if(g && g->name){
		    NSString *groupName = [NSString stringWithUTF8String:g->name];
			if(groupName && [groupName length] != 0){
				[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
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
				[[adium contactController] listObjectAttributesChanged:self
														  modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
			}
		}
	}
	
    //Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy forEvent:(GaimBuddyEvent)event
{
//	if(GAIM_DEBUG) NSLog(@"accountUpdateBuddy: %s forEvent: %i",buddy->name,event);
    
    AIListContact           *theContact;
	
    //Get the node's ui_data
    theContact = (AIListContact *)buddy->node.ui_data;
	
	//Create the contact if necessary
    if(!theContact) theContact = [self contactAssociatedWithBuddy:buddy];
	
	switch(event)
	{
		//Online / Offline
		case GAIM_BUDDY_SIGNON:
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
		case GAIM_BUDDY_SIGNOFF:
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
			}
		}   break;
		case GAIM_BUDDY_SIGNON_TIME:
		{
			if (buddy->signon != 0) {
				//Set the signon time
				[theContact setStatusObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->signon]
										   forKey:@"Signon Date"
										   notify:NO];
			}
		}
			
			//Away status
		case GAIM_BUDDY_AWAY:
		case GAIM_BUDDY_AWAY_RETURN:
		{
			BOOL newAway = (event == GAIM_BUDDY_AWAY);
			NSNumber *storedValue = [theContact statusObjectForKey:@"Away"];
			if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
				[theContact setStatusObject:[NSNumber numberWithBool:newAway] forKey:@"Away" notify:NO];
			}
		}   break;
			
		//Idletime
		case GAIM_BUDDY_IDLE:
		case GAIM_BUDDY_IDLE_RETURN:
		{
			NSDate *idleDate = [theContact statusObjectForKey:@"IdleSince"];
			int currentIdle = buddy->idle;
			if(currentIdle != (int)([idleDate timeIntervalSince1970])){
				//If there is an idle time, or if there was one before, then update
				if ((buddy->idle > 0) || idleDate) {
					[theContact setStatusObject:((currentIdle > 0) ? [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)currentIdle] : nil)
										 forKey:@"IdleSince"
										 notify:NO];
				}
			}
		}   break;
			
		case GAIM_BUDDY_EVIL:
		{
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
		case GAIM_BUDDY_ICON:
		{
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
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)accountRemoveBuddy:(GaimBuddy*)buddy
{
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


/***********************/
/* accountConv methods */
/***********************/
#pragma mark GaimConversations
- (void)accountConvDestroy:(GaimConversation*)conv
{
    AIChat *chat = (AIChat*) conv->ui_data;
    if (chat) {
        AIListContact *listContact = (AIListContact*) [chat listObject];
        if(listContact) [self setTypingFlagOfContact:listContact to:NO];
    }
}

- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type
{
    AIChat *chat = (AIChat*) conv->ui_data;
    GaimConvIm *im = gaim_conversation_get_im_data(conv);
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
				NSLog(@"got a conv update %i",type);
//            {
//                NSNumber *typing=[[handle statusDictionary] objectForKey:@"Typing"];
//                if (typing && [typing boolValue])
//                    NSLog(@"handle %@ is typing and got a nontyping update of type %i",[listContact displayName],type);
//            }
			break;
        }
    }
}

- (void)accountConvReceivedIM:(const char*)message inConversation:(GaimConversation*)conv withFlags:(GaimMessageFlags)flags atTime: (time_t)mtime
{
    if (GAIM_DEBUG) {
		NSLog(@"Received %s from %s",message,conv->name);
    }
    
    if ((flags & GAIM_MESSAGE_SEND) != 0) {
        /*
         * TODO
         * gaim is telling us that our message was sent successfully. Some
         * day, we should avoid claiming it was until we get this
         * notification.
         */
        return;
    }
    
    AIChat 			*chat = (AIChat*) conv->ui_data;
    AIListContact 	*listContact = (AIListContact*) [chat listObject];
    
    if (chat == nil) {
        if (listContact == nil) {
			NSAssert(account != nil, @"account was nil");
			NSAssert(conv->name != nil, @"conv->name was nil");
			
			NSString *assertString = [NSString stringWithFormat:@"conv->name was %s on message %s on account 0x%x",conv->name,message,account];
			NSAssert([(NSString *)[NSString stringWithUTF8String:(conv->name)] length] != 0, assertString);
            GaimBuddy 	*buddy = gaim_find_buddy(account, conv->name);
            if (buddy == NULL) {
                buddy = gaim_buddy_new(account, conv->name, NULL);  //create a GaimBuddy
                GaimGroup *group = gaim_find_group(_("Orphans"));   //get the GaimGroup
                if (group == NULL) {                                //if the group doesn't exist yet
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
            listContact = [self contactAssociatedWithBuddy:buddy];
			NSAssert(listContact != nil, @"listContact was nil immediately after contactAssociatedWithBuddy");
        }
		
		/*
		 Adam: I had two instances of Adium connect on the same account name, and
		an incoming message caused the one instance to assert here, but the other instance was fine...
		
		If no serviceID or UID is passed up there ^^ , listContact will be nil and trigger this assertion
		... so, if buddy is nil or buddy->name is nil or 0 length, we wont get a UID, wont get a list contact, and then will assert below
		
		Is this how we are supposed to handle incoming stranger messages?  By looking up a buddy from conv->name ?
		
		 Evan: It's the best we have to work with if conv->ui_data is nil.
		 */
#warning This assertion is firing almost randomly
		
		NSAssert(listContact != nil, @"contactAssociatedWithBuddy must have returned nil.");
        // Need to start a new chat, associating with the gaim conv
        chat = [[adium contentController] chatWithContact:listContact
											initialStatus:[NSDictionary dictionaryWithObject:[NSValue valueWithPointer:conv]
																					  forKey:@"GaimConv"]];
		// Associate the gaim conv with the AIChat
		conv->ui_data = chat;
		
		NSAssert(chat != nil, @"Failed to generate a chat");		
    } else  {
        NSAssert(listContact != nil, @"Existing chat yet no existing handle?");
    }
    
    //clear the typing flag
    [self setTypingFlagOfContact:listContact to:NO];
    
	NSString			*bodyString = [NSString stringWithUTF8String:message];

	if ((flags & GAIM_MESSAGE_IMAGES) != 0) {
		bodyString = [self _processGaimImagesInString:bodyString];
	}
	
    NSAttributedString *body = [AIHTMLDecoder decodeHTML:bodyString];
    AIContentMessage *messageObject =
        [AIContentMessage messageInChat:chat
                             withSource:listContact
                            destination:self
                                   date:[NSDate dateWithTimeIntervalSince1970: mtime]
                                message:body
                              autoreply:(flags & GAIM_MESSAGE_AUTO_RESP) != 0];
    [[adium contentController] addIncomingContentObject:messageObject];
}

- (NSString *)_processGaimImagesInString:(NSString *)inString
{
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*newString;

    int imageID;
	BOOL found = NO;
	
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
			GaimStoredImage *gaimImage = gaim_imgstore_get(imageID);
			NSString		*imagePath = [self _messageImageCachePathForID:imageID];

			NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:[NSData dataWithBytes:gaimImage->data 
																							length:gaimImage->size]];
            
            [[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:imagePath atomically:YES];

			//Write an <IMG SRC="filepath"> tag
			[newString appendString:[NSString stringWithFormat:@"<IMG SRC=\"%@\">",imagePath]];
		}
	}
	
	return ([newString autorelease]);
}

/********************************/
/* AIAccount subclassed methods */
/********************************/
#pragma mark AIAccount Subclassed Methods
- (void)initAccount
{
    chatDict = [[NSMutableDictionary alloc] init];
    filesToSendArray = [[NSMutableArray alloc] init];

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
		[(CBGaimServicePlugin *)service removeAccount:account];
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


/*********************/
/* AIAccount_Content */
/*********************/
#pragma mark Content
- (BOOL)sendContentObject:(AIContentObject*)object
{
    BOOL            sent = NO;
	
	if (gc && account && gaim_account_is_connected(account)) {
		if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0) {
			AIContentMessage	*cm = (AIContentMessage*)object;
			AIChat				*chat = [cm chat];
			
			//***NOTE: listObject is probably the wrong thing to use here - won't that mess up multiuser chats?
			AIListObject		*listObject = [chat listObject];
			
			NSString			*body = [self encodedAttributedString:[cm message] forListObject:listObject];
			GaimConversation	*conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
			const char			*destination = [[listObject UID] UTF8String];
			
			//create a new conv if necessary - this happens, for example, if an existing chat is suddenly our responsibility
			//whereas it previously belonged to another account
			if (conv == NULL) {
				//***NOTE: need to check if the chat is an IM or a CHAT and handle accordingly
				conv = gaim_conversation_new(GAIM_CONV_IM, account, destination);
				
				//associate the AIChat with the gaim conv
				conv->ui_data = chat;
				[[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
				
				[chatDict setObject:chat forKey:[listObject UID]];                
			}
			
			switch (gaim_conversation_get_type(conv)) {
				case GAIM_CONV_IM:
				{
					//        NSLog(@"sending %s to %@",[body UTF8String],[[chat listObject] displayName]);
					serv_send_im(gc, destination, [body UTF8String], [cm autoreply] ? GAIM_CONV_IM_AUTO_RESP : 0);
					//gaim_conv_im_send(im, [body UTF8String]);
					sent = YES;
					break;
				}
				case GAIM_CONV_CHAT:
				{
					NSLog(@"sending to a chat");	
					sent = NO;
					break;
				}
			}
		}else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){
			AIContentTyping *ct = (AIContentTyping*)object;
			AIChat *chat = [ct chat];
			GaimConversation *conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
			
			if(conv){
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
	
    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        if(weAreOnline && (inListObject == nil || [[inListObject statusObjectForKey:@"Online"] boolValue])){ 
			return(YES);
        }
    }
	
    return(NO);
}

//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{	
	//Correctly enable/disable the chat
#warning All opened chats assumed valid until a better system for doing this reliably is figured out.
	[[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];

	//This is potentially problematic
	AIListObject *listObject = [chat listObject];
	NSAssert(listObject != nil, @"ListObject for the chat is nil, unfortunately.");
	
	//Associate our chat with the libgaim conversation
	if(![[chat statusDictionary] objectForKey:@"GaimConv"]){
		GaimConversation 	*conv = gaim_conversation_new(GAIM_CONV_IM, account, [[listObject UID] UTF8String]);
		NSAssert(conv != nil, @"gaim_conversation_new returned nil");
		
		conv->ui_data = chat;
		[[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
	}
	
	//Track
	[chatDict setObject:chat forKey:[listObject UID]];

	return(YES);
}

- (BOOL)closeChat:(AIChat*)chat
{
    GaimConversation *conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
    if (conv)
        gaim_conversation_destroy(conv);

    [[chat statusDictionary] removeObjectForKey:@"GaimConv"];
	[chatDict removeObjectForKey:chat];
	
    return YES;
}


/*********************/
/* AIAccount_Handles */
/*********************/
#pragma mark Contacts
//To allow root level buddies on protocols which don't support them, we map any buddies in a group
//named after this account's UID to the root group.  These functions handle the mapping.  Group names should
//be filtered through incoming before being sent to Adium - and group names from Adium should be filtered through
//outgoing before being used.
- (NSString *)_mapIncomingGroupName:(NSString *)name
{
	if([[name compactedString] caseInsensitiveCompare:[self UID]] == 0){
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

- (void)removeContacts:(NSArray *)objects
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while(object = [enumerator nextObject]){
		NSString	*groupName = [self _mapOutgoingGroupName:[object remoteGroupName]];
		GaimBuddy 	*buddy = gaim_find_buddy(account,[[object UID] UTF8String]);
		
		//Remove this contact from the server-side and gaim-side lists
		serv_remove_buddy(gc, [[object UID] UTF8String], [groupName UTF8String]);
		if (buddy)
			gaim_blist_remove_buddy(buddy);

		[object setStatusObject:nil forKey:@"GaimBuddy" notify:NO];
			
		//Remove it from Adium's list
		[object setRemoteGroupName:nil];
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
		}
		
		//Add the buddy locally to libgaim, and then to the serverside list
		gaim_blist_add_buddy(buddy, NULL, group, NULL);
		serv_add_buddy(gc, [[object UID] UTF8String], group);
		
		//Add it to Adium's list
		[object setRemoteGroupName:[inGroup UID]]; //Use the non-mapped group name locally
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
			NSString	*oldGroupName = [self _mapOutgoingGroupName:[listObject remoteGroupName]];
			
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
		NSEnumerator	*enumerator = [[[adium contactController] allContactsInGroup:inGroup onAccount:self] objectEnumerator];
		AIListContact	*contact;
		
		while(contact = [enumerator nextObject]){
			[contact setRemoteGroupName:newName];
		}
	}
}

//- (BOOL)moveHandleWithUID:(NSString *)inUID toGroup:(NSString *)inGroup
//{
//    AIHandle	*handle;
//    if(handle = [handleDict objectForKey:inUID]){
//        GaimGroup *oldGroup = gaim_find_group([[handle serverGroup] UTF8String]);   //get the GaimGroup        
//        GaimGroup *newGroup = gaim_find_group([inGroup UTF8String]);                //get the GaimGroup
//        if (newGroup == NULL) {                                                        //if the group doesn't exist yet
//                                                                                                                                                                
//            //           NSLog(@"Creating a new group");
//            newGroup = gaim_group_new([inGroup UTF8String]);                           //create the GaimGroup
//        }
//        
//        GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);
//        if (buddy != NULL) {
//            serv_move_buddy(buddy,oldGroup,newGroup);
//        } else {
//            return NO;
//        }
//    }
//    return NO;
//}
	


// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return([[self statusObjectForKey:@"Online"] boolValue]);
}


//{
//    AIHandle	*handle;
//    if(handle = [handleDict objectForKey:inUID]){
//        GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);
//        
//        serv_remove_buddy(gc,[inUID UTF8String],[[handle serverGroup] UTF8String]); //remove it from the list serverside
//        gaim_blist_remove_buddy(buddy);                                             //remove it gaimside
//        
//        return YES;
//    } else 
//        return NO;
//}
	
//    serv_remove_group(gc,[inGroup UTF8String]);             //remove it from the list serverside
//    
//    GaimGroup *group = gaim_find_group([inGroup UTF8String]);   //get the GaimGroup
//    gaim_blist_remove_group(group);                         //remove it gaimside
//															
//        NSLog(@"remove group %@",inGroup);
//    return YES;

// Returns a dictionary of AIHandles available on this account
//- (NSDictionary *)availableHandles //return nil if no contacts/list available
//{
//    if([[self statusObjectForKey:@"Online"] boolValue] || [[self statusObjectForKey:@"Connecting"] boolValue]){
//        return(handleDict);
//    }else{
//        return(nil);
//    }
//}
	
//// Returns YES if the list is editable
//- (BOOL)contactListEditable
//{
//    return YES;
//}
//
//// Add a handle to this account
//- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
//{
//    AIHandle	*handle;
//    
//    if(inTemporary) inGroup = @"__Strangers";    
//    if(!inGroup) inGroup = @"Unknown";
//    
//    //Check to see if the handle already exists, and remove the duplicate if it does
//    if(handle = [handleDict objectForKey:inUID]){
//        [self removeHandleWithUID:inUID]; //Remove the handle
//    }
//    
//    //Create the handle
//    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] identifier] 
//                                       UID:inUID 
//                               serverGroup:inGroup 
//                                 temporary:inTemporary 
//                                forAccount:self];
//    NSString    *handleUID = [handle UID];
//    NSString    *handleServerGroup = [handle serverGroup];
//    
//    //Add the handle
//	[handleDict setObject:handle forKey:[handle UID]];                  //Add it locally
//	
//    GaimGroup *group = gaim_find_group([handleServerGroup UTF8String]); //get the GaimGroup
//    if (group == NULL) {                                                //if the group doesn't exist yet
//        group = gaim_group_new([handleServerGroup UTF8String]);         //create the GaimGroup
//        gaim_blist_add_group(group, NULL);                              //add it gaimside (server will add as needed)
//    }
//    
//    GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);     //verify the buddy does not already exist
//    if (buddy == NULL) {                                                //should always be null
//        buddy = gaim_buddy_new(account, [handleUID UTF8String], NULL);  //create a GaimBuddy
//    }
//	
//    gaim_blist_add_buddy(buddy, NULL, group, NULL);                     //add the buddy to the gaimside list
//    serv_add_buddy(gc,[handleUID UTF8String],group);                    //and add the buddy serverside
//	
//    //From TOC2
//    //[self silenceUpdateFromHandle:handle]; //Silence the server's initial update command
//    
//    //Update the contact list
//    [[adium contactController] handle:handle addedToAccount:self];
//	
//    return(handle);
//}
//
//// Remove a handle from this account
//- (BOOL)removeHandleWithUID:(NSString *)inUID
//{
//    AIHandle	*handle;
//    if(handle = [handleDict objectForKey:inUID]){
//        GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);
//        
//        serv_remove_buddy(gc,[inUID UTF8String],[[handle serverGroup] UTF8String]); //remove it from the list serverside
//        gaim_blist_remove_buddy(buddy);                                             //remove it gaimside
//        
//        return YES;
//    } else 
//        return NO;
//}
//
//// Add a group to this account
//- (BOOL)addServerGroup:(NSString *)inGroup
//{
//    GaimGroup *group = gaim_group_new([inGroup UTF8String]);    //create the GaimGroup
//    gaim_blist_add_group(group,NULL);                           //add it gaimside (server will make it as needed)
//                                                                
//    //    NSLog(@"added group %@",inGroup);
//    return NO;
//}
//// Remove a group
//- (BOOL)removeServerGroup:(NSString *)inGroup
//{
//    serv_remove_group(gc,[inGroup UTF8String]);             //remove it from the list serverside
//    
//    GaimGroup *group = gaim_find_group([inGroup UTF8String]);   //get the GaimGroup
//    gaim_blist_remove_group(group);                         //remove it gaimside
//															
//        NSLog(@"remove group %@",inGroup);
//    return YES;
//}
//
//- (BOOL)moveHandleWithUID:(NSString *)inUID toGroup:(NSString *)inGroup
//{
//    AIHandle	*handle;
//    if(handle = [handleDict objectForKey:inUID]){
//        GaimGroup *oldGroup = gaim_find_group([[handle serverGroup] UTF8String]);   //get the GaimGroup        
//        GaimGroup *newGroup = gaim_find_group([inGroup UTF8String]);                //get the GaimGroup
//        if (newGroup == NULL) {                                                        //if the group doesn't exist yet
//                                                                                                                                                                
//            //           NSLog(@"Creating a new group");
//            newGroup = gaim_group_new([inGroup UTF8String]);                           //create the GaimGroup
//        }
//        
//        GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);
//        if (buddy != NULL) {
//            serv_move_buddy(buddy,oldGroup,newGroup);
//        } else {
//            return NO;
//        }
//    }
//    return NO;
//}
	
- (AIListContact *)contactAssociatedWithBuddy:(GaimBuddy *)buddy
{
	NSAssert(buddy != nil,@"contactAssociatedWithBuddy: passed a nil buddy");
	
	AIListContact	*contact;
	NSString		*contactUID = [NSString stringWithUTF8String:(buddy->name)];
	
	//Evan: temporary assert
	NSAssert(contactUID != nil,@"contactAssociatedWithBuddy: contactUID was nil");
	
	//Get our contact
	contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
												  accountID:[self uniqueObjectID]
														UID:[contactUID compactedString]];
	
	//Evan: temporary asserts
	NSAssert ([[service handleServiceType] identifier] != nil,@"contactAssociatedWithBuddy: [[service handleServiceType] identifier] was nil");
	NSAssert ([contactUID compactedString] != nil,@"contactAssociatedWithBuddy: [contactUID compactedString] was nil");
	NSAssert (contact != nil,@"contactAssociatedWithBuddy: contact was nil");
	
    //Associate the handle with ui_data and the buddy with our statusDictionary
    buddy->node.ui_data = [contact retain];
    [contact setStatusObject:[NSValue valueWithPointer:buddy] forKey:@"GaimBuddy" notify:NO];
	
	return(contact);
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
	AIListContact   *contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
																   accountID:[self uniqueObjectID]
																		 UID:[[NSString stringWithUTF8String:(xfer->who)] compactedString]];
	
    ESFileTransfer * fileTransfer = [ESFileTransfer fileTransferWithContact:contact forAccount:self]; 

    [fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
    xfer->ui_data = fileTransfer;
    
    return fileTransfer;
}

//Update an ESFileTransfer object progress
- (void)accountXferUpdateProgress:(GaimXfer *)xfer percent:(float)percent
{
    [(ESFileTransfer *)(xfer->ui_data) setPercentDone:percent bytesSent:(xfer->bytes_sent)];
}

//The remote side canceled the transfer, the fool.  Tell the fileTransferController then destroy the xfer
- (void)accountXferCanceledRemotely:(GaimXfer *)xfer
{
    [[adium fileTransferController] transferCanceled:(ESFileTransfer *)(xfer->ui_data)];
//    gaim_xfer_destroy(xfer);
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

/***************************/
/* Account private methods */
/***************************/
#pragma mark Private
// Removes all the possible status flags from the passed contact
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact
{
    NSArray			*keyArray = [self contactStatusFlags];
	NSEnumerator	*enumerator = [keyArray objectEnumerator];
	NSString		*key;
	
	while(key = [enumerator nextObject]){
		[contact setStatusObject:nil forKey:key notify:NO];
	}
	[contact notifyOfChangedStatusSilently:YES];
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
						  notify:YES];
    }
}


- (void)displayError:(NSString *)errorDesc
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ (%@) : Gaim error",[self UID],[self serviceID]]
                                    withDescription:errorDesc];
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
	
	//Configure libgaim's proxy settings
	[self configureAccountProxy];
	
	//Set password and connect
	gaim_account_set_password(account, [password UTF8String]);
	gc = gaim_account_connect(account);
}

//Configure libgaim's proxy settings using the current system values
- (void)configureAccountProxy
{
	GaimProxyInfo *proxy_info = gaim_proxy_info_new();
	
	if([(CBGaimServicePlugin *)service configureGaimProxySettings]) {
		char *type = (char *)gaim_prefs_get_string("/core/proxy/type");
		int proxytype;
		
		if (!strcmp(type, "none"))
			proxytype = GAIM_PROXY_NONE;
		else if (!strcmp(type, "http"))
			proxytype = GAIM_PROXY_HTTP;
		else if (!strcmp(type, "socks4"))
			proxytype = GAIM_PROXY_SOCKS4;
		else if (!strcmp(type, "socks5"))
			proxytype = GAIM_PROXY_SOCKS5;
		else if (!strcmp(type, "envvar"))
			proxytype = GAIM_PROXY_USE_ENVVAR;
		else
			proxytype = -1;
		
		proxy_info->type = proxytype;
		
		proxy_info->host = (char *)gaim_prefs_get_string("/core/proxy/host");
		proxy_info->port = (int)gaim_prefs_get_int("/core/proxy/port");
		
		proxy_info->username = (char *)gaim_prefs_get_string("/core/proxy/username"),
		proxy_info->password = (char *)gaim_prefs_get_string("/core/proxy/password");
		
		NSLog(@"Proxy settings: %i %s:%i %s %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username,proxy_info->password);
		
	} else {
		proxy_info->type = GAIM_PROXY_NONE;
		NSLog(@"No proxy settings.");
	}
	
	gaim_account_set_proxy_info(account,proxy_info);
}

//Disconnect this account
- (void)disconnect
{
    //We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];

    //Tell libgaim to disconnect
    if(gaim_account_is_connected(account)){
        gaim_account_disconnect(account); 
    }
}

/*****************************/
/* accountConnection methods */
/*****************************/
//Our account was disconnected, report the error
- (void)accountConnectionReportDisconnect:(const char*)text
{
    [self displayError:[NSString stringWithUTF8String:text]];
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
    
	//Reset the gaim account (We don't want it tracking anything between sessions)
    [self resetLibGaimAccount];
	
    //We are now offline
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:YES];
    
    //Clear out the GaimConv pointers in the chat statusDictionaries, as they no longer have meaning
    AIChat *chat;
    enumerator = [chatDict objectEnumerator];
    while (chat = [enumerator nextObject]) {
        [[chat statusDictionary] removeObjectForKey:@"GaimConv"];
    }       
    
    //Remove our chat dictionary
    [chatDict release]; chatDict = [[NSMutableDictionary alloc] init];
    
    //If we were disconnected unexpectedly, attempt a reconnect
    if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
		if (reconnectAttemptsRemaining) {
			[self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY];
			reconnectAttemptsRemaining--;
		}
    }
}

//Our account has connected (called automatically by gaimServicePlugin)
- (void)accountConnectionConnected
{
    //We are now online
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:YES];
    
    //Silence updates
    [self silenceAllHandleUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
    
    //Set our initial status
    [self updateAllStatusKeys];
	
    //Reset reconnection attempts
    reconnectAttemptsRemaining = RECONNECTION_ATTEMPTS;
}

//Reset the libgaim account, causing it to forget all saved information
//We don't want libgaim keeping track of anything between sessions... we handle all that on our own
- (void)resetLibGaimAccount
{
    gaim_core_mainloop_finish_events();
    
	//Remove the account - may want to also destroy it?  Just destroying it causes crashes.
	//This will remove any gaimBuddies, account information, etc.
    [(CBGaimServicePlugin *)service removeAccount:account];
    gaim_accounts_remove (account); account = NULL;
    gc = NULL;

    [self createNewGaimAccount];
    
    gaim_core_mainloop_finish_events();
}

- (void)createNewGaimAccount
{
//	NSString *accountName = [self preferenceForKey:KEY_ACCOUNT_NAME group:GROUP_ACCOUNT_STATUS];
//	
//	//Sanity check: If no preference has been set, use the UID
//	if (!accountName)
//		accountName = UID;
	
    //Create a fresh version of the account
    account = gaim_account_new([UID UTF8String], [self protocolPlugin]);
    gaim_accounts_add(account);
    
	[(CBGaimServicePlugin *)service addAccount:self forGaimAccountPointer:account];
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
	NSData	*data;
	
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
	if (gc && account) 
		serv_set_away(gc, GAIM_AWAY_CUSTOM, awayHTML);
    
    //We are now away
    [self setStatusObject:[NSNumber numberWithBool:(awayMessage != nil)] forKey:@"Away" notify:NO];
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
    [self setStatusObject:profile forKey:@"TextProfile" notify:NO];
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


@end
