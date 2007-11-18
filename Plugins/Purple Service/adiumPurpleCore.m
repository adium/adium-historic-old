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

#import "adiumPurpleCore.h"

#import "adiumPurpleAccounts.h"
#import "adiumPurpleBlist.h"
#import "adiumPurpleConnection.h"
#import "adiumPurpleConversation.h"
#import "adiumPurpleDnsRequest.h"
#import "adiumPurpleEventloop.h"
#import "adiumPurpleFt.h"
#import "adiumPurpleNotify.h"
#import "adiumPurplePrivacy.h"
#import "adiumPurpleRequest.h"
#import "adiumPurpleRoomlist.h"
#import "adiumPurpleSignals.h"
#import "adiumPurpleWebcam.h"
#import "adiumPurpleCertificateTrustWarning.h"

#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import "AILibpurplePlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>

#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
#if (PURPLE_DEBUG)
static void adiumPurpleDebugPrint(PurpleDebugLevel level, const char *category, const char *debug_msg)
{
	//Log error
	if (!category) category = "general"; //Category can be nil
	AILog(@"(Libpurple: %s) %s",category, debug_msg);
}

static PurpleDebugUiOps adiumPurpleDebugOps = {
    adiumPurpleDebugPrint
};

PurpleDebugUiOps *adium_purple_debug_get_ui_ops(void)
{
	return &adiumPurpleDebugOps;
}
#endif

// Core ------------------------------------------------------------------------------------------------------

extern gboolean purple_init_ssl_plugin(void);
extern gboolean purple_init_ssl_openssl_plugin(void);
extern gboolean purple_init_ssl_cdsa_plugin(void);
extern gboolean purple_init_gg_plugin(void);
extern gboolean purple_init_jabber_plugin(void);
extern gboolean purple_init_sametime_plugin(void);
extern gboolean purple_init_msn_plugin(void);
extern gboolean purple_init_myspace_plugin(void);
extern gboolean purple_init_novell_plugin(void);
extern gboolean purple_init_qq_plugin(void);
extern gboolean purple_init_simple_plugin(void);
extern gboolean purple_init_yahoo_plugin(void);
extern gboolean purple_init_zephyr_plugin(void);
extern gboolean purple_init_aim_plugin(void);
extern gboolean purple_init_icq_plugin(void);

static void init_all_plugins()
{
	AILog(@"adiumPurpleCore: load_all_plugins()");

	//First, initialize our built-in plugins
	purple_init_ssl_plugin();
#ifndef HAVE_CDSA
    purple_init_ssl_openssl_plugin();
#else
	purple_init_ssl_cdsa_plugin();
#endif

	//Load each plugin
	NSEnumerator			*enumerator = [[SLPurpleCocoaAdapter libpurplePluginArray] objectEnumerator];
	id <AILibpurplePlugin>	plugin;

	while ((plugin = [enumerator nextObject])) {
		if ([plugin respondsToSelector:@selector(installLibpurplePlugin)]) {
			[plugin installLibpurplePlugin];
		}
	}
#ifdef HAVE_CDSA
	{
		PurplePlugin *cdsa_plugin = purple_plugins_find_with_name("CDSA");
		if(cdsa_plugin) {
			gboolean ok = NO;
			purple_plugin_ipc_call(cdsa_plugin, "register_certificate_ui_cb", &ok, adium_query_cert_chain);
		}
	}
#endif
}

static void load_external_plugins(void)
{
	//Load each plugin
	NSEnumerator			*enumerator = [[SLPurpleCocoaAdapter libpurplePluginArray] objectEnumerator];
	id <AILibpurplePlugin>	plugin;
	
	while ((plugin = [enumerator nextObject])) {
		if ([plugin respondsToSelector:@selector(loadLibpurplePlugin)]) {
			[plugin loadLibpurplePlugin];
		}
	}	
}

static void adiumPurplePrefsInit(void)
{
    //Disable purple away handling - we do it ourselves
	purple_prefs_set_bool("/purple/away/away_when_idle", FALSE);
	purple_prefs_set_string("/purple/away/auto_reply","never");

	//Disable purple idle reporting - we do it ourselves
	purple_prefs_set_bool("/purple/away/report_idle", FALSE);

    //Disable purple conversation logging
    purple_prefs_set_bool("/purple/logging/log_chats", FALSE);
    purple_prefs_set_bool("/purple/logging/log_ims", FALSE);

    //Typing preference
    purple_prefs_set_bool("/purple/conversations/im/send_typing", TRUE);
	
	//Use server alias where possible
	purple_prefs_set_bool("/purple/buddies/use_server_alias", TRUE);

	//Ensure we are using caching
	purple_buddy_icons_set_caching(TRUE);	
}

static void adiumPurpleCoreDebugInit(void)
{
#if (PURPLE_DEBUG)
	AILog(@"adiumPurpleCoreDebugInit()");
    purple_debug_set_ui_ops(adium_purple_debug_get_ui_ops());
#endif
	
	//Initialize all plugins. This could be done in STATIC_PROTO_INIT in libpurple's config.h at build time, but doing it here allows easier changes.
	init_all_plugins();
}

/* The core is ready... finish configuring libpurple and its plugins */
static void adiumPurpleCoreUiInit(void)
{		
	AILog(@"adiumPurpleCoreUiInit");
	//Initialize the core UI ops
    purple_blist_set_ui_ops(adium_purple_blist_get_ui_ops());
    purple_connections_set_ui_ops(adium_purple_connection_get_ui_ops());
    purple_privacy_set_ui_ops (adium_purple_privacy_get_ui_ops());	
	purple_accounts_set_ui_ops(adium_purple_accounts_get_ui_ops());

	/* Why use Purple's accounts and blist list when we have the information locally?
		*		- Faster account connection: Purple doesn't have to recreate the local list
		*		- Privacy/blocking support depends on the accounts and blist files existing
		*
		*	Another possible advantage:
		*		- Using Purple's own buddy icon caching (which depends on both files) allows us to avoid
		*			re-requesting icons we already have locally on some protocols such as AIM.
		*/	
	//Setup the buddy list; then load the blist.
	purple_set_blist(purple_blist_new());
	AILog(@"adiumPurpleCore: purple_blist_load()...");
	purple_blist_load();
	
	//Configure signals for receiving purple events
	configureAdiumPurpleSignals();
	
	//Configure the GUI-related UI ops last
	purple_roomlist_set_ui_ops (adium_purple_roomlist_get_ui_ops());
    purple_notify_set_ui_ops(adium_purple_notify_get_ui_ops());
    purple_request_set_ui_ops(adium_purple_request_get_ui_ops());
	purple_xfers_set_ui_ops(adium_purple_xfers_get_ui_ops());
	purple_dnsquery_set_ui_ops(adium_purple_dns_request_get_ui_ops());
	
	adiumPurpleConversation_init();

#if	ENABLE_WEBCAM
	initPurpleWebcamSupport();
#endif
	
	load_external_plugins();
}

static void adiumPurpleCoreQuit(void)
{
    AILog(@"Core quit");
    exit(0);
}

static PurpleCoreUiOps adiumPurpleCoreOps = {
    adiumPurplePrefsInit,
    adiumPurpleCoreDebugInit,
    adiumPurpleCoreUiInit,
    adiumPurpleCoreQuit
};

PurpleCoreUiOps *adium_purple_core_get_ops(void)
{
	return &adiumPurpleCoreOps;
}
