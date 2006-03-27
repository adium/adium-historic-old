//
//  AdiumOTREncryption.m
//  Adium
//
//  Created by Evan Schoenberg on 12/28/05.
//

#import "AdiumOTREncryption.h"
#import <Adium/AIContentMessage.h>
#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AILoginController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIService.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIHTMLDecoder.h>

#import <AIUtilities/AIStringAdditions.h>

#import "ESOTRPrivateKeyGenerationWindowController.h"
#import "ESOTRPreferences.h"
#import "ESOTRUnknownFingerprintController.h"
#import "OTRCommon.h"

#define PRIVKEY_PATH [[[[[AIObject sharedAdiumInstance] loginController] userDirectory] stringByAppendingPathComponent:@"otr.private_key"] UTF8String]
#define STORE_PATH	 [[[[[AIObject sharedAdiumInstance] loginController] userDirectory] stringByAppendingPathComponent:@"otr.fingerprints"] UTF8String]

#define CLOSED_CONNECTION_MESSAGE "has closed his private connection to you"

/* OTRL_POLICY_MANUAL doesn't let us respond to other users' automatic attempts at encryption.
* If either user has OTR set to Automatic, an OTR session should be begun; without this modified
* mask, both users would have to be on automatic for OTR to begin automatically, even though one user
* _manually_ attempting OTR will _automatically_ bring the other into OTR even if the setting is Manual.
*/
#define OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE	( OTRL_POLICY_MANUAL | \
													  OTRL_POLICY_WHITESPACE_START_AKE | \
													  OTRL_POLICY_ERROR_START_AKE )

@interface AdiumOTREncryption (PRIVATE)
- (void)setSecurityDetails:(NSDictionary *)securityDetailsDict forChat:(AIChat *)inChat;
- (NSString *)localizedOTRMessage:(NSString *)message withUsername:(NSString *)username;
- (void)notifyWithTitle:(NSString *)title primary:(NSString *)primary secondary:(NSString *)secondary;

- (void)upgradeOTRFromGaimIfNeeded;
@end

@implementation AdiumOTREncryption

/* We'll only use the one OtrlUserState. */
static OtrlUserState otrg_plugin_userstate = NULL;
static AdiumOTREncryption	*adiumOTREncryption = nil;

void otrg_ui_update_fingerprint(void);
void update_security_details_for_chat(AIChat *chat);
void send_default_query_to_chat(AIChat *inChat);
void disconnect_from_chat(AIChat *inChat);
void disconnect_from_context(ConnContext *context);
TrustLevel otrg_plugin_context_to_trust(ConnContext *context);

- (id)init
{
	//Singleton
	if (adiumOTREncryption) {
		[self release];
		
		return [adiumOTREncryption retain];
	}

	if ((self = [super init])) {
		adiumOTREncryption = self;

		/* Initialize the OTR library */
		OTRL_INIT;

		/*
		gaim_signal_connect(conn_handle, "signed-on", otrg_plugin_handle,
							GAIM_CALLBACK(process_connection_change), NULL);
		gaim_signal_connect(conn_handle, "signed-off", otrg_plugin_handle,
							GAIM_CALLBACK(process_connection_change), NULL);		
		 */
	}
	
	return self;
}

- (void)controllerDidLoad
{
	[self upgradeOTRFromGaimIfNeeded];

	/* Make our OtrlUserState; we'll only use the one. */
	otrg_plugin_userstate = otrl_userstate_create();

	int err;
	
	err = otrl_privkey_read(otrg_plugin_userstate, PRIVKEY_PATH);
	if (err) {
		const char *errMsg = gpg_strerror(err);
		
		if (errMsg && strcmp(errMsg, "No such file or directory")) {
			NSLog(@"Error reading %s: %s", PRIVKEY_PATH, errMsg);
		}
	}

	otrg_ui_update_keylist();

	err = otrl_privkey_read_fingerprints(otrg_plugin_userstate, STORE_PATH,
								   NULL, NULL);
	if (err) {
		const char *errMsg = gpg_strerror(err);
		
		if (errMsg && strcmp(errMsg, "No such file or directory")) {
			NSLog(@"Error reading %s: %s", STORE_PATH, errMsg);
		}
	}

	otrg_ui_update_fingerprint();
	
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumWillTerminate:)
									   name:Adium_WillTerminate
									 object:nil];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateSecurityDetails:) 
									   name:Chat_SourceChanged
									 object:nil];
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateSecurityDetails:) 
									   name:Chat_DestinationChanged
									 object:nil];
	
	//Add the Encryption preferences
	OTRPrefs = [[ESOTRPreferences preferencePane] retain];
}

- (void)dealloc
{
	[OTRPrefs release];
	
	[super dealloc];
}


#pragma mark -

/* 
* @brief Return an NSDictionary* describing a ConnContext.
 *
 *      Key				 :        Contents
 * @"Fingerprint"		 : NSString of the fingerprint's human-readable hash
 * @"Incoming SessionID" : NSString of the incoming sessionID
 * @"Outgoing SessionID" : NSString of the outgoing sessionID
 * @"EncryptionStatus"	 : An AIEncryptionStatus
 * @"AIAccount"			 : The AIAccount of this context
 * @"who"				 : The UID of the remote user *
 * @result The dictinoary
 */
static NSDictionary* details_for_context(ConnContext *context)
{
	NSDictionary		*securityDetailsDict;
	if (context == NULL) {
		return nil;
	}
	
	Fingerprint *fprint = context->active_fingerprint;
	
	unsigned char *fingerprint;
	char our_hash[45], their_hash[45];
	
    if (fprint == NULL) return nil;
    if (fprint->fingerprint == NULL) return nil;
    context = fprint->context;
    if (context == NULL) return nil;
	
	fingerprint = fprint->fingerprint;
	
    TrustLevel			level = otrg_plugin_context_to_trust(context);
	AIEncryptionStatus	encryptionStatus;
	AIAccount			*account;
	
	switch (level) {
		default:
	    case TRUST_NOT_PRIVATE:
			encryptionStatus = EncryptionStatus_None;
			break;
		case TRUST_UNVERIFIED:
			encryptionStatus = EncryptionStatus_Unverified;
			break;
		case TRUST_PRIVATE:
			encryptionStatus = EncryptionStatus_Verified;
			break;
		case TRUST_FINISHED:
			encryptionStatus = EncryptionStatus_Finished;
			break;
	}
	
    otrl_privkey_fingerprint(otrg_plugin_userstate, our_hash,
							 context->accountname, context->protocol);
	
    otrl_privkey_hash_to_human(their_hash, fprint->fingerprint);
	
	char hash[45];
    otrl_privkey_hash_to_human(hash, fingerprint);
	
	account = [[[AIObject sharedAdiumInstance] accountController] accountWithInternalObjectID:[NSString stringWithUTF8String:context->accountname]];

	securityDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:hash], @"Fingerprint",
		[NSNumber numberWithInt:encryptionStatus], @"EncryptionStatus",
		account, @"AIAccount",
		[NSString stringWithUTF8String:context->username], @"who",
		[NSString stringWithUTF8String:our_hash], @"Outgoing SessionID",
		[NSString stringWithUTF8String:their_hash], @"Incoming SessionID",
		nil];
	
	AILog(@"Security details: %@",securityDetailsDict);
	
	return securityDetailsDict;
}


static AIAccount* accountFromAccountID(const char *accountID)
{
	return [[[AIObject sharedAdiumInstance] accountController] accountWithInternalObjectID:[NSString stringWithUTF8String:accountID]];
}

static AIService* serviceFromServiceID(const char *serviceID)
{
	return [[[AIObject sharedAdiumInstance] accountController] serviceWithUniqueID:[NSString stringWithUTF8String:serviceID]];
}

static AIListContact* contactFromInfo(const char *accountID, const char *serviceID, const char *username)
{
	return [[[AIObject sharedAdiumInstance] contactController] contactWithService:serviceFromServiceID(serviceID)
																		  account:accountFromAccountID(accountID)
																			  UID:[NSString stringWithUTF8String:username]];
}
static AIListContact* contactForContext(ConnContext *context)
{
	return contactFromInfo(context->accountname, context->protocol, context->username);
}

static AIChat* chatForContext(ConnContext *context)
{
	AIListContact *listContact = contactForContext(context);
	AIChat *chat = [[[AIObject sharedAdiumInstance] chatController] existingChatWithContact:listContact];
	if (!chat) {
		chat = [[[AIObject sharedAdiumInstance] chatController] chatWithContact:listContact];
	}
	
	return chat;
}


static OtrlPolicy policyForContact(AIListContact *contact)
{
	OtrlPolicy		policy = OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE;
	
	//Force OTRL_POLICY_MANUAL when interacting with mobile numbers
	if ([[contact UID] characterAtIndex:0] == '+') {
		policy = OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE;
		
	} else {
		NSNumber					*prefNumber;
		AIEncryptedChatPreference	pref;
		
		//Get the contact's preference (or its containing group, or so on)
		prefNumber = [contact preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
										 group:GROUP_ENCRYPTION];
		if (!prefNumber || ([prefNumber intValue] == EncryptedChat_Default)) {
			//If no contact preference or the contact is set to use the default, use the account preference
			prefNumber = [[contact account] preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
													   group:GROUP_ENCRYPTION];		
		}
		
		if (prefNumber) {
			pref = [prefNumber intValue];
			
			switch (pref) {
				case EncryptedChat_Never:
					policy = OTRL_POLICY_NEVER;
					break;
				case EncryptedChat_Manually:
				case EncryptedChat_Default:
					policy = OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE;
					break;
				case EncryptedChat_Automatically:
					policy = OTRL_POLICY_OPPORTUNISTIC;
					break;
				case EncryptedChat_RejectUnencryptedMessages:
					policy = OTRL_POLICY_ALWAYS;
					break;
			}
		} else {
			policy = OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE;
		}
	}
	
	return policy;
	
}

//Return the ConnContext for a Conversation, or NULL if none exists
static ConnContext* contextForChat(AIChat *chat)
{
	AIAccount	*account;
    const char *username, *accountname, *proto;
    ConnContext *context;
	
    /* Do nothing if this isn't an IM conversation */
    if ([chat isGroupChat]) return nil;
	
    account = [chat account];
	accountname = [[account internalObjectID] UTF8String];
	proto = [[[account service] serviceCodeUniqueID] UTF8String];
    username = [[[chat listObject] UID] UTF8String];
	
    context = otrl_context_find(otrg_plugin_userstate,
								username, accountname, proto, 0, NULL,
								NULL, NULL);
	
	return context;
}

/* What level of trust do we have in the privacy of this ConnContext? */
TrustLevel otrg_plugin_context_to_trust(ConnContext *context)
{
    TrustLevel level = TRUST_NOT_PRIVATE;
	
    if (context && context->msgstate == OTRL_MSGSTATE_ENCRYPTED) {
		if (context->active_fingerprint->trust &&
			context->active_fingerprint->trust[0] != '\0') {
			level = TRUST_PRIVATE;
		} else {
			level = TRUST_UNVERIFIED;
		}
    } else if (context && context->msgstate == OTRL_MSGSTATE_FINISHED) {
		level = TRUST_FINISHED;
    }
	
    return level;
}

#pragma mark -

static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
	return policyForContact(contactForContext(context));	
}

/* Generate a private key for the given accountname/protocol */
void otrg_plugin_create_privkey(const char *accountname,
								const char *protocol)
{	
	AIAccount	*account = accountFromAccountID(accountname);
	AIService	*service = serviceFromServiceID(protocol);
	
	NSString	*identifier = [NSString stringWithFormat:@"%@ (%@)",[account formattedUID], [service shortDescription]];
	
	[ESOTRPrivateKeyGenerationWindowController startedGeneratingForIdentifier:identifier];
	
    /* Generate the key */
    otrl_privkey_generate(otrg_plugin_userstate, PRIVKEY_PATH,
						  accountname, protocol);
    otrg_ui_update_keylist();
	
    /* Mark the dialog as done. */
	[ESOTRPrivateKeyGenerationWindowController finishedGeneratingForIdentifier:identifier];
}

static void create_privkey_cb(void *opdata, const char *accountname,
							  const char *protocol)
{
	otrg_plugin_create_privkey(accountname, protocol);
}

static int is_logged_in_cb(void *opdata, const char *accountname,
						   const char *protocol, const char *recipient)
{
	return ([contactFromInfo(accountname, protocol, recipient) online]);
}

static void inject_message_cb(void *opdata, const char *accountname,
							  const char *protocol, const char *recipient, const char *message)
{	
	[[[AIObject sharedAdiumInstance] contentController] sendRawMessage:[NSString stringWithUTF8String:message]
															 toContact:contactFromInfo(accountname, protocol, recipient)];
}

/*
 * @brief Display an OTR message
 *
 * This should be displayed within the relevant chat.
 *
 * @result 0 if we handled displaying the message; 1 if we could not
 */
static int display_otr_message(const char *accountname, const char *protocol,
							   const char *username, const char *msg)
{
	NSString		 *message;
	AIAdium			 *sharedAdium = [AIObject sharedAdiumInstance];
	AIListContact	 *listContact = contactFromInfo(accountname, protocol, username);
	AIChat			 *chat;
	AIContentMessage *messageObject;
	
	if (!(chat = [[sharedAdium chatController] existingChatWithContact:listContact])) {
		chat = [[sharedAdium chatController] chatWithContact:listContact];
	}
	
	//If we can't get a chat for some reason, we can't handle displayed this error message, so return 1
	if (!chat) return 1;

	message = [NSString stringWithUTF8String:msg];
	
	if (([message rangeOfString:@"The following message received from"].location != NSNotFound) &&
		([message rangeOfString:@"was not encrypted:"].location != NSNotFound)) {
		/*
		 * If we receive an unencrypted message, display it as a normal incoming message with the bolded warning that
		 * the message was not encrypted
		 */		
		NSRange			startRange = [message rangeOfString:@"The following message received from"];
		NSRange			endRange = [message rangeOfString:@"was not encrypted:"];
		NSMutableString *mutableMessage = [[message mutableCopy] autorelease];
		
		[mutableMessage replaceCharactersInRange:NSMakeRange(startRange.location, NSMaxRange(endRange) - startRange.location)
									  withString:[adiumOTREncryption localizedOTRMessage:@"The following message was not encrypted:"
																			withUsername:nil]];
		
		message = mutableMessage;

		messageObject = [AIContentMessage messageInChat:chat
											 withSource:listContact
											destination:[chat account]
												   date:nil
												message:[AIHTMLDecoder decodeHTML:message]
											  autoreply:NO];
		
		[[sharedAdium contentController] receiveContentObject:messageObject];
		
	} else {
		NSString	*formattedUID = [listContact formattedUID];

		//All other OTR messages should be displayed as status messages; decode the message to strip any HTML
		message = [adiumOTREncryption localizedOTRMessage:message
											 withUsername:formattedUID];
		[[sharedAdium contentController] displayStatusMessage:[[AIHTMLDecoder decodeHTML:message] string]
													   ofType:@"encryption"
													   inChat:chat];
	}
	
	//We handled it
	return 0;
}

static void notify_cb(void *opdata, OtrlNotifyLevel level,
					  const char *accountname, const char *protocol, const char *username,
					  const char *title, const char *primary, const char *secondary)
{
	AIListContact	*listContact = contactFromInfo(accountname, protocol, username);
	NSString		*formattedUID = [listContact formattedUID];

	[adiumOTREncryption notifyWithTitle:[adiumOTREncryption localizedOTRMessage:[NSString stringWithUTF8String:title]
																   withUsername:formattedUID]
								primary:[adiumOTREncryption localizedOTRMessage:[NSString stringWithUTF8String:primary]
																   withUsername:formattedUID]
							  secondary:[adiumOTREncryption localizedOTRMessage:[NSString stringWithUTF8String:secondary]
																   withUsername:formattedUID]];
}

static int display_otr_message_cb(void *opdata, const char *accountname,
								  const char *protocol, const char *username, const char *msg)
{
	return display_otr_message(accountname, protocol, username, msg);
}

static void update_context_list_cb(void *opdata)
{
	otrg_ui_update_keylist();
}

static const char *protocol_name_cb(void *opdata, const char *protocol)
{
	return [[serviceFromServiceID(protocol) shortDescription] UTF8String];
}

static void protocol_name_free_cb(void *opdata, const char *protocol_name)
{
    /* Do nothing, since we didn't actually allocate any memory in
	* protocol_name_cb. */
}

static void confirm_fingerprint_cb(void *opdata, OtrlUserState us,
								   const char *accountname, const char *protocol, const char *username,
								   unsigned char fingerprint[20])
{
	ConnContext			*context;
	
	context = otrl_context_find(us, username, accountname,
								protocol, 0, NULL, NULL, NULL);
	
	if (context == NULL/* || context->msgstate != OTRL_MSGSTATE_ENCRYPTED*/) {
		NSLog(@"otrg_adium_dialog_unknown_fingerprint: Ack!");
		return;
	}
	
	[adiumOTREncryption performSelector:@selector(verifyUnknownFingerprint:)
							 withObject:[NSValue valueWithPointer:context]
							 afterDelay:0];
}

static void write_fingerprints_cb(void *opdata)
{
	otrg_plugin_write_fingerprints();
}

static void gone_secure_cb(void *opdata, ConnContext *context)
{
	AIChat *chat = chatForContext(context);

    update_security_details_for_chat(chat);
	otrg_ui_update_fingerprint();
}

static void gone_insecure_cb(void *opdata, ConnContext *context)
{
	AIChat *chat = chatForContext(context);

    update_security_details_for_chat(chat);
	otrg_ui_update_fingerprint();
}

static void still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
    if (is_reply == 0) {
		//		otrg_dialog_stillconnected(context);
		AILog(@"Still secure...");
    }
}

static void log_message_cb(void *opdata, const char *message)
{
    AILog([NSString stringWithFormat:@"otr: %s", (message ? message : "(null)")]);
}

static OtrlMessageAppOps ui_ops = {
    policy_cb,
    create_privkey_cb,
    is_logged_in_cb,
    inject_message_cb,
    notify_cb,
    display_otr_message_cb,
    update_context_list_cb,
    protocol_name_cb,
    protocol_name_free_cb,
    confirm_fingerprint_cb,
    write_fingerprints_cb,
    gone_secure_cb,
    gone_insecure_cb,
    still_secure_cb,
    log_message_cb
};

#pragma mark -

- (void)willSendContentMessage:(AIContentMessage *)inContentMessage
{
	const char	*originalMessage = [[inContentMessage encodedMessage] UTF8String];
	AIAccount	*account = (AIAccount *)[inContentMessage source];
    const char	*accountname = [[account internalObjectID] UTF8String];
    const char	*protocol = [[[account service] serviceCodeUniqueID] UTF8String];
    const char	*username = [[[inContentMessage destination] UID] UTF8String];
	char		*newMessage = NULL;

    gcry_error_t err;
	
    if (!username || !originalMessage)
		return;

    err = otrl_message_sending(otrg_plugin_userstate, &ui_ops, /* opData */ NULL,
							   accountname, protocol, username, originalMessage, /* tlvs */ NULL, &newMessage,
							   /* add_appdata cb */NULL, /* appdata */ NULL);

    if (err && newMessage == NULL) {
		//Be *sure* not to send out plaintext
		[inContentMessage setEncodedMessage:nil];

    } else if (newMessage) {
		//This new message is what should be sent to the remote contact
		[inContentMessage setEncodedMessage:[NSString stringWithUTF8String:newMessage]];

		//We're now done with newMessage
		otrl_message_free(newMessage);
    }
}

- (NSString *)decryptIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	NSString	*decryptedMessage = nil;
	const char *message = [inString UTF8String];
	char *newMessage = NULL;
    OtrlTLV *tlvs = NULL;
    OtrlTLV *tlv = NULL;
	const char *username = [[inListContact UID] UTF8String];
    const char *accountname = [[inAccount internalObjectID] UTF8String];
    const char *protocol = [[[inAccount service] serviceCodeUniqueID] UTF8String];
	BOOL	res;

	/* If newMessage is set to non-NULL and res is 0, use newMessage.
	 * If newMessage is set to non-NULL and res is not 0, display nothing as this was an OTR message
	 * If newMessage is set to NULL and res is 0, use message
	 */
    res = otrl_message_receiving(otrg_plugin_userstate, &ui_ops, NULL,
								 accountname, protocol, username, message,
								 &newMessage, &tlvs, NULL, NULL);
	
	if (!newMessage && !res) {
		//Use the original mesage; this was not an OTR-related message
		decryptedMessage = inString;
	} else if (newMessage && !res) {
		//We decryped an OTR-encrypted message
		decryptedMessage = [NSString stringWithUTF8String:newMessage];

	} else /* (newMessage && res) */{
		//This was an OTR protocol message
		decryptedMessage = nil;
	}

    tlv = otrl_tlv_find(tlvs, OTRL_TLV_DISCONNECTED);
    if (tlv) {
		/* Notify the user that the other side disconnected. */
		display_otr_message(accountname, protocol, username, CLOSED_CONNECTION_MESSAGE);

		otrg_ui_update_keylist();
    }

    otrl_tlv_free(tlvs);
	
	return decryptedMessage;
}

- (void)requestSecureOTRMessaging:(BOOL)inSecureMessaging inChat:(AIChat *)inChat
{
	if (inSecureMessaging) {
		send_default_query_to_chat(inChat);

	} else {
		disconnect_from_chat(inChat);
	}
}

- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	ConnContext		*context = contextForChat(inChat);
	NSDictionary	*responseInfo = details_for_context(context);;

	[ESOTRUnknownFingerprintController showVerifyFingerprintPromptWithResponseInfo:responseInfo];	
}

/*
 * @brief Adium will begin terminating
 *
 * Send the OTRL_TLV_DISCONNECTED packets when we're about to quit before we disconnect
 */
- (void)adiumWillTerminate:(NSNotification *)inNotification
{
	ConnContext *context = otrg_plugin_userstate->context_root;
	while(context) {
		ConnContext *next = context->next;
		if (context->msgstate == OTRL_MSGSTATE_ENCRYPTED &&
			context->protocol_version > 1) {
			disconnect_from_context(context);
		}
		context = next;
	}
}

/*
 * @brief A chat notification was posted after which we should update our security details
 *
 * @param inNotification A notification whose object is the AIChat in question
 */
- (void)updateSecurityDetails:(NSNotification *)inNotification
{
	update_security_details_for_chat([inNotification object]);
}

void update_security_details_for_chat(AIChat *inChat)
{
	ConnContext *context = contextForChat(inChat);

	[adiumOTREncryption setSecurityDetails:details_for_context(context)
								   forChat:inChat];
}

- (void)setSecurityDetails:(NSDictionary *)securityDetailsDict forChat:(AIChat *)inChat
{
	if (inChat) {
		NSMutableDictionary	*fullSecurityDetailsDict;
		
		if (securityDetailsDict) {
			NSString				*format, *description;
			fullSecurityDetailsDict = [[securityDetailsDict mutableCopy] autorelease];
			
			/* Encrypted by Off-the-Record Messaging
				*
				* Fingerprint for TekJew:
				* <Fingerprint>
				*
				* Secure ID for this session:
				* Incoming: <Incoming SessionID>
				* Outgoing: <Outgoing SessionID>
				*/
			format = [@"%@\n\n" stringByAppendingString:AILocalizedString(@"Fingerprint for %@:","Fingerprint for <name>:")];
			format = [format stringByAppendingString:@"\n%@\n\n%@\n%@ %@\n%@ %@"];
			
			description = [NSString stringWithFormat:format,
				AILocalizedString(@"Encrypted by Off-the-Record Messaging",nil),
				[[inChat listObject] formattedUID],
				[securityDetailsDict objectForKey:@"Fingerprint"],
				AILocalizedString(@"Secure ID for this session:",nil),
				AILocalizedString(@"Incoming:",nil),
				[securityDetailsDict objectForKey:@"Incoming SessionID"],
				AILocalizedString(@"Outgoing:",nil),
				[securityDetailsDict objectForKey:@"Outgoing SessionID"],
				nil];
			
			[fullSecurityDetailsDict setObject:description
										forKey:@"Description"];
		} else {
			fullSecurityDetailsDict = nil;	
		}
		
		[inChat setSecurityDetails:fullSecurityDetailsDict];
	}
}	

#pragma mark -

void send_default_query_to_chat(AIChat *inChat)
{
	//Note that we pass a name for display, not internal usage
	char *msg = otrl_proto_default_query_msg([[[inChat account] formattedUID] UTF8String],
											 policyForContact([inChat listObject]));
	
	[[[AIObject sharedAdiumInstance] contentController] sendRawMessage:[NSString stringWithUTF8String:(msg ? msg : "?OTRv2?")]
															 toContact:[inChat listObject]];
}

/* Disconnect a context, sending a notice to the other side, if
* appropriate. */
void disconnect_from_context(ConnContext *context)
{
    otrl_message_disconnect(otrg_plugin_userstate, &ui_ops, NULL,
							context->accountname, context->protocol, context->username);
	gone_insecure_cb(NULL, context);
}

void disconnect_from_chat(AIChat *inChat)
{
	disconnect_from_context(contextForChat(inChat));
}

#pragma mark -

/* Forget a fingerprint */
void otrg_ui_forget_fingerprint(Fingerprint *fingerprint)
{
    ConnContext *context;

    /* Don't do anything with the active fingerprint if we're in the
	 * ENCRYPTED state. */
    context = (fingerprint ? fingerprint->context : NULL);
    if (context && (context->msgstate == OTRL_MSGSTATE_ENCRYPTED &&
					context->active_fingerprint == fingerprint)) return;
	
    otrl_context_forget_fingerprint(fingerprint, 1);
    otrg_plugin_write_fingerprints();
}

void otrg_plugin_write_fingerprints(void)
{
    otrl_privkey_write_fingerprints(otrg_plugin_userstate, STORE_PATH);
	otrg_ui_update_fingerprint();
}

void otrg_ui_update_keylist(void)
{
	[adiumOTREncryption prefsShouldUpdatePrivateKeyList];
}

void otrg_ui_update_fingerprint(void)
{
	[adiumOTREncryption prefsShouldUpdateFingerprintsList];
}

OtrlUserState otrg_get_userstate(void)
{
	return otrg_plugin_userstate;
}

#pragma mark -

- (void)verifyUnknownFingerprint:(NSValue *)contextValue
{
	NSDictionary		*responseInfo;
	
	responseInfo = details_for_context([contextValue pointerValue]);
	
	[ESOTRUnknownFingerprintController showUnknownFingerprintPromptWithResponseInfo:responseInfo];
}

/*
 * @brief Call this function when our DSA key is updated; it will redraw the Encryption preferences item, if visible.
 */
- (void)prefsShouldUpdatePrivateKeyList
{
	[OTRPrefs updatePrivateKeyList];
}

/*
 * @brief Update the list of other users' fingerprints, if it's visible
 */
- (void)prefsShouldUpdateFingerprintsList
{
	[OTRPrefs updateFingerprintsList];
}

#pragma mark Localization

- (NSString *)localizedOTRMessage:(NSString *)message withUsername:(NSString *)username
{
	NSString	*localizedOTRMessage = nil;
	
	if (([message rangeOfString:@"You sent unencrypted data to"].location != NSNotFound) &&
		([message rangeOfString:@"who wasn't expecting it"].location != NSNotFound)) {
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"You sent an unencrypted message, but %@ was expecting encryption.", "Message when sending unencrypted messages to a contact expecting encrypted ones. %s will be a name."),
			username];
		
	} else if ([message rangeOfString:@CLOSED_CONNECTION_MESSAGE].location != NSNotFound) {
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"%@ is no longer using encryption; you should cancel encryption on your side.", "Message when the remote contact cancels his half of an encrypted conversation. %s will be a name."),
			username];
		
	} else if ([message isEqualToString:@"Private connection closed"]) {
		localizedOTRMessage = AILocalizedString(@"Private connectiion closed", nil);

	} else if ([message rangeOfString:@"has already closed his private connection to you"].location != NSNotFound) {
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"%@'s private connection to you is closed.", "Statement that someone's private (encrypted) connection is closed."),
			username];

	} else if ([message isEqualToString:@"Your message was not sent.  Either close your private connection to him, or refresh it."]) {
		localizedOTRMessage = AILocalizedString(@"Your message was not sent. You should end the encrypted chat on your side or re-request encryption.", nil);

	} else if ([message isEqualToString:@"The following message was not encrypted:"]) {
		localizedOTRMessage = AILocalizedString(@"The following message was not encrypted:", nil);
	}
	
	return (localizedOTRMessage ? localizedOTRMessage : message);
}


- (void)notifyWithTitle:(NSString *)title primary:(NSString *)primary secondary:(NSString *)secondary
{
	//XXX todo: search on ops->notify in message.c in libotr and handle / localize the error messages
	[[adium interfaceController] handleMessage:primary
							   withDescription:secondary
							   withWindowTitle:title];
}

#pragma mark Upgrading gaim-otr --> Adium-otr
- (NSDictionary *)prplDict
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"joscar-OSCAR-AIM", @"prpl-oscar",
		@"libgaim-Gadu-Gadu", @"prpl-gg",
		@"libgaim-Jabber", @"prpl-jabber",
		@"libgaim-Sametime", @"prpl-meanwhile",
		@"libgaim-MSN", @"prpl-msn",
		@"libgaim-GroupWise", @"prpl-novell",
		@"libgaim-Yahoo!", @"prpl-yahoo",
		@"libgaim-zephyr", @"prpl-zephyr", nil];
}

- (NSString *)upgradedFingerprintsFromFile:(NSString *)inPath
{
	NSString		*sourceFingerprints = [NSString stringWithContentsOfUTF8File:inPath];
	
	if (!sourceFingerprints  || ![sourceFingerprints length]) return nil;

	NSScanner		*scanner = [NSScanner scannerWithString:sourceFingerprints];
	NSMutableString *outFingerprints = [NSMutableString string];
	NSCharacterSet	*tabAndNewlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\t\n\r"];
	
	//Skip quotes
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
	
	NSDictionary	*prplDict = [self prplDict];
	
	NSArray			*adiumAccounts = [[adium accountController] accounts];
	
	while (![scanner isAtEnd]) {
		//username     accountname  protocol      key	trusted\n
		NSString		*chunk;
		NSString		*username, *accountname, *protocol, *key, *trusted;
		
		//username
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&username];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];
		
		//accountname
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&accountname];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];
		
		//protocol
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&protocol];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];
		
		//key
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&key];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:&chunk];
		
		//We have a trusted entry
		if ([chunk isEqualToString:@"\t"]) {
			//key
			[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&trusted];
			[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];		
		} else {
			trusted = nil;
		}
		
		AIAccount		*account;
		NSEnumerator	*enumerator = [adiumAccounts objectEnumerator];
		
		while ((account = [enumerator nextObject])) {
			//Hit every possibile name for this account along the way
			if ([[NSSet setWithObjects:[account UID],[account formattedUID],[[account UID] compactedString], nil] containsObject:accountname]) {
				if ([[[account service] serviceCodeUniqueID] isEqualToString:[prplDict objectForKey:protocol]]) {
					[outFingerprints appendString:
						[NSString stringWithFormat:@"%@\t%@\t%@\t%@", username, [account internalObjectID], [[account service] serviceCodeUniqueID], key]];
					if (trusted) {
						[outFingerprints appendString:@"\t"];
						[outFingerprints appendString:trusted];
					}
					[outFingerprints appendString:@"\n"];
				}
			}
		}
	}
	
	return outFingerprints;
}

- (NSString *)upgradedPrivateKeyFromFile:(NSString *)inPath
{
	NSMutableString	*sourcePrivateKey = [[[NSString stringWithContentsOfUTF8File:inPath] mutableCopy] autorelease];
	
	if (!sourcePrivateKey || ![sourcePrivateKey length]) return nil;

	/*
	 * Gaim used the account name for the name and the prpl id for the protocol.
	 * We will use the internalObjectID for the name and the service's uniqueID for the protocol.
	 */
	
	/* Remove Jabber resources... from the private key list
	* If you used a non-default resource, no upgrade for you.
	*/
	[sourcePrivateKey replaceOccurrencesOfString:@"/Adium"
									  withString:@""
										 options:NSLiteralSearch
										   range:NSMakeRange(0, [sourcePrivateKey length])];
	
	AIAccount		*account;
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	
	NSDictionary	*prplDict = [self prplDict];
	
	while ((account = [enumerator nextObject])) {
		//Hit every possibile name for this account along the way
		NSEnumerator	*accountNameEnumerator = [[NSSet setWithObjects:[account UID],[account formattedUID],[[account UID] compactedString], nil] objectEnumerator];
		NSString		*accountName;
		NSString		*accountInternalObjectID = [NSString stringWithFormat:@"\"%@\"",[account internalObjectID]];
		
		while ((accountName = [accountNameEnumerator nextObject])) {
			NSRange			accountNameRange = NSMakeRange(0, 0);
			NSRange			searchRange = NSMakeRange(0, [sourcePrivateKey length]);
			
			while (accountNameRange.location != NSNotFound &&
				   (NSMaxRange(searchRange) <= [sourcePrivateKey length])) {
				//Find the next place this account name is located
				accountNameRange = [sourcePrivateKey rangeOfString:accountName
														   options:NSLiteralSearch
															 range:searchRange];
				
				if (accountNameRange.location != NSNotFound) {
					//Update our search range
					searchRange.location = NSMaxRange(accountNameRange);
					searchRange.length = [sourcePrivateKey length] - searchRange.location;
					
					//Make sure that this account name actually begins and finishes a name; otherwise (name TekJew2) matches (name TekJew)
					if ((![[sourcePrivateKey substringWithRange:NSMakeRange(accountNameRange.location - 6, 6)] isEqualToString:@"(name "] &&
						 ![[sourcePrivateKey substringWithRange:NSMakeRange(accountNameRange.location - 7, 7)] isEqualToString:@"(name \""]) ||
						(![[sourcePrivateKey substringWithRange:NSMakeRange(NSMaxRange(accountNameRange), 1)] isEqualToString:@")"] &&
						 ![[sourcePrivateKey substringWithRange:NSMakeRange(NSMaxRange(accountNameRange), 2)] isEqualToString:@"\")"])) {
						continue;
					}
					
					/* Within that range, find the next "(protocol " which encloses
						* a string of the form "(protocol protocol-name)"
						*/
					NSRange protocolRange = [sourcePrivateKey rangeOfString:@"(protocol "
																	options:NSLiteralSearch
																	  range:searchRange];
					if (protocolRange.location != NSNotFound) {
						//Update our search range
						searchRange.location = NSMaxRange(protocolRange);
						searchRange.length = [sourcePrivateKey length] - searchRange.location;

						NSRange nextClosingParen = [sourcePrivateKey rangeOfString:@")"
																		   options:NSLiteralSearch
																			 range:searchRange];
						NSRange protocolNameRange = NSMakeRange(NSMaxRange(protocolRange),
																nextClosingParen.location - NSMaxRange(protocolRange));
						NSString *protocolName = [sourcePrivateKey substringWithRange:protocolNameRange];
						//Remove a trailing quote if necessary
						if ([[protocolName substringFromIndex:([protocolName length]-1)] isEqualToString:@"\""]) {
							protocolName = [protocolName substringToIndex:([protocolName length]-1)];
						}
							
						NSString *uniqueServiceID = [prplDict objectForKey:protocolName];
						
						if ([[[account service] serviceCodeUniqueID] isEqualToString:uniqueServiceID]) {
							//Replace the protocol name first
							[sourcePrivateKey replaceCharactersInRange:protocolNameRange
															withString:uniqueServiceID];
							
							//Then replace the account name which was before it (so the range hasn't changed)
							[sourcePrivateKey replaceCharactersInRange:accountNameRange
															withString:accountInternalObjectID];
						}
					}
				}
			}
		}			
	}
	
	return sourcePrivateKey;
}

- (void)upgradeOTRFromGaimIfNeeded
{
	if (![[[adium preferenceController] preferenceForKey:@"GaimOTR_to_AdiumOTR_Update"
												   group:@"OTR"] boolValue]) {
		NSString	  *destinationPath = [[adium loginController] userDirectory];
		NSString	  *sourcePath = [destinationPath stringByAppendingPathComponent:@"libgaim"];
		
		NSString *privateKey = [self upgradedPrivateKeyFromFile:[sourcePath stringByAppendingPathComponent:@"otr.private_key"]];
		if (privateKey && [privateKey length]) {
			[privateKey writeToFile:[destinationPath stringByAppendingPathComponent:@"otr.private_key"]
						 atomically:NO];
		}

		NSString *fingerprints = [self upgradedFingerprintsFromFile:[sourcePath stringByAppendingPathComponent:@"otr.fingerprints"]];
		if (fingerprints && [fingerprints length]) {
			[fingerprints writeToFile:[destinationPath stringByAppendingPathComponent:@"otr.fingerprints"]
						   atomically:NO];
		}

		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:@"GaimOTR_to_AdiumOTR_Update"
											  group:@"OTR"];
	}
}

@end
