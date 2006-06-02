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

#import <JavaVM/NSJavaVirtualMachine.h>

#import <dns_sd.h> // for SRV lookup
#import "ruli/ruli_parse.h"

@interface NSString (JIDAdditions)

- (NSString*)jidUsername;
- (NSString*)jidHost;
- (NSString*)jidResource;
- (NSString*)jidUserHost;

@end

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
    if(!chatdata) {
        chatdata = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(removeChat:)
                                                     name:Chat_WillClose
                                                   object:nil];
    } else
        [chatdata removeAllObjects];
}

- (void)dealloc {
    [chatdata release];
    chatdata = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)removeChat:(NSNotification*)n {
    [chatdata removeObjectForKey:[[n object] uniqueChatID]];
}

- (AIListContact *)contactWithJID:(NSString *)inJID
{
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
            [chatdata setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                thread?thread:[chat uniqueChatID], @"thread",
                                resource, @"resource", // might be nil!
                                nil] forKey:[chat uniqueChatID]];
        }
        
        SmackXXHTMLExtension *spe = [packet getExtension:@"html" :@"http://jabber.org/protocol/xhtml-im"];
        if(spe) {
            JavaIterator *iter = [spe getBodies];
            NSString *htmlmsg = nil;
            if(iter && [iter hasNext])
                htmlmsg = [iter next];
            if([htmlmsg length] > 0)
                inMessage = [[NSAttributedString alloc] initWithHTML:[htmlmsg dataUsingEncoding:NSUnicodeStringEncoding] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnicodeStringEncoding] forKey:NSCharacterEncodingDocumentOption] documentAttributes:NULL];
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
    NSString *jid = [packet getFrom];
    NSString *type = [[packet getType] toString];
    NSString *status = [packet getStatus];
    NSString *mode = [[packet getMode] toString];
    
    AIListContact *listContact = [self contactWithJID:[jid jidUserHost]];
    AIStatusType statustype = AIOfflineStatusType;
    
    if([type isEqualToString:@"available"]) {
        if(!mode || [mode isEqualToString:@"available"] || [mode isEqualToString:@"chat"])
            statustype = AIAvailableStatusType;
        else if([mode isEqualToString:@"invisible"])
            statustype = AIInvisibleStatusType;
        else
            statustype = AIAwayStatusType;
    } else if([type isEqualToString:@"unavailable"])
        statustype = AIOfflineStatusType;
    else if([type isEqualToString:@"subscribe"]) {
        // ###
        return;
    } else if([type isEqualToString:@"subscribed"]) {
        // ###
        return;
    } else if([type isEqualToString:@"unsubscribe"]) {
        // ###
        return;
    } else if([type isEqualToString:@"unsubscribed"]) {
        // ###
        return;
    }
    
//    NSLog(@"jid = \"%@\", mode = \"%@\", statustype = \"%d\"", jid, mode, statustype);
	[listContact setOnline:statustype != AIOfflineStatusType
                    notify:NotifyLater
                  silently:silentAndDelayed];
    
    [listContact setStatusWithName:mode statusType:statustype notify:NotifyLater];
    if(status) {
        NSAttributedString *statusMessage = [[NSAttributedString alloc] initWithString:status attributes:nil];
        [listContact setStatusMessage:statusMessage notify:NotifyLater];
        [statusMessage release];
    } else
        [listContact setStatusMessage:nil notify:NotifyLater];
    
    //Apply the change
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)receiveIQPacket:(SmackIQ*)packet {
    if([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.RosterPacket"]) {
        SmackRosterPacket *srp =(SmackRosterPacket*)packet;
        JavaIterator *iter = [srp getRosterItems];
        while([iter hasNext]) {
            SmackRosterPacketItem *srpi = [iter next];
            NSString *name = [srpi getName];
            NSString *jid = [srpi getUser];
            
            AIListContact *listContact = [self contactWithJID:jid];
            
            if(![[listContact formattedUID] isEqualToString:jid])
                [listContact setFormattedUID:jid notify:NotifyLater];
            
            // XMPP supports contacts that are in multiple groups, Adium does not.
            // First I'm checking if the group it's in here locally is one of the groups
            // the contact is in on the server. If this is not the case, I set the contact
            // to be in the first group on the list.
            JavaIterator *iter2 = [srpi getGroupNames];
            NSString *storedgroupname = [listContact remoteGroupName];
            if(storedgroupname) {
                while([iter2 hasNext]) {
                    NSString *groupname = [iter2 next];
                    if([storedgroupname isEqualToString:groupname])
                        break;
                }
                if(![iter2 hasNext])
                    storedgroupname = nil;
            }
            if(!storedgroupname) {
                iter2 = [srpi getGroupNames];
                if([iter2 hasNext])
                    [listContact setRemoteGroupName:[iter2 next]];
                else
                    [listContact setRemoteGroupName:@"nobody knows the trouble I've seen"];
            }
            [self setListContact:listContact toAlias:name];
        }
//    } else if([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@""]) {
        
    }
}

- (BOOL)sendMessageObject:(AIContentMessage *)inMessageObject {
    if([inMessageObject isAutoreply])
        return NO; // protocol doesn't support autoreplies
    
    AIChat *chat = [inMessageObject chat];
    NSDictionary *chatinfo = [chatdata objectForKey:[chat uniqueChatID]];
    
    if(!chatinfo) // first message was sent by us
        [chatdata setObject:chatinfo = [NSDictionary dictionaryWithObjectsAndKeys:
            [chat uniqueChatID], @"thread",
            nil] forKey:[chat uniqueChatID]];
    
    NSString *jid = [[[inMessageObject chat] listObject] UID];
    if([chatinfo objectForKey:@"resource"])
        jid = [NSString stringWithFormat:@"%@/%@",jid,[chatinfo objectForKey:@"resource"]];

    SmackMessage *newmsg = NewSmackMessage(jid,[SmackCocoaAdapter staticObjectField:@"CHAT" inJavaClass:@"org.jivesoftware.smack.packet.Message$Type"]);
    
    [newmsg setThread:[chatinfo objectForKey:@"thread"]];
    [newmsg setBody:[inMessageObject messageString]];
    // ### XHTML
    
    [connection sendPacket:newmsg];
    [newmsg release];
    return YES;
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage {
    NSString *statusName = [statusState statusName];
    NSString *statusField = nil;
    if([statusName isEqualToString:STATUS_NAME_AVAILABLE])
        statusField = @"AVAILABLE";
    else if([statusName isEqualToString:STATUS_NAME_AWAY])
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
    
    SmackPresence *newPresence = NewSmackPresence([SmackCocoaAdapter staticObjectField:@"AVAILABLE" inJavaClass:@"org.jivesoftware.smack.packet.Presence$Type"], [statusMessage string], [SmackCocoaAdapter staticObjectField:statusField inJavaClass:@"org.jivesoftware.smack.packet.Presence$Mode"]);
    
    [connection sendPacket:newPresence];
    [newPresence release];
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

NSString *decodeDNSName(const unsigned char *input, unsigned len) {
    NSMutableString *result = [NSMutableString string];
    unsigned pos = 0;
    while(input[pos] && pos < len) {
        if(pos + input[pos] > len)
            return nil; // invalid string (buffer overflow!)
        NSString *element = [[NSString alloc] initWithBytesNoCopy:(void*)&input[pos+1] length:input[pos] encoding:NSASCIIStringEncoding freeWhenDone:NO];
        [result appendFormat:@"%@.",element];
        [element release];
        pos += input[pos]+1;
    }
    return result;
}

struct SmackDNSServiceQueryRecordReplyContext {
    NSString **host;
    int *portnum;
};

static void SmackDNSServiceQueryRecordReply(
 DNSServiceRef                       DNSServiceRef,
 DNSServiceFlags                     flags,
 uint32_t                            interfaceIndex,
 DNSServiceErrorType                 errorCode,
 const char                          *fullname,
 uint16_t                            rrtype,
 uint16_t                            rrclass,
 uint16_t                            rdlen,
 const void                          *rdata,
 uint32_t                            ttl,
 void                                *context
 ) {
    struct SmackDNSServiceQueryRecordReplyContext *ctx = (struct SmackDNSServiceQueryRecordReplyContext*)context;
    ruli_srv_rdata_t srvdata;
    
    if(ruli_parse_rr_srv(&srvdata, rdata, rdlen) == RULI_PARSE_RR_OK) {
        *(ctx->host) = decodeDNSName(srvdata.target,srvdata.target_len);
        *(ctx->portnum) = srvdata.port;
    } else
        *(ctx->portnum) = -1;
}

- (SmackConnectionConfiguration*)connectionConfiguration {
    NSString *host = [self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
    int portnum = 5222;
    
    if(!host || [host length] == 0) { // did the user not supply a host?
        // do an SRV lookup
        host = [[self explicitFormattedUID] jidHost];
        char fullName[kDNSServiceMaxDomainName];
        
        DNSServiceConstructFullName(fullName,NULL,"_xmpp-client._tcp",[host cStringUsingEncoding:NSUTF8StringEncoding] /* ### punycode */);
        
        DNSServiceRef sdRef;
        struct SmackDNSServiceQueryRecordReplyContext ctx = {
            &host, &portnum
        };
        
        if(DNSServiceQueryRecord(&sdRef, 0, 0, fullName,
                                 kDNSServiceType_SRV, kDNSServiceClass_IN, SmackDNSServiceQueryRecordReply, &ctx) == kDNSServiceErr_NoError) {
            DNSServiceProcessResult(sdRef);
            DNSServiceRefDeallocate(sdRef);
            
            if(portnum==-1) {
                NSNumber *port = [self preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];
                if(!port)
                    portnum = [[self preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue]?5223:5222;
                else
                    portnum = [port intValue];
            }
        } else {
            NSNumber *port = [self preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];
            if(!port)
                portnum = [[self preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue]?5223:5222;
            else
                portnum = [port intValue];
        }
    } else {
        NSNumber *port = [self preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];
        if(!port)
            portnum = [[self preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue]?5223:5222;
        else
            portnum = [port intValue];
    }
    
    SmackConnectionConfiguration *conf = [NSClassFromString(@"org.jivesoftware.smack.ConnectionConfiguration") newWithSignature:@"(Ljava/lang/String;ILjava/lang/String;)",host,portnum,[[self explicitFormattedUID] jidHost]];
    
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
    
    return [conf autorelease];
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

@end
