//
//  ESGaimZephyrAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//

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
	
	NSString	*exposure_level, encoding;
	BOOL		write_anyone, write_zsubs, allowPlaintext;
	
	write_anyone = [[self preferenceForKey:KEY_ZEPHYR_EXPORT_ANYONE group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "write_anyone", write_anyone);

	write_zsubs = [[self preferenceForKey:KEY_ZEPHYR_EXPORT_SUBS group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "write_zsubs", write_zsubs);
	
	exposure_level = [self preferenceForKey:KEY_ZEPHYR_EXPOSURE group:GROUP_ACCOUNT_STATUS];
	gaim_account_set_string(account, "exposure_level", [exposure_level UTF8String]);

	encoding = [self preferenceForKey:KEY_ZEPHYR_ENCODING group:GROUP_ACCOUNT_STATUS];
	gaim_account_set_string(account, "encoding", [encoding UTF8String]);
}

@end
