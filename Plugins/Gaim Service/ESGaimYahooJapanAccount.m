//
//  ESGaimYahooJapanAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Apr 22 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimYahooJapanAccount.h"

@implementation ESGaimYahooJapanAccount

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];

	gaim_account_set_bool(account, "yahoojp", TRUE);
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	NSString	*hostName;
	
	//Host (server) - Yahoo! Japan uses a different server preference key than other accounts, so set that here
	hostName = [self host];
	if (hostName && [hostName length]){
		gaim_account_set_string(account, "serverjp", [hostName UTF8String]);
	}
}

@end
