//
//  AIAccountProxySettingsView.m
//  Adium
//
//  Created by Adam Iser on 1/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIAccountProxySettings.h"

@interface AIAccountProxySettings (PRIVATE)
- (void)_initAccountProxySettings;
@end

@implementation AIAccountProxySettings

//Init our account proxy settings and inject our controls into the custom view
- (id)initReplacingView:(NSView *)replaceView
{
	[super init];
	
	//Load our view
	[NSBundle loadNibNamed:@"AccountProxy" owner:self];
	
	//Replace the passed view with our own
	[[replaceView superview] addSubview:view_accountProxy];
	[view_accountProxy setFrame:[replaceView frame]];
	[view_accountProxy setAutoresizingMask:[replaceView autoresizingMask]];
	[replaceView removeFromSuperview];

	//Setup our menu
	[menu_proxy setMenu:[self _proxyMenu]];
	
	return(self);
}

//Dealloc
- (void)dealloc
{
	[super dealloc];
}

//Delegate
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}
- (id)delegate{
	return(delegate);
}

//Configure the proxy view for the passed account
- (void)configureForAccount:(AIAccount *)inAccount
{
	if(account != inAccount){
		NSString				*proxyHostName, *proxyUserName, *proxyPassword;
		NSNumber				*proxyTypeNumber, *proxyPortNumber;

		[account release];
		account = [inAccount retain];

		//Configure view
		//Proxy type
		proxyTypeNumber = [account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
		[menu_proxy selectItemAtIndex:[menu_proxy indexOfItemWithTag:[proxyTypeNumber intValue]]];
		
		//Proxy name
		proxyHostName = [account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
		[textField_proxyHostName setStringValue:(proxyHostName ? proxyHostName : @"")];
		
		//Proxy port number
		proxyPortNumber = [account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
		[textField_proxyPortNumber setStringValue:(proxyPortNumber ? [proxyPortNumber stringValue] : @"")];
		
		proxyUserName = [account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
		[textField_proxyUserName setStringValue:(proxyUserName ? proxyUserName : @"")];
		
		if (proxyHostName && proxyUserName){
			proxyPassword = [[adium accountController] passwordForProxyServer:proxyHostName
																	 userName:proxyUserName];
			[textField_proxyPassword setStringValue:(proxyPassword ? proxyPassword : @"")];
		}
		
		[self configureControlDimming];
	}
}

//User changed proxy preference
//We set to nil instead of the @"" a stringValue would return because we want to return to the global (default) value
//if the user clears the field
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *sender = [aNotification object];
	
	if(sender == textField_proxyHostName){
		[account setPreference:[sender stringValue]
						forKey:KEY_ACCOUNT_GAIM_PROXY_HOST
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if(sender == textField_proxyPortNumber){
		[account setPreference:[NSNumber numberWithInt:[sender intValue]]
						forKey:KEY_ACCOUNT_GAIM_PROXY_PORT
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if(sender == textField_proxyUserName){
		NSString	*userName = [sender stringValue];
		
		//If the username changed, save the new username and clear the password field
		if(![userName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_USERNAME 
														  group:GROUP_ACCOUNT_STATUS]]){
			[account setPreference:userName
							forKey:KEY_ACCOUNT_GAIM_PROXY_USERNAME
							 group:GROUP_ACCOUNT_STATUS];
			
			//Update the password field
			[textField_proxyPassword setStringValue:@""];
			[textField_proxyPassword setEnabled:(userName && [userName length])];
		}
	}
}

- (IBAction)toggleProxy:(id)sender
{
	
	
	
}

//Configure dimming of proxy controls
- (void)configureControlDimming
{
	
	NSNumber			*proxyTypeNumber = [account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	AdiumGaimProxyType  proxyType = (proxyTypeNumber ? [proxyTypeNumber intValue] : Gaim_Proxy_Default_SOCKS5);
	BOOL				editableProxySettings = ((proxyType != Gaim_Proxy_None) &&
												 (proxyType != Gaim_Proxy_Default_SOCKS5) &&
												 (proxyType != Gaim_Proxy_Default_HTTP) && 
												 (proxyType != Gaim_Proxy_Default_SOCKS4));
	
	[textField_proxyHostName	setEnabled:editableProxySettings];
	[textField_proxyPortNumber  setEnabled:editableProxySettings];
	[textField_proxyUserName	setEnabled:editableProxySettings];
	[textField_proxyPassword	setEnabled:(editableProxySettings && [[textField_proxyUserName stringValue] length])];
}


//Proxy type menu ------------------------------------------------------------------------------------------------------
#pragma mark Proxy type menu
//Build and return the proxy type menu
- (NSMenu *)_proxyMenu
{
    NSMenu			*proxyMenu = [[NSMenu alloc] init];
	
    [proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"None",nil) tag:Gaim_Proxy_None]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS4 Settings",nil) tag:Gaim_Proxy_Default_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS5 Settings",nil) tag:Gaim_Proxy_Default_SOCKS5]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide HTTP Settings",nil) tag:Gaim_Proxy_Default_HTTP]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"SOCKS4" tag:Gaim_Proxy_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"SOCKS5" tag:Gaim_Proxy_SOCKS5]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"HTTP" tag:Gaim_Proxy_HTTP]];
	
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
	
	return [menuItem autorelease];
}

//User selected new proxy type
- (void)changeProxyType:(id)sender
{
	[account setPreference:[NSNumber numberWithInt:[sender tag]]
					forKey:KEY_ACCOUNT_GAIM_PROXY_TYPE
					 group:GROUP_ACCOUNT_STATUS];
	
	[self configureControlDimming];
}

@end



