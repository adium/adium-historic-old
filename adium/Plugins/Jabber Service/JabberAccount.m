#import "JabberAccount.h"
#import <acid.h>
#import "JabberAccountViewController.h"
#include <openssl/md5.h>
#include <unistd.h>

const int STARTUP_TIME = 20;

@interface JabberAccount (PRIVATE)
- (void)initAccount;
- (void)connect;
- (void)onSessionConnected:(NSNotification*)n;
- (void)onSessionAuthReady:(NSNotification*)n;
- (void)onSessionStarted:(NSNotification*)n;
- (void)onSessionEnded:(NSNotification*)n;
- (void)onMessage:(NSNotification*)n;
- (void)authenticate:(NSString*)password;
- (void)onError:(NSNotification*)n;
- (void)disconnect;
- (void)onPresenceChange:(NSNotification*)n;
- (AIChat *)_openChatWithHandle:(AIHandle *)handle;
@end

@implementation JabberAccount

#pragma mark AIAccount_Content

- (BOOL)sendContentObject:(AIContentObject *)object
{
    BOOL                sent = NO;
    AIListContact       *listObject;
    AIHandle            *handle;

    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSString *body = [[(AIContentMessage*)object message] string];
        //Get the destination handle
        listObject = (AIListContact *)[[object chat] listObject];
        handle = [listObject handleForAccount:self];
        if(!handle){
            handle = [self addHandleWithUID:[[listObject UID] compactedString] serverGroup:nil temporary:YES];
        }
        JabberMessage *msg = [[JabberMessage alloc]
            initWithRecipient:[[JabberID alloc] initWithUserHost:[listObject UID] andResource:nil]
                      andBody:body];
        [session sendElement: msg];
        sent = YES;
    }
    return sent;
}

// Returns YES if the contact is available for receiving content of the specified type
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    BOOL        available = NO;
    BOOL        weAreOnline = ([[[owner accountController] propertyForKey:@"Status" account:self] intValue]
                               == STATUS_ONLINE);

    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        if(weAreOnline){
            // Jabber can send messages to people while they are offline. They get them later.
            available = YES;
        }
    }

    return(available);
}

- (AIChat *)openChatWithListObject:(AIListObject *)inListObject
{
    AIHandle            *handle;
    AIChat              *chat = nil;

    if([inListObject isKindOfClass:[AIListContact class]]){
        //Get our handle for this contact
        handle = [(AIListContact *)inListObject handleForAccount:self];
        if(!handle){
            handle = [self addHandleWithUID:[[inListObject UID] compactedString] serverGroup:nil temporary:
                YES];
        }
        chat = [self _openChatWithHandle:handle];
    }

    return(chat);
}

//
- (AIChat *)_openChatWithHandle:(AIHandle *)handle
{
    AIChat      *chat;

    //Create chat
    if(!(chat = [chatDict objectForKey:[handle UID]])){
        AIListContact   *containingContact = [handle containingContact];
        BOOL            handleIsOnline;

        //Create the chat
        chat = [AIChat chatForAccount:self];

        //NSLog(@"adding list object %@ containingContact %@",[handle UID],[handle containingContact]);
        //Set the chat participants
        [chat addParticipatingListObject:containingContact];

        //Correctly enable/disable the chat
        handleIsOnline = [[[handle statusDictionary] objectForKey:@"Online"] boolValue];
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:handleIsOnline] forKey:@"Enabled"];

        //
        [chatDict setObject:chat forKey:[handle UID]];
        [[owner contentController] noteChat:chat forAccount:self];
    }

    return(chat);
}

- (BOOL)closeChat:(AIChat *)inChat
{
    return NO;
}

#pragma mark AIAccount_Handles

// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles //return nil if no contacts/list available
{
    int status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
    return (status == STATUS_ONLINE) ? handleDict : nil;
}

// Returns YES if the list is editable
- (BOOL)contactListEditable
{
    return NO;
}

// Add a handle to this account
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    if (inTemporary) {
        inGroup = @"__Strangers";
    } else if (!inGroup) {
        inGroup = @"Unknown";
    }
    AIHandle *handle;
    if((handle = [handleDict objectForKey:inUID])){
        [self removeHandleWithUID:inUID]; //Remove the handle
    }
    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] identifier] UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:self];
    [handleDict setObject:handle forKey:[handle UID]];
    [[owner contactController] handle:handle addedToAccount:self];
    return handle;
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
    [[owner interfaceController] handleErrorMessage:@"Jabber Error"
                                    withDescription:errorDesc];
}

#pragma mark AIAccount subclassed methods

- (void)initAccount
{
    NSLog(@"JabberAccount initAccount:");
    handleDict = [[NSMutableDictionary alloc] init];
    chatDict = [[NSMutableDictionary alloc] init];
    session = [[JabberSession alloc] init];
    [[session roster] setDelegate: self];
    [session addObserver:self selector:@selector(onSessionConnected:) name:JSESSION_CONNECTED];
    [session addObserver:self selector:@selector(onSessionAuthReady:) name:JSESSION_AUTHREADY];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_SOCKET];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_CONNECT_FAILED];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_AUTHFAILED];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_BADUSER];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_REGFAILED];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_XMLPARSER];
    [session addObserver:self selector:@selector(onSessionStarted:) name:JSESSION_STARTED];
    [session addObserver:self selector:@selector(onSessionEnded:) name:JSESSION_ENDED];
    [session addObserver:self selector:@selector(onMessage:)
                   xpath:@"/message[!@type='groupchat']"];
    [session addObserver:self selector:@selector(onPresenceChange:) name:JPRESENCE_JID_DEFAULT_CHANGED];
    [session addObserver:self selector:@selector(onPresenceChange:) name:JPRESENCE_JID_UNAVAILABLE];    
}

- (void)dealloc
{
    [handleDict release];
    [chatDict release];
    [session release];
    [super dealloc];
}

- (id <AIAccountViewController>)accountView
{
    return([JabberAccountViewController accountViewForAccount:self]);
}

- (NSString *)accountID //unique throught the whole app
{
    return [NSString stringWithFormat:@"Jabber.%@",[self UID]];
}

- (NSString *)UID //unique to the service
{
    return [NSString stringWithFormat:@"%@@%@",[propertiesDict objectForKey:@"Username"],[propertiesDict objectForKey:@"Host"]];
}

- (NSString *)serviceID //service id
{
    return @"Jabber";
}

- (NSString *)accountDescription
{
    return [self UID];
}

- (NSArray *)supportedPropertyKeys
{
    return([NSArray arrayWithObjects:@"Online", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    NSLog(@"jabber: statusForKey: %@ willChangeTo: %@", key, inValue);
    ACCOUNT_STATUS status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
        
    if([key compare:@"Online"] == 0)
    {
        if([inValue boolValue]) //Connect
        { 
            if(status == STATUS_OFFLINE)
            {
                [self connect];
            }            
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                [self disconnect];
            }
        }

    }
}

#pragma mark Private methods

- (void)connect
{
    NSLog(@"jabber: connect");
    NSAssert(myID == nil, @"JID should be nil before connecting");
    myID = [JabberID withUserHost:[self UID] andResource:@"Adium"];
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_CONNECTING]
                                        forKey:@"Status" account:self];
    NSLog(@"starting session");
    [session startSession:myID onPort:5222];
}

- (void)authenticate:(NSString*)password
{
    NSLog(@"jabber: sending password");
    [[session authManager] authenticateWithPassword:password];
}

/* Without this, the onMessage listener won't register properly. But I don't understand it. What does this do? */
- (id)copyWithZone:(NSZone*)z
{
    return [self retain];
}

- (void)disconnect
{
    NSLog(@"jabber: disconnect");
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_DISCONNECTING]
        forKey:@"Status" account:self];
    [session stopSession];
    NSAssert(myID != nil, @"no id when disconnecting");
    [myID release];
    myID = nil;

    //Remove all our handles
    [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
    [[owner contactController] handlesChangedForAccount:self];

    // Set status as offline
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];
}

- (void)startupEnded
{
    silentAndDelayed = FALSE;
    [initialTimer release];
    initialTimer = nil;
}

#pragma mark JabberSession callbacks


- (void)onSessionStarted:(NSNotification*)n
{
    NSAssert(groupTracker == nil, @"group tracker set before session started");
    groupTracker = [[JabberGroupTracker alloc] init];
    NSLog(@"jabber: session started");
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
                                    forKey:@"Status" account:self];
    [session sendString:@"<presence><priority>5</priority></presence>"];
    silentAndDelayed = TRUE;
    NSAssert(initialTimer == nil, @"have timer already");
    initialTimer = [[NSTimer scheduledTimerWithTimeInterval:STARTUP_TIME
                                                     target:self
                                                   selector:@selector(startupEnded)
                                                   userInfo:nil
                                                    repeats:NO] retain];
}

- (void)onSessionEnded:(NSNotification*)n
{
    NSLog(@"Jabber: session ended");
    if (initialTimer != nil) {
        [initialTimer invalidate];
        [initialTimer release];
        initialTimer = nil;
    }
    NSAssert(groupTracker != nil, @"group tracker should not be nil when session ended");
    [groupTracker release];
    groupTracker = nil;
}

- (void)onSessionConnected:(NSNotification*)n
{
    NSLog(@"jabber: session connected");
}

- (void)onError:(NSNotification*)n
{
    NSLog(@"jabber: error");
}

- (void)onSessionAuthReady:(NSNotification*)n
{
    NSLog(@"jabber: auth ready");
    [[owner accountController] passwordForAccount:self notifyingTarget:self selector:@selector(authenticate:)];
}

- (void)onMessage:(NSNotification*)n
{
    JabberMessage *m = (JabberMessage*) [n object];
    NSString *from = [[m from] userhost];
    NSLog(@"jabber: message from %@: %@", from, [m body]);
    AIHandle *handle;
    handle = [handleDict objectForKey: from];
    if (!handle) {
        NSLog(@"adding handle");
        handle = [self addHandleWithUID:from serverGroup:nil temporary:YES];
    }
    NSLog(@"containing contact: %@", [handle containingContact]);
    NSLog(@"creating chat");
    AIChat *chat = [self _openChatWithHandle:handle];
    AIContentMessage *messageObject;
    NSLog(@"creating message object");
    messageObject = [AIContentMessage messageInChat:chat
                                         withSource:[handle containingContact]
                                        destination:self
                                               date:nil//[m delayedOnDate]
                                            message:[[NSAttributedString alloc] initWithString:[m body]]
                                          autoreply:NO];
    NSLog(@"adding incoming content object");
    [[owner contentController] receiveContentObjectmessageObject];
    NSLog(@"done");
}

- (void) onPresenceChange: (NSNotification*)n
{
    if ([n name] == JPRESENCE_JID_UNAVAILABLE) {
        NSString *uid = [[n object] userhost];
        NSLog(@"%@ unavailable", uid);
        AIHandle *handle = [handleDict objectForKey: uid];
        if (!handle) {
            // Acid apparently sends presence changes before roster changes
            NSLog(@"presence for previously unknown handle %@", uid);
            handle = [self addHandleWithUID:uid serverGroup:nil temporary:NO];
        }
        NSMutableDictionary *handleStatusDict = [handle statusDictionary];
        [handleStatusDict setObject:[NSNumber numberWithBool:NO] forKey:@"Online"];
        [[owner contactController] handleStatusChanged:handle
                                    modifiedStatusKeys:[NSArray arrayWithObject: @"Online"]
                                               delayed:NO
                                                silent:NO];
    } else { // JPRESENCE_JID_DEFAULT_CHANGED
        JabberPresence *pres = [n object];
        NSString *uid = [[pres from] userhost];
        NSLog(@"default presence change for %@ (%@: %@)", uid, [pres show], [pres status]);
        AIHandle *handle = [handleDict objectForKey: uid];
        if (!handle) {
            // Acid apparently sends presence changes before roster changes
            NSLog(@"presence for previously unknown handle %@", uid);
            handle = [self addHandleWithUID:uid serverGroup:nil temporary:NO];
        }
        NSMutableDictionary *handleStatusDict = [handle statusDictionary];
        NSMutableArray *changed = [NSMutableArray arrayWithCapacity:2];

        NSString *newShow = [pres show];
        bool newAway = (newShow != nil);
        id oldAway = [handleStatusDict objectForKey:@"Away"];
        if (oldAway == nil || [oldAway boolValue] != newAway) {
            [changed addObject: @"Away"];
            [handleStatusDict setObject:[NSNumber numberWithBool:newAway] forKey:@"Away"];
        }

        id oldMessage = [handleStatusDict objectForKey:@"StatusMessage"];
        NSString *newMessage = [[NSAttributedString alloc] initWithString: [pres status]];
        if (oldMessage != newMessage) {
            [changed addObject: @"StatusMessage"];
            if (newMessage == nil)
                [handleStatusDict removeObjectForKey: @"StatusMessage"];
            else
                [handleStatusDict setObject:newMessage forKey:@"StatusMessage"];
        }

        id oldOnline = [handleStatusDict objectForKey:@"Online"];
        if (oldOnline == nil || [oldOnline boolValue] == NO) {
            [changed addObject: @"Online"];
            [handleStatusDict setObject:[NSNumber numberWithBool:YES] forKey:@"Online"];
        }
        
        [[owner contactController] handleStatusChanged:handle
                                    modifiedStatusKeys:changed
                                               delayed:silentAndDelayed
                                                silent:silentAndDelayed];
    }
}

#pragma mark JabberRosterDelegate protocol

-(void) onBeginUpdate {
    NSLog(@"onBeginUpdate");
}

-(void) onEndUpdate {
    NSLog(@"onEndUpdate");
}

-(void) onItem:(id)item addedToGroup:(NSString*)group
{
    NSLog(@"item %@ added to group %@", [item displayName], group);
    NSString *uid = [[item JID] userhost];
    AIHandle *handle = [handleDict objectForKey: uid];
    if (!handle) {
        NSLog(@"creating");
        handle = [self addHandleWithUID:uid serverGroup:nil temporary:NO];
    } else
        NSLog(@"already present");
}

- (void) onItem:(id)item removedFromGroup:(NSString*)group
{
    NSString *uid = [[item JID] userhost];
    NSLog(@"item %@ removed from from %@", [item displayName], group);
    AIHandle *handle = [handleDict objectForKey: uid];
    if (handle) {
        NSLog(@"removing");
        [self removeHandleWithUID:uid];
    } else
        NSLog(@"already removed");
}

@end
