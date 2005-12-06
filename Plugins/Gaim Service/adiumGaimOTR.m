/* 
* Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "adiumGaimOTR.h"
#import "AIContentController.h"
#import "AIPreferenceController.h"
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIObjectAdditions.h>

#import "gaimOTRCommon.h"

/* Adium OTR headers */
#import "ESGaimOTRUnknownFingerprintController.h"
#import "ESGaimOTRPrivateKeyGenerationWindowController.h"
#import "ESGaimOTRPreferences.h"

static NSMutableDictionary	*otrPolicyCache = nil;

#define CLOSED_CONNECTION_MESSAGE "has closed his private connection to you"

/* OTRL_POLICY_MANUAL doesn't let us respond to other users' automatic attempts at encryption.
 * If either user has OTR set to Automatic, an OTR session should be begun; without this modified
 * mask, both users would have to be on automatic for OTR to begin automatically, even though one user
 * _manually_ attempting OTR will _automatically_ bring the other into OTR even if the setting is Manual.
 */
#define OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE	( OTRL_POLICY_MANUAL | \
													  OTRL_POLICY_WHITESPACE_START_AKE | \
													  OTRL_POLICY_ERROR_START_AKE )
@interface ESGaimOTRAdapter (PRIVATE)
- (NSString *)localizedOTRMessage:(NSString *)message withUsername:(const char *)username;
- (void)prefsShouldUpdatePrivateKeyList;
- (void)prefsShouldUpdateFingerprintsList;
- (void)verifyUnknownFingerprint:(NSValue *)contextValue;
- (NSNumber *)determinePolicyForContact:(AIListContact *)contact;
@end

#pragma mark Adium convenience functions

static ESGaimOTRAdapter* getOTRAdapter()
{
	static ESGaimOTRAdapter		*otrAdapter = nil;

	if (!otrAdapter) {
		/* Create the OTR adapter on the main thread, since it registers as a preference observer and 
		 * creates a preference pane, and the Adium core does not waste cycles thread safing these processes.
		 */
		otrAdapter = [[ESGaimOTRAdapter alloc] mainPerformSelector:@selector(init)
													   returnValue:YES];		
	}
	
	return otrAdapter;
}

//Return the ConnContext for a GaimConversation, or NULL if none exists
static ConnContext* context_for_conv(GaimConversation *conv)
{
    GaimAccount *account;
    char *username;
    const char *accountname, *proto;
    ConnContext *context;
	
    /* Do nothing if this isn't an IM conversation */
    if (gaim_conversation_get_type(conv) != GAIM_CONV_TYPE_IM) return nil;
	
    account = gaim_conversation_get_account(conv);
    accountname = gaim_account_get_username(account);
    proto = gaim_account_get_protocol_id(account);
    username = g_strdup(
						gaim_normalize(account, gaim_conversation_get_name(conv)));
	
    context = otrl_context_find(otrg_plugin_userstate,
								username, accountname, proto, 0, NULL,
								NULL, NULL);
	g_free(username);
	
	return context;
}


/* 
 * @brief Return an NSDictionary* describing a ConnContext.
 *
 *      Key				 :        Contents
 * @"Fingerprint"		 : NSString of the fingerprint's human-readable hash
 * @"Incoming SessionID" : NSString of the incoming sessionID
 * @"Outgoing SessionID" : NSString of the outgoing sessionID
 * @"EncryptionStatus"	 : An AIEncryptionStatus
 * @"accountname"		 : The local account of this context
 * @"who"				 : The UID of the remote user
 * @"protocol"			 : The name of the Gaim prpl of this context
 *
 * @result The dictinoary
 */
static NSDictionary* details_for_context(ConnContext *context)
{
	NSDictionary		*securityDetailsDict;
	if (context == NULL) {
		NSLog(@"Ack! (%x)",context);
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
	
	securityDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:hash], @"Fingerprint",
		[NSNumber numberWithInt:encryptionStatus], @"EncryptionStatus",
		[NSString stringWithUTF8String:context->accountname], @"accountname",
		[NSString stringWithUTF8String:context->username], @"who",
		((context->protocol) ? [NSString stringWithUTF8String:context->protocol] : @""), @"protocol",
		[NSString stringWithUTF8String:our_hash], @"Outgoing SessionID",
		[NSString stringWithUTF8String:their_hash], @"Incoming SessionID",
		nil];
	
	return securityDetailsDict;
}

#pragma mark Dialogs

/* This is just like gaim_notify_message, except: (a) it doesn't grab
* keyboard focus, (b) the button is "OK" instead of "Close", and (c)
* the labels aren't limited to 2K. */
static void otrg_adium_dialog_notify_message(GaimNotifyMsgType type, 
											 const char *accountname, const char *protocol, const char *username,
											 const char *title, const char *primary, const char *secondary)
{
	//	GaimAccount	*account = gaim_accounts_find(accountname, protocol);
	
	AILog(@"otrg_adium_dialog_notify_message: %s ; %s",primary, secondary);
	
	//XXX todo: search on ops->notify in message.c in libotr and handle the error messages
	//	if (!(gaim_conv_present_error(username, account, msg))) {
	//Just pass it to gaim_notify_message()
	gaim_notify_message(adium_gaim_get_handle(), type, title, primary, secondary, NULL, NULL);		
	//	}
}

//Return 0 if we handled dislaying the message; non-0 if it should be displayed as a normal message
static int otrg_adium_dialog_display_otr_message(const char *accountname, const char *protocol,
												 const char *username, const char *msg)
{
	GaimAccount			*account;
	GaimConversation	*conv;
	AIChat				*chat;
	NSString			*message;
	NSString			*localizedMessage;
	
	//Find the GaimAccount and existing conversation which was just connected
	account = gaim_accounts_find(accountname, protocol);
	conv = gaim_find_conversation_with_account(GAIM_CONV_TYPE_IM, username, account);
	chat = existingChatLookupFromConv(conv);
	message = [NSString stringWithUTF8String:msg];
	
	if ((localizedMessage = [getOTRAdapter() localizedOTRMessage:message
													withUsername:username])) {
		
		[[[AIObject sharedAdiumInstance] contentController] mainPerformSelector:@selector(displayStatusMessage:ofType:inChat:)
																	 withObject:localizedMessage
																	 withObject:@"encryption"
																	 withObject:chat
																  waitUntilDone:YES];
		return 0; /* We handled it */
	} else {
		return 1; /* Display it as a normal message */
	}
}

/* Structure passed to and from OTR in relation to the key generation dialogue */
struct s_OtrgDialogWait {
	NSString	*identifier;
};

/* Began generating a private key.
* Return a handle that will be passed to otrg_adium_dialog_private_key_wait_done(). */
static OtrgDialogWaitHandle otrg_adium_dialog_private_key_wait_start(const char *account,
																	 const char *protocol)
{
	GaimPlugin *p;
    const char *protocol_print;
	
	p = gaim_find_prpl(protocol);
    protocol_print = (p ? p->info->name : "Unknown");
	
	NSString				*identifier;
    OtrgDialogWaitHandle	handle = malloc(sizeof(struct s_OtrgDialogWait));
	
	identifier = [NSString stringWithFormat:@"%s (%s)",account, protocol_print];
    handle->identifier = [identifier retain];
	
	[ESGaimOTRPrivateKeyGenerationWindowController startedGeneratingForIdentifier:identifier];
	
    return handle;
}

/* Done creating the private key */
static void otrg_adium_dialog_private_key_wait_done(OtrgDialogWaitHandle handle)
{
	NSString	*identifier = handle->identifier;
	
	[ESGaimOTRPrivateKeyGenerationWindowController finishedGeneratingForIdentifier:identifier];
	
	[identifier release];
	handle->identifier = NULL;
}

/* Show a dialog informing the user that a correspondent (who) has sent
 * us a Key Exchange Message (kem) that contains an unknown fingerprint.
 * Ask the user whether to accept the fingerprint or not.
 */
static void otrg_adium_dialog_unknown_fingerprint(OtrlUserState us, const char *accountname,
												  const char *protocol, const char *who,
												  unsigned char fingerprint[20])

{
	ConnContext			*context;
	
	context = otrl_context_find(us, who, accountname,
								protocol, 0, NULL, NULL, NULL);
	
	if (context == NULL/* || context->msgstate != OTRL_MSGSTATE_ENCRYPTED*/) {
		NSLog(@"otrg_adium_dialog_unknown_fingerprint: Ack!");
		return;
	}
	
	[getOTRAdapter() performSelector:@selector(verifyUnknownFingerprint:)
						  withObject:[NSValue valueWithPointer:context]
						  afterDelay:0];
}

static void otrg_adium_dialog_verify_fingerprint(Fingerprint *fprint)
{
	adium_gaim_verify_fingerprint_for_context(fprint->context);
}

/* Call this when a context transitions from (a state other than
* CONN_CONNECTED) to CONN_CONNECTED. */
static void otrg_adium_dialog_connected(ConnContext *context)
{
	NSDictionary		*securityDetailsDict;
	GaimAccount			*account;
	GaimConversation	*conv;
	
	//Find the GaimAccount and existing conversation which was just connected
	account = gaim_accounts_find(context->accountname, context->protocol);
	conv = gaim_find_conversation_with_account(GAIM_CONV_TYPE_IM, context->username, account);
	
	//If there is no existing conversation, make one
	if (!conv) {
		conv = gaim_conversation_new(GAIM_CONV_TYPE_IM, account, context->username);	
	}
	
	if (conv) {
		securityDetailsDict = details_for_context(context);
		
		[[SLGaimCocoaAdapter sharedInstance] gaimConversation:conv
										   setSecurityDetails:securityDetailsDict];
	}
}

/* Call this when a context transitions from CONN_CONNECTED to
* (a state other than CONN_CONNECTED). */
static void otrg_adium_dialog_disconnected(ConnContext *context)
{
	GaimConversation	*conv;
	
	conv = gaim_find_conversation_with_account(GAIM_CONV_TYPE_IM,
											   context->username,
											   gaim_accounts_find(context->accountname, context->protocol));
	if (conv) {
		[[SLGaimCocoaAdapter sharedInstance] gaimConversation:conv
										   setSecurityDetails:nil];
	}
}

/* Call this when we receive a Key Exchange message that doesn't cause
* our state to change (because it was just the keys we knew already). */
static void otrg_adium_dialog_stillconnected(ConnContext *context)
{
	GaimConversation	*conv;
	GaimAccount			*account;
	
	account = gaim_accounts_find(context->accountname, context->protocol);
	conv = gaim_find_conversation_with_account(GAIM_CONV_TYPE_IM,
											   context->username,
											   account);
	[[SLGaimCocoaAdapter sharedInstance] refreshedSecurityOfGaimConversation:conv];
}

static void otrg_adium_dialog_finished(const char *accountname,
									   const char *protocol, const char *username)
{
	otrg_adium_dialog_display_otr_message(accountname, protocol, username, CLOSED_CONNECTION_MESSAGE);
}

/* Set all OTR buttons to "sensitive" or "insensitive" as appropriate.
* Call this when accounts are logged in or out. */
static void otrg_adium_dialog_resensitize_all(void)
{
	
}

/* When a conversation is created, check to see if it is already connected */
static void otrg_adium_dialog_new_conv(GaimConversation *conv)
{
	ConnContext		*context;
	TrustLevel		trustLevel;
	
	context = context_for_conv(conv);
	trustLevel = otrg_plugin_context_to_trust(context);
	
	if (trustLevel != TRUST_NOT_PRIVATE) {
		NSDictionary	*securityDetailsDict;
		
		securityDetailsDict = details_for_context(context);
		
		[[SLGaimCocoaAdapter sharedInstance] gaimConversation:conv
										   setSecurityDetails:securityDetailsDict];
	}
}

/* Called before Gaim destroys a conversation */
static void otrg_adium_dialog_remove_conv(GaimConversation *conv)
{
	
}

static OtrgDialogUiOps otrg_adium_dialog_ui_ops = {
    otrg_adium_dialog_notify_message,
	otrg_adium_dialog_display_otr_message,
    otrg_adium_dialog_private_key_wait_start,
    otrg_adium_dialog_private_key_wait_done,
    otrg_adium_dialog_unknown_fingerprint,
	otrg_adium_dialog_verify_fingerprint,
    otrg_adium_dialog_connected,
    otrg_adium_dialog_disconnected,
    otrg_adium_dialog_stillconnected,
	otrg_adium_dialog_finished,
    otrg_adium_dialog_resensitize_all,
    otrg_adium_dialog_new_conv,
    otrg_adium_dialog_remove_conv
};

/* Get the adium dialog UI ops */
OtrgDialogUiOps *otrg_adium_dialog_get_ui_ops(void)
{
    return &otrg_adium_dialog_ui_ops;
}

#pragma mark UI (Preferences)
/*
 * @brief Call this function when the DSA key is updated; it will redraw the UI, if visible.
 *
 * Note that OTR calls this the "fingerprint" in this context, but it is more properly called the private key list
 */
static void otrg_adium_ui_update_fingerprint(void)
{
	AILog(@"OTR: Should update fingerprint");
	[getOTRAdapter() prefsShouldUpdatePrivateKeyList];
}

/*
 * @brief Update the keylist, if it's visible
 *
 * Note that the 'keylist' is the list of fingerprints, which we call the fingerprints list for clarity.
 */
static void otrg_adium_ui_update_keylist(void)
{
	[getOTRAdapter() prefsShouldUpdateFingerprintsList];
}

static void otrg_adium_ui_config_buddy(GaimBuddy *buddy)
{
	/* This is for displaying the buddy-specific OTR configuration.  We don't need it as the Adium Get Info window
	* handles the relevant preferences. */
}

static OtrlPolicy otrg_adium_ui_find_policy(GaimAccount *account, const char *name)
{
	GaimBuddy					*buddy = gaim_find_buddy(account, name);
	AIListContact				*contact = contactLookupFromBuddy(buddy);
	NSNumber					*policyNumber;
	
	//First try to use our cache
	policyNumber = [otrPolicyCache objectForKey:[contact internalObjectID]];
	if (!policyNumber) {
		//If a policy isn't cached, look it up
		policyNumber = [getOTRAdapter() mainPerformSelector:@selector(determinePolicyForContact:)
												 withObject:contact
												returnValue:YES];
	}
	
	return [policyNumber intValue];
}

static OtrgUiUiOps otrg_adium_ui_ui_ops = {
    otrg_adium_ui_update_fingerprint,
    otrg_adium_ui_update_keylist,
	otrg_adium_ui_config_buddy,
	otrg_adium_ui_find_policy
};

/* Get the Adium UI ops */
OtrgUiUiOps *otrg_adium_ui_get_ui_ops(void)
{
    return &otrg_adium_ui_ui_ops;
}

#pragma mark Connecting/Disconnecting
void adium_gaim_otr_connect_conv(GaimConversation *conv)
{
	/* Do nothing if this isn't an IM conversation */
	if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_IM) { 
		otrg_plugin_send_default_query_conv(conv);
	}
}

void adium_gaim_otr_disconnect_conv(GaimConversation *conv)
{
	ConnContext	*context;
	
	/* Do nothing if this isn't an IM conversation */
	if ((gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_IM) &&
		(context = context_for_conv(conv))) {
		otrg_ui_disconnect_connection(context);
	}
}

void adium_gaim_verify_fingerprint_for_context(ConnContext *context)
{
	NSDictionary		*responseInfo;
	
	responseInfo = details_for_context(context);
	
	[ESGaimOTRUnknownFingerprintController mainPerformSelector:@selector(showVerifyFingerprintPromptWithResponseInfo:)
													withObject:responseInfo];	
}

void adium_gaim_verify_fingerprint_for_conv(GaimConversation *conv)
{
	ConnContext	*context;
	
	/* Do nothing if this isn't an IM conversation */
	if ((gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_IM) &&
		(context = context_for_conv(conv))) {
		adium_gaim_verify_fingerprint_for_context(context);
	}	
}

#pragma mark Initial setup
gboolean gaim_init_otr_plugin(void);
void initGaimOTRSupprt(void)
{
	//Init the plugin
	gaim_init_otr_plugin();

	//Set the UI Ops
	otrg_ui_set_ui_ops(otrg_adium_ui_get_ui_ops());
	
    otrg_dialog_set_ui_ops(otrg_adium_dialog_get_ui_ops());
}

@implementation ESGaimOTRAdapter

- (id)init
{
	if ((self = [super init])) {
		[[adium preferenceController] registerPreferenceObserver:self
														forGroup:GROUP_ENCRYPTION];
		
		OTRPrefs = [[ESGaimOTRPreferences preferencePane] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[OTRPrefs release];
	
	[super dealloc];
}

- (void)verifyUnknownFingerprint:(NSValue *)contextValue
{
	NSDictionary		*responseInfo;
	
	responseInfo = details_for_context([contextValue pointerValue]);
	
	[ESGaimOTRUnknownFingerprintController mainPerformSelector:@selector(showUnknownFingerprintPromptWithResponseInfo:)
													withObject:responseInfo];	
}

/*!
* @brief Preferences changed
 *
 * Clear our policy cache.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!key || [key isEqualToString:KEY_ENCRYPTED_CHAT_PREFERENCE]) {
		[otrPolicyCache release]; otrPolicyCache = [[NSMutableDictionary alloc] init];
	}
}

/*!
* @brief Return the OtrlPolicy for a contact as the intValue of an NSNumber
 *
 * Look to the contact's preference, then to its account's preference, then fall back on OPPORTUNISTIC as a default.
 * Cache the result in our otrPolicyCache NSMutableDictionary.
 */
- (NSNumber *)determinePolicyForContact:(AIListContact *)contact
{
	OtrlPolicy	policy = OTRL_POLICY_MANUAL_AND_REPOND_TO_WHITESPACE;
	NSNumber	*policyNumber;
	NSString	*contactInternalObjectID;
	
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
	
	policyNumber = [NSNumber numberWithInt:policy];
	
	if ((contactInternalObjectID = [contact internalObjectID])) {
		[otrPolicyCache setObject:policyNumber
						   forKey:contactInternalObjectID];
	}
	
	return policyNumber;	
}

/*
 * @brief The preferences should update the private key.
 *
 * OTR 
 */
- (void)prefsShouldUpdatePrivateKeyList
{
	AILog(@"Should update private key list");
	[OTRPrefs performSelectorOnMainThread:@selector(updatePrivateKeyList)
							   withObject:nil
							waitUntilDone:NO];
}

/*
 * @brief The preferences should update the key list.
 */
- (void)prefsShouldUpdateFingerprintsList
{
	AILog(@"Should update fingerprints list");
	[OTRPrefs performSelectorOnMainThread:@selector(updateFingerprintsList)
							   withObject:nil
							waitUntilDone:NO];
}

- (NSString *)localizedOTRMessage:(NSString *)message withUsername:(const char *)username
{
	NSString	*localizedOTRMessage = nil;
	
	if (([message rangeOfString:@"You sent unencrypted data to"].location != NSNotFound) &&
		([message rangeOfString:@"who was expecting encrypted messages"].location != NSNotFound)) {
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"You sent an unencrypted message, but %s was expecting encryption.", "Message when sending unencrypted messages to a contact expecting encrypted ones. %s will be a name."),
			username];
	} else if ([message rangeOfString:@CLOSED_CONNECTION_MESSAGE].location != NSNotFound) {
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"%s is no longer using encryption; you should cancel encryption on your side.", "Message when the remote contact cancels his half of an encrypted conversation. %s will be a name."),
			username];
	}
	
	return localizedOTRMessage;
}


@end
