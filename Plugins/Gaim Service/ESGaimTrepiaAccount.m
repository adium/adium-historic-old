//
//  ESGaimTrepiaAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimTrepiaAccount.h"
#import "ESGaimTrepiaAccountViewController.h"

@implementation ESGaimTrepiaAccount

#ifndef TREPIA_NOT_AVAILABLE

static BOOL didInitTrepia = NO;

- (const char*)protocolPlugin
{
	if (!didInitTrepia) didInitTrepia = gaim_init_trepia_plugin();
    return "prpl-trepia";
}

- (NSString *)hostKey
{
	return KEY_TREPIA_HOST;
}

- (NSString *)portKey
{
	return KEY_TREPIA_PORT;
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Logging in",nil);
			break;
		case 2:
			return AILocalizedString(@"Retrieving buddy list",nil);
			break;
	}
	return nil;
}

#endif
@end