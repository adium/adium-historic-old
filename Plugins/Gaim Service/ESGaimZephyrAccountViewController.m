//
//  ESGaimZephyrAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "ESGaimZephyrAccountViewController.h"
#import "ESGaimZephyrAccount.h"

@implementation ESGaimZephyrAccountViewController

- (NSString *)nibName{
    return(@"ESGaimZephyrAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_exportAnyone setState:[[account preferenceForKey:KEY_ZEPHYR_EXPORT_ANYONE group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_exportSubs setState:[[account preferenceForKey:KEY_ZEPHYR_EXPORT_SUBS group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	[textField_exposure setStringValue:[account preferenceForKey:KEY_ZEPHYR_EXPOSURE group:GROUP_ACCOUNT_STATUS]];
	[textField_encoding setStringValue:[account preferenceForKey:KEY_ZEPHYR_ENCODING group:GROUP_ACCOUNT_STATUS]];
}

- (IBAction)changedConnectionPreference:(id)sender
{	
	if (sender == checkBox_exportAnyone){
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_EXPORT_ANYONE
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == checkBox_exportSubs){
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_EXPORT_SUBS
						 group:GROUP_ACCOUNT_STATUS];
	}else{
		[super changedConnectionPreference:sender];
	}
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *sender = [notification object];
	if (sender == textField_exposure){
		NSString *exposure = [sender stringValue];
		[account setPreference:([exposure length] ? exposure : nil)
						forKey:KEY_ZEPHYR_EXPOSURE
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == textField_encoding){
		NSString *encoding = [sender stringValue];

		[account setPreference:([encoding length] ? encoding : nil)
						forKey:KEY_ZEPHYR_ENCODING
						 group:GROUP_ACCOUNT_STATUS];
	}else{
		[super controlTextDidChange:notification];
	}		
}

@end
