//
//  ESGaimNovellAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimNovellAccount.h"

@implementation ESGaimNovellAccount

static BOOL didInitNovell;

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitNovell) didInitNovell = gaim_init_novell_plugin();
    return "prpl-novell";
}

- (NSString *)hostKey
{
	return KEY_NOVELL_HOST;
}

- (NSString *)portKey
{
	return KEY_NOVELL_PORT;
}

@end
