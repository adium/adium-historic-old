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

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_HTTPConnectMethod setState:[[account preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];
}

- (IBAction)changedConnectionPreference:(id)sender
{	
	if (sender == checkBox_HTTPConnectMethod){
		[account setPreference:[NSNumber numberWithBool:[sender state]] 
						forKey:KEY_MSN_HTTP_CONNECT_METHOD
						 group:GROUP_ACCOUNT_STATUS];
	}else{
		[super changedConnectionPreference:sender];		
	}
}

//Update display for account status change
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	
	if(inObject == nil || inObject == account){
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
			BOOL shouldEnable = ![[account statusObjectForKey:@"Online"] boolValue];
			[checkBox_HTTPConnectMethod setEnabled:shouldEnable];
		}
	}
	
	return([super updateListObject:inObject keys:inModifiedKeys silent:silent]);
}

@end