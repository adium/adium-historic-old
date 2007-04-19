//
//  ESPurpleSimpleAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import "ESPurpleSimpleAccount.h"

@implementation ESPurpleSimpleAccount

- (const char*)protocolPlugin
{
    return "prpl-simple";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	BOOL useUDP = [[self preferenceForKey:KEY_SIMPLE_USE_UDP group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "udp", useUDP);
	
	BOOL publishStatus = [[self preferenceForKey:KEY_SIMPLE_PUBLISH_STATUS group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "dopublish", publishStatus);
}

- (const char *)gaimAccountName
{
	NSString	*userNameWithHost;

	/*
	 * Purple stores the username in the format username@server.  We need to pass it a username in this format.
	 */
	if ([UID rangeOfString:@"@"].location != NSNotFound) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self host]];
	}
	
	return [userNameWithHost UTF8String];
}

@end
