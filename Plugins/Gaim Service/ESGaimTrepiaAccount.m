//
//  ESGaimTrepiaAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
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
			return NSLocalizedString(@"Connecting",nil);
			break;
		case 1:
			return NSLocalizedString(@"Logging in",nil);
			break;
		case 2:
			return NSLocalizedString(@"Retrieving buddy list",nil);
			break;
	}
	return nil;
}

#endif
@end