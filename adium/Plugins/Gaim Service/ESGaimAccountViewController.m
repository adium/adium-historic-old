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
	NSString		*hostName, *proxyHostName, *proxyUserName, *proxyPassword;
	NSNumber		*proxyTypeNumber, *proxyPortNumber;
	int				port;
	
	//Host name
	hostName = [theAccount host];
	[textField_hostName setStringValue:(hostName ? hostName : @"")];
	
	//Port number
	port = [theAccount port];
	if (port){
		[textField_portNumber setIntValue:port];
	}else{
		[textField_portNumber setStringValue:@""];	
	}
	
	//Proxy type
	[menu_proxy setMenu:[self _proxyMenu]];
	proxyTypeNumber = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	[menu_proxy selectItemAtIndex:[menu_proxy indexOfItemWithTag:[proxyTypeNumber intValue]]];
	
	//Proxy name
	proxyHostName = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
	[textField_proxyHostName setStringValue:(proxyHostName ? proxyHostName : @"")];
	
	//Proxy port number
	proxyPortNumber = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
	[textField_proxyPortNumber setStringValue:(proxyPortNumber ? [proxyPortNumber stringValue] : @"")];

	proxyUserName = [theAccount preferenceForKey:KEY_ACCOUNT_GAIM_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
	[textField_proxyUserName setStringValue:(proxyUserName ? proxyUserName : @"")];

	if (proxyHostName && proxyUserName){
		proxyPassword = [[adium accountController] passwordForProxyServer:proxyHostName
																 userName:proxyUserName];
		[textField_proxyPassword setStringValue:(proxyPassword ? proxyPassword : @"")];
	}
	
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

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *sender = [aNotification object];
	if (sender == textField_hostName){
		NSString *hostName = [textField_hostName stringValue];
		[account setPreference:([hostName length] ? hostName : nil)
						forKey:[account hostKey]
						 group:GROUP_ACCOUNT_STATUS];	
		
	}else if (sender == textField_portNumber){
		[account setPreference:([[sender stringValue] length] ? [NSNumber numberWithInt:[sender intValue]] : nil)
						forKey:[account portKey]
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == textField_proxyHostName){
		[account setPreference:[sender stringValue]
						forKey:KEY_ACCOUNT_GAIM_PROXY_HOST
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == textField_proxyPortNumber){
		[account setPreference:[NSNumber numberWithInt:[sender intValue]]
						forKey:KEY_ACCOUNT_GAIM_PROXY_PORT
						 group:GROUP_ACCOUNT_STATUS];
		
	}else if (sender == textField_proxyUserName){
		NSString	*userName = [sender stringValue];
		[account setPreference:userName
						forKey:KEY_ACCOUNT_GAIM_PROXY_USERNAME
						 group:GROUP_ACCOUNT_STATUS];
		
		//Update the password field
		[textField_proxyPassword setStringValue:@""];
		[textField_proxyPassword setEnabled:(userName && [userName length])];
		
	}
}

- (IBAction)changedConnectionPreference:(id)sender
{
	if (sender == textField_proxyPassword){
		[[adium accountController] setPassword:[textField_proxyPassword stringValue]
								forProxyServer:[textField_proxyHostName stringValue]
									  userName:[textField_proxyUserName stringValue]];
	}else if (sender == textField_hostName){
		//Access the host name so we can redisplay the default value if applicable
		NSString * hostName = [(CBGaimAccount *)account host];
		
		if (hostName){
			[textField_hostName setStringValue:hostName];
		}
	}else if (sender == textField_portNumber){
		//Set the port number so we can redisplay the default value if needed
		int port = [(CBGaimAccount *)account port];
		
		if (port){
			[textField_portNumber setIntValue:port];
		}
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
	BOOL				editableProxySettings = ((proxyType != Gaim_Proxy_None) && (proxyType != Gaim_Proxy_Default));
	BOOL				accountOffline = ![[account statusObjectForKey:@"Online"] boolValue];
	BOOL				enableProxySettings = editableProxySettings && accountOffline;
	
	[textField_hostName			setEnabled:accountOffline];
	[textField_portNumber		setEnabled:accountOffline];

	[menu_proxy					setEnabled:accountOffline];
	
	[textField_proxyHostName	setEnabled:enableProxySettings];
	[textField_proxyPortNumber  setEnabled:enableProxySettings];
	[textField_proxyUserName	setEnabled:enableProxySettings];
	[textField_proxyPassword	setEnabled:(enableProxySettings && [[textField_proxyUserName stringValue] length])];
}

//Update display for account status change
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	if(inObject == nil || inObject == account){
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
			[self configureConnectionControlDimming];
			
		}
	}
	
	return(	[super updateListObject:inObject keys:inModifiedKeys silent:silent] );
}

@end
