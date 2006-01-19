//
//  AdiumAuthorization.m
//  Adium
//
//  Created by Evan Schoenberg on 1/18/06.
//

#import "AdiumAuthorization.h"
#import <Adium/AIAccount.h>

#import "ESAuthorizationRequestWindowController.h"

@implementation AdiumAuthorization

- (id)init
{
	if ((self = [super init])) {
		
	}
	
	return self;
}

- (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount
{
	return [ESAuthorizationRequestWindowController showAuthorizationRequestWithDict:inDict forAccount:inAccount];
}

@end
