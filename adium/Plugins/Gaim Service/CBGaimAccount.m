//
//  CBGaimAccount.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimAccount.h"

#define NO_GROUP @"__NoGroup__"

@interface CBGaimAccount (PRIVATE)
- (AIChat*)_openChatWithHandle:(AIHandle*)handle andConversation:(GaimConversation*)conv;
- (void)displayError:(NSString *)errorDesc;
- (void)setAwayMessage:(id)msg;
- (void)signonTimerExpired:(NSTimer*)timer;
- (ESFileTransfer *)createFileTransferObjectForXfer:(GaimXfer *)xfer;
- (void)connect;
- (void)disconnect;
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle;
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
    id awayMessage = [propertiesDict objectForKey:@"AwayMessage"];
    if (awayMessage != nil) {
        NSLog(@"Initial away message");
        [self setAwayMessage:awayMessage];
    }
    NSLog(@"Setting handle updates to silent and delayed (connected)");
    silentAndDelayed = YES;
    NSAssert(signonTimer == nil, @"Already have a signon timer");
    signonTimer = [[NSTimer scheduledTimerWithTimeInterval:15
                                                   target:self
                                                 selector:@selector(signonTimerExpired:)
                                                 userInfo:nil
                                                  repeats:NO] retain];
}

- (void)signonTimerExpired:(NSTimer*)timer
{
    [signonTimer invalidate];
    [signonTimer release];
    signonTimer = nil;
    silentAndDelayed = NO;
    NSLog(@"Setting handle updates to loud and instantaneous (signon timer expired)");
}

- (void)accountConnectionDisconnected
{
    NSLog(@"accountConnectionDisconnected starting");
    [[owner accountController] 
        setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];
    NSLog(@"accountConnectionDisconnected ending");
    if (signonTimer != nil) {
        [signonTimer invalidate];
        [signonTimer release];
        signonTimer = nil;
    }
}

/************************/
/* accountBlist methods */
/************************/

- (void)accountNewBuddy:(GaimBuddy*)buddy
{
//    NSLog(@"accountNewBuddy (%s)", buddy->name);
    AIHandle *handle = [AIHandle
        handleWithServiceID:[self serviceID]
        UID:[[NSString stringWithUTF8String:buddy->name] compactedString]
        serverGroup:NO_GROUP
        temporary:NO
        forAccount:self];
    [handleDict setObject:handle forKey:[[NSString stringWithFormat:@"%s", buddy->name] compactedString]];
    buddy->node.ui_data = [handle retain];
    [[handle statusDictionary] setObject:[NSValue valueWithPointer:buddy] forKey:@"GaimBuddy"];
}

- (void)accountUpdateBuddy:(GaimBuddy*)buddy
{
//    NSLog(@"accountUpdateBuddy (%s)", buddy->name);

    NSMutableArray *modifiedKeys = [NSMutableArray array];
    AIHandle *theHandle = (AIHandle*) buddy->node.ui_data;
    NSAssert(theHandle != nil, @"Buddy has no associated handle");
    
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
        [[owner contactController] handle:theHandle removedFromAccount:self];
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

    //if anything changed
    if([modifiedKeys count] > 0)
    {  
        //tell the contact controller, silencing if necessary
        [[owner contactController] handleStatusChanged:theHandle
                                    modifiedStatusKeys:modifiedKeys
                                               delayed:silentAndDelayed
                                                silent:silentAndDelayed];
    }
}

- (void)accountRemoveBuddy:(GaimBuddy*)buddy
{
    NSLog(@"accountRemoveBuddy (%s)", buddy->name);
    //stored the key as a compactedString originally
    [handleDict removeObjectForKey:[[NSString stringWithFormat:@"%s", buddy->name] compactedString]];
    NSAssert(buddy->node.ui_data != NULL, @"Removing a node we don't have a handle for");
    [(AIHandle *)buddy->node.ui_data release];
    buddy->node.ui_data = NULL;
    [[owner contactController] handlesChangedForAccount:self];
}

/***********************/
/* accountConv methods */
/***********************/

- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type
{
    AIChat *chat = (AIChat*) conv->ui_data;
    GaimConvIm *im = gaim_conversation_get_im_data(conv);
    NSAssert(im != nil, @"We only do IM conversations");
    NSAssert(chat != nil, @"Conversation update with no AIChat");
    AIListContact *listContact = (AIListContact*) [chat listObject];
    NSAssert(listContact != nil, @"Conversation with no one?");
    AIHandle *handle = [listContact handleForAccount:self];
    NSAssert(handle != nil, @"listContact without handle");
    switch (type) {
        case GAIM_CONV_UPDATE_TYPING:
            {
                NSNumber *typing = [NSNumber numberWithBool:(gaim_conv_im_get_typing_state(im) == GAIM_TYPING)];
                NSLog(@"Changing typing state to %@", typing);
                [[handle statusDictionary] setObject:typing forKey:@"Typing"];
                [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"] delayed:NO silent:NO];
            }
            break;
        default:
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

/*****************************************************/
/* File transfer / AIAccount_Files inherited methods */
/*****************************************************/

//The account requested that we received a file; set up the ESFileTransfer and query the fileTransferController for a save location
- (void)accountXferRequestFileReceiveWithXfer:(GaimXfer *)xfer
{
    ESFileTransfer * fileTransfer = [[self createFileTransferObjectForXfer:xfer] retain];
    
    [fileTransfer setRemoteFilename:[NSString stringWithUTF8String:(xfer->filename)]];
        
    [[owner fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

//The account requested that we send a file, but we do not know what file yet - query the fileTransferController for a target file
/*- (void)accountXferSendFileWithXfer:(GaimXfer *)xfer
{
    ESFileTransfer * fileTransfer = [[self createFileTransferObjectForXfer:xfer] retain];
    //prompt the fileTransferController for the target filename
    [[owner fileTransferController] sendRequestForFileTransfer:fileTransfer];
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
    [[owner fileTransferController] transferCanceled:(ESFileTransfer *)(xfer->ui_data)];
    gaim_xfer_destroy(xfer);
}

//Accept a send or receive ESFileTransfer object, beginning the transfer.  Subsequently inform the fileTransferController that the fun has begun.
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
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
    [[owner fileTransferController] beganFileTransfer:fileTransfer];
}

//User refused a receive request.  Tell gaim, then release the ESFileTransfer object
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    gaim_xfer_request_denied((GaimXfer *)[[fileTransfer accountData] pointerValue]);
    [fileTransfer release];
}



/********************************/
/* AIAccount subclassed methods */
/********************************/

- (void)initAccount
{
    NSLog(@"CBGaimAccount initAccount");
    handleDict = [[NSMutableDictionary alloc] init];
//    chatDict = [[NSMutableDictionary alloc] init];
    filesToSendArray = [[NSMutableArray alloc] init];
    
    account = gaim_account_new([[self UID] UTF8String], [self protocolPlugin]);
    gaim_accounts_add(account);
    gc = NULL;
    NSLog(@"created GaimAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
    signonTimer = nil;
    
}

- (void)dealloc
{
    NSLog(@"CBGaimAccount dealloc");
//    [chatDict release];
    [handleDict release];
    [filesToSendArray release];
    if (signonTimer != nil) {
        [signonTimer invalidate];
        [signonTimer release];
        signonTimer = nil;
    }
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
        @"AwayMessage",
        nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    ACCOUNT_STATUS status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
    if([key compare:@"Online"] == 0)
    {
        if([inValue boolValue]) {
            if(status == STATUS_OFFLINE) { 
                [self connect];
            }
        } else { //Disconnect
            if(status == STATUS_ONLINE) {
                [self disconnect];
            }
        }
    } 
    else if (status == STATUS_ONLINE) { //now look at keys which only make sense while online
        if ([key compare:@"IdleSince"] == 0){
            // Even if we're setting a non-zero idle time, set it to zero first.
            // Some clients ignore idle time changes unless it moves to/from 0.
            serv_set_idle(gc, 0);
            if (inValue != nil) {
                int newIdle = -[inValue timeIntervalSinceNow];
                serv_set_idle(gc, newIdle);
            }
        }
        else if ([key compare:@"AwayMessage"] == 0) {
            [self setAwayMessage:inValue];
        }
    }
}


- (void)setAwayMessage:(id)message
{
    char *newValue = NULL;
    
    if (message) {
        newValue = g_strdup([[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:message]
                                               headers:YES
                                              fontTags:YES
                                         closeFontTags:YES
                                             styleTags:YES
                            closeStyleTagsOnFontChange:NO
                                        encodeNonASCII:NO] UTF8String]);
    }
    // gaim expects us to allocate the away message and leave it allocated;
    // it takes responsibilty for freeing it.
    serv_set_away(gc, GAIM_AWAY_CUSTOM, newValue);
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
                        closeStyleTagsOnFontChange:NO
                                    encodeNonASCII:NO];
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

/***************************/
/* Account private methods */
/***************************/

// Removes all the possible status flags (that are valid on the calling account) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle
{
    NSArray * keyArray = [self supportedPropertyKeys];
    [[handle statusDictionary] removeObjectsForKeys:keyArray];
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray delayed:YES silent:YES];
}

//connecting / disconnecting
- (void)connect
{
    //get password
    [[owner accountController] passwordForAccount:self 
                                  notifyingTarget:self selector:@selector(finishConnect:)];
}

- (void)disconnect
{
    //signing off
    [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_DISCONNECTING]
                         forKey:@"Status" account:self];
    
    //Flush all our handle status flags
  //  enumerator = [[handleDict allValues] objectEnumerator];
 //   while((handle = [enumerator nextObject])){
 //       [self removeAllStatusFlagsFromHandle:handle];
//    }
    
    //Remove all our handles
   // [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
  //  [[owner contactController] handlesChangedForAccount:self];
    
    //tell gaim to disconnect
    
    silentAndDelayed = YES;
    NSLog(@"Setting handle updates to silent and delayed (disconnecting)");
    gaim_account_disconnect(account); gc = NULL;
}


@end
