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

#pragma mark Dialogs
/* This is just like gaim_notify_message, except: (a) it doesn't grab
* keyboard focus, (b) the button is "OK" instead of "Close", and (c)
* the labels aren't limited to 2K. */
static void otrg_adium_dialog_notify_message(GaimNotifyMsgType type,
										   const char *title, const char *primary, const char *secondary)
{
	GaimDebug (@"otrg_adium_dialog_notify_message: type %i ; title %s ; primary %s ; secondary %s", type, title, primary, secondary);
	gaim_notify_message(adium_gaim_get_handle(), type, title, primary, secondary, NULL, NULL);
}

/* blargh? */
struct s_OtrgDialogWait {
	char	*label;
};

/* Put up a Please Wait dialog, with the "OK" button desensitized.
* Return a handle that must eventually be passed to
* otrg_dialog_wait_done. */
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

/* Append the given text to the dialog, and sensitize the "OK" button. */
static void otrg_adium_dialog_private_key_wait_done(OtrgDialogWaitHandle handle)
{
	GaimDebug (@"otrg_adium_dialog_private_key_wait_done");

	gaim_notify_message(adium_gaim_get_handle(), GAIM_NOTIFY_MESSAGE, "Done", "Private key generation...", "complete.", NULL, NULL);

	/*
    const char *oldmarkup;
    char *newmarkup;
	
    oldmarkup = adium_label_get_label(GTK_LABEL(handle->label));
    newmarkup = g_strdup_printf("%s%s", oldmarkup, " Done.");
	
    gtk_label_set_markup(adium_LABEL(handle->label), newmarkup);
    gtk_widget_show(handle->label);
    gtk_dialog_set_response_sensitive(GTK_DIALOG(handle->dialog),
									  GTK_RESPONSE_ACCEPT, 1);
	
    g_free(newmarkup);
    free(handle);
	 */
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
	GaimDebug (@"otrg_adium_dialog_unknown_fingerprint: who: %s protocol: %s",who,protocol);
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
    char fingerprint[45];
    unsigned char *sessionid;
    char sess1[21], sess2[21];
    char *primary = g_strdup_printf("Private connection with %s "
									"established.", context->username);
    char *secondary;
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
    
    secondary = g_strdup_printf("Fingerprint for %s:\n%s\n\n"
								"Secure id for this session:\n"
								"<span %s>%s</span> <span %s>%s</span>", context->username,
								fingerprint,
								dir == SESS_DIR_LOW ? "weight=\"bold\"" : "", sess1,
								dir == SESS_DIR_HIGH ? "weight=\"bold\"" : "", sess2);
	
    otrg_dialog_notify_info("Private connection established",
							primary, secondary);
	
    g_free(primary);
    g_free(secondary);
 /*   dialog_update_label(context, 1); */
}

/* Call this when a context transitions from CONN_CONNECTED to
* (a state other than CONN_CONNECTED). */
static void otrg_adium_dialog_disconnected(ConnContext *context)
{
    char *primary = g_strdup_printf("Private connection with %s lost.",
									context->username);
    otrg_dialog_notify_warning("Private connection lost", primary, NULL);
    g_free(primary);
/*    dialog_update_label(context, 0); */
}

/* Call this when we receive a Key Exchange message that doesn't cause
* our state to change (because it was just the keys we knew already). */
static void otrg_adium_dialog_stillconnected(ConnContext *context)
{
    char *secondary = g_strdup_printf("<span size=\"larger\">Successfully "
									  "refreshed private connection with %s.</span>", context->username);
    otrg_dialog_notify_info("Refreshed private connection", NULL, secondary);
    g_free(secondary);
/*    dialog_update_label(context, 1); */
}

/* Set all OTR buttons to "sensitive" or "insensitive" as appropriate.
* Call this when accounts are logged in or out. */
static void otrg_adium_dialog_resensitize_all(void)
{
	GaimDebug (@"otrg_adium_dialog_resensitize_all");
 //   gaim_conversation_foreach(dialog_resensitize);
}

/* Set up the per-conversation information display */
static void otrg_adium_dialog_new_conv(GaimConversation *conv)
{
	GaimDebug (@"otrg_adium_dialog_new_conv: %s",conv->name);
#if 0
    GaimAccount *account;
    char *username;
    const char *accountname, *proto;
    ConnContext *context;
    ConnectionState state;
	
    /* Do nothing if this isn't an IM conversation */
    if (gaim_conversation_get_type(conv) != GAIM_CONV_IM) return;
	
    account = gaim_conversation_get_account(conv);
    accountname = gaim_account_get_username(account);
    proto = gaim_account_get_protocol_id(account);
    username = g_strdup(
						gaim_normalize(account, gaim_conversation_get_name(conv)));
	
    context = otrl_context_find(username, accountname, proto, 0, NULL,
								NULL, NULL);
    state = context ? context->state : CONN_UNCONNECTED;
    g_free(username);

	/* Add a clickable button, or set one up, or something, which when clicked ends up calling
		otrg_dialog_clicked_connect(conv); */
#endif
	
	/* XXX DEBUG: Immediately attempt to connect */
	//otrg_plugin_send_default_query_conv(conv);
}

/* Remove the per-conversation information display */
static void otrg_adium_dialog_remove_conv(GaimConversation *conv)
{
	GaimDebug (@"otrg_adium_dialog_remove_conv: %s",conv->name);
	/* Do nothing if this isn't an IM conversation */
    if (gaim_conversation_get_type(conv) != GAIM_CONV_IM) return;
	
	/* Remove the buttons or disable them or whatever */
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

#pragma mark Initial setup
void initGaimOTRSupprt(void)
{
	//Init the plugin
	gaim_init_otr_plugin();
	
	//Set the UI Ops
	otrg_ui_set_ui_ops(otrg_adium_ui_get_ui_ops());

    otrg_dialog_set_ui_ops(otrg_adium_dialog_get_ui_ops());
}