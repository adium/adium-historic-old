//
//  adiumGaimCore.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

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

#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
#if (GAIM_DEBUG)
static void adiumGaimDebugPrint(GaimDebugLevel level, const char *category, const char *format, va_list args)
{
	gchar *arg_s = g_strdup_vprintf(format, args); //NSLog sometimes chokes on the passed args, so we'll use vprintf
	
	/*	AILog(@"%x: (Debug: %s) %s",[NSRunLoop currentRunLoop], category, arg_s); */
	//Log error
	if(!category) category = "general"; //Category can be nil
	
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
static void adiumGaimPrefsInit(void)
{
    //Disable gaim away handling - we do it ourselves
    gaim_prefs_set_bool("/core/conversations/away_back_on_send", FALSE);
    gaim_prefs_set_bool("/core/away/auto_response/enabled", FALSE);
    gaim_prefs_set_string("/core/away/auto_reply","never");
	
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
}

static void adiumGaimCoreDebugInit(void)
{
#if (GAIM_DEBUG)
    gaim_debug_set_ui_ops(adium_gaim_debug_get_ui_ops());
#endif
}

static void adiumGaimCoreUiInit(void)
{
	gaim_eventloop_set_ui_ops(adium_gaim_eventloop_get_ui_ops());
    gaim_blist_set_ui_ops(adium_gaim_blist_get_ui_ops());
    gaim_connections_set_ui_ops(adium_gaim_connection_get_ui_ops());
    gaim_conversations_set_win_ui_ops(adium_gaim_conversation_get_win_ui_ops());
    gaim_notify_set_ui_ops(adium_gaim_notify_get_ui_ops());
    gaim_request_set_ui_ops(adium_gaim_request_get_ui_ops());
    gaim_xfers_set_ui_ops(adium_gaim_xfers_get_ui_ops());
    gaim_privacy_set_ui_ops (adium_gaim_privacy_get_ui_ops());
	gaim_roomlist_set_ui_ops (adium_gaim_roomlist_get_ui_ops());	
#if	ENABLE_WEBCAM
	gaim_webcam_set_ui_ops(adium_gaim_webcam_get_ui_ops());
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