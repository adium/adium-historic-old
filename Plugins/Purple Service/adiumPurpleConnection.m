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

#import "adiumPurpleConnection.h"
#import <AIUtilities/AIObjectAdditions.h>

static void adiumPurpleConnConnectProgress(PurpleConnection *gc, const char *text, size_t step, size_t step_count)
{
    AILog(@"Connecting: gc=0x%x (%s) %i / %i", gc, text, step, step_count);
	
	/*
	NSNumber	*connectionProgressPrecent = [NSNumber numberWithFloat:((float)step/(float)(step_count-1))];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionProgressStep:percentDone:)
										 withObject:[NSNumber numberWithInt:step]
										 withObject:connectionProgressPrecent];
	 */
}

static void adiumPurpleConnConnected(PurpleConnection *gc)
{
    AILog(@"Connected: gc=%x", gc);
	
	[accountLookup(gc->account) accountConnectionConnected];
}

static void adiumPurpleConnDisconnected(PurpleConnection *gc)
{
    AILog(@"Disconnected: gc=%x", gc);
	//    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
	//        return;
    [accountLookup(gc->account) accountConnectionDisconnected];
}

static void adiumPurpleConnNotice(PurpleConnection *gc, const char *text)
{
    AILog(@"Connection Notice: gc=%x (%s)", gc, text);
	
	NSString *connectionNotice = [NSString stringWithUTF8String:text];
	[accountLookup(gc->account) accountConnectionNotice:connectionNotice];
}

static void adiumPurpleConnReportDisconnect(PurpleConnection *gc, const char *text)
{
    AILog(@"Connection Disconnected: gc=%x (%s)", gc, text);
	
	NSString	*disconnectError = (text ? [NSString stringWithUTF8String:text] : @"");
    [accountLookup(gc->account) accountConnectionReportDisconnect:disconnectError];
}

static PurpleConnectionUiOps adiumPurpleConnectionOps = {
    adiumPurpleConnConnectProgress,
    adiumPurpleConnConnected,
    adiumPurpleConnDisconnected,
    adiumPurpleConnNotice,
    adiumPurpleConnReportDisconnect
};

PurpleConnectionUiOps *adium_purple_connection_get_ui_ops(void)
{
	return &adiumPurpleConnectionOps;
}
