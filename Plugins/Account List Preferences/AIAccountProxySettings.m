//
//  AIAccountProxySettingsView.m
//  Adium
//
//  Created by Adam Iser on 1/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIAccountProxySettings.h"

@interface AIAccountProxySettings (PRIVATE)
- (void)configureControlDimming;
- (void)updatePasswordField;


- (NSMenu *)_proxyMenu;
- (NSMenuItem *)_proxyMenuItemWithTitle:(NSString *)title tag:(int)tag;
@end

@implementation AIAccountProxySettings

//Init our account proxy settings
- (id)init
{
	[super init];
	
	//Load our view
	[NSBundle loadNibNamed:@"AccountProxy" owner:self];
	
	//Setup our menu
	[popUpButton_proxy setMenu:[self _proxyMenu]];
	
	return(self);
}

- (NSView *)view
{
	return(view_accountProxy);
}

//Dealloc
- (void)dealloc
{
	[super dealloc];
}


//
- (IBAction)toggleProxy:(id)sender
{
	[self configureControlDimming];
}

- (void)changeProxyType:(id)sender
{
	[self configureControlDimming];
}


//Configure the proxy view for the passed account
- (void)configureForAccount:(AIAccount *)inAccount
{
	if(account != inAccount){
		[account release];
		account = [inAccount retain];

		//Enabled & Type
		[checkBox_useProxy setState:[[account preferenceForKey:KEY_ACCOUNT_PROXY_ENABLED
														 group:GROUP_ACCOUNT_STATUS] boolValue]];
		[popUpButton_proxy compatibleSelectItemWithTag:[[account preferenceForKey:KEY_ACCOUNT_PROXY_TYPE
																			group:GROUP_ACCOUNT_STATUS] intValue]];
		
		//Host & Port
		NSString	*proxyHost = [account preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
		[textField_proxyHostName setStringValue:(proxyHost ? proxyHost : @"")];
		
		NSString	*proxyPort = [account preferenceForKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
		[textField_proxyPortNumber setStringValue:(proxyPort ? proxyHost : @"")];
		
		//Username
		NSString	*proxyUser = [account preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
		[textField_proxyUserName setStringValue:(proxyUser ? proxyHost : @"")];

		[self updatePasswordField];
		[self configureControlDimming];
	}
}

//Save current control values
- (void)saveConfiguration
{
	NSString	*proxyHostName = [textField_proxyHostName stringValue];
	NSString	*proxyUserName = [textField_proxyUserName stringValue];

	//Password
	if(![proxyUserName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS]] ||
	   ![proxyHostName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS]]){
		
		[[adium accountController] setPassword:[textField_proxyPassword stringValue]
								forProxyServer:proxyHostName
									  userName:proxyUserName];
	}

	//Enabled & Type
	[account setPreference:[NSNumber numberWithInt:[checkBox_useProxy state]]
					forKey:KEY_ACCOUNT_PROXY_ENABLED group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithInt:[[popUpButton_proxy selectedItem] tag]]
					forKey:KEY_ACCOUNT_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	
	//Host & Port
	[account setPreference:[textField_proxyHostName stringValue]
					forKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[textField_proxyPortNumber stringValue]
					forKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
	
	//Username
	[account setPreference:[textField_proxyUserName stringValue]
					forKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
}


//Update password field
- (void)updatePasswordField
{
	NSString	*proxyHostName = [textField_proxyHostName stringValue];
	NSString	*proxyUserName = [textField_proxyUserName stringValue];
	
	if(proxyHostName && proxyUserName){
		NSString *proxyPassword = [[adium accountController] passwordForProxyServer:proxyHostName
																		   userName:proxyUserName];
		[textField_proxyPassword setStringValue:(proxyPassword ? proxyPassword : @"")];
	}
}	

//User changed proxy preference
//We set to nil instead of the @"" a stringValue would return because we want to return to the global (default) value
//if the user clears the field
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *sender = [aNotification object];
	
	if(sender == textField_proxyHostName){
		
	}else if(sender == textField_proxyPortNumber){
		[account setPreference:[NSNumber numberWithInt:[textField_proxyPortNumber intValue]]
						forKey:KEY_ACCOUNT_PROXY_PORT
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if(sender == textField_proxyUserName){
		NSString	*userName = [textField_proxyUserName stringValue];
		
		//If the username changed, save the new username and clear the password field
		if(![userName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME 
														  group:GROUP_ACCOUNT_STATUS]]){
			[account setPreference:userName
							forKey:KEY_ACCOUNT_PROXY_USERNAME
							 group:GROUP_ACCOUNT_STATUS];
			
			//Update the password field
			[textField_proxyPassword setStringValue:@""];
			[textField_proxyPassword setEnabled:(userName && [userName length])];
		}
	}
}


//Configure dimming of proxy controls
- (void)configureControlDimming
{
	AdiumProxyType	proxyType = [[popUpButton_proxy selectedItem] tag];
	BOOL			proxyEnabled = [checkBox_useProxy state];
	BOOL			usingSystemwide = (proxyType == Adium_Proxy_Default_SOCKS5 ||
									   proxyType == Adium_Proxy_Default_HTTP || 
									   proxyType == Adium_Proxy_Default_SOCKS4);
	
	[popUpButton_proxy setEnabled:proxyEnabled];
	[textField_proxyHostName setEnabled:(proxyEnabled && !usingSystemwide)];
	[textField_proxyPortNumber setEnabled:(proxyEnabled && !usingSystemwide)];
	[textField_proxyUserName setEnabled:(proxyEnabled && !usingSystemwide)];
	[textField_proxyPassword setEnabled:(proxyEnabled && !usingSystemwide)];
}


//Proxy type menu ------------------------------------------------------------------------------------------------------
#pragma mark Proxy type menu
//Build and return the proxy type menu
- (NSMenu *)_proxyMenu
{
    NSMenu			*proxyMenu = [[NSMenu alloc] init];
	
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS4 Settings",nil) tag:Adium_Proxy_Default_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS5 Settings",nil) tag:Adium_Proxy_Default_SOCKS5]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide HTTP Settings",nil) tag:Adium_Proxy_Default_HTTP]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"SOCKS4" tag:Adium_Proxy_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"SOCKS5" tag:Adium_Proxy_SOCKS5]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"HTTP" tag:Adium_Proxy_HTTP]];
	
	return [proxyMenu autorelease];
}

//
- (NSMenuItem *)_proxyMenuItemWithTitle:(NSString *)title tag:(int)tag
{
	NSMenuItem		*menuItem;
    
    menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																	target:self
																	action:@selector(changeProxyType:)
															 keyEquivalent:@""];
    [menuItem setTag:tag];
	
	return([menuItem autorelease]);
}

@end



