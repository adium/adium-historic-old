//
//  ESGaimAntepoAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 11/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESGaimAntepoAccount.h"

@implementation ESGaimAntepoAccount

- (void)configureGaimAccount
{
	[super configureGaimAccount];

	gaim_account_set_bool(account, "auth_plain_in_clear", TRUE);
}

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];

	//Antepo uses a full email address; need to enable our special case within libgaim for not
	//parsing the @blah.com into a desired host name
	gaim_account_set_bool(account, "use_full_username", TRUE);
}

@end
