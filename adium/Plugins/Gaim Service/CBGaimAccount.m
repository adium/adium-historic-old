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

#define NO_GROUP                @"__NoGroup__"
#define USER_ICON_CACHE_PATH    @"~/Library/Caches/Adium"
#define USER_ICON_CACHE_NAME    @"UserIcon_%@"
#define MESSAGE_IMAGE_CACHE_NAME	@"Image_%@_%i"

#define AUTO_RECONNECT_DELAY	2.0	//Delay in seconds
#define RECONNECTION_ATTEMPTS   4

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
	if(GAIM_DEBUG) NSLog(@"new: %s",buddy->name);
	[self contactAssociatedWithBuddy:buddy]; //Create a contact and hook it to this buddy
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy
{
	if(GAIM_DEBUG) NSLog(@"update: %s",buddy->name);
    
    int                     online;
    AIListContact           *theContact;
	
    //Get the node's ui_data
    theContact = (AIListContact *)buddy->node.ui_data;
	
	//Create the contact if necessary
    if(!theContact) theContact = [self contactAssociatedWithBuddy:buddy];

    //Group changes - gaim buddies start off in no group, so this is an important update for us
    if(![theContact remoteGroupNameForAccount:self]){
        GaimGroup *g = gaim_find_buddys_group(buddy);
		if(g/* && strcmp([[theContact remoteGroupNameForAccount:self] UTF8String], g->name)*/){
		    NSString *groupName = [NSString stringWithUTF8String:g->name];
		    if (![groupName length])
			groupName = [self unknownGroupName];
		    [theContact setRemoteGroupName:groupName forAccount:self];
        }
    }
    

    
	
    
    //Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy forEvent:(GaimBuddyEvent)event
{
	if(GAIM_DEBUG) NSLog(@"update: %s forEvent: %i",buddy->name,event);
    
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
			NSNumber *contactOnlineStatus = [theContact statusObjectForKey:@"Online" withOwner:self];
			if(!contactOnlineStatus || ([contactOnlineStatus boolValue] != YES)){
				[theContact setStatusObject:[NSNumber numberWithBool:YES] withOwner:self forKey:@"Online" notify:NO];
				[self _setInstantMessagesWithContact:theContact enabled:YES];
				
				if(!silentAndDelayed){
					[theContact setStatusObject:[NSNumber numberWithBool:YES] withOwner:self forKey:@"Signed On" notify:NO];
					[theContact setStatusObject:nil withOwner:self forKey:@"Signed Off" notify:NO];
					[theContact setStatusObject:nil withOwner:self forKey:@"Signed On" afterDelay:15];
				}
				
				//Display Name - use the serverside buddy_alias if present
				{
					char *alias = (char *)gaim_get_buddy_alias(buddy);
					char *disp_name = (char *)[[theContact statusObjectForKey:@"Display Name" withOwner:self] UTF8String];
					if(!disp_name) disp_name = "";
					
					if(alias && strcmp(disp_name, alias)){
						[theContact setStatusObject:[NSString stringWithUTF8String:alias]
										  withOwner:self
											 forKey:@"Display Name"
											 notify:NO];
					}
				}
				
			}
		}   break;
		case GAIM_BUDDY_SIGNOFF:
		{
			NSNumber *contactOnlineStatus = [theContact statusObjectForKey:@"Online" withOwner:self];
			if(!contactOnlineStatus || ([contactOnlineStatus boolValue] != NO)){
				[theContact setStatusObject:[NSNumber numberWithBool:NO] withOwner:self forKey:@"Online" notify:NO];
				[self _setInstantMessagesWithContact:theContact enabled:NO];
				
				if(!silentAndDelayed){
					[theContact setStatusObject:[NSNumber numberWithBool:YES] withOwner:self forKey:@"Signed Off" notify:NO];
					[theContact setStatusObject:nil withOwner:self forKey:@"Signed On" notify:NO];
					[theContact setStatusObject:nil withOwner:self forKey:@"Signed Off" afterDelay:15];
				}
			}
		}   break;
		case GAIM_BUDDY_SIGNON_TIME:
		{
			if (buddy->signon != 0) {
				//Set the signon time
				[theContact setStatusObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->signon]
										withOwner:self
										   forKey:@"Signon Date"
										   notify:NO];
			}
		}
			
			//Away status
		case GAIM_BUDDY_AWAY:
		case GAIM_BUDDY_AWAY_RETURN:
		{
			BOOL newAway = (event == GAIM_BUDDY_AWAY);
			NSNumber *storedValue = [theContact statusObjectForKey:@"Away" withOwner:self];
			if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
				[theContact setStatusObject:[NSNumber numberWithBool:newAway] withOwner:self forKey:@"Away" notify:NO];
			}
		}   break;
			
		//Idletime
		case GAIM_BUDDY_IDLE:
		case GAIM_BUDDY_IDLE_RETURN:
		{
			NSDate *idleDate = [theContact statusObjectForKey:@"IdleSince" withOwner:self];
			int currentIdle = buddy->idle;
			if(currentIdle != (int)([idleDate timeIntervalSince1970])){
				//If there is an idle time, or if there was one before, then update
				if ((buddy->idle > 0) || idleDate) {
					[theContact setStatusObject:((currentIdle > 0) ? [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)currentIdle] : nil)
									  withOwner:self
										 forKey:@"IdleSince"
										 notify:NO];
				}
			}
		}   break;
			
		case GAIM_BUDDY_EVIL:
		{
			//Set the warning level or clear it if it's now 0.
			int evil = buddy->evil;
			NSNumber *currentWarningLevel = [theContact statusObjectForKey:@"Warning" withOwner:self];
			if (evil > 0){
				if (!currentWarningLevel || ([currentWarningLevel intValue] != evil)) {
					[theContact setStatusObject:[NSNumber numberWithInt:evil]
									  withOwner:self 
										 forKey:@"Warning"
										 notify:NO];
				}
			}else{
				if (currentWarningLevel) {
					[theContact setStatusObject:nil
									  withOwner:self
										 forKey:@"Warning" 
										 notify:NO];   
				}
			}
		}   break;
			
		//Buddy Icon
		case GAIM_BUDDY_ICON:
		{
			GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
			if(buddyIcon && (buddyIcon != [[theContact statusObjectForKey:@"BuddyImagePointer" withOwner:self] pointerValue])) {                            
				//save this for convenience
				[theContact setStatusObject:[NSValue valueWithPointer:buddyIcon]
								  withOwner:self
									 forKey:@"BuddyImagePointer"
									 notify:NO];
				
				//set the buddy image
				NSImage *image = [[[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_buddy_icon_get_data(buddyIcon, &(buddyIcon->len))
																			   length:buddyIcon->len]] autorelease];
				[theContact setStatusObject:image withOwner:self forKey:@"UserIcon" notify:NO];
			}
		}   break;
	}
	
	//Apply any changes
	[theContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)accountRemoveBuddy:(GaimBuddy*)buddy
{
	AIListContact	*theContact = (AIListContact *)buddy->node.ui_data ;
	
    if(theContact){
		[theContact setRemoteGroupName:nil forAccount:self];
		[self removeAllStatusFlagsFromContact:theContact];

		[theContact release];
        buddy->node.ui_data = NULL;
    }
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
            GaimBuddy 	*buddy = gaim_find_buddy(account, conv->name);
            if (buddy == NULL) {
                buddy = gaim_buddy_new(account, conv->name, NULL);  //create a GaimBuddy
                GaimGroup *group = gaim_find_group(_("Orphans"));   //get the GaimGroup
                if (group == NULL) {                                //if the group doesn't exist yet
                    group = gaim_group_new(_("Orphans"));           //create the GaimGroup
                    gaim_blist_add_group(group, NULL);              //add it gaimside
                }
                gaim_blist_add_buddy(buddy, NULL, group, NULL);     //add the buddy to the gaimside list
            }
            listContact = [self contactAssociatedWithBuddy:buddy];
        }
        // Need to start a new chat
        chat = [self _openChatWithContact:listContact andConversation:conv];
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

    //create an initial gaim account
    [self createNewGaimAccount];
    gc = NULL;
    if (GAIM_DEBUG) NSLog(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
    
    //ensure our user icon cache path exists
    [AIFileUtilities createDirectory:[USER_ICON_CACHE_PATH stringByExpandingTildeInPath]];
}

- (void)dealloc
{
    [(CBGaimServicePlugin *)service removeAccount:account];
    
    [chatDict release];
    [filesToSendArray release];

    [super dealloc];
}

- (NSString *)accountID {
    return [NSString stringWithFormat:@"GAIM-%@.%@", [self serviceID], [self UID]];
}

- (NSString *)accountDescription {
    return [self UIDAndServiceID];
}

- (NSString *)unknownGroupName {
    return (@"Unknown");
}

- (NSDictionary *)defaultProperties { return([NSDictionary dictionary]); }
- (id <AIAccountViewController>)accountView{ return(nil); }


/*********************/
/* AIAccount_Content */
/*********************/
#pragma mark Content
- (BOOL)sendContentObject:(AIContentObject*)object
{
    BOOL            sent = NO;
	
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0) {
        AIContentMessage *cm = (AIContentMessage*)object;
        AIChat *chat = [cm chat];
        NSString *body = [self encodedAttributedString:[cm message] forListObject:[chat listObject]];
        GaimConversation *conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
        
        //create a new conv if necessary - this happens, for example, if an existing chat is suddenly our responsibility
        //whereas it previously belonged to another account
        if (conv == NULL) {
            //***NOTE: need to check if the chat is an IM or a CHAT and handle accordingly
            conv = gaim_conversation_new(GAIM_CONV_IM, account, [[[chat listObject] UID] UTF8String]);
            //associate the AIChat with the gaim conv
            conv->ui_data = chat;
            [[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
            //***NOTE: listObject is probably the wrong thing to use here - won't that mess up multiuser chats?
            [chatDict setObject:chat forKey:[[chat listObject] UID]];                
        }
        
        GaimConvIm *im = gaim_conversation_get_im_data(conv);
        
//        NSLog(@"sending %s to %@",[body UTF8String],[[chat listObject] displayName]);
        gaim_conv_im_send(im, [body UTF8String]);
        sent = YES;
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
	
    return sent;
}

//Return YES if we're available for sending the specified content.
//If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    BOOL	weAreOnline = [[self statusObjectForKey:@"Online"] boolValue];
	
    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        if(weAreOnline && (inListObject == nil || [[inListObject statusObjectForKey:@"Online" withOwner:self] boolValue])){ 
			return(YES);
        }
    }
	
    return(NO);
}

- (AIChat*)openChatWithListObject:(AIListObject*)inListObject
{
    AIChat		*chat = nil;
	
    if([inListObject isKindOfClass:[AIListContact class]]){        
        chat = [self _openChatWithContact:(AIListContact *)inListObject andConversation:NULL];
    }
	
    return(chat);
}

- (AIChat*)_openChatWithContact:(AIListContact *)contact andConversation:(GaimConversation*)conv
{
    AIChat *chat;
	
    //create a chat if we're passed a null conversation or the conversation we're passed doesn't have a chat yet
    if(!conv || !(chat = conv->ui_data)){
        chat = [AIChat chatForAccount:self];
        
        [chat addParticipatingListObject:contact];
		
        BOOL handleIsOnline;        
        handleIsOnline = YES; // TODO
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:handleIsOnline] forKey:@"Enabled"];
        
        if (conv == NULL) {
            conv = gaim_conversation_new(GAIM_CONV_IM, account, [[contact UID] UTF8String]);
        }
        
        //associate the AIChat with the gaim conv
        conv->ui_data = chat;
        [[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
        [chatDict setObject:chat forKey:[contact UID]];
        [[adium contentController] noteChat:chat forAccount:self];
    } 
    return chat;
}

- (BOOL)closeChat:(AIChat*)inChat
{
    GaimConversation *conv = (GaimConversation*) [[[inChat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
    if (conv)
        gaim_conversation_destroy(conv);
    [chatDict removeObjectForKey:inChat];
    return YES;
}


/*********************/
/* AIAccount_Handles */
/*********************/
#pragma mark Contacts

//Update the status of a contact (Request their profile)
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{	
    //Request profile
    if(gc && ([[inContact statusObjectForKey:@"Online" withOwner:self] boolValue])){
		serv_get_info(gc, [[inContact UID] UTF8String]);
    }
}

- (void)removeContacts:(NSArray *)objects
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while(object = [enumerator nextObject]){
		NSString	*group = [object remoteGroupNameForAccount:self];
		GaimBuddy 	*buddy = gaim_find_buddy(account,[[object UID] UTF8String]);
		
		[object setRemoteGroupName:nil forAccount:self];
		serv_remove_buddy(gc, [[object UID] UTF8String], [group UTF8String]);	//remove it from the list serverside
		gaim_blist_remove_buddy(buddy);											//remove it gaimside
	}
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)inGroup
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while(object = [enumerator nextObject]){
		//Get the group (Create if necessary)
		GaimGroup *group = gaim_find_group([[inGroup UID] UTF8String]);
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
		
		//Set our remote grouping
		[object setRemoteGroupName:[inGroup UID] forAccount:self];
	}
}

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
//// Rename a group
//- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
//{
//    GaimGroup *group = gaim_find_group([inGroup UTF8String]);   //get the GaimGroup
//    if (group != NULL) {                                        //if we find the GaimGroup
//        NSLog(@"serv_rename_group(%@,%@)",inGroup,newName);
//        serv_rename_group(gc, group, [newName UTF8String]);     //rename
//        NSLog(@"gaim_blist_remove_group(%@)",inGroup);
//        gaim_blist_remove_group(group);                         //remove the old one gaimside
//        return YES;
//    } else
//        return NO;
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
	AIListContact	*contact;
	NSString		*contactUID = [NSString stringWithUTF8String:(buddy->name)];
	
	//Get our contact
	contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
														UID:[contactUID compactedString]];
	
    //Associate the handle with ui_data and the buddy with our statusDictionary
    buddy->node.ui_data = [contact retain];
    [contact setStatusObject:[NSValue valueWithPointer:buddy] withOwner:self forKey:@"GaimBuddy" notify:NO];
	
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


//Create an ESFileTransfer object from an xfer, associating the xfer with the object and the object with the xfer
- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer
{
    //****
	AIListContact   *contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
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
    NSArray			*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"IdleSince",@"Signon Date",@"Away",@"Client",@"TextProfile",nil];
	NSEnumerator	*enumerator = [keyArray objectEnumerator];
	NSString		*key;
	
	while(key = [enumerator nextObject]){
		[contact setStatusObject:nil withOwner:self forKey:key notify:NO];
	}
	[contact notifyOfChangedStatusSilently:YES];
}

- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing
{
    BOOL currentValue = [[contact statusObjectForKey:@"Typing" withOwner:self] boolValue];
	
    if(typing != currentValue){
		[contact setStatusObject:[NSNumber numberWithBool:typing]
					   withOwner:self
						  forKey:@"Typing"
						  notify:YES];
    }
}


- (void)displayError:(NSString *)errorDesc
{
    [[adium interfaceController] handleErrorMessage:@"Gaim error"
                                    withDescription:errorDesc];
}

- (NSString *)_userIconCachePath
{    
    NSString    *userIconCacheFilename = [NSString stringWithFormat:USER_ICON_CACHE_NAME, [self UIDAndServiceID]];
    return([[USER_ICON_CACHE_PATH stringByAppendingPathComponent:userIconCacheFilename] stringByExpandingTildeInPath]);
}

- (NSString *)_messageImageCachePathForID:(int)imageID
{
    NSString    *messageImageCacheFilename = [NSString stringWithFormat:MESSAGE_IMAGE_CACHE_NAME, [self UIDAndServiceID], imageID];
    return([[[USER_ICON_CACHE_PATH stringByAppendingPathComponent:messageImageCacheFilename] stringByAppendingPathExtension:@"png"] stringByExpandingTildeInPath]);	
}

//Account Connectivity -------------------------------------------------------------------------------------------------
#pragma mark Account Connectivity
//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
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
	if([(CBGaimServicePlugin *)service configureGaimProxySettings]) {
		GaimProxyInfo *proxy_info = gaim_proxy_info_new();
		
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
		
		gaim_account_set_proxy_info(account,proxy_info);
	}
}

//Disconnect this account
- (void)disconnect
{
    //We are disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
	[[adium contactController] delayListObjectNotifications];

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

//Our account has disconnected (called automatically by gaimServicePlugin)
- (void)accountConnectionDisconnected
{
    NSEnumerator    *enumerator;
    
    //We are now offline
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:YES];
    
    //Flush all our handle status flags
//#warning (Intentional) This is dreadfully inefficient.  Is there a faster solution to disconnecting?
//libgaim does this for us w/ remove messages
//    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
//    while((contact = [enumerator nextObject])){
//        [self removeAllStatusFlagsFromContact:contact];
////		[contact setRemoteGroupName:nil forAccount:self];
//    }
    
    //Clear out the GaimConv pointers in the chat statusDictionaries, as they no longer have meaning
    AIChat *chat;
    enumerator = [chatDict objectEnumerator];
    while (chat = [enumerator nextObject]) {
        [[chat statusDictionary] removeObjectForKey:@"GaimConv"];
    }       
    
    //Remove our chat dictionary
    [chatDict release]; chatDict = [[NSMutableDictionary alloc] init];
    
    //Reset the gaim account (We don't want it tracking anything between sessions)
    [self resetLibGaimAccount];
    
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
	[[adium contactController] delayListObjectNotifications];
    
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
    //Recreate a fresh version of the account
    account = gaim_account_new([[self UID] UTF8String], [self protocolPlugin]);
    gaim_accounts_add(account);
    [(CBGaimServicePlugin *)service addAccount:self forGaimAccountPointer:account];
}

//Account Status ------------------------------------------------------------------------------------------------------
#pragma mark Account Status
//Status keys this account supports
- (NSArray *)supportedPropertyKeys
{
    return([NSArray arrayWithObjects:
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
        nil]);
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
                    
                }
        }

	//User Icon can be set regardless of ONLINE state
	if([key compare:@"UserIcon"] == 0) {
		if(data = [self preferenceForKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS]){
			[self setAccountUserImage:[[[NSImage alloc] initWithData:data] autorelease]];
		}
	}
}
- (void)setAttributedStatusString:(NSAttributedString *)attributedString forKey:(NSString *)key
{
    if ([key compare:@"AwayMessage"] == 0){
        [self setAccountAwayTo:attributedString];
    } else if ([key compare:@"TextProfile"] == 0) {
        [self setAccountProfileTo:attributedString];
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
    serv_set_info(gc, profileHTML);
    
    if (GAIM_DEBUG) NSLog(@"updating profile to %@",[profile string]);
    
    //We now have a profile
    [self setStatusObject:profile forKey:@"TextProfile" notify:NO];
}

// *** USER IMAGE
//Set our user image (Pass nil for no image)
- (void)setAccountUserImage:(NSImage *)image
{
	//Clear the existing icon first
	gaim_account_set_buddy_icon(account, nil);

	//Now pass libgaim the new icon.  Libgaim takes icons as a file, so we save our
	//image to one, and then pass libgaim the path.
	if(image){          
		NSData 		*data = [image JPEGRepresentation];
		NSString    *buddyImageFilename = [self _userIconCachePath];
		
		if([data writeToFile:buddyImageFilename atomically:YES]){
			gaim_account_set_buddy_icon(account, [buddyImageFilename UTF8String]);
		}else{
			NSLog(@"Error writing file %@",buddyImageFilename);   
		}
	}

	//We now have an icon
	[self setStatusObject:image forKey:@"UserIcon" notify:YES];
}


@end
