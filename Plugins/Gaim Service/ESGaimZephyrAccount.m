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

#import "ESGaimZephyrAccountViewController.h"
#import "ESGaimZephyrAccount.h"

@implementation ESGaimZephyrAccount

static BOOL didInitZephyr = NO;

- (const char*)protocolPlugin
{
	if (!didInitZephyr) didInitZephyr = gaim_init_zephyr_plugin();
    return "prpl-zephyr";
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	NSString	*exposure_level, *encoding;
	BOOL		write_anyone, write_zsubs;
	
	write_anyone = [[self preferenceForKey:KEY_ZEPHYR_EXPORT_ANYONE group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "write_anyone", write_anyone);

	write_zsubs = [[self preferenceForKey:KEY_ZEPHYR_EXPORT_SUBS group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "write_zsubs", write_zsubs);
	
	exposure_level = [self preferenceForKey:KEY_ZEPHYR_EXPOSURE group:GROUP_ACCOUNT_STATUS];
	gaim_account_set_string(account, "exposure_level", [exposure_level UTF8String]);

	encoding = [self preferenceForKey:KEY_ZEPHYR_ENCODING group:GROUP_ACCOUNT_STATUS];
	gaim_account_set_string(account, "encoding", [encoding UTF8String]);
}

//No need for a password for Zephyr accounts
- (BOOL)requiresPassword
{
	return NO;
}

//Zephyr connects to a local host so need not disconnect/reconnect as the network changes
- (BOOL)connectivityBasedOnNetworkReachability
{
	return NO;
}

@end
