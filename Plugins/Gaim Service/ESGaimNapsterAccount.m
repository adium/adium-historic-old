//
//  ESGaimNapsterAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESGaimNapsterAccountViewController.h"
#import "ESGaimNapsterAccount.h"

@implementation ESGaimNapsterAccount

static BOOL didInitNapster = NO;

- (const char*)protocolPlugin
{
	if (!didInitNapster) didInitNapster = gaim_init_napster_plugin();
    return "prpl-napster";
}

- (NSString *)hostKey
{
	return KEY_NAPSTER_HOST;
}

- (NSString *)portKey
{
	return KEY_NAPSTER_PORT;
}

@end