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
#import "AIInterfaceController.h"
#import "AIChat.h"
#import "AIListContact.h"
#import "AIContentMessage.h"
#import "AIChatController.h"
#import "AIContentController.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import "AIStatusDefines.h"
#import "AIStatusController.h"
#import "SmackListContact.h"
#import "SmackXMPPRegistration.h"

#import "ruli/ruli.h"
#import <AIUtilities/AIStringUtilities.h>

@implementation NSString (JIDAdditions)

- (NSString*)jidUsername {
    NSRange userrange = [self rangeOfString:@"@" options:NSLiteralSearch];
    if(userrange.location != NSNotFound)
        return [self substringToIndex:userrange.location];
    return @"";
}
- (NSString*)jidHost {
    NSRange hoststartrange = [self rangeOfString:@"@" options:NSLiteralSearch];
    if(hoststartrange.location == NSNotFound)
        hoststartrange.location = (unsigned int)-1;
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
    return @""; // no resource
}
- (NSString*)jidUserHost { // remove resource
    NSRange resourcerange = [self rangeOfString:@"/" options:NSLiteralSearch | NSBackwardsSearch];
    if(resourcerange.location != NSNotFound)
        return [self substringToIndex:resourcerange.location];
    return self; // no resource
}

@end

@class SmackXMPPRosterPlugin, SmackXMPPMessagePlugin, SmackXMPPErrorMessagePlugin, SmackXMPPHeadlineMessagePlugin, SmackXMPPMultiUserChatPlugin, SmackXMPPGatewayInteractionPlugin, SmackXMPPServiceDiscoveryBrowsing, SmackXMPPFileTransferPlugin, SmackXMPPChatStateNotificationsPlugin, SmackXMPPVCardPlugin, SmackXMPPVersionPlugin, SmackXMPPPrivacyPlugin, SmackJinglePlugin, SmackXMPPPhonePlugin;

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
    
    if(!plugins) {
        Class XMPPPlugins[] = {
            [SmackXMPPRosterPlugin class],
            [SmackXMPPMessagePlugin class],
            [SmackXMPPErrorMessagePlugin class],
            [SmackXMPPHeadlineMessagePlugin class],
            [SmackXMPPMultiUserChatPlugin class],
            [SmackXMPPGatewayInteractionPlugin class],
            [SmackXMPPServiceDiscoveryBrowsing class],
            [SmackXMPPFileTransferPlugin class],
            [SmackXMPPChatStateNotificationsPlugin class],
            [SmackXMPPVCardPlugin class],
            [SmackXMPPVersionPlugin class],
            [SmackXMPPPrivacyPlugin class],
            [SmackJinglePlugin class],
            [SmackXMPPPhonePlugin class],
            nil
        };
        
        int i;
        plugins = [[NSMutableArray alloc] init];
        
        for(i = 0; XMPPPlugins[i]; i++)
            [self addPlugin:XMPPPlugins[i]];
    }
}

- (void)addPlugin:(Class)pluginclass
{
    NSObject *plugin = [[pluginclass alloc] initWithAccount:self];
    [(NSMutableArray*)plugins addObject:plugin];
    [plugin release];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [plugins release]; plugins = nil;
    [serverinfo release]; serverinfo = nil;
    [super dealloc];
}

// plugins might add other protocols to this class
// so we have to ask them if they add anything
- (BOOL)conformsToProtocol:(Protocol*)proto
{
    // if we support it, all is great
    if([super conformsToProtocol:proto])
        return YES;
    // otherwise, ask the plugins
    NSEnumerator *e = [plugins objectEnumerator];
    id plugin;
    while((plugin = [e nextObject]))
    {
        if([plugin respondsToSelector:@selector(addsProtocolSupport:)] && [plugin addsProtocolSupport:proto])
            return YES;
    }
    // nobody likes that protocol, give up
    return NO;
}

- (BOOL)silentAndDelayed {
    return silentAndDelayed;
}

- (AIService*)service {
    return service;
}

- (void)connect {
    [super connect];
    AILog(@"XMPP connect");
    
    if(!smackAdapter)
        smackAdapter = [[SmackCocoaAdapter alloc] initForAccount:self];
}

- (void)disconnect {
    connection = nil;

    AILog(@"XMPP disconnect");
    [super disconnect];

    [[smackAdapter connection] close];
    
    [smackAdapter release];
    smackAdapter = nil;
    
    [serverinfo release]; serverinfo = nil;
    [self didDisconnect];
}

- (NSString*)resource
{
    NSString *resource = [self preferenceForKey:@"Resource" group:GROUP_ACCOUNT_STATUS];
    return resource?resource:@"Adium";
}

- (void)connected:(SmackXMPPConnection*)conn {
    connection = conn;
    NSString *jid = [self explicitFormattedUID];

    NSEnumerator *e = [plugins objectEnumerator];
    id plugin;
    while((plugin = [e nextObject]))
        if([plugin respondsToSelector:@selector(connected:)])
            [plugin connected:conn];
    
    @try {
        
        [conn login:[jid jidUsername]
                   :[[adium accountController] passwordForAccount:self]
                   :[self resource]
                   :NO];
        
        // get features supported by server before doing anything
        [serverinfo release]; serverinfo = nil;
        serverinfo = [[[SmackCocoaAdapter serviceDiscoveryManagerForConnection:conn] discoverInfo:[conn getServiceName]] retain];

        [self didConnect];
        
        // initial presence is sent automatically by Adium

		[self silenceAllContactUpdatesForInterval:18.0];
		[[adium contactController] delayListObjectNotificationsUntilInactivity];
    }@catch(NSException *e) {
        // caused by invalid password
        [self disconnect];
        if([[e reason] isEqualToString:@"SASL authentication failed"]) // ugly ugly ugly, but no other way
        {
            [self serverReportedInvalidPassword];
            [self autoReconnectAfterDelay:1.0];
        } else
            [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Error logging into account %@.","Error logging into account %@."),jid] withDescription:[e reason]];
        return;
    }
}

- (void)disconnected:(SmackXMPPConnection*)conn {
    // waaaah
    [self didDisconnect];
    NSEnumerator *e = [plugins objectEnumerator];
    id plugin;
    while((plugin = [e nextObject]))
        if([plugin respondsToSelector:@selector(disconnected:)])
            [plugin disconnected:conn];
    [self removeAllContacts];
    [serverinfo release]; serverinfo = nil;
}

- (void)connectionError:(NSString*)error {
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Connection error on account %@.","Connection error on account %@."),[self explicitFormattedUID]] withDescription:error];
    [self didDisconnect];
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
    
    SmackMessage *message = [SmackCocoaAdapter message];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPMessageSentNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           inMessageObject, AIMessageObjectKey,
                                                           message, SmackXMPPPacket,
                                                           nil]];
    
    // the message is valid only when a 'to' is set, so only send it in this case!
    if([[message getTo] length] != 0)
        [connection sendPacket:message];
    
    return YES;
}

- (SmackPresence*)getUserPresenceForStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
    NSString *statusName = [statusState statusName];
    NSString *statusField = nil;
    int priority = [[self preferenceForKey:@"awayPriority" group:GROUP_ACCOUNT_STATUS] intValue];
    
    if([statusName isEqualToString:STATUS_NAME_AVAILABLE]) {
        statusField = @"available";
        priority = [[self preferenceForKey:@"availablePriority" group:GROUP_ACCOUNT_STATUS] intValue];
    } else if([statusName isEqualToString:STATUS_NAME_AWAY])
        statusField = @"away";
    else if([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT])
        statusField = @"chat";
    else if([statusName isEqualToString:STATUS_NAME_DND])
        statusField = @"dnd";
    else if([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY])
        statusField = @"xa";
    else // shouldn't happen (except for invisible)
        statusField = @"available";
    
    return [SmackCocoaAdapter presenceWithTypeString:@"available"
                                              status:[statusMessage string]
                                            priority:priority
                                          modeString:statusField];
}

- (SmackPresence*)getCurrentUserPresence
{
    return [self getUserPresenceForStatusState:[self statusState] usingStatusMessage:[self statusMessage]];
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage {
    NSLog(@"new status: %@",statusState);
    if([[statusState statusName] isEqualToString:STATUS_NAME_INVISIBLE])
    {
        if(currentlyInvisible)
            return;
        if(![serverinfo containsFeature:@"http://jabber.org/protocol/invisibility"])
        {
            // I can't use AIInterfaceController's questions, since this has to happen synchronously
            // (otherwise the plugins could send presence messages while the question is still displayed)
            if([[NSAlert alertWithMessageText:AILocalizedString(@"Invisible Status Not Supported by Server","Invisible Status Not Supported by Server")
                             defaultButton:AILocalizedString(@"Disconnect","Disconnect")
                           alternateButton:AILocalizedString(@"Continue","Continue")
                               otherButton:nil
                 informativeTextWithFormat:AILocalizedString(@"The server %@ does not support invisiblity. Disconnect?","The server %@ does not support invisiblity. Disconnect?"),[connection getServiceName]] runModal] == NSAlertDefaultReturn)
                [self disconnect];
            else
                // change status to available
                [[adium statusController] applyState:[AIStatus statusOfType:AIAvailableStatusType] toAccounts:[NSArray arrayWithObject:self]];
                // this should trigger sending setStatusState:usingStatusMessage: again
            return;
        } else {
            [connection sendPacket:[SmackCocoaAdapter invisibleCommandForInvisibility:YES]];
            currentlyInvisible = YES;
        }
    } else if(currentlyInvisible) { // become visible again
        [connection sendPacket:[SmackCocoaAdapter invisibleCommandForInvisibility:NO]];
        currentlyInvisible = NO;
    }
    
    SmackPresence *packet = [self getUserPresenceForStatusState:statusState usingStatusMessage:statusMessage];
    // let others add stuff to this presence packet
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPPresenceSentNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
    [connection sendPacket:packet];
}

- (BOOL)currentlyInvisible
{
    return currentlyInvisible;
}

- (void)broadcastCurrentPresence
{
    [self setStatusState:[self statusState] usingStatusMessage:[self statusMessage]];
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
                    host = [[[NSString alloc] initWithBytes:dname length:(dname[dname_length-1] == '.')?dname_length-1:dname_length encoding:NSASCIIStringEncoding] autorelease];
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

- (BOOL)supportsOfflineMessaging {
	return YES;
}

- (BOOL)allowsNewlinesInMessages {
	return YES;
}

/*- (BOOL)supportsFolderTransfer {
	return NO;
}*/

// dynamic properties
- (void)updateStatusForKey:(NSString *)key
{
    NSLog(@"udpateStatusForKey:%@",key);
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPUpdateStatusNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:key forKey:SmackXMPPStatusKey]];
    [super updateStatusForKey:key];
}

#pragma mark Status

- (NSSet *)supportedPropertyKeys {
	static	NSMutableSet	*supportedPropertyKeys = nil;
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"Online",
			@"FormattedUID",
			KEY_ACCOUNT_DISPLAY_NAME,
			@"Display Name",
			@"StatusState",
			KEY_USE_USER_ICON,
			@"Enabled",
            @"TextProfile",
            @"DefaultUserIconFilename",
            KEY_ACCOUNT_CHECK_MAIL,
			nil];
        [supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
    
	return supportedPropertyKeys;
}

#pragma mark Messaging, Chatting, Strings

- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact {
    return NO;
}

- (BOOL)openChat:(AIChat *)chat {
    [[adium interfaceController] openChat:chat];
    return YES;
}

- (BOOL)closeChat:(AIChat *)chat {
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
    NSEnumerator *e = [objects objectEnumerator];
    AIListContact *contact;
    SmackRoster *smroster = [connection getRoster];

    NSString *groupname = [group displayName];
    
    while((contact = [e nextObject]))
        [SmackCocoaAdapter createRosterEntryInRoster:smroster withJID:[contact UID] name:[contact ownDisplayName] group:groupname];
}

- (void)removeContacts:(NSArray *)objects {
    NSEnumerator *e = [objects objectEnumerator];
    AIListContact *contact;
    SmackRoster *smroster = [connection getRoster];
    
    while((contact = [e nextObject]))
    {
        SmackRosterEntry *entry = [smroster getEntry:[contact UID]];
        if(entry)
            [smroster removeEntry:entry];
        [contact setRemoteGroupName:nil];
    }
}

- (void)deleteGroup:(AIListGroup *)group {
    // as soon as there are no users in a group, the group ceases to exist
    // so we don't have to do anything here (afaik Adium removes all people from that group first)
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group {
    NSEnumerator *e = [objects objectEnumerator];
    AIListContact *contact;
    SmackRoster *smroster = [connection getRoster];
    
    SmackRosterGroup *newgroup = [smroster getGroup:[group displayName]];
    if(!newgroup) // if it doesn't exist, create it
        newgroup = [smroster createGroup:[group displayName]];
    
    while((contact = [e nextObject]))
    {
        NSString *oldgroup = [[contact parentGroup] displayName];
        SmackRosterEntry *rosterentry = [smroster getEntry:[contact UID]];
        
        JavaIterator *iter = [rosterentry getGroups];
        
        // remove entry from group if it actually belonged to the group
        while([iter hasNext])
        {
            SmackRosterGroup *rostergroup = [iter next];
            if([[rostergroup getName] isEqualToString:oldgroup]) {
                [rostergroup removeEntry:rosterentry];
                break;
            }
        }
        // add it to the new group, even when it wasn't in the old one before
        // Note that this whole thing might behave strangely if someone is in multiple groups,
        // since Adium doesn't handle that case at all!
        
        [newgroup addEntry:rosterentry];
    }
}

- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName {
    [[[connection getRoster] getGroup:[group displayName]] setName:newName];
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    NSMutableArray *menuItems = [NSMutableArray array];
    
    // order is important here, so we can't use the NSNotification-system
    NSEnumerator *e = [plugins objectEnumerator];
    id plugin;
    while((plugin = [e nextObject]))
        if([plugin respondsToSelector:@selector(menuItemsForContact:)])
        {
            NSArray *pluginMenuItems = [plugin menuItemsForContact:inContact];
            if(pluginMenuItems)
                [menuItems addObjectsFromArray:pluginMenuItems];
        }
    
    [menuItems addObjectsFromArray:[super menuItemsForContact:inContact]];
    return menuItems;
}

- (NSArray *)accountActionMenuItems {
    NSMutableArray *menuItems = [NSMutableArray array];
    
    // order is important here, so we can't use the NSNotification-system
    NSEnumerator *e = [plugins objectEnumerator];
    id plugin;
    while((plugin = [e nextObject]))
        if([plugin respondsToSelector:@selector(accountActionMenuItems)])
        {
            NSArray *pluginMenuItems = [plugin accountActionMenuItems];
            if(pluginMenuItems)
                [menuItems addObjectsFromArray:pluginMenuItems];
        }

    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Change Account Details...","Change Account Details...") action:@selector(changeAccountDetails:) keyEquivalent:@""];
    [mitem setTarget:self];
    [menuItems addObject:mitem];
    [mitem release];
    
    [menuItems addObjectsFromArray:[super accountActionMenuItems]];
    
    return menuItems;
}

- (void)changeAccountDetails:(id)sender
{
    [[[SmackXMPPRegistration alloc] initWithAccount:self registerWith:[[self explicitFormattedUID] jidHost]] autorelease];
}

#pragma mark Secure messsaging

- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	return [super allowSecureMessagingTogglingForChat:inChat];
}

- (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict didAuthorize:(BOOL)inDidAuthorize {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:inDidAuthorize?@"subscribed":@"unsubscribed"];
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
	[listContact notifyOfChangedStatusSilently:NO];
	
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

@end
