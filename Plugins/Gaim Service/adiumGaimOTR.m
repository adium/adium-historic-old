//
//  adiumGaimOTR.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimOTR.h"

/* OTR headers */
#import <Libgaim/ui.h>
#import <Libgaim/dialogs.h>

#pragma mark Adium convenience functions

//Return the ConnContext for a GaimConversation, or NULL if none exists
static ConnContext* context_for_conv(GaimConversation *conv)
{
    GaimAccount *account;
    char *username;
    const char *accountname, *proto;
    ConnContext *context;
	
    /* Do nothing if this isn't an IM conversation */
    if (gaim_conversation_get_type(conv) != GAIM_CONV_IM) return;
	
    account = gaim_conversation_get_account(conv);
    accountname = gaim_account_get_username(account);
    proto = gaim_account_get_protocol_id(account);
    username = g_strdup(
						gaim_normalize(account, gaim_conversation_get_name(conv)));
	
    context = otrl_context_find(username, accountname, proto, 0, NULL,
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
	
    /*
	 secondary = g_strdup_printf("Fingerprint for %s:\n%s\n\n"
								 "Secure id for this session:\n"
								 "<span %s>%s</span> <span %s>%s</span>", context->username,
								 fingerprint,
								 dir == SESS_DIR_LOW ? "weight=\"bold\"" : "", sess1,
								 dir == SESS_DIR_HIGH ? "weight=\"bold\"" : "", sess2);
	 */
	
	securityDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:fingerprint], @"Fingerprint",
		[NSString stringWithUTF8String:((dir == SESS_DIR_LOW) ? sess1 : sess2)], @"Incoming SessionID",
		[NSString stringWithUTF8String:((dir == SESS_DIR_HIGH) ? sess2 : sess1)], @"Outgoing SessionID",
		nil];
	
	return(securityDetailsDict);
}

#pragma mark Dialogs

/* This is just like gaim_notify_message, except: (a) it doesn't grab
 * keyboard focus, (b) the button is "OK" instead of "Close", and (c)
 * the labels aren't limited to 2K. */
static void otrg_adium_dialog_notify_message(GaimNotifyMsgType type,
										   const char *title, const char *primary, const char *secondary)
{
	//Just pass it to gaim_notify_message()
	gaim_notify_message(adium_gaim_get_handle(), type, title, primary, secondary, NULL, NULL);
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
static void otrg_adium_dialog_unknown_fingerprint(const char *who,
												const char *protocol, OTRKeyExchangeMsg kem,
												void (*response_cb)(OtrlMessageAppOps *ops, void *opdata,
																	OTRConfirmResponse *response_data, int resp),
												OtrlMessageAppOps *ops, void *opdata,
												OTRConfirmResponse *response_data)
{
    char hash[45];
    NSString *label_text;
//    struct ufcbdata *cbd = malloc(sizeof(struct ufcbdata));
    GaimPlugin *p = gaim_find_prpl(protocol);
    
    otrl_privkey_hash_to_human(hash, kem->key_fingerprint);
    label_text = [NSString stringWithFormat:@"%s (%s) has presented us with an unknown fingerprint:\n\n%s\n\nDo you want to accept this fingerprint as valid?", 
		who, (p && p->info->name) ? p->info->name : "Unknown", hash];
	
//    label = adium_label_new(NULL);

	GaimDebug(@"otrg_adium_dialog_unknown_fingerprint label_text is %@",label_text);
	
	if ((NSRunAlertPanel(@"Unknown OTR fingerprint",label_text,@"Yes",@"No",nil)) == NSAlertDefaultReturn){
		response_cb(ops, opdata, response_data, 1);
	}else{
		response_cb(ops, opdata, response_data, 0);		
	}
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
	GaimDebug (@"otrg_adium_ui_update_fingerprint");
}

/* Update the keylist, if it's visible */
static void otrg_adium_ui_update_keylist(void)
{
	GaimDebug (@"otrg_adium_ui_update_keylist");
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

static OtrgUiUiOps otrg_adium_ui_ui_ops = {
    otrg_adium_ui_update_fingerprint,
    otrg_adium_ui_update_keylist
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