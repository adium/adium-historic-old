//
//  adiumGaimOTR.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimOTR.h"

/* libotr headers */
#import <libotr/proto.h>
#import <libotr/context.h>
#import <libotr/message.h>

/* gaim-otr headers */
#import <Libgaim/ui.h>
#import <Libgaim/dialogs.h>
#import <Libgaim/otr-plugin.h>

/* Adium headers */
#import "ESGaimOTRUnknownFingerprintController.h"

#pragma mark Adium convenience functions

//Return the ConnContext for a GaimConversation, or NULL if none exists
static ConnContext* context_for_conv(GaimConversation *conv)
{
    GaimAccount *account;
    char *username;
    const char *accountname, *proto;
    ConnContext *context;
	
    /* Do nothing if this isn't an IM conversation */
    if (gaim_conversation_get_type(conv) != GAIM_CONV_IM) return nil;
	
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


/* Return an NSDictionary* describing a ConnContext.
* @"Fingerprint" : NSString of the fingerprint
* @"Incoming SessionID" : NSString of the incoming sessionID
* @"Outgoing SessionID" : NSString of the outgoing sessionID
*/
static NSDictionary* details_for_context(ConnContext *context)
{
	NSDictionary		*securityDetailsDict;
	
    char fingerprint[45];
    unsigned char *sessionid;
    char sess1[21], sess2[21];
    int i;
    SessionDirection dir = context->sesskeys[1][0].dir;
	
    /* Make a human-readable version of the fingerprint */
    otrl_privkey_hash_to_human(fingerprint,
							   context->active_fingerprint->fingerprint);

    /* Make a human-readable version of the sessionid (in two parts) */
    sessionid = context->sesskeys[1][0].sessionid;
    for(i=0;i<10;++i) sprintf(sess1+(2*i), "%02x", sessionid[i]);
    sess1[20] = '\0';
    for(i=0;i<10;++i) sprintf(sess2+(2*i), "%02x", sessionid[i+10]);
    sess2[20] = '\0';

	securityDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:fingerprint], @"Fingerprint",
		[NSString stringWithUTF8String:((dir == SESS_DIR_LOW) ? sess1 : sess2)], @"Incoming SessionID",
		[NSString stringWithUTF8String:((dir == SESS_DIR_HIGH) ? sess1 : sess2)], @"Outgoing SessionID",
		nil];
	
	return(securityDetailsDict);
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
//	if (!(gaim_conv_present_error(username, account, msg))){
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
	conv = gaim_find_conversation_with_account(username, account);
	chat = existingChatLookupFromConv(conv);
	message = [NSString stringWithUTF8String:msg];

	if(localizedMessage = [[SLGaimCocoaAdapter sharedInstance] localizedOTRMessage:message
																	  withUsername:username]){
		
		[[[AIObject sharedAdiumInstance] contentController] mainPerformSelector:@selector(displayStatusMessage:ofType:inChat:)
																	 withObject:localizedMessage
																	 withObject:@"encryption"
																	 withObject:chat
																  waitUntilDone:YES];
		return 0; /* We handled it */
	}else{
		return 1; /* Display it as a normal message */
	}
}

/* blargh? */
struct s_OtrgDialogWait {
	char	*label;
};

/* Began generating a private key.
 * Return a handle that will be passed to otrg_adium_dialog_private_key_wait_done(). */
static OtrgDialogWaitHandle otrg_adium_dialog_private_key_wait_start(const char *account,
																   const char *protocol)
{
	GaimPlugin *p;
	char *title, *primary, *secondary;
    const char *protocol_print;
	
	p = gaim_find_prpl(protocol);
    protocol_print = (p ? p->info->name : "Unknown");
	
    /* Create the Please Wait... dialog */
	title = "Generating private key";
	primary =  "Please wait";
	
    secondary = g_strdup_printf("Generating private key for %s (%s)...",
								account, protocol_print);

		/*
	adiumWidget *label;
    adiumWidget *dialog = create_dialog(GAIM_NOTIFY_MSG_INFO, title,
									  primary, secondary, 0, &label);
		 */
    OtrgDialogWaitHandle handle = malloc(sizeof(struct s_OtrgDialogWait));
	/*
    handle->dialog = dialog;
    handle->label = label;
*/
	gaim_notify_message(adium_gaim_get_handle(), GAIM_NOTIFY_MESSAGE, title, primary, secondary, NULL, NULL);
		
	g_free(secondary);
	
    return handle;
}

/* Done creating the private key */
static void otrg_adium_dialog_private_key_wait_done(OtrgDialogWaitHandle handle)
{
	gaim_notify_message(adium_gaim_get_handle(), GAIM_NOTIFY_MESSAGE, "Done", "Private key generation...", "complete.", NULL, NULL);
}

/* Show a dialog informing the user that a correspondent (who) has sent
 * us a Key Exchange Message (kem) that contains an unknown fingerprint.
 * Ask the user whether to accept the fingerprint or not.  If yes, call
 * response_cb(ops, opdata, response_data, resp) with resp = 1.  If no,
 * set resp = 0.  If the user destroys the dialog without answering, set
 * resp = -1. */
static void otrg_adium_dialog_unknown_fingerprint(OtrlUserState us, const char *accountname,
												const char *protocol, const char *who, OTRKeyExchangeMsg kem,
												void (*response_cb)(OtrlUserState us, OtrlMessageAppOps *ops,
																	void *opdata, OTRConfirmResponse *response_data, int resp),
												OtrlMessageAppOps *ops, void *opdata,
												OTRConfirmResponse *response_data)
{
    GaimPlugin			*p = gaim_find_prpl(protocol);
	NSDictionary		*responseInfo;
    char				hash[45];

	/*
	GaimAccount			*account;
	GaimConversation	*conv;
	AIChat				*chat;	
	//Find the AIChat which has an unknown fingerprint
	account = gaim_accounts_find(accountname, protocol);
	conv = gaim_find_conversation_with_account(username, account);
	chat = chatLookupFromConv(conv);
	 */

	//Get the human readable fingerprint hash
    otrl_privkey_hash_to_human(hash, kem->key_fingerprint);
	
	responseInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:hash], @"hash",
		[NSString stringWithUTF8String:who], @"who",
		((p && p->info->name) ? [NSString stringWithUTF8String:p->info->name] : @""), @"protocol",
		[NSValue valueWithPointer:response_cb], @"response_cb",
		[NSValue valueWithPointer:us], @"OtrlUserState",
		[NSValue valueWithPointer:ops], @"OtrlMessageAppOps",
		[NSValue valueWithPointer:opdata], @"opdata",
		[NSValue valueWithPointer:response_data], @"OTRConfirmResponse",
		nil];

	[ESGaimOTRUnknownFingerprintController mainPerformSelector:@selector(showUnknownFingerprintPromptWithResponseInfo:)
													withObject:responseInfo];
}

/*
 * @brief Send the fingerprint response to OTR
 *
 * Called on the gaim thread by SLGaimCocoaAdapter.
 */
void otrg_adium_unknown_fingerprint_response(NSDictionary *responseInfo, BOOL accepted)
{
	OtrlUserState us = [[responseInfo objectForKey:@"OtrlUserState"] pointerValue];
	void (*response_cb)(OtrlUserState us, OtrlMessageAppOps *ops,
						void *opdata, OTRConfirmResponse *response_data, int resp) = [[responseInfo objectForKey:@"response_cb"] pointerValue];
	OtrlMessageAppOps *ops = [[responseInfo objectForKey:@"OtrlMessageAppOps"] pointerValue];
	void *opdata = [[responseInfo objectForKey:@"opdata"] pointerValue];
	OTRConfirmResponse *response_data = [[responseInfo objectForKey:@"OTRConfirmResponse"] pointerValue];

	response_cb(us, ops, opdata, response_data, (accepted ? 1 : 0));
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
	conv = gaim_find_conversation_with_account(context->username, account);
	
	//If there is no existing conversation, make one
	if(!conv){
		conv = gaim_conversation_new(GAIM_CONV_IM, account, context->username);	
	}
	
	securityDetailsDict = details_for_context(context);

	[[SLGaimCocoaAdapter sharedInstance] gaimConversation:conv
									   setSecurityDetails:securityDetailsDict];
}

/* Call this when a context transitions from CONN_CONNECTED to
* (a state other than CONN_CONNECTED). */
static void otrg_adium_dialog_disconnected(ConnContext *context)
{
	GaimConversation	*conv;

	conv = gaim_find_conversation_with_account(context->username,
											   gaim_accounts_find(context->accountname, context->protocol));
	[[SLGaimCocoaAdapter sharedInstance] gaimConversation:conv
									   setSecurityDetails:nil];
}

/* Call this when we receive a Key Exchange message that doesn't cause
* our state to change (because it was just the keys we knew already). */
static void otrg_adium_dialog_stillconnected(ConnContext *context)
{
	GaimConversation	*conv;
	GaimAccount			*account;
	
	account = gaim_accounts_find(context->accountname, context->protocol);
	conv = gaim_find_conversation_with_account(context->username,
											   account);
	[[SLGaimCocoaAdapter sharedInstance] refreshedSecurityOfGaimConversation:conv];
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
	ConnectionState state;

	context = context_for_conv(conv);
    state = context ? context->state : CONN_UNCONNECTED;

	if(state == CONN_CONNECTED){
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
    otrg_adium_dialog_connected,
    otrg_adium_dialog_disconnected,
    otrg_adium_dialog_stillconnected,
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
/* Call this function when the DSA key is updated; it will redraw the
* UI, if visible. */
static void otrg_adium_ui_update_fingerprint(void)
{

}

/* Update the keylist, if it's visible */
static void otrg_adium_ui_update_keylist(void)
{
#if 0
    gchar *titles[4];
    char hash[45];
    ConnContext * context;
    Fingerprint * fingerprint;
    int selected_row = -1;
	
    gtkWidget *keylist = ui_layout.keylist;
	
    if (keylist == NULL)
		return;

    for (context = otrl_context_root; context != NULL;
		 context = context->next) {
		int i;
		GaimPlugin *p;
		char *proto_name;
		fingerprint = context->fingerprint_root.next;
		if (fingerprint == NULL) {
			titles[0] = context->username;
			titles[1] = (gchar *) otrl_context_statestr[context->state];
			titles[2] = "No fingerprint";
			p = gaim_find_prpl(context->protocol);
			proto_name = (p && p->info->name) ? p->info->name : "Unknown";
			titles[3] = g_strdup_printf("%s (%s)", context->accountname,
										proto_name);
			i = adium_clist_append(adium_CLIST(keylist), titles);
			g_free(titles[3]);
			adium_clist_set_row_data(adium_CLIST(keylist), i,
								   &(context->fingerprint_root));
			if (ui_layout.selected_fprint == &(context->fingerprint_root)) {
				selected_row = i;
			}
		} else {
			while(fingerprint) {
				titles[0] = context->username;
				if (context->state == CONN_CONNECTED &&
					context->active_fingerprint != fingerprint) {
					titles[1] = "Unused";
				} else {
					titles[1] =
					(gchar *) otrl_context_statestr[context->state];
				}
				otrl_privkey_hash_to_human(hash, fingerprint->fingerprint);
				titles[2] = hash;
				p = gaim_find_prpl(context->protocol);
				proto_name = (p && p->info->name) ? p->info->name : "Unknown";
				titles[3] = g_strdup_printf("%s (%s)", context->accountname,
											proto_name);
				i = adium_clist_append(adium_CLIST(keylist), titles);
				g_free(titles[3]);
				adium_clist_set_row_data(adium_CLIST(keylist), i, fingerprint);
				if (ui_layout.selected_fprint == fingerprint) {
					selected_row = i;
				}
				fingerprint = fingerprint->next;
			}
		}
    }
#endif
}

static void otrg_adium_ui_config_buddy(GaimBuddy *buddy)
{
	/* This is for configuring the otr UI for a buddy.  We don't need it. */	
}

static OtrlPolicy otrg_adium_ui_find_policy(GaimAccount *account, const char *name)
{
	GaimBuddy					*buddy = gaim_find_buddy(account, name);
	AIListContact				*contact = contactLookupFromBuddy(buddy);
	NSNumber					*policyNumber;

	policyNumber = [ESGaimOTRAdapter mainPerformSelector:@selector(policyForContact:)
											  withObject:contact
											 returnValue:YES];
	
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
	if(gaim_conversation_get_type(conv) == GAIM_CONV_IM){ 
		otrg_plugin_send_default_query_conv(conv);
	}		
}

void adium_gaim_otr_disconnect_conv(GaimConversation *conv)
{
	ConnContext	*context;

	/* Do nothing if this isn't an IM conversation */
	if((gaim_conversation_get_type(conv) == GAIM_CONV_IM) &&
	   (context = context_for_conv(conv))){
		   otrg_ui_disconnect_connection(context);
	}
}

#pragma mark Initial setup
void initGaimOTRSupprt(void)
{
	//Init the plugin
	gaim_init_otr_plugin();
	
	//Set the UI Ops
	otrg_ui_set_ui_ops(otrg_adium_ui_get_ui_ops());

    otrg_dialog_set_ui_ops(otrg_adium_dialog_get_ui_ops());
}

@implementation ESGaimOTRAdapter

/*
 * @brief Return the OtrlPolicy for a contact as the intValue of an NSNumber
 *
 * Look to the contact's preference, then to its account's preference, then fall back on OPPORTUNISTIC as a default
 */
+ (NSNumber *)policyForContact:(AIListContact *)contact
{
	NSNumber					*prefNumber;
	AIEncryptedChatPreference	pref;
	OtrlPolicy					policy;
	
	//Get the contact's preference (or its containing group, or so on)
	prefNumber = [contact preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
								   group:GROUP_ENCRYPTION];
	if(!prefNumber || ([prefNumber intValue] == EncryptedChat_Default)){
		//If no contact preference or the contact is set to use the default, use the account preference
		prefNumber = [[contact account] preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
												   group:GROUP_ENCRYPTION];		
	}

	if(prefNumber){
		pref = [prefNumber intValue];
		
		switch(pref){
			case EncryptedChat_Never:
				policy = OTRL_POLICY_NEVER;
				break;
			case EncryptedChat_Manually:
			case EncryptedChat_Default:
				policy = OTRL_POLICY_MANUAL;
				break;
			case EncryptedChat_Automatically:
				policy = OTRL_POLICY_OPPORTUNISTIC;
				break;
			case EncryptedChat_RejectUnencryptedMessages:
				policy = OTRL_POLICY_ALWAYS;
				break;
		}
	}else{
		policy = OTRL_POLICY_MANUAL;
	}
	
	return [NSNumber numberWithInt:policy];	
}

@end