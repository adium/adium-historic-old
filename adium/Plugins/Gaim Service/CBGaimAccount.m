//
//  CBGaimAccount.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimAccount.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

#define NO_GROUP @"__NoGroup__"

@interface CBGaimAccount (PRIVATE)
- (AIChat*)_openChatWithHandle:(AIHandle*)handle andConversation:(GaimConversation*)conv;
- (void)displayError:(NSString *)errorDesc;
@end

@implementation CBGaimAccount

- (GaimAccount*)gaimAccount
{
    return account;
}

// Subclasses must override this
- (const char*)protocolPlugin { return NULL; }

/*****************************/
/* accountConnection methods */
/*****************************/

- (void)accountConnectionReportDisconnect:(const char*)text
{
    [self displayError: [NSString stringWithUTF8String: text]];
}

- (void)accountConnectionConnected
{
    [[owner accountController]
        setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
        forKey:@"Status" account:self];
}

- (void)accountConnectionDisconnected
{
    NSLog(@"accountConnectionDisconnected starting");
    [[owner accountController] 
        setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];

    //Remove all our handles
    NSLog(@"removing handles");
    [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
    // TODO: what should we do with the GaimConversations, GaimChats, and GaimBuddys?
    [[owner contactController] handlesChangedForAccount:self];
    NSLog(@"accountConnectionDisconnected ending");
}

/************************/
/* accountBlist methods */
/************************/

- (void)accountBlistNewNode:(GaimBlistNode *)node
{
//    NSLog(@"New node");
    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {
        GaimBuddy *buddy = (GaimBuddy *)node;
        
        //create the handle, group-less for now
        AIHandle *theHandle = [AIHandle 
            handleWithServiceID:[self serviceID]
            UID:[[NSString stringWithUTF8String:buddy->name] compactedString]
            serverGroup:NO_GROUP
            temporary:NO
            forAccount:self];
//        NSLog(@"created handle %@",[[NSString stringWithUTF8String:buddy->name] compactedString]);
        //stuff it in the dict - we store as a compactedString (that is, lowercase without spaces) for now because the TOC2 plugin does 
        [handleDict setObject:theHandle forKey:[[NSString stringWithFormat:@"%s", buddy->name] compactedString]];
        
        //set up our ui_data
        node->ui_data = [theHandle retain];
        
        //[[owner contactController] handlesChangedForAccount:self];
    }
}

- (void)accountBlistUpdate:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    //NSLog(@"Update");
    if(node)
    {
        //extract the GaimBuddy from whatever we were passed
        GaimBuddy *buddy = nil;
        if(GAIM_BLIST_NODE_IS_BUDDY(node))
            buddy = (GaimBuddy *)node;
        else if(GAIM_BLIST_NODE_IS_CONTACT(node))
            buddy = ((GaimContact *)node)->priority;
        if (buddy) {
        NSMutableArray *modifiedKeys = [NSMutableArray array];
        AIHandle *theHandle = (AIHandle *)node->ui_data;
        
        int online = (GAIM_BUDDY_IS_ONLINE(buddy) ? 1 : 0);
        
        NSMutableDictionary * statusDict = [theHandle statusDictionary];
        //NSLog(@"%d", online);
        
        //see if our online state is up to date
        if([[statusDict objectForKey:@"Online"] intValue] != online)
        {
            [statusDict
                setObject:[NSNumber numberWithInt:online] 
                forKey:@"Online"];
            [modifiedKeys addObject:@"Online"];
 /*           
                 //This doesn't work - buddy->signon is always 0.  not sure why.
            NSLog(@"%i",buddy->signon);
            if (online && buddy->signon != 0) {
            //Set the signon time
                NSLog(@"%i resolves to %@",buddy->signon,[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->signon] description]);
                NSMutableDictionary * statusDict = [theHandle statusDictionary];
                
                [statusDict setObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->signon] forKey:@"Signon Date"];
                [modifiedKeys addObject:@"Signon Date"];
            }
*/
        }
        
        //snag the correct alias, and the current display name
        char *alias = (char *)gaim_get_buddy_alias(buddy);
        char *disp_name = (char *)[[statusDict objectForKey:@"Display Name"] cString];
        if(!disp_name) disp_name = "";
        
        //check 'em and update
        if(alias && strcmp(disp_name, alias))
        {
            [statusDict
                setObject:[NSString stringWithUTF8String:alias]
                forKey:@"Display Name"];
            [modifiedKeys addObject:@"Display Name"];
        }
                
        //update their idletime
        if(buddy->idle != (int)([[[theHandle statusDictionary] objectForKey:@"IdleSince"] timeIntervalSince1970]))
        {
            if(buddy->idle != 0)
            {
                [statusDict
                    setObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->idle]
                    forKey:@"IdleSince"];
            }
            else
            {
                [statusDict removeObjectForKey:@"IdleSince"];
            }
            [modifiedKeys addObject:@"IdleSince"];
        }
        
        //did the group change/did we finally find out what group the buddy is in
        GaimGroup *g = gaim_find_buddys_group(buddy);
        if(g && strcmp([[theHandle serverGroup] cString], g->name))
        {
            [[owner contactController] handle:[theHandle copy] removedFromAccount:self];
//            NSLog(@"Changed to group %s", g->name);
            [theHandle setServerGroup:[NSString stringWithUTF8String:g->name]];
            [[owner contactController] handle:theHandle addedToAccount:self];
        }
        
        //grab their data, and compare
        GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
        if(buddyIcon)
        {
            if(buddyIcon != [[statusDict objectForKey:@"BuddyImagePointer"] pointerValue])
            {
//                NSLog(@"Icon for %s", buddy->name);
                                
                //save this for convenience
                [[theHandle statusDictionary]
                    setObject:[NSValue valueWithPointer:buddyIcon]
                    forKey:@"BuddyImagePointer"];
            
                //set the buddy image
                [statusDict
                    setObject:[[[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_buddy_icon_get_data(buddyIcon, &(buddyIcon->len)) length:buddyIcon->len]] autorelease]
                       forKey:@"BuddyImage"];
                
                //BuddyImagePointer is just for us, shh, keep it secret ;)
                [modifiedKeys addObject:@"BuddyImage"];
            }
        }     
        
        // Away status
        BOOL newAway = (buddy->uc & UC_UNAVAILABLE) != 0;
        id storedValue = [[theHandle statusDictionary] objectForKey:@"Away"];
        if (storedValue == nil || newAway != [storedValue boolValue]) {
            [[theHandle statusDictionary] setObject:[NSNumber numberWithBool:newAway] forKey:@"Away"];
            [modifiedKeys addObject:@"Away"];
        }

        //if anything chnaged
        if([modifiedKeys count] > 0)
        {
    //        NSLog(@"Changed %@", modifiedKeys);
            
            //tell the contact controller, silencing if necessary
            [[owner contactController] handleStatusChanged:theHandle
                                        modifiedStatusKeys:modifiedKeys
                                                   delayed:NO
                                                    silent:online
                ? (gaim_connection_get_state(gaim_account_get_connection(buddy->account)) == GAIM_CONNECTING)
                : (buddy->present != GAIM_BUDDY_SIGNING_OFF)];
            /* the silencing code does -not- work. I either need to change the way gaim works, or get someone to change it. */
        }
    }
    }
}

- (void)accountBlistRemove:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    //stored the key as a compactedString originally
    [handleDict removeObjectForKey:[[NSString stringWithFormat:@"%s", ((GaimBuddy *)node)->name] compactedString]];
    [(AIHandle *)node->ui_data release];
    node->ui_data = NULL;
    
    [[owner contactController] handlesChangedForAccount:self];
}

/***********************/
/* accountConv methods */
/***********************/

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
            handle = [self addHandleWithUID:[uid compactedString]
                                serverGroup:nil
                                  temporary:YES];
        }
        // Need to start a new chat
        chat = [self _openChatWithHandle:handle andConversation:conv];
    } else  {
        NSAssert(handle != nil, @"Existing chat yet no existing handle?");
    }
    NSAttributedString *body = [AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String: message]];
    AIContentMessage *messageObject =
        [AIContentMessage messageInChat:chat
                             withSource:[handle containingContact]
                            destination:self
                                   date:[NSDate dateWithTimeIntervalSince1970: mtime]
                                message:body
                              autoreply:(flags & GAIM_MESSAGE_AUTO_RESP) != 0];
    [[owner contentController] addIncomingContentObject:messageObject];
}

/********************************/
/* AIAccount subclassed methods */
/********************************/

- (void)initAccount
{
    NSLog(@"CBGaimAccount initAccount");
    handleDict = [[NSMutableDictionary alloc] init];
//    chatDict = [[NSMutableDictionary alloc] init];
    account = gaim_account_new([[self UID] UTF8String], [self protocolPlugin]);
    gaim_accounts_add(account);
    NSLog(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
}

- (void)dealloc
{
    NSLog(@"CBGaimAccount dealloc");
//    [chatDict release];
    [handleDict release];
    gaim_accounts_delete(account); account = NULL;
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
        @"BuddyImage",
        @"Away",
        nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    NSLog(@"gaim: statusForKey: %@ willChangeTo: %@", key, inValue);
    ACCOUNT_STATUS status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
        
    if([key compare:@"Online"] == 0)
    {
        if([inValue boolValue]) //Connect
        { 
            if(status == STATUS_OFFLINE)
            {                
                //get password
                [[owner accountController] passwordForAccount:self 
                    notifyingTarget:self selector:@selector(finishConnect:)];
            }
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                //we're signing off, give us a minute.
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_DISCONNECTING]
                    forKey:@"Status" account:self];
                
                gaim_account_disconnect(account); gc = NULL;
            }
        }
    }
    if ([key compare:@"IdleSince"] == 0)
    {
        // Even if we're setting a non-zero idle time, set it to zero first.
        // Some clients ignore idle time changes unless it moves to/from 0.
        serv_set_idle(gc, 0);
        if (inValue != nil) {
            int newIdle = -[inValue timeIntervalSinceNow];
            serv_set_idle(gc, newIdle);
        }
    }
}

- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0)
    {
        //now we start to connect
        [[owner accountController] 
            setProperty:[NSNumber numberWithInt:STATUS_CONNECTING]
            forKey:@"Status" account:self];

        //setup the account, get things ready
        GaimAccount *testAccount = gaim_account_new([[self UID] UTF8String], [self protocolPlugin]);
        gaim_account_set_password(testAccount, [inPassword cString]);
        
        gc = gaim_account_connect(testAccount);
    }
}


- (NSString *)accountID {
    return [NSString stringWithFormat:@"GAIM-%@.%@", [self serviceID], [self UID]];
}

- (NSString *)UIDAndServiceID {
    return [NSString stringWithFormat:@"%@.%@", [self serviceID], [self UID]];
}

- (NSString *)accountDescription {
    return [self UIDAndServiceID];
}

- (NSDictionary *)defaultProperties { return([NSDictionary dictionary]); }
- (id <AIAccountViewController>)accountView{ return(nil); }

//subclasses must override these

- (NSString *)UID { return nil; }
- (NSString *)serviceID { return nil; }

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
                        closeStyleTagsOnFontChange:NO];
        AIChat *chat = [cm chat];
        GaimConversation *conv = (GaimConversation*) [[[chat statusDictionary] objectForKey:@"GaimConv"] pointerValue];
        NSAssert(conv != NULL, @"Not a gaim conversation");
        GaimConvIm *im = gaim_conversation_get_im_data(conv);
        gaim_conv_im_send(im, [body UTF8String]);
        sent = YES;
    }
    return sent;
}

- (BOOL)availableForSendingContentType:(NSString*)inType toListObject:(AIListObject*)inListObject
{
    BOOL available = NO;
    BOOL weAreOnline = ([[[owner accountController] propertyForKey:@"Status" account:self] intValue] == STATUS_ONLINE);

    if ([inType compare:CONTENT_MESSAGE_TYPE] == 0 && weAreOnline) {
        // TODO: check if they are online
        available = YES;
    }
    return available;
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
        chat = [AIChat chatWithOwner:owner forAccount:self];
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
//        [chatDict setObject:chat forKey:[handle UID]];
        [[owner contentController] noteChat:chat forAccount:self];
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
//    [chatDict removeObjectForKey: inChat];
    return YES;
}


/*********************/
/* AIAccount_Handles */
/*********************/

// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles //return nil if no contacts/list available
{
    int	status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
    
    if(status == STATUS_ONLINE || status == STATUS_CONNECTING)
    {
        return(handleDict);
    }
    else
    {
        return(nil);
    }
}
// Returns YES if the list is editable
- (BOOL)contactListEditable
{
    return NO;
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
    
    //Add the handle
    //[self AIM_AddHandle:[handle UID] toGroup:[handle serverGroup]]; //Add it server-side
    [handleDict setObject:handle forKey:[handle UID]]; //Add it locally
    //[self silenceUpdateFromHandle:handle]; //Silence the server's initial update command
    
    //Update the contact list
    [[owner contactController] handle:handle addedToAccount:self];
    
    return(handle);
}

// Remove a handle from this account
- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    return NO;
}

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup
{
    return NO;
}
// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup
{
    return NO;
}
// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    return NO;
}

- (void)displayError:(NSString *)errorDesc
{
    [[owner interfaceController] handleErrorMessage:@"Gaim error"
                                    withDescription:errorDesc];
}

@end
