//
//  ESGaimDotMacAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 10/30/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
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

/*
 * @brief Set the spacing and capitilization of our formatted UID serverside (from CBGaimOscarAccount)
 *
 * CBGaimOscarAccount calls this to perform spacing/capitilization setting serverside.  This is not supported
 * for .Mac accounts and will throw a SNAC error if attempted.  Override the method to perform no action for .Mac.
 */
- (void)setFormattedUID {};

@end
