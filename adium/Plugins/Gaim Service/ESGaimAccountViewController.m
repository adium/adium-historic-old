//
//  ESGaimAccountView.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimAccountViewController.h"
#import "CBGaimAccount.h"

@interface ESGaimAccountViewController (PRIVATE)
- (void)configureConnectionControlDimming;
- (NSMenu *)_proxyMenu;
- (NSMenuItem *)_proxyMenuItemWithTitle:(NSString *)title tag:(int)tag;
@end

@implementation ESGaimAccountViewController

- (NSString *)nibName{
    return(@"GaimAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
    
	CBGaimAccount   *theAccount = (CBGaimAccount *)inAccount;
	NSString		*hostName, *proxyHostName;
	int				port, proxyPort;
	NSNumber		*proxyTypeNumber;
	NSNumber		*proxyAuthenticateNumber;
	
	//Host name
	hostName = [theAccount host];

	if (hostName){
		[textField_hostName setStringValue:hostName];
	}
	
	//Port number
	port = [theAccount port];
	if (port){
		[textField_portNumber setIntValue:port];
	}
	
	//Proxy type
	[menu_proxy setMenu:[self _proxyMenu]];
	proxyTypeNumber = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	[menu_proxy selectItemAtIndex:[menu_proxy indexOfItemWithTag:[proxyTypeNumber intValue]]];
	
	//Proxy name
	proxyHostName = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
	if (proxyHostName){
		[textField_proxyHostName setStringValue:proxyHostName];
	}
	
	//Proxy port number
	proxyPort = [[theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_PORT group:GROUP_ACCOUNT_STATUS] intValue];
	if (proxyPort){
		[textField_proxyPortNumber setIntValue:proxyPort];
	}
	
	//Proxy must authenticate?
	proxyAuthenticateNumber = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_AUTHENTICATE group:GROUP_ACCOUNT_STATUS];
	[button_proxyRequireAuthentication setState:proxyAuthenticateNumber ? [proxyAuthenticateNumber boolValue] : NSOffState];
	
	[self configureConnectionControlDimming];
}

- (NSMenu *)_proxyMenu
{
    NSMenu			*proxyMenu = [[NSMenu alloc] init];
	
    [proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"None",nil) tag:Gaim_Proxy_None]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS Settings",nil) tag:Gaim_Proxy_Default]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"HTTP",nil) tag:Gaim_Proxy_HTTP]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"SOCKS4",nil) tag:Gaim_Proxy_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"SOCKS5",nil) tag:Gaim_Proxy_SOCKS5]];
				
	return [proxyMenu autorelease];
}

- (NSMenuItem *)_proxyMenuItemWithTitle:(NSString *)title tag:(int)tag
{
	NSMenuItem		*menuItem;
    
    menuItem = [[NSMenuItem alloc] initWithTitle:title
                                           target:self
                                           action:@selector(changeProxyType:)
                                    keyEquivalent:@""];
    [menuItem setTag:tag];
	
	return [menuItem autorelease];
}

- (IBAction)changedConnectionPreference:(id)sender
{
	if (sender == textField_hostName){
		NSString *stringValue = [sender stringValue];
		if ([stringValue length]){
			[account setPreference:stringValue
							forKey:[account hostKey]
							 group:GROUP_ACCOUNT_STATUS];
		}else{
			[account setPreference:nil
							forKey:[account hostKey]
							 group:GROUP_ACCOUNT_STATUS];
			
			//Set the host name so we can redisplay the default value if needed
			NSString *hostName = [(CBGaimAccount *)account host];
			
			if (hostName){
				[textField_hostName setStringValue:hostName];
			}
		}
		
	}else if (sender == textField_portNumber){
		if ([[sender stringValue] length]){
			[account setPreference:[NSNumber numberWithInt:[sender intValue]]
							forKey:[account portKey]
							 group:GROUP_ACCOUNT_STATUS];
		}else{
			[account setPreference:nil
							forKey:[account portKey]
							 group:GROUP_ACCOUNT_STATUS];
			
			//Set the port number so we can redisplay the default value if needed
			int portNumber = [(CBGaimAccount *)account port];
			
			if (portNumber){
				[textField_portNumber setIntValue:portNumber];
			}
		}
		
	}else if (sender == textField_proxyHostName){
		[account setPreference:[sender stringValue]
						forKey:KEY_ACCOUNT_GAIM_PROXY_HOST
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == textField_proxyPortNumber){
		[account setPreference:[NSNumber numberWithInt:[sender intValue]]
						forKey:KEY_ACCOUNT_GAIM_PROXY_PORT
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == button_proxyRequireAuthentication){
		[account setPreference:[NSNumber numberWithInt:[sender intValue]]
						forKey:KEY_ACCOUNT_GAIM_PROXY_AUTHENTICATE
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == button_proxySetPassword){
		//Display the set password sheet
	}
}

- (void)changeProxyType:(id)sender
{
	[account setPreference:[NSNumber numberWithInt:[sender tag]]
					forKey:KEY_ACCOUNT_GAIM_PROXY_TYPE
					 group:GROUP_ACCOUNT_STATUS];
	
	[self configureConnectionControlDimming];
}

- (void)configureConnectionControlDimming
{
	NSNumber			*proxyTypeNumber = [account preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];

	AdiumGaimProxyType  proxyType = (proxyTypeNumber ? [proxyTypeNumber intValue] : Gaim_Proxy_Default);
	BOOL				enableProxySettings = ((proxyType != Gaim_Proxy_None) && (proxyType != Gaim_Proxy_Default));

	[textField_proxyHostName setEnabled:enableProxySettings];
	[textField_proxyPortNumber setEnabled:enableProxySettings];
	[button_proxyRequireAuthentication setEnabled:enableProxySettings];
	[button_proxySetPassword setEnabled:enableProxySettings];
}

@end


