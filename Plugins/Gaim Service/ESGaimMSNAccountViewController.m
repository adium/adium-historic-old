//
//  ESGaimMSNAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESGaimMSNAccountViewController.h"
#import "ESGaimMSNAccount.h"

@implementation ESGaimMSNAccountViewController

- (NSString *)nibName{
    return(@"ESGaimMSNAccountView");
}

//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	[checkBox_HTTPConnectMethod setState:[[account preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	[account setPreference:[NSNumber numberWithBool:[checkBox_HTTPConnectMethod state]] 
					forKey:KEY_MSN_HTTP_CONNECT_METHOD group:GROUP_ACCOUNT_STATUS];
}

@end