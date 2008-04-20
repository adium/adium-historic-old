//
//  ESIRCAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ESIRCAccount.h"

/*
void purple_account_set_username(void *account, const char *username);
void purple_account_set_bool(void *account, const char *name,
						   BOOL value);
*/
@implementation ESIRCAccount

- (const char *)protocolPlugin
{
	return "prpl-irc";
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString *)serverSuffix
{
	return @"irc.freenode.net";
}

- (const char *)purpleAccountName
{
	NSString	*myUID = [self formattedUID];
	BOOL		serverAppendedToUID  = ([myUID rangeOfString:@"@"].location != NSNotFound);

	return [(serverAppendedToUID ? myUID : [myUID stringByAppendingString:[self serverSuffix]]) UTF8String];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username([self purpleAccount], [self purpleAccountName]);
	
	BOOL useSSL = [[self preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	
	purple_account_set_bool([self purpleAccount], "ssl", useSSL);
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

- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	return ([[[inContact UID] lowercaseString] isEqualToString:@"nickserv"] ||
			[[[inContact UID] lowercaseString] isEqualToString:@"chanserv"]);
}

@end
