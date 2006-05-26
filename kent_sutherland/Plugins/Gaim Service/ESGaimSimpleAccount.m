//
//  ESGaimSimpleAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import "ESGaimSimpleAccount.h"

@implementation ESGaimSimpleAccount

gboolean gaim_init_simple_plugin(void);
- (const char*)protocolPlugin
{
    return "prpl-simple";
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	BOOL useUDP = [[self preferenceForKey:KEY_SIMPLE_USE_UDP group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "udp", useUDP);
	
	BOOL publishStatus = [[self preferenceForKey:KEY_SIMPLE_PUBLISH_STATUS group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "dopublish", publishStatus);
}

- (const char *)gaimAccountName
{
	NSString	*userNameWithHost;

	/*
	 * Gaim stores the username in the format username@server.  We need to pass it a username in this format.
	 */
	if ([UID rangeOfString:@"@"].location != NSNotFound) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self host]];
	}
	
	return [userNameWithHost UTF8String];
}

@end
