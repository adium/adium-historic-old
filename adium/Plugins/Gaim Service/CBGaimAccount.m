//
//  CBGaimAccount.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

//evands note: may want to use a mutableOnwerArray inside chat statusDictionary properties so that we can have multiple gaim accounts in the same chat.

#import "CBGaimAccount.h"
#import "CBGaimServicePlugin.h"

#define OWN_BUDDY_IMAGE         @"/Users/evands/evands.jpg"
#define PROFILE_STRING          @"I'm using Adium 2.0. Are you? www.adiumx.com"

#define NO_GROUP                @"__NoGroup__"
#define USER_ICON_CACHE_PATH    @"~/Library/Caches/Adium"
#define USER_ICON_CACHE_NAME    @"UserIcon_%@"

#define AUTO_RECONNECT_DELAY	2.0	//Delay in seconds

@interface CBGaimAccount (PRIVATE)
- (AIChat*)_openChatWithHandle:(AIHandle*)handle andConversation:(GaimConversation*)conv;
- (void)displayError:(NSString *)errorDesc;
- (void)setBuddyImageFromFilename:(char *)imageFilename;
- (void)signonTimerExpired:(NSTimer*)timer;
- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;
- (void)connect;
- (void)disconnect;
- (void)autoReconnectAfterDelay:(int)delay;
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle;
- (NSString *)_userIconCachePath;
- (void)setTypingFlagOfHandle:(AIHandle *)handle to:(BOOL)typing;
- (AIHandle *)createHandleAssociatingWithBuddy:(GaimBuddy *)buddy;
@end

@implementation CBGaimAccount

- (GaimAccount*)gaimAccount
{
    return account;
}

// Subclasses must override this
- (const char*)protocolPlugin { return NULL; }


/************************/
/* accountBlist methods */
/************************/

- (void)accountNewBuddy:(GaimBuddy*)buddy
{
//    NSLog(@"accountNewBuddy (%s)", buddy->name);
    [self createHandleAssociatingWithBuddy:buddy];
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy
{
//    NSLog(@"accountUpdateBuddy (%s)", buddy->name);
    int                     online;
    NSMutableDictionary     *statusDict;
    NSMutableArray          *modifiedKeys = [NSMutableArray array];
    AIHandle                *theHandle;

    //Get the node's ui_data
    theHandle = (AIHandle*)buddy->node.ui_data;

    //no associated handle - gaim has a buddy for us but we are no longer tracking that buddy
    if (!theHandle) { 
        theHandle = [handleDict objectForKey:[[NSString stringWithUTF8String:(buddy->name)] compactedString]];    
        if (theHandle) {
            buddy->node.ui_data = theHandle;
        } else {
            //use the buddy's information gaimside to create the needed Adium handle
            theHandle = [self createHandleAssociatingWithBuddy:buddy];
            //Update the contact list
            if (!silentAndDelayed)
                [[adium contactController] handle:theHandle 
                                   addedToAccount:self];
        }
    }
    
    statusDict = [theHandle statusDictionary];
    
    //Online / Offline
    online = (GAIM_BUDDY_IS_ONLINE(buddy) ? 1 : 0);
    if([[statusDict objectForKey:@"Online"] intValue] != online)
    {
        NSNumber *onlineNum = [NSNumber numberWithBool:online];
        [statusDict setObject:onlineNum forKey:@"Online"];
        [modifiedKeys addObject:@"Online"];
        
        //Enable/disable any instant messages with this handle
        AIChat *chat = [chatDict objectForKey:[[theHandle containingContact] UID]];
        if (chat) {
            //Enable/disable the chat
            [[chat statusDictionary] setObject:onlineNum forKey:@"Enabled"];
            
            //Notify
            [[adium notificationCenter] postNotificationName:Content_ChatStatusChanged object:chat userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Enabled"] forKey:@"Keys"]];            
        }
/*           
        //This doesn't work - buddy->signon is always 0.  evands has a patch to fix this gaimside, but the gaim pepople won't accept it since signon is apparently oscar-specific.
        if (online && buddy->signon != 0) {
        //Set the signon time
            NSMutableDictionary * statusDict = [theHandle statusDictionary];
            
            [statusDict setObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->signon] forKey:@"Signon Date"];
            [modifiedKeys addObject:@"Signon Date"];
        }
*/
    }

    //Display Name - use the serverside buddy_alias if present - do we want to be doing this?
    {
        char *alias = (char *)gaim_get_buddy_alias(buddy);
        char *disp_name = (char *)[[statusDict objectForKey:@"Display Name"] UTF8String];
        if(!disp_name) disp_name = "";
    
        if(alias && strcmp(disp_name, alias))
        {
            [statusDict setObject:[NSString stringWithUTF8String:alias]
                           forKey:@"Display Name"];
            [modifiedKeys addObject:@"Display Name"];
        }
    }
            
    //Idletime
    {
        if(buddy->idle != (int)([[[theHandle statusDictionary] objectForKey:@"IdleSince"] timeIntervalSince1970])){
            if(buddy->idle != 0){
                [statusDict setObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->idle]
                               forKey:@"IdleSince"];
            } else {
                [statusDict removeObjectForKey:@"IdleSince"];
            }
            [modifiedKeys addObject:@"IdleSince"];
        }
    }
    
    //Group changes - gaim buddies start off in no group, so this is an important update for us
    {
        GaimGroup *g = gaim_find_buddys_group(buddy);
        if(g && strcmp([[theHandle serverGroup] UTF8String], g->name)){
            //            NSLog(@"Changed to group %s", g->name);        
            [[adium contactController] handle:theHandle removedFromAccount:self];
            [theHandle setServerGroup:[NSString stringWithUTF8String:g->name]];
            [[adium contactController] handle:theHandle addedToAccount:self];
        }
    }
    
    //Buddy Icon
    {
        GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
        if(buddyIcon && (buddyIcon != [[statusDict objectForKey:@"BuddyImagePointer"] pointerValue])) {                            
            //save this for convenience
            [[theHandle statusDictionary]
                    setObject:[NSValue valueWithPointer:buddyIcon]
                       forKey:@"BuddyImagePointer"];
            
            //set the buddy image
            NSImage *image = [[[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_buddy_icon_get_data(buddyIcon, &(buddyIcon->len)) length:buddyIcon->len]] autorelease];
            [statusDict setObject:image forKey:@"UserIcon"];

            //BuddyImagePointer is just for us, shh, keep it secret ;)
            [modifiedKeys addObject:@"UserIcon"];
        }
    }     
    
    //Away status
    {
        BOOL newAway = ((buddy->uc & UC_UNAVAILABLE) != 0);
        NSNumber *storedValue = [[theHandle statusDictionary] objectForKey:@"Away"];
        if (storedValue == nil || newAway != [storedValue boolValue]) {
            [[theHandle statusDictionary] setObject:[NSNumber numberWithBool:newAway] 
                                             forKey:@"Away"];
            [modifiedKeys addObject:@"Away"];
        }
    }
    
    //Broadcast any changes
    if([modifiedKeys count] > 0){
        //tell the contact controller, silencing if necessary
        [[adium contactController] handleStatusChanged:theHandle
                                    modifiedStatusKeys:modifiedKeys
                                               delayed:silentAndDelayed
                                                silent:silentAndDelayed];
    }
}

- (void)accountRemoveBuddy:(GaimBuddy*)buddy
{
    //stored the key as a compactedString originally
    [handleDict removeObjectForKey:[[NSString stringWithFormat:@"%s", buddy->name] compactedString]];

    if (buddy->node.ui_data != NULL) {
        [(AIHandle *)buddy->node.ui_data release];
        buddy->node.ui_data = NULL;
        if (!silentAndDelayed)
            [[adium contactController] handlesChangedForAccount:self];
    }
}

/***********************/
/* accountConv methods */
/***********************/

- (void)accountConvDestroy:(GaimConversation*)conv
{
    AIChat *chat = (AIChat*) conv->ui_data;
    if (chat) {
        AIListContact *listContact = (AIListContact*) [chat listObject];
        AIHandle *handle = [listContact handleForAccount:self];
        if (handle) {
            [self setTypingFlagOfHandle:handle to:NO];
        }
    }
}

- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type
{
    AIChat *chat = (AIChat*) conv->ui_data;
    GaimConvIm *im = gaim_conversation_get_im_data(conv);
    NSAssert(im != nil, @"We only do IM conversations");
    NSAssert(chat != nil, @"Conversation update with no AIChat");
    AIListContact *listContact = (AIListContact*) [chat listObject];
    NSAssert(listContact != nil, @"Conversation with no one?");
    AIHandle *handle = [listContact handleForAccount:self];
    if (!handle) {
        handle = [self addHandleWithUID:[[listContact UID] compactedString]
                            serverGroup:[[listContact containingGroup] UID]
                              temporary:YES];
    }
    NSAssert(handle != nil, @"listContact without handle");
    switch (type) {
        case GAIM_CONV_UPDATE_TYPING:
            {
                [self setTypingFlagOfHandle:handle to:(gaim_conv_im_get_typing_state(im) == GAIM_TYPING)];
            }
            break;
        case GAIM_CONV_UPDATE_AWAY:
            {
            //If the conversation update is UPDATE_AWAY, it seems to suppress the typing state being updated
            //Reset gaim's typing tracking, then update to receive a GAIM_CONV_UPDATE_TYPING message
            gaim_conv_im_set_typing_state(im, GAIM_NOT_TYPING);
            gaim_conv_im_update_typing(im);
            }
            break;
        default:
        {
            NSNumber *typing=[[handle statusDictionary] objectForKey:@"Typing"];
            if (typing && [typing boolValue])
                NSLog(@"handle %@ is typing and got a nontyping update of type %i",[listContact displayName],type);
        }
            break;
    }
}

- (void)accountConvReceivedIM: (const char*)message inConversation:(GaimConversation*)conv withFlags: (GaimMessageFlags)flags atTime: (time_t)mtime
{
    if ((flags & GAIM_MESSAGE_SEND) != 0) {
        /*
         * TODO
         * gaim is telling us that our message was sent successfully. Some
         * day, we should avoid claiming it was until we get this
         * notification.
         */
        return;
    }
    AIChat *chat = (AIChat*) conv->ui_data;
    NSString *uid = [NSString stringWithUTF8String: conv->name];
//    AIChat *chat = [chatDict objectForKey:uid];
    
    AIHandle *handle = [handleDict objectForKey:[uid compactedString]];    
    if (chat == nil) {
        if (handle == nil) {
            GaimBuddy *buddy = gaim_find_buddy(account,conv->name);
            if (buddy != NULL) {
                //use the buddy's information gaimside to create the needed Adium handle
                handle = [self createHandleAssociatingWithBuddy:buddy];
            } else {
                handle = [self addHandleWithUID:[uid compactedString]
                                    serverGroup:nil
                                      temporary:YES];
            }
        }
        // Need to start a new chat
        chat = [self _openChatWithHandle:handle andConversation:conv];
    } else  {
        NSAssert(handle != nil, @"Existing chat yet no existing handle?");
    }
    
    //clear the typing flag
    [self setTypingFlagOfHandle:handle to:NO];
    
    NSAttributedString *body = [AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String: message]];
    AIContentMessage *messageObject =
        [AIContentMessage messageInChat:chat
                             withSource:[handle containingContact]
                            destination:self
                                   date:[NSDate dateWithTimeIntervalSince1970: mtime]
                                message:body
                              autoreply:(flags & GAIM_MESSAGE_AUTO_RESP) != 0];
    [[adium contentController] addIncomingContentObject:messageObject];
}

/********************************/
/* AIAccount subclassed methods */
/********************************/

- (void)initAccount
{
    handleDict = [[NSMutableDictionary alloc] init];
    chatDict = [[NSMutableDictionary alloc] init];
    filesToSendArray = [[NSMutableArray alloc] init];

    //create an initial gaim account
    NSLog(@"Creating %@",[self UID]);
    account = gaim_account_new([[self UID] UTF8String], [self protocolPlugin]);
    gaim_accounts_add(account);
    gc = NULL;
    NSLog(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
    signonTimer = nil;
    password = nil;
    
    //ensure our user icon cache path exists
    [AIFileUtilities createDirectory:[USER_ICON_CACHE_PATH stringByExpandingTildeInPath]];
    
    //TEMP: set profile
    {
#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT			@"Default Font"
#define KEY_FORMATTING_TEXT_COLOR		@"Default Text Color"
#define KEY_FORMATTING_BACKGROUND_COLOR		@"Default Background Color"
#define KEY_FORMATTING_SUBBACKGROUND_COLOR	@"Default SubBackground Color"
        
        NSDictionary		*prefs;
        NSColor			*textColor;
        NSColor			*backgroundColor;
        NSColor			*subBackgroundColor;
        NSFont			*font;
        NSDictionary            *attributes;
        
        //Get the prefs
        prefs = [[adium preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
        font = [[prefs objectForKey:KEY_FORMATTING_FONT] representedFont];
        textColor = [[prefs objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor];
        backgroundColor = [[prefs objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor];
        subBackgroundColor = [[prefs objectForKey:KEY_FORMATTING_SUBBACKGROUND_COLOR] representedColor];
        
        //Setup the attributes
        if(!subBackgroundColor){
            attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, nil];
        }else{
            attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, subBackgroundColor, NSBackgroundColorAttributeName, nil];
        }
        NSAttributedString *profile = [[[NSAttributedString alloc] initWithString:PROFILE_STRING attributes:attributes] autorelease];

        [self setPreference:[profile dataRepresentation] forKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS];
    }
}

- (void)dealloc
{
    NSLog(@"CBGaimAccount dealloc");
    [(CBGaimServicePlugin *)service removeAccount:account];
    
    [chatDict release];
    [handleDict release];
    [filesToSendArray release];
    if (signonTimer != nil) {
        [signonTimer invalidate];
        [signonTimer release];
        signonTimer = nil;
    }

    //  is deleting the accoutn necessary?  this seems to throw an exception.
//    gaim_accounts_delete(account); account = NULL;
    
    // TODO: remove this from the account dict that the ServicePlugin keeps
    
    [super dealloc];
}

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

- (void)updateStatusForKey:(NSString *)key
{
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];

    //Online status changed
    if([key compare:@"Online"] == 0){
        if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            if(!areOnline) [self connect];
        }else{
            if(areOnline) [self disconnect];
        }
    } 
    
    //Now look at keys which only make sense while online
    if(areOnline){
        if ([key compare:@"IdleSince"] == 0){
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
            // Even if we're setting a non-zero idle time, set it to zero first.
            // Some clients ignore idle time changes unless it moves to/from 0.
            serv_set_idle(gc, 0);
            if (idleSince != nil) {
                int newIdle = -[idleSince timeIntervalSinceNow];
                serv_set_idle(gc, newIdle);
            }
			[self setStatusObject:idleSince forKey:@"IdleSince" notify:YES];
        }
        else if ([key compare:@"AwayMessage"] == 0) {
			NSString	*awayMessage = [self preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
            [self setAwayMessage:awayMessage];
			[self setStatusObject:awayMessage forKey:@"StatusMessage" notify:YES];
        }
        else if([key compare:@"TextProfile"] == 0){
            NSString	*profile = [self preferenceForKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS];
			[self setProfile:profile];
			[self setStatusObject:profile forKey:@"TextProfile" notify:YES];
        }
    }
    
    //User Icon can be set regardless of ONLINE state
    if([key compare:@"UserIcon"] == 0) {
	NSData	*newIconData = [self preferenceForKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS];
	NSImage	*newIcon = [[[NSImage alloc] initWithData:newIconData] autorelease];
	
	[self setStatusObject:newIcon forKey:@"UserIcon" notify:YES];
        
	//gaim requires a file to be used as the userIcon.  Give it its file.
        if(newIcon) {          
            NSData 	*data = [[newIcon JPEGRepresentation] retain];
            NSString    *buddyImageFilename = [[self _userIconCachePath] retain];
            if([data writeToFile:buddyImageFilename atomically:YES]){
                [self setBuddyImageFromFilename:(char *)[buddyImageFilename UTF8String]];
            }else{
                NSLog(@"Error writing file %@",buddyImageFilename);   
            }
            [buddyImageFilename release];
        }else{
            [self setBuddyImageFromFilename:nil];   
        }
    }
}

- (NSString *)accountID {
    return [NSString stringWithFormat:@"GAIM-%@.%@", [self serviceID], [self UID]];
}

- (NSString *)accountDescription {
    return [self UIDAndServiceID];
}

- (NSDictionary *)defaultProperties { return([NSDictionary dictionary]); }
- (id <AIAccountViewController>)accountView{ return(nil); }


/*********************/
/* AIAccount_Content */
/*********************/

- (BOOL)sendContentObject:(AIContentObject*)object
{
    BOOL            sent = NO;

    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0) {
        AIContentMessage *cm = (AIContentMessage*)object;
        NSString *body = [AIHTMLDecoder encodeHTML:[cm message]
                                           headers:YES
                                          fontTags:YES
                                     closeFontTags:NO
                                         styleTags:YES
                        closeStyleTagsOnFontChange:NO
                                    encodeNonASCII:NO
                                        imagesPath:nil];
        AIChat *chat = [cm chat];
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
        gaim_conv_im_send(im, [body UTF8String]);
        sent = YES;
    }
    return sent;
}

//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    BOOL 	available = NO;
    BOOL	weAreOnline = ([inType compare:CONTENT_MESSAGE_TYPE] == 0 && [[self statusObjectForKey:@"Online"] boolValue]);
    
    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        if(weAreOnline){
            if(inListObject == nil){ 
                available = YES; //If we're online, we're most likely available to message this object
            }else{
                if([inListObject isKindOfClass:[AIListContact class]]){
                    AIHandle	*handle = [(AIListContact *)inListObject handleForAccount:self];
                    
                    if(handle && [[[handle statusDictionary] objectForKey:@"Online"] boolValue]){
                        available = YES; //This handle is online and on our list
                    }
                }
            }
        }
    }
    return(available);
}

- (AIChat*)openChatWithListObject:(AIListObject*)inListObject
{
    AIHandle *handle;
    AIChat *chat = nil;

    if ([inListObject isKindOfClass:[AIListContact class]]) {
        handle = [(AIListContact*)inListObject handleForAccount:self];
        if (!handle) {
            handle = [self addHandleWithUID:[[inListObject UID] compactedString]
                                serverGroup:nil
                                  temporary:YES];
        }
        chat = [self _openChatWithHandle:handle andConversation:NULL];
    }
    return chat;
}

- (AIChat*)_openChatWithHandle:(AIHandle*)handle andConversation:(GaimConversation*)conv
{
    AIChat *chat;

    //create a chat if we're passed a null conversation or the conversation we're passed doesn't have a chat associated with it
//    if(!(chat = [chatDict objectForKey:[handle UID]])){
    if(!conv || !(chat = conv->ui_data)){
        chat = [AIChat chatForAccount:self];
        AIListContact   *contact = [handle containingContact];
        
        [chat addParticipatingListObject:contact];

        BOOL handleIsOnline;        
        handleIsOnline = YES; // TODO
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:handleIsOnline] forKey:@"Enabled"];
        
        if (conv == NULL) {
            conv = gaim_conversation_new(GAIM_CONV_IM, account, [[handle UID] UTF8String]);
        }
        
        //associate the AIChat with the gaim conv
        conv->ui_data = chat;
        [[chat statusDictionary] setObject:[NSValue valueWithPointer:conv] forKey:@"GaimConv"];
        [chatDict setObject:chat forKey:[handle UID]];
        [[adium contentController] noteChat:chat forAccount:self];
    } 
    return chat;
}

- (BOOL)closeChat:(AIChat*)inChat
{
    AIHandle *handle = [(AIListContact*)[inChat listObject] handleForAccount:self];
    if ([handle temporary]) {
        [self removeHandleWithUID:[handle UID]];
    }
    GaimConversation *conv = (GaimConversation*) [[[inChat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
    NSAssert(conv != nil, @"No gaim conversation associated with chat");
    gaim_conversation_destroy(conv);
    [chatDict removeObjectForKey:inChat];
    return YES;
}


/*********************/
/* AIAccount_Handles */
/*********************/

// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles //return nil if no contacts/list available
{
    if([[self statusObjectForKey:@"Online"] boolValue] || [[self statusObjectForKey:@"Connecting"] boolValue]){
        return(handleDict);
    }else{
        return(nil);
    }
}
// Returns YES if the list is editable
- (BOOL)contactListEditable
{
    return YES;
}

// Add a handle to this account
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    AIHandle	*handle;
    
    if(inTemporary) inGroup = @"__Strangers";    
    if(!inGroup) inGroup = @"Unknown";
    
    //Check to see if the handle already exists, and remove the duplicate if it does
    if(handle = [handleDict objectForKey:inUID]){
        [self removeHandleWithUID:inUID]; //Remove the handle
    }
    
    //Create the handle
    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] identifier] UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:self];
    NSString    *handleUID = [handle UID];
    NSString    *handleServerGroup = [handle serverGroup];
    
    //Add the handle
    GaimGroup *group = gaim_find_group([handleServerGroup UTF8String]); //get the GaimGroup
    if (group == NULL) {                                                //if the group doesn't exist yet
        group = gaim_group_new([handleServerGroup UTF8String]);         //create the GaimGroup
        gaim_blist_add_group(group, NULL);                              //add it gaimside (server will add as needed)
    }
    
    GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);     //verify the buddy does not already exist
    if (buddy == NULL) {                                                //should always be null
        buddy = gaim_buddy_new(account, [handleUID UTF8String], NULL);  //create a GaimBuddy
    }

    gaim_blist_add_buddy(buddy, NULL, group, NULL);                     //add the buddy to the gaimside list
    serv_add_buddy(gc,[handleUID UTF8String],group);                    //and add the buddy serverside

    [handleDict setObject:handle forKey:[handle UID]];                  //Add it locally

    //From TOC2
    //[self silenceUpdateFromHandle:handle]; //Silence the server's initial update command
    
    //Update the contact list
    [[adium contactController] handle:handle addedToAccount:self];
        
    return(handle);
}

// Remove a handle from this account
- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    AIHandle	*handle;
    if(handle = [handleDict objectForKey:inUID]){
        GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);
        
        serv_remove_buddy(gc,[inUID UTF8String],[[handle serverGroup] UTF8String]); //remove it from the list serverside
        gaim_blist_remove_buddy(buddy);                                             //remove it gaimside
        
        return YES;
    } else 
        return NO;
}

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup
{
    GaimGroup *group = gaim_group_new([inGroup UTF8String]);    //create the GaimGroup
    gaim_blist_add_group(group,NULL);                           //add it gaimside (server will make it as needed)
//    NSLog(@"added group %@",inGroup);
    return NO;
}
// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup
{
    serv_remove_group(gc,[inGroup UTF8String]);             //remove it from the list serverside
    
    GaimGroup *group = gaim_find_group([inGroup UTF8String]);   //get the GaimGroup
    gaim_blist_remove_group(group);                         //remove it gaimside
//    NSLog(@"remove group %@",inGroup);
    return YES;
}
// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    GaimGroup *group = gaim_find_group([inGroup UTF8String]);   //get the GaimGroup
    if (group != NULL) {                                        //if we find the GaimGroup
        serv_rename_group(gc, group, [newName UTF8String]);     //rename
        gaim_blist_remove_group(group);                         //remove the old one gaimside
        return YES;
    } else
        return NO;
}

- (BOOL)moveHandleWithUID:(NSString *)inUID toGroup:(NSString *)inGroup
{
    AIHandle	*handle;
    if(handle = [handleDict objectForKey:inUID]){
        GaimGroup *oldGroup = gaim_find_group([[handle serverGroup] UTF8String]);   //get the GaimGroup        
        GaimGroup *newGroup = gaim_find_group([inGroup UTF8String]);                //get the GaimGroup
        if (newGroup == NULL) {                                                        //if the group doesn't exist yet
 //           NSLog(@"Creating a new group");
            newGroup = gaim_group_new([inGroup UTF8String]);                           //create the GaimGroup
        }
        
        GaimBuddy *buddy = gaim_find_buddy(account,[inUID UTF8String]);
        if (buddy != NULL) {
            serv_move_buddy(buddy,oldGroup,newGroup);
        } else {
            return NO;
        }
    }
    return NO;
}

- (AIHandle *)createHandleAssociatingWithBuddy:(GaimBuddy *)buddy
{
    GaimGroup   *group = gaim_find_buddys_group(buddy); //get the group
    NSString    *groupName;
    if (group)
    groupName = [NSString stringWithCString:(group->name)];
    else
    groupName = NO_GROUP;


    AIHandle *handle = [AIHandle
        handleWithServiceID:[self serviceID]
                        UID:[[NSString stringWithUTF8String:buddy->name] compactedString]
                serverGroup:groupName
                  temporary:NO
                 forAccount:self];
    [handleDict setObject:handle forKey:[[NSString stringWithFormat:@"%s", buddy->name] compactedString]];

    //Associate the handle with ui_data and the buddy with our statusDictionary
    buddy->node.ui_data = [handle retain];
    [[handle statusDictionary] setObject:[NSValue valueWithPointer:buddy] forKey:@"GaimBuddy"];
 
    return handle;
}

/*********************/
/* AIAccount_Privacy */
/*********************/

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

/*****************************/
/* accountConnection methods */
/*****************************/

- (void)accountConnectionReportDisconnect:(const char*)text
{
    [self displayError: [NSString stringWithUTF8String: text]];
}

- (void)accountConnectionConnected
{
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:YES];
    
    NSLog(@"Setting handle updates to silent and delayed (connected)");
    silentAndDelayed = YES;
    NSAssert(signonTimer == nil, @"Already have a signon timer");
    signonTimer = [[NSTimer scheduledTimerWithTimeInterval:18
                                                    target:self
                                                  selector:@selector(signonTimerExpired:)
                                                  userInfo:nil
                                                   repeats:NO] retain];
    [self performSelector:@selector(delayedInitialSettings:) withObject:nil afterDelay:1];
}

- (void)delayedInitialSettings:(id)object
{
    //Set our correct status
    [self updateStatusForKey:@"IdleSince"];
    [self updateStatusForKey:@"TextProfile"];
    [self updateStatusForKey:@"AwayMessage"];
    [self updateStatusForKey:@"UserIcon"];
    
    //Load our buddy icon from a file
    NSImage *buddyImage = [[NSImage alloc] initWithContentsOfFile:OWN_BUDDY_IMAGE];
    if(buddyImage && [buddyImage isValid]){
	[self setPreference:[buddyImage TIFFRepresentation] forKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS];
    }
    [buddyImage release];
}


- (void)signonTimerExpired:(NSTimer*)timer
{
    [signonTimer invalidate];
    [signonTimer release];
    signonTimer = nil;
    silentAndDelayed = NO;
    NSLog(@"Setting handle updates to loud and instantaneous (signon timer expired)");
    
    [[adium contactController] handlesChangedForAccount:self];
}

//connecting / disconnecting
- (void)connect
{
    //get password
    [[adium accountController] passwordForAccount:self 
                                  notifyingTarget:self selector:@selector(finishConnect:)];
}
//Called by the accountController once a password is available
- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0)
    {
        if(password != inPassword){
            [password release]; password = [inPassword copy];
        }
        
        //now we start to connect
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];
        
        //setup the account, get things ready
        gaim_account_set_password(account, [password UTF8String]);
        
        //configure at sign on time so we get the latest settings from the system
        if ([(CBGaimServicePlugin *)service configureGaimProxySettings]) {
            
            //proxy info - once account prefs are in place, this should be able to use the gaim prefs (which are set by the service plugin and are our systemwide prefs) or account-specific prefs
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
        //NSLog(@"%i %s %i %s %s",proxy_info->type,proxy_info->host,proxy_info->port,proxy_info->username,proxy_info->password);
        
        gc = gaim_account_connect(account);
    }
}

- (void)disconnect
{
    NSEnumerator    *enumerator;
    AIHandle        *handle;
    
    //signing off
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
    
    //tell gaim to disconnect    
    silentAndDelayed = YES;
    NSLog(@"Setting handle updates to silent and delayed (disconnecting)");

    //Flush all our handle status flags
    enumerator = [[handleDict allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeAllStatusFlagsFromHandle:handle];
    }
    //Clear out the GaimConv pointers in the chat statusDictionaries, as they no longer have meaning
    AIChat *chat;
    enumerator = [chatDict objectEnumerator];
    while (chat = [enumerator nextObject]) {
        [[chat statusDictionary] removeObjectForKey:@"GaimConv"];
    }       
    
    //Remove all our handles
    [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
    [[adium contactController] handlesChangedForAccount:self];
    
    //Remove our chat dictionary
    [chatDict release]; chatDict = [[NSMutableDictionary alloc] init];
        
    gaim_account_disconnect(account); gc = NULL;
    
    //we don't want gaim keeping tracking of our buddies between sessions - we do that.
    //gaim_accounts_remove(account);
    //This will remove any buddies from the buddy list that belong to this account, and will also destroy account
    [(CBGaimServicePlugin *)service removeAccount:account];
    gaim_accounts_delete(account); account = NULL;
    
    //create a new account for next time
    account = gaim_account_new([[self UID] UTF8String], [self protocolPlugin]);
    gaim_accounts_add(account);
    [(CBGaimServicePlugin *)service addAccount:self forGaimAccountPointer:account];
}

//Called automatically by gaimServicePlugin whenever we disconnected for any reason
- (void)accountConnectionDisconnected
{
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:YES];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:YES];

    if(signonTimer != nil) {
        [signonTimer invalidate];
        [signonTimer release];
        signonTimer = nil;
    }
    
    //If adium's status for the account was Online, we were disconnected unexpectedly
    if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]) {
        //clean up
        [self disconnect];
        //reconnect
        [self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY];
    }
}

// Auto-Reconnect -------------------------------------------------------------------------------------
//Attempts to auto-reconnect (after an X second delay)
- (void)autoReconnectAfterDelay:(int)delay
{
    //Install a timer to autoreconnect after a delay
    [NSTimer scheduledTimerWithTimeInterval:delay
                                     target:self
                                   selector:@selector(autoReconnectTimer:)
                                   userInfo:nil
                                    repeats:NO];
    
    NSLog(@"Auto-Reconnect in %i seconds",delay);
}

//
- (void)autoReconnectTimer:(NSTimer *)inTimer
{
    //If we're still offline, continue with the reconnect
    if([[self statusObjectForKey:@"Online"] boolValue] && ![[self statusObjectForKey:@"Connecting"] boolValue]){
        NSLog(@"Attempting Auto-Reconnect");
        
        //Instead of calling connect, we directly call the second phase of connecting, passing it the user's password.  This prevents users who don't keychain passwords from having to enter them for a reconnect.
        [self finishConnect:password];
    }
}

/*****************************************************/
/* File transfer / AIAccount_Files inherited methods */
/*****************************************************/

//The account requested that we received a file; set up the ESFileTransfer and query the fileTransferController for a save location
- (void)accountXferRequestFileReceiveWithXfer:(GaimXfer *)xfer
{
    NSLog(@"file transfer request received");
    ESFileTransfer * fileTransfer = [[self createFileTransferObjectForXfer:xfer] retain];
    
    [fileTransfer setRemoteFilename:[NSString stringWithUTF8String:(xfer->filename)]];
    
    [[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

//The account requested that we send a file, but we do not know what file yet - query the fileTransferController for a target file
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
    AIHandle * handle = [handleDict objectForKey:[[NSString stringWithUTF8String:(xfer->who)] compactedString]];
    //handle new handles here
    //****
    
    ESFileTransfer * fileTransfer = [ESFileTransfer fileTransferWithHandle:handle forAccount:self]; 
    
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
    gaim_xfer_destroy(xfer);
}

//Accept a send or receive ESFileTransfer object, beginning the transfer.  Subsequently inform the fileTransferController that the fun has begun.
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

// Removes all the possible status flags (that are valid on the calling account) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle
{
    NSArray * keyArray = [self supportedPropertyKeys];
    [[handle statusDictionary] removeObjectsForKeys:keyArray];
    [[adium contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray delayed:YES silent:YES];
}

- (void)setTypingFlagOfHandle:(AIHandle *)handle to:(BOOL)typing
{
    BOOL currentValue = [[[handle statusDictionary] objectForKey:@"Typing"] boolValue];
    
    if((typing && !currentValue) || (!typing && currentValue)){
        [[handle statusDictionary] setObject:[NSNumber numberWithBool:typing] 
                                      forKey:@"Typing"];
        [[adium contactController] handleStatusChanged:handle 
                                    modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"] 
                                               delayed:YES 
                                                silent:NO];
    }
}

- (void)setAwayMessage:(id)message
{
    char *newValue = NULL;
    
    if (message) {
        newValue = (char *)[[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:message]
                                              headers:YES
                                             fontTags:YES   closeFontTags:YES
                                            styleTags:YES   closeStyleTagsOnFontChange:NO
                                       encodeNonASCII:NO
                                           imagesPath:nil] UTF8String];
    }
    
    serv_set_away(gc, GAIM_AWAY_CUSTOM, newValue);
}
- (void)setProfile:(id)profile
{
    char *newValue = NULL;
    
    if (profile) {
        newValue = (char *)[[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:profile]
                                              headers:YES
                                             fontTags:YES   closeFontTags:YES
                                            styleTags:YES   closeStyleTagsOnFontChange:NO
                                       encodeNonASCII:NO
                                           imagesPath:nil] UTF8String];
    }
    
    serv_set_info(gc, newValue);
}

- (void)setBuddyImageFromFilename:(char *)imageFilename
{
    //Set to nil first
    gaim_account_set_buddy_icon(account, nil);
    //Set to new user icon
    gaim_account_set_buddy_icon(account,imageFilename);
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

@end
