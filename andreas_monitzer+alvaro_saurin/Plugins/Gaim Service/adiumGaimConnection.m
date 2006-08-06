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

#import "adiumGaimConnection.h"
#import <AIUtilities/AIObjectAdditions.h>

static void adiumGaimConnConnectProgress(GaimConnection *gc, const char *text, size_t step, size_t step_count)
{
    GaimDebug (@"Connecting: gc=0x%x (%s) %i / %i", gc, text, step, step_count);
	
	/*
	NSNumber	*connectionProgressPrecent = [NSNumber numberWithFloat:((float)step/(float)(step_count-1))];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionProgressStep:percentDone:)
										 withObject:[NSNumber numberWithInt:step]
										 withObject:connectionProgressPrecent];
	 */
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    GaimDebug (@"Connected: gc=%x", gc);
	
	[accountLookup(gc->account) accountConnectionConnected];
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    GaimDebug (@"Disconnected: gc=%x", gc);
	//    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
	//        return;
    [accountLookup(gc->account) accountConnectionDisconnected];
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    GaimDebug (@"Connection Notice: gc=%x (%s)", gc, text);
	
	NSString *connectionNotice = [NSString stringWithUTF8String:text];
	[accountLookup(gc->account) accountConnectionNotice:connectionNotice];
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    GaimDebug (@"Connection Disconnected: gc=%x (%s)", gc, text);
	
	NSString	*disconnectError = [NSString stringWithUTF8String:text];
    [accountLookup(gc->account) accountConnectionReportDisconnect:disconnectError];
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
