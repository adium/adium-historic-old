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

@end
