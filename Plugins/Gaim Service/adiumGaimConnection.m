/*
 *  adiumGaimConnection.m
 *  Adium
 *
 *  Created by Evan Schoenberg on 1/22/05.
 *  Copyright 2005 The Adium Team. All rights reserved.
 *
 */

#import "adiumGaimConnection.h"

static void adiumGaimConnConnectProgress(GaimConnection *gc, const char *text, size_t step, size_t step_count)
{
    GaimDebug (@"Connecting: gc=0x%x (%s) %i / %i", gc, text, step, step_count);
	
	NSNumber	*connectionProgressPrecent = [NSNumber numberWithFloat:((float)step/(float)(step_count-1))];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionProgressStep:percentDone:)
										 withObject:[NSNumber numberWithInt:step]
										 withObject:connectionProgressPrecent];
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    GaimDebug (@"Connected: gc=%x", gc);
	
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionConnected)];
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    GaimDebug (@"Disconnected: gc=%x", gc);
	//    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
	//        return;
    [accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionDisconnected)];
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    GaimDebug (@"Connection Notice: gc=%x (%s)", gc, text);
	
	NSString *connectionNotice = [NSString stringWithUTF8String:text];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionNotice:)
										 withObject:connectionNotice];
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    GaimDebug (@"Connection Disconnected: gc=%x (%s)", gc, text);
	
	NSString	*disconnectError = [NSString stringWithUTF8String:text];
    [accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionReportDisconnect:)
										 withObject:disconnectError];
}

static GaimConnectionUiOps adiumGaimConnectionOps = {
    adiumGaimConnConnectProgress,
    adiumGaimConnConnected,
    adiumGaimConnDisconnected,
    adiumGaimConnNotice,
    adiumGaimConnReportDisconnect
};

GaimConnectionUiOps *adium_gaim_connection_get_ui_ops(void)
{
	return &adiumGaimConnectionOps;
}
