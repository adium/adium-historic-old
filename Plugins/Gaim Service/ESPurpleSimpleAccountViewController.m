//
//  ESPurpleSimpleAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleSimpleAccountViewController.h"
#import "ESPurpleSimpleAccount.h"

@implementation ESPurpleSimpleAccountViewController
- (NSString *)nibName{
    return @"ESPurpleSimpleAccountView";
}

//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];

	[checkBox_publishStatus setState:[[account preferenceForKey:KEY_SIMPLE_PUBLISH_STATUS 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_useUDP setState:[[account preferenceForKey:KEY_SIMPLE_USE_UDP 
												   group:GROUP_ACCOUNT_STATUS] boolValue]];

}

//Save controls
- (void)saveConfiguration
{
	[account setPreference:[NSNumber numberWithBool:[checkBox_publishStatus state]] 
					forKey:KEY_SIMPLE_PUBLISH_STATUS group:GROUP_ACCOUNT_STATUS];

	[account setPreference:[NSNumber numberWithBool:[checkBox_useUDP state]] 
					forKey:KEY_SIMPLE_USE_UDP group:GROUP_ACCOUNT_STATUS];

	[super saveConfiguration];
}

@end
