//
//  ESGaimJabberAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESGaimJabberAccountViewController.h"

@implementation ESGaimJabberAccountViewController

- (NSString *)nibName{
    return(@"ESGaimJabberAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	//Connection security
	[checkBox_useTLS setState:[[account preferenceForKey:KEY_JABBER_USE_TLS group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_forceOldSSL setState:[[account preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_allowPlaintext setState:[[account preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	//Resource
	[textField_resource setStringValue:[account preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS]];
	
	//Connect server
	NSString *connectServer = [account preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	[textField_connectServer setStringValue:(connectServer ? connectServer : @"")];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	//Connection security
	[account setPreference:[NSNumber numberWithBool:[checkBox_useTLS state]]
					forKey:KEY_JABBER_USE_TLS group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_forceOldSSL state]]
					forKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_allowPlaintext state]]
					forKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS];

	//Resource
	[account setPreference:([[textField_resource stringValue] length] ? [textField_resource stringValue] : nil)
					forKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
	
	//Connect server
	[account setPreference:([[textField_connectServer stringValue] length] ? [textField_connectServer stringValue] : nil)
					forKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
}

@end
