//
//  ESGaimJabberAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
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
	
	[checkBox_useTLS setState:[[account preferenceForKey:KEY_JABBER_USE_TLS group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_forceOldSSL setState:[[account preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_allowPlaintext setState:[[account preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	NSString *resource = [account preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
	[textField_resource setStringValue:[account preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS]];
	
	NSString *connectServer = [account preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	[textField_connectServer setStringValue:(connectServer ? connectServer : @"")];
}
/*
//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    [super changedPreference:sender];
}
*/

- (IBAction)changedConnectionPreference:(id)sender
{	
	if (sender == checkBox_useTLS){
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_JABBER_USE_TLS
						 group:GROUP_ACCOUNT_STATUS];
			
	}else if (sender == checkBox_forceOldSSL){
		[account setPreference:[NSNumber numberWithBool:[sender state]]
												 forKey:KEY_JABBER_FORCE_OLD_SSL
												  group:GROUP_ACCOUNT_STATUS];
			
	}else if (sender == checkBox_allowPlaintext){
		[account setPreference:[NSNumber numberWithBool:[sender state]]
												 forKey:KEY_JABBER_ALLOW_PLAINTEXT
												  group:GROUP_ACCOUNT_STATUS];
			
	}else if (sender == textField_resource){
		//Access the host name so we can redisplay the default value if applicable
		if (![[textField_resource stringValue] length]){
			NSString *resource = [[adium preferenceController] preferenceForKey:KEY_JABBER_RESOURCE
																		  group:GROUP_ACCOUNT_STATUS];
			if (resource){
				[textField_resource setStringValue:resource];
			}
		}
		
	}else{
		[super changedConnectionPreference:sender];		
	}
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *sender = [notification object];
	if (sender == textField_connectServer){
		NSString *connectServer = [sender stringValue];
		[account setPreference:([connectServer length] ? connectServer : nil)
						forKey:KEY_JABBER_CONNECT_SERVER
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == textField_resource){
		NSString *resource = [textField_resource stringValue];
		[account setPreference:([resource length] ? resource : nil)
						forKey:KEY_JABBER_RESOURCE
						 group:GROUP_ACCOUNT_STATUS];
		
	}else{
		[super controlTextDidChange:notification];
	}
}

//Update display for account status change
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	
	if(inObject == nil || inObject == account){
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
			BOOL shouldEnable = ![[account statusObjectForKey:@"Online"] boolValue];
			[checkBox_useTLS setEnabled:shouldEnable];
			[checkBox_forceOldSSL setEnabled:shouldEnable];
			[checkBox_allowPlaintext setEnabled:shouldEnable];
			[textField_connectServer setEnabled:shouldEnable];
			[textField_resource setEnabled:shouldEnable];
		}
	}
	
	return(	[super updateListObject:inObject keys:inModifiedKeys silent:silent] );
}
@end
