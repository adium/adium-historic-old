#import "JabberAccount.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "JabberAccountViewController.h"
#include <openssl/md5.h>
#include <unistd.h>

@interface JabberAccount (PRIVATE)
- (void)initAccount;
- (void)connect;
- (void)onSessionConnected:(NSNotification*)n;
- (void)onSessionAuthReady:(NSNotification*)n;
- (void)onSessionStarted:(NSNotification*)n;
- (void)onMessage:(NSNotification*)n;
- (void)authenticate:(NSString*)password;
- (void)onError:(NSNotification*)n;
- (void)disconnect;
- (AIChat *)_openChatWithHandle:(AIHandle *)handle;
@end

@implementation JabberAccount

/*********************/
/* AIAccount_Content */
/*********************/

- (BOOL)sendContentObject:(AIContentObject *)object
{
    return NO;
}

// Returns YES if the contact is available for receiving content of the specified type
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    return NO;
}

- (AIChat *)openChatWithListObject:(AIListObject *)inListObject
{
    return nil;
}

//
- (AIChat *)_openChatWithHandle:(AIHandle *)handle
{
    return nil;
}

- (BOOL)closeChat:(AIChat *)inChat
{
    return NO;
}


/*********************/
/* AIAccount_Handles */
/*********************/

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
    return nil;
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

/********************/
/* AIAccount_Groups */
/********************/

/********************************/
/* AIAccount subclassed methods */
/********************************/

- (void)initAccount
{
    handleDict = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
    [handleDict release];
    [super dealloc];
}

- (id <AIAccountViewController>)accountView
{
    return([JabberAccountViewController accountViewForOwner:owner account:self]);
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

- (NSString *)UIDAndServiceID //serviceid.uid
{
    return [NSString stringWithFormat:@"%@.%@",[self serviceID],[self UID]];
}

- (NSString *)accountDescription
{
    return [self UID];
}

- (NSArray *)supportedPropertyKeys
{
    return([NSArray arrayWithObjects:@"Online", @"Offline", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    NSLog(@"jabber: statusForKey: %@ willChangeTo: %d", key, inValue);
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

/*******************/
/* Private methods */
/*******************/

- (void)connect
{
    NSLog(@"jabber: connect");
    myID = [JabberID withUserHost:[self UID] andResource:@"Adium"];
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_CONNECTING]
                                        forKey:@"Status" account:self];
    session = [[JabberSession alloc] init];
    NSLog(@"adding session connected listener");
    [session addObserver:self selector:@selector(onSessionConnected:) name:JSESSION_CONNECTED];
    NSLog(@"adding auth ready listener");
    [session addObserver:self selector:@selector(onSessionAuthReady:) name:JSESSION_AUTHREADY];
    NSLog(@"adding error listener");
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_SOCKET];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_CONNECT_FAILED];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_AUTHFAILED];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_BADUSER];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_REGFAILED];
    [session addObserver:self selector:@selector(onError:) name:JSESSION_ERROR_XMLPARSER];
    NSLog(@"adding started listener");
    [session addObserver:self selector:@selector(onSessionStarted:) name:JSESSION_STARTED];
    NSLog(@"adding message listener");
    [session addObserver:self selector:@selector(onMessage:)
             xpath:@"/message[!@type='groupchat']"];
    NSLog(@"starting session");
    [session startSession:myID onPort:5222];
}

- (void)onSessionStarted:(NSNotification*)n
{
    NSLog(@"jabber: session started");
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
                                        forKey:@"Status" account:self];
    [session sendString:@"<presence><priority>5</priority></presence>"];
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

- (void)authenticate:(NSString*)password
{
    NSLog(@"jabber: sending password");
    [[session authManager] authenticateWithPassword:password];
}

- (void)onMessage:(NSNotification*)n
{
    JabberMessage *m = (JabberMessage*) [n object];
    NSLog(@"jabber: message");
    NSString *from = [[m from] userhost];
    AIHandle *handle;
    handle = [handleDict objectForKey: from];
    if (!handle) {
        handle = [self addHandleWithUID:from serverGroup:nil temporary:YES];
    }
    if(![[[handle statusDictionary] objectForKey:@"Online"] boolValue]){
        [[handle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Online"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Online"] delayed:NO silent:YES];
    }
    AIChat *chat = [self _openChatWithHandle:handle];
    AIContentMessage *messageObject;
    messageObject = [AIContentMessage messageInChat:chat
                                         withSource:[handle containingContact]
                                        destination:self
                                               date:[m delayedOnDate]
                                            message:[m body]
                                          autoreply:NO];
    [[owner contentController] addIncomingContentObject:messageObject];    
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
    [session removeObserver:self];
    [session release];
    session = nil;
    [myID release];
    myID = nil;

    // Set status as offline
    [[owner accountController] setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];
}

@end
