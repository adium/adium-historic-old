//
//  ESGaimDotMacAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 10/30/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESGaimDotMacAccount.h"

@implementation ESGaimDotMacAccount

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];
	
	NSString	 *userNameWithMacDotCom = nil;

	if (([UID rangeOfString:@"@mac.com"
					options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)].location != NSNotFound)){
		userNameWithMacDotCom = UID;
	}else{
		userNameWithMacDotCom = [UID stringByAppendingString:@"@mac.com"];
	}

	gaim_account_set_username(account, [userNameWithMacDotCom UTF8String]);
}

@end
