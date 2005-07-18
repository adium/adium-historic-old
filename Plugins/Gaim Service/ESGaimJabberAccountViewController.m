/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ESGaimJabberAccountViewController.h"
#import <Adium/AIAccount.h>

@implementation ESGaimJabberAccountViewController

- (NSString *)nibName{
    return @"ESGaimJabberAccountView";
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

/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@jabber.org","Sample name and server for new Jabber accounts");
}

@end
