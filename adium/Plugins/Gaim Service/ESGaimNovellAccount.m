//
//  ESGaimNovellAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//

#import "ESGaimNovellAccount.h"

@implementation ESGaimNovellAccount

- (const char*)protocolPlugin
{
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
