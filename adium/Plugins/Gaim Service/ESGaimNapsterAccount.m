//
//  ESGaimNapsterAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimNapsterAccountViewController.h"
#import "ESGaimNapsterAccount.h"

@implementation ESGaimNapsterAccount

static BOOL didInitNapster = NO;

- (const char*)protocolPlugin
{
	if (!didInitNapster) didInitNapster = gaim_init_napster_plugin();
    return "prpl-napster";
}

@end