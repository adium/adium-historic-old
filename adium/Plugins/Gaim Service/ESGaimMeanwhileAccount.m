//
//  ESGaimMeanwhileAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//

#import "ESGaimMeanwhileAccount.h"

@implementation ESGaimMeanwhileAccount

static BOOL didInitMeanwhile = NO;

- (const char*)protocolPlugin
{
	if (!didInitMeanwhile) didInitMeanwhile = gaim_init_meanwhile_plugin();
    return "prpl-meanwhile";
}

- (NSString *)hostKey
{
	return KEY_MEANWHILE_HOST;
}

- (NSString *)portKey
{
	return KEY_MEANWHILE_PORT;
}

@end
