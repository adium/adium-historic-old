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
#import "AIHTMLDecoder.h"

#import "SmackXMPPRosterPlugin.h"

//#import <dns_sd.h> // for SRV lookup
#import "ruli/ruli.h"

//#define SRVDNSTimeout 2.0

static AIHTMLDecoder *messageencoder = nil;

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
        SmackXMPPRosterPlugin *rosterplugin = [[SmackXMPPRosterPlugin alloc] initWithAccount:self];
        plugins = [[NSArray alloc] initWithObjects:rosterplugin,nil];
        [rosterplugin release];
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
    
    // handle chats natively
    
    NSString *type = [[packet getType] toString];
    NSLog(@"message type %@",type);
    if([type isEqualToString:@"normal"] || [type isEqualToString:@"chat"]) {
        AIChat				*chat;
        AIContentMessage	*messageObject;
        NSAttributedString  *inMessage = nil;
        NSString *from = [packet getFrom];
        NSString *resource = [from jidResource];
        NSString *thread = [packet getThread];
        
        AIListContact *sourceContact = [self contactWithJID:[from jidUserHost]];
        
        if (!(chat = [[adium chatController] existingChatWithContact:sourceContact])) {
            chat = [[adium chatController] openChatWithContact:sourceContact];
            [chat setStatusObject:thread?thread:[chat uniqueChatID] forKey:@"XMPPThreadID" notify:NotifyLater];
            if(resource)
                [chat setStatusObject:resource forKey:@"XMPPResource" notify:NotifyLater];

            //Apply the change
            [chat notifyOfChangedStatusSilently:silentAndDelayed];
        }
        
        SmackXXHTMLExtension *spe = [packet getExtension:@"html" :@"http://jabber.org/protocol/xhtml-im"];
        if(spe) {
            JavaIterator *iter = [spe getBodies];
            NSString *htmlmsg = nil;
            if(iter && [iter hasNext])
                htmlmsg = [iter next];
            if([htmlmsg length] > 0) {
                if(!messageencoder) {
                    messageencoder = [[AIHTMLDecoder alloc] init];
                    [messageencoder setGeneratesStrictXHTML:YES];
                    [messageencoder setIncludesHeaders:NO];
                    [messageencoder setIncludesStyleTags:YES];
                    [messageencoder setEncodesNonASCII:NO];
                }
                inMessage = [[messageencoder decodeHTML:htmlmsg] retain];
            }
        }
        if(!inMessage)
            inMessage = [[NSAttributedString alloc] initWithString:[packet getBody] attributes:nil];
            
        messageObject = [AIContentMessage messageInChat:chat
                                             withSource:sourceContact
                                            destination:self
                                                   date:[NSDate date]
                                                message:inMessage
                                              autoreply:NO];
        [inMessage release];
        
        [[adium contentController] receiveContentObject:messageObject];
    }
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
    
    AIChat *chat = [inMessageObject chat];
    
    NSString *threadid = [chat statusObjectForKey:@"XMPPThreadID"];
    NSString *resource = [chat statusObjectForKey:@"XMPPResource"];
    
    if(!threadid) { // first message was sent by us
        [chat setStatusObject:threadid = [chat uniqueChatID] forKey:@"XMPPThreadID"  notify:NotifyLater];
        
        //Apply the change
        [chat notifyOfChangedStatusSilently:silentAndDelayed];
    }
    
    NSString *jid = [[[inMessageObject chat] listObject] UID];
    if(resource)
        jid = [NSString stringWithFormat:@"%@/%@",jid,resource];

    SmackMessage *newmsg = [SmackCocoaAdapter messageTo:jid typeString:@"CHAT"];
    
    [newmsg setThread:threadid];
    [newmsg setBody:[inMessageObject messageString]];
    // ### XHTML
    
    NSAttributedString *attmessage = [inMessageObject message];
    if(!messageencoder) {
        messageencoder = [[AIHTMLDecoder alloc] init];
        [messageencoder setGeneratesStrictXHTML:YES];
        [messageencoder setIncludesHeaders:NO];
        [messageencoder setIncludesStyleTags:YES];
        [messageencoder setEncodesNonASCII:NO];
    }
    
    NSString *xhtmlmessage = [messageencoder encodeHTML:attmessage imagesPath:nil];
    // for some reason I can't specify that I don't want <html> but that I do want <body>...
    NSString *xhtmlbody = [NSString stringWithFormat:@"<body xmlns='http://www.w3.org/1999/xhtml'>%@</body>",xhtmlmessage];
    
    SmackXXHTMLExtension *xhtml = [SmackCocoaAdapter XHTMLExtension];
    [xhtml addBody:xhtmlbody];
    
    [newmsg addExtension:xhtml];
    
    [connection sendPacket:newmsg];
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
    
}

- (void)removeContacts:(NSArray *)objects {
    
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
