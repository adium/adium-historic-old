//
//  ESGaimTrepiaAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
//

#import "ESGaimTrepiaAccount.h"
#import "ESGaimTrepiaAccountViewController.h"

@implementation ESGaimTrepiaAccount

static BOOL didInitTrepia = NO;

- (const char*)protocolPlugin
{
	if (!didInitTrepia) didInitTrepia = gaim_init_trepia_plugin();
    return "prpl-trepia";
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
@end