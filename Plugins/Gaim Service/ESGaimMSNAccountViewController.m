//
//  ESGaimMSNAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimMSNAccountViewController.h"
#import "ESGaimMSNAccount.h"

@implementation ESGaimMSNAccountViewController

- (NSString *)nibName{
    return(@"ESGaimMSNAccountView");
}
- (NSString *)userNameLabel{
    return(@"Passport");    //Sign-in name
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_HTTPConnectMethod setState:[[account preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];

	[checkBox_treatDisplayNamesAsStatus setState:[[account preferenceForKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_conversationClosed setState:[[account preferenceForKey:KEY_MSN_CONVERSATION_CLOSED 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_conversationTimedOut setState:[[account preferenceForKey:KEY_MSN_CONVERSATION_TIMED_OUT 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];

}

- (IBAction)changedPreference:(id)sender
{
	if (sender == checkBox_treatDisplayNamesAsStatus){
		[account setPreference:[NSNumber numberWithBool:[sender state]] 
						forKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == checkBox_conversationClosed){
		[account setPreference:[NSNumber numberWithBool:[sender state]] 
						forKey:KEY_MSN_CONVERSATION_CLOSED
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == checkBox_conversationTimedOut){
		[account setPreference:[NSNumber numberWithBool:[sender state]] 
						forKey:KEY_MSN_CONVERSATION_TIMED_OUT
						 group:GROUP_ACCOUNT_STATUS];
		
	}else{
		[super changedPreference:sender];		
	}
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
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	
	if(inObject == nil || inObject == account){
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
			BOOL shouldEnable = ![[account statusObjectForKey:@"Online"] boolValue];
			[checkBox_HTTPConnectMethod setEnabled:shouldEnable];
		}
	}
	
	return(	[super updateListObject:inObject keys:inModifiedKeys silent:silent] );
}

@end