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

#import "adiumGaimCore.h"

#import "adiumGaimBlist.h"
#import "adiumGaimConnection.h"
#import "adiumGaimConversation.h"
#import "adiumGaimEventloop.h"
#import "adiumGaimFt.h"
#import "adiumGaimNotify.h"
#import "adiumGaimPrivacy.h"
#import "adiumGaimRequest.h"
#import "adiumGaimRoomlist.h"
#import "adiumGaimSignals.h"
#import "adiumGaimWebcam.h"

#import "SLGaimCocoaAdapter.h"
#import "AILibgaimPlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>

#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
#if (GAIM_DEBUG)
static void adiumGaimDebugPrint(GaimDebugLevel level, const char *category, const char *format, va_list args)
{
	gchar *arg_s = g_strdup_vprintf(format, args); //NSLog sometimes chokes on the passed args, so we'll use vprintf
	
	/*	AILog(@"%x: (Debug: %s) %s",[NSRunLoop currentRunLoop], category, arg_s); */
	//Log error
	if (!category) category = "general"; //Category can be nil
	
	AILog(@"(Libgaim: %s) %s",category, arg_s);
	
	g_free(arg_s);
}

static GaimDebugUiOps adiumGaimDebugOps = {
    adiumGaimDebugPrint
};

GaimDebugUiOps *adium_gaim_debug_get_ui_ops(void)
{
	return &adiumGaimDebugOps;
}
#endif

// Core ------------------------------------------------------------------------------------------------------

extern gboolean gaim_init_ssl_plugin(void);
extern gboolean gaim_init_ssl_openssl_plugin(void);
extern gboolean gaim_init_gg_plugin(void);
extern gboolean gaim_init_jabber_plugin(void);
extern gboolean gaim_init_sametime_plugin(void);
extern gboolean gaim_init_sametime_plugin(void);
extern gboolean gaim_init_msn_plugin(void);
extern gboolean gaim_init_novell_plugin(void);
extern gboolean gaim_init_msn_plugin(void);
extern gboolean gaim_init_simple_plugin(void);
extern gboolean gaim_init_yahoo_plugin(void);
extern gboolean gaim_init_zephyr_plugin(void);
#ifndef JOSCAR_SUPERCEDE_LIBGAIM
	extern gboolean gaim_init_oscar_plugin(void);
#endif

static void load_all_plugins()
{
	//First, initialize our built-in plugins
	gaim_init_ssl_plugin();
	gaim_init_ssl_openssl_plugin();
	gaim_init_gg_plugin();
	gaim_init_jabber_plugin();
	gaim_init_sametime_plugin();
	gaim_init_sametime_plugin();
	gaim_init_msn_plugin();
	gaim_init_novell_plugin();
	gaim_init_msn_plugin();
	gaim_init_simple_plugin();
	gaim_init_yahoo_plugin();
	gaim_init_zephyr_plugin();
#ifndef JOSCAR_SUPERCEDE_LIBGAIM
	gaim_init_oscar_plugin();
#endif

	//Load each plugin
	NSEnumerator			*enumerator = [[SLGaimCocoaAdapter libgaimPluginArray] objectEnumerator];
	id <AILibgaimPlugin>	plugin;

	while ((plugin = [enumerator nextObject])) {
		if ([plugin respondsToSelector:@selector(installLibgaimPlugin)]) {
			[plugin installLibgaimPlugin];
		}
	}
}

static void adiumGaimPrefsInit(void)
{
    //Disable gaim away handling - we do it ourselves
	gaim_prefs_set_bool("/core/away/away_when_idle", FALSE);
	gaim_prefs_set_string("/core/away/auto_reply","never");

	//Disable gaim idle reporting - we do it ourselves
	gaim_prefs_set_bool("/core/away/report_idle", FALSE);

    //Disable gaim conversation logging
    gaim_prefs_set_bool("/gaim/gtk/logging/log_chats", FALSE);
    gaim_prefs_set_bool("/gaim/gtk/logging/log_ims", FALSE);
    
    //Typing preference
    gaim_prefs_set_bool("/core/conversations/im/send_typing", TRUE);
	
	//Use server alias where possible
	gaim_prefs_set_bool("/core/buddies/use_server_alias", TRUE);
	
	//MSN preferences
	gaim_prefs_set_bool("/plugins/prpl/msn/conv_close_notice", TRUE);
	gaim_prefs_set_bool("/plugins/prpl/msn/conv_timeout_notice", TRUE);

	//Ensure we are using caching
	gaim_buddy_icons_set_caching(TRUE);
	
	//Load all plugins. This could be done in STATIC_PROTO_INIT in libgaim's config.h at build time, but doing it here allows easier changes.
	load_all_plugins();
}

static void adiumGaimCoreDebugInit(void)
{
#if (GAIM_DEBUG)
    gaim_debug_set_ui_ops(adium_gaim_debug_get_ui_ops());
#endif
}

/* The core is ready... finish configuring libgaim and its plugins */
static void adiumGaimCoreUiInit(void)
{
	GaimDebug (@"adiumGaimCoreUiInit");
	//Initialize the core UI ops
    gaim_blist_set_ui_ops(adium_gaim_blist_get_ui_ops());
    gaim_connections_set_ui_ops(adium_gaim_connection_get_ui_ops());
    gaim_privacy_set_ui_ops (adium_gaim_privacy_get_ui_ops());	

	/* Why use Gaim's accounts and blist list when we have the information locally?
		*		- Faster account connection: Gaim doesn't have to recreate the local list
		*		- Privacy/blocking support depends on the accounts and blist files existing
		*
		*	Another possible advantage:
		*		- Using Gaim's own buddy icon caching (which depends on both files) allows us to avoid
		*			re-requesting icons we already have locally on some protocols such as AIM.
		*   However, we seem to end up with out of date icons when we rely on Gaim's caching, particularly over MSN,
		*   so we'll just ignore this gain and turn off caching. 
		*/	
	//Setup the buddy list; then load the blist.
	gaim_set_blist(gaim_blist_new());

	gaim_blist_load();
	
	//Configure signals for receiving gaim events
	configureAdiumGaimSignals();
	
	//Configure the GUI-related UI ops last
	gaim_roomlist_set_ui_ops (adium_gaim_roomlist_get_ui_ops());
    gaim_notify_set_ui_ops(adium_gaim_notify_get_ui_ops());
    gaim_request_set_ui_ops(adium_gaim_request_get_ui_ops());
	gaim_xfers_set_ui_ops(adium_gaim_xfers_get_ui_ops());
	
	adiumGaimConversation_init();

#if	ENABLE_WEBCAM
	initGaimWebcamSupport();
#endif
}

static void adiumGaimCoreQuit(void)
{
    GaimDebug (@"Core quit");
    exit(0);
}

static GaimCoreUiOps adiumGaimCoreOps = {
    adiumGaimPrefsInit,
    adiumGaimCoreDebugInit,
    adiumGaimCoreUiInit,
    adiumGaimCoreQuit
};

GaimCoreUiOps *adium_gaim_core_get_ops(void)
{
	return &adiumGaimCoreOps;
}
