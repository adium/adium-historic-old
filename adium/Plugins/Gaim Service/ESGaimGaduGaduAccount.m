//
//  ESGaimGaduGaduAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.


#import "ESGaimGaduGaduAccountViewController.h"
#import "ESGaimGaduGaduAccount.h"

@implementation ESGaimGaduGaduAccount


static BOOL didInitGG = NO;

- (const char*)protocolPlugin
{
	if (!didInitGG) didInitGG = gaim_init_gg_plugin();
    return "prpl-gg";
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Looking up server",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data",nil);
			break;			
		case 3:
			return AILocalizedString(@"Balancer handshake",nil);
			break;
		case 4:
			return AILocalizedString(@"Reading server key",nil);
			break;
		case 5:
			return AILocalizedString(@"Exchanging key hash",nil);
			break;
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_GADU_GADU_HOST;
}

- (NSString *)portKey
{
	return KEY_GADU_GADU_PORT;
}

@end