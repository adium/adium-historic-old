//
//  SmackXMPPAccount.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPAccount.h"
#import "SmackCocoaAdapter.h"
#import "ESDebugAILog.h"
#import "SmackInterfaceDefinitions.h"
#import "AIAdium.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIChat.h"
#import "AIListContact.h"
#import "AIContentMessage.h"
#import "AIChatController.h"
#import "AIContentController.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import "AIStatusDefines.h"
#import "AIStatusController.h"
#import "SmackListContact.h"

#import "ruli/ruli.h"

@implementation NSString (JIDAdditions)

- (NSString*)jidUsername {
    NSRange userrange = [self rangeOfString:@"@" options:NSLiteralSearch];
    if(userrange.location != NSNotFound)
        return [self substringToIndex:userrange.location];
    return self;
}
- (NSString*)jidHost {
    NSRange hoststartrange = [self rangeOfString:@"@" options:NSLiteralSearch];
    if(hoststartrange.location == NSNotFound)
        return nil;
    // look for resource
    NSRange hostendrange = [self rangeOfString:@"/" options:NSLiteralSearch range:NSMakeRange(hoststartrange.location,[self length]-hoststartrange.location)];
    if(hostendrange.location != NSNotFound)
        return [self substringWithRange:NSMakeRange(hoststartrange.location+1,hostendrange.location-hoststartrange.location-1)];
    // no resource
    return [self substringFromIndex:hoststartrange.location+1];
}
- (NSString*)jidResource {
    NSRange resourcerange = [self rangeOfString:@"/" options:NSLiteralSearch | NSBackwardsSearch];
    if(resourcerange.location != NSNotFound)
        return [self substringFromIndex:resourcerange.location+1];
    return nil; // no resource
}
- (NSString*)jidUserHost { // remove resource
    NSRange resourcerange = [self rangeOfString:@"/" options:NSLiteralSearch | NSBackwardsSearch];
    if(resourcerange.location != NSNotFound)
        return [self substringToIndex:resourcerange.location];
    return self; // no resource
}

@end

@class SmackXMPPRosterPlugin, SmackXMPPMessagePlugin, SmackXMPPErrorMessagePlugin, SmackXMPPHeadlineMessagePlugin;

@interface NSObject (SmackXMPPPluginAddition)
- (id)initWithAccount:(SmackXMPPAccount*)account;
@end

@implementation SmackXMPPAccount

- (void)initAccount {
	[super initAccount];

    static BOOL beganInitializingJavaVM = NO;
	if (!beganInitializingJavaVM && [self enabled]) {
		[SmackCocoaAdapter initializeJavaVM];
		beganInitializingJavaVM = YES;
	}
    
    if(!roster)
        roster = [[NSMutableDictionary alloc] init];
    else
        [roster removeAllObjects];
    
    if(!plugins) {
        Class XMPPPlugins[] = {
            [SmackXMPPRosterPlugin class],
            [SmackXMPPMessagePlugin class],
            [SmackXMPPErrorMessagePlugin class],
            [SmackXMPPHeadlineMessagePlugin class],
            nil
        };
        
        int i;
        plugins = [[NSMutableArray alloc] init];
        
        for(i = 0; XMPPPlugins[i]; i++) {
            NSObject *plugin = [[XMPPPlugins[i] alloc] initWithAccount:self];
            [(NSMutableArray*)plugins addObject:plugin];
            [plugin release];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [roster release]; roster = nil;
    [plugins release]; plugins = nil;
    [super dealloc];
}

- (BOOL)silentAndDelayed {
    return silentAndDelayed;
}

- (AIService*)service {
    return service;
}

- (AIListContact *)contactWithJID:(NSString *)inJID
{
    AIListContact *result = [roster objectForKey:inJID];
    if(result)
        return result;
	return ([[adium contactController] contactWithService:service
												  account:self
													  UID:inJID]);
}

- (void)connect {
    [super connect];
    AILog(@"XMPP connect");
    
    if(!smackAdapter)
        smackAdapter = [[SmackCocoaAdapter alloc] initForAccount:self];
}

- (void)disconnect {
    AILog(@"XMPP disconnect");
    [super disconnect];
    
    [[smackAdapter connection] close];
    
    [smackAdapter release];
    smackAdapter = nil;
}

- (void)connected:(SmackXMPPConnection*)conn {
    connection = conn;
    @try {
        NSString *jid = [self explicitFormattedUID];
        NSString *resource = [self preferenceForKey:@"Resource" group:GROUP_ACCOUNT_STATUS];
        
        [conn login:[jid jidUsername]
                   :[[adium accountController] passwordForAccount:self]
                   :resource?resource:@"Adium"];
        
        [self didConnect];
        
        [self setStatusState:[self statusState] usingStatusMessage:[self statusMessage]];
        
		[self silenceAllContactUpdatesForInterval:18.0];
		[[adium contactController] delayListObjectNotificationsUntilInactivity];
        
    }@catch(NSException *e) {
        NSLog(@"exception raised! name = %@, reason = %@, userInfo = %@",[e name],[e reason],[[e userInfo] description]);
        // caused by invalid password
        [self disconnect];
    }
}

- (void)disconnected:(SmackXMPPConnection*)conn {
    // waaaah
    [self didDisconnect];
}

- (void)connectionError:(NSString*)error {
    AILog(@"Got connection error \"%@\"!",error);
}

- (void)receiveMessagePacket:(SmackMessage*)packet {
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPMessagePacketReceivedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
}

- (void)receivePresencePacket:(SmackPresence*)packet {
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPPresencePacketReceivedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
}    

- (void)receiveIQPacket:(SmackIQ*)packet {
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPIQPacketReceivedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
}    

- (BOOL)sendMessageObject:(AIContentMessage *)inMessageObject {
    if([inMessageObject isAutoreply])
        return NO; // protocol doesn't support autoreplies
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPMessageSentNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:inMessageObject forKey:AIMessageObjectKey]];
    
    return YES;
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage {
    NSString *statusName = [statusState statusName];
    NSString *statusField = nil;
    int priority = [[self preferenceForKey:@"awayPriority" group:GROUP_ACCOUNT_STATUS] intValue];
    
    if([statusName isEqualToString:STATUS_NAME_AVAILABLE]) {
        statusField = @"AVAILABLE";
        priority = [[self preferenceForKey:@"availablePriority" group:GROUP_ACCOUNT_STATUS] intValue];
    } else if([statusName isEqualToString:STATUS_NAME_AWAY])
        statusField = @"AWAY";
    else if([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT])
        statusField = @"CHAT";
    else if([statusName isEqualToString:STATUS_NAME_DND])
        statusField = @"DO_NOT_DISTURB";
    else if([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY])
        statusField = @"EXTENDED_AWAY";
    else if([statusName isEqualToString:STATUS_NAME_INVISIBLE])
        statusField = @"INVISIBLE";
    else // shouldn't happen
        statusField = @"AVAILABLE";
    
    SmackPresence *newPresence = [SmackCocoaAdapter presenceWithTypeString:@"AVAILABLE"
                                                                    status:[statusMessage string]
                                                                  priority:priority
                                                                modeString:statusField];
    
    [connection sendPacket:newPresence];
}

- (void)performRegisterWithPassword:(NSString *)inPassword {
    [super performRegisterWithPassword:inPassword];
}

- (NSString *)accountWillSetUID:(NSString *)proposedUID {
	return [super accountWillSetUID:proposedUID];
}

- (void)didChangeUID {
    [super didChangeUID];
}

- (void)willBeDeleted {
    [super willBeDeleted];
}

- (NSString *)explicitFormattedUID {
	return [super explicitFormattedUID];
}

- (NSString*)hostName {
    NSString *host = [self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
    if(!host || [host length] == 0) {
        return [[self explicitFormattedUID] jidHost];
    }
    return host;
}

- (SmackConnectionConfiguration*)connectionConfiguration {
    NSString *host = [self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
    int portnum = [[self preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue]?5223:5222;
    
    if(!host || [host length] == 0) { // did the user not supply a host?
 
        // do an SRV lookup
        
        host = [[self explicitFormattedUID] jidHost];
        ruli_sync_t *query = ruli_sync_query("_xmpp-client._tcp", [host cStringUsingEncoding:NSUTF8StringEncoding] /* ### punycode */, portnum, RULI_RES_OPT_SEARCH | RULI_RES_OPT_SRV_RFC3484 | RULI_RES_OPT_SRV_CNAME /* be tolerant to broken DNS configurations */);
        
        int srv_code;
        
        if(query != NULL && (srv_code = ruli_sync_srv_code(query)) == 0) {
            ruli_list_t *list = ruli_sync_srv_list(query);
            // we should use some kind of round-robbin to try the other results from this query
            
            if(ruli_list_size(list) > 0) {
                ruli_srv_entry_t *srventry = ruli_list_get(list,0);
                
                char dname[RULI_LIMIT_DNAME_TEXT_BUFSZ];
                int dname_length;
                
                if(ruli_dname_decode(dname, RULI_LIMIT_DNAME_TEXT_BUFSZ, &dname_length, srventry->target, srventry->target_len) == RULI_TXT_OK) {
                    host = [[[NSString alloc] initWithBytes:dname length:dname_length encoding:NSASCIIStringEncoding] autorelease];
                    portnum = srventry->port;
                } else
                    AILog(@"XMPP: failed decoding SRV resolve domain name");
            } else
                AILog(@"XMPP: SRV query returned 0 results");
            
            ruli_sync_delete(query);
        } else
            AILog(@"XMPP: SRV resolve for host \"%@\" returned error %d", host, srv_code);

        NSLog(@"host = %@:%d",host,portnum);
    } else {
        NSNumber *port = [self preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];
        if(port)
            portnum = [port intValue];
    }
    
    SmackConnectionConfiguration *conf = [SmackCocoaAdapter connectionConfigurationWithHost:host port:portnum service:[[self explicitFormattedUID] jidHost]];
        
    [conf setCompressionEnabled:![[self preferenceForKey:@"disableCompression"
                                                   group:GROUP_ACCOUNT_STATUS] boolValue]];
    [conf setDebuggerEnabled:NO];
    [conf setExpiredCertificatesCheckEnabled:![[self preferenceForKey:@"allowExpired"
                                                                group:GROUP_ACCOUNT_STATUS] boolValue]];
    [conf setNotMatchingDomainCheckEnabled:![[self preferenceForKey:@"allowNonMatchingHost"
                                                              group:GROUP_ACCOUNT_STATUS] boolValue]];
    [conf setSASLAuthenticationEnabled:![[self preferenceForKey:@"disableSASL"
                                                          group:GROUP_ACCOUNT_STATUS] boolValue]];
    [conf setSelfSignedCertificateEnabled:[[self preferenceForKey:@"allowSelfSigned"
                                                            group:GROUP_ACCOUNT_STATUS] boolValue]];
    [conf setTLSEnabled:![[self preferenceForKey:@"disableTLS"
                                           group:GROUP_ACCOUNT_STATUS] boolValue]];
    
    return conf;
}

- (SmackXMPPConnection*)connection {
    return connection;
}

#pragma mark Properties

- (BOOL)shouldSendAutoresponsesWhileAway {
	return NO;
}

- (BOOL)disconnectOnFastUserSwitch {
	return NO;
}

- (BOOL)connectivityBasedOnNetworkReachability {
	return YES;
}

- (BOOL)suppressTypingNotificationChangesAfterSend {
	return NO;
}

- (BOOL)supportsOfflineMessaging {
	return YES;
}

- (BOOL)allowsNewlinesInMessages {
	return YES;
}

/*- (BOOL)supportsFolderTransfer {
	return NO;
}*/

#pragma mark Status

- (NSSet *)supportedPropertyKeys {
	static	NSSet	*supportedPropertyKeys = nil;
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSSet alloc] initWithObjects:
			@"Online",
			@"FormattedUID",
			KEY_ACCOUNT_DISPLAY_NAME,
			@"Display Name",
			@"StatusState",
			KEY_USE_USER_ICON,
			@"Enabled",
            @"TextProfile",
            @"DefaultUserIconFilename",
			nil];
	}
    
	return supportedPropertyKeys;
}

- (void)delayedUpdateContactStatus:(AIListContact *)inContact {
    [super delayedUpdateContactStatus:inContact];
}

#pragma mark Messaging, Chatting, Strings

- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact {
    return NO;
}

- (BOOL)openChat:(AIChat *)chat {
    return YES;
}

- (BOOL)closeChat:(AIChat *)chat {
    return YES;
}

- (BOOL)inviteContact:(AIListObject *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage {
    return NO;
}

- (BOOL)joinGroupChatNamed:(NSString *)name {
    return NO;
}

- (BOOL)sendTypingObject:(AIContentTyping *)inTypingObject {
    NSLog(@"typing %@",([inTypingObject typingState]==AINotTyping)?@"NO":(([inTypingObject typingState]==AITyping)?@"TYPING":@"ENTEREDTEXT"));
    return YES;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject {
    return [super encodedAttributedString:inAttributedString forListObject:inListObject];
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage {
    return [super encodedAttributedStringForSendingContentMessage:inContentMessage];
}

#pragma mark Presence Tracking

- (BOOL)contactListEditable {
	return YES;
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group {
    // ### request authorization
}

- (void)removeContacts:(NSArray *)objects {
    // ### remove authorization
}

- (void)deleteGroup:(AIListGroup *)group {
    
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group {
    
}

- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName {
    
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    return [super menuItemsForContact:inContact];
}

- (NSArray *)accountActionMenuItems {
    return [super accountActionMenuItems];
}

#pragma mark Secure messsaging

- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	return [super allowSecureMessagingTogglingForChat:inChat];
}

- (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict didAuthorize:(BOOL)inDidAuthorize {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:inDidAuthorize?@"SUBSCRIBED":@"UNSUBSCRIBED"];
    [packet setTo:[infoDict objectForKey:@"Remote Name"]];
    
    [connection sendPacket:packet];
}

#pragma mark Buddy list
- (void)setListContact:(AIListContact *)listContact toAlias:(NSString *)inAlias
{
	BOOL			changes = NO, nameChanges = NO;
	
	if (inAlias && ([inAlias length] == 0)) inAlias = nil;
	
	AIMutableOwnerArray	*displayNameArray = [listContact displayArrayForKey:@"Display Name"];
	NSString			*oldDisplayName = [displayNameArray objectValue];
	
	//If the mutableOwnerArray's current value isn't identical to this alias, we should set it
	if (![[displayNameArray objectWithOwner:self] isEqualToString:inAlias]) {
		[displayNameArray setObject:inAlias
						  withOwner:self
					  priorityLevel:Low_Priority];
		
		//If this causes the object value to change, we need to request a manual update of the display name
		if (oldDisplayName != [displayNameArray objectValue]) {
			nameChanges = YES;
		}
	}
	
	if (![[listContact statusObjectForKey:@"Server Display Name"] isEqualToString:inAlias]) {
		[listContact setStatusObject:inAlias
							  forKey:@"Server Display Name"
							  notify:NotifyLater];
		changes = YES;
	}
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
	
	if (nameChanges) {
		//Notify of display name changes
		[[adium contactController] listObjectAttributesChanged:listContact
												  modifiedKeys:[NSSet setWithObject:@"Display Name"]];
		
		//XXX - There must be a cleaner way to do this alias stuff!  This works for now
		//Request an alias change
		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:listContact
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];
	}
}

- (void)addListContact:(AIListContact*)listContact {
    [roster setObject:listContact forKey:[listContact UID]];
}

@end
