//
//  ESIRCAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ESIRCAccount.h"

/*
void gaim_account_set_username(void *account, const char *username);
void gaim_account_set_bool(void *account, const char *name,
						   BOOL value);
*/
@implementation ESIRCAccount

- (const char *)protocolPlugin
{
	return "prpl-irc";
}

- (void)dealloc
{
	NSLog(@"Dealloc %@",self);
	
	[super dealloc];
}

- (NSString *)serverSuffix
{
	return @"irc.freenode.net";
}

- (const char *)gaimAccountName
{
	return [super gaimAccountName];

	NSString	*userNameWithHost = nil;
	BOOL		serverAppendedToUID;
	NSString	*myUID = [self UID];

	serverAppendedToUID = ([myUID rangeOfString:@"@"].location != NSNotFound);
	
	if (serverAppendedToUID) {
		userNameWithHost = myUID;
	} else {
		userNameWithHost = [myUID stringByAppendingString:[self serverSuffix]];
	}

	return [myUID UTF8String];
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	gaim_account_set_username([self gaimAccount], [self gaimAccountName]);
	
	//'Connect via' server (nil by default)
	BOOL useSSL = [[self preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	
	gaim_account_set_bool([self gaimAccount], "ssl", useSSL);
}

/*!
* @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 *
 * Rather than having a separate server field, IRC uses the servername after the user name.
 * username@server.org
 */
- (NSString *)host
{
	NSString	*host;
	NSString	*myUID = [self UID];

	int location = [myUID rangeOfString:@"@"].location;
	
	if ((location != NSNotFound) && (location + 1 < [myUID length])) {
		host = [myUID substringFromIndex:(location + 1)];
		
	} else {
		host = [self serverSuffix];
	}
	
	return host;
}

@end
