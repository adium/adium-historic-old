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

#import "AIAccountController.h"
#import "AILoginController.h"
#import "AdiumPasswords.h"
#import "ESAccountPasswordPromptController.h"
#import "ESProxyPasswordPromptController.h"
#import <AIUtilities/AIKeychain.h>
#import <AIUtilities/AIKeychainOld.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>

@interface AdiumPasswords (PRIVATE)
- (NSString *)_accountNameForAccount:(AIAccount *)inAccount;
- (NSString *)_passKeyForAccount:(AIAccount *)inAccount;
- (NSString *)_accountNameForProxyServer:(NSString *)proxyServer userName:(NSString *)userName;
- (NSString *)_passKeyForProxyServer:(NSString *)proxyServer;
@end

@implementation AdiumPasswords

//Accounts -------------------------------------------------------------------------------------------------------------
#pragma mark Accounts

/*!
 * @brief Set the password of an account
 *
 * @param inPassword password to store
 * @param inAccount account the password belongs to
 */
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount
{
	NSError *error = nil;
	[[AIKeychain defaultKeychain_error:&error] setInternetPassword:inPassword
														 forServer:[self _passKeyForAccount:inAccount]
														   account:[self _accountNameForAccount:inAccount]
														  protocol:FOUR_CHAR_CODE('AdIM')
															 error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't ignore it if we're trying to set the password, though (because that would be strange).
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (inPassword || (err != errSecItemNotFound)) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not %@ password for account %@: %@ returned %i (%@)", inPassword ? @"set" : @"remove", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

/*!
 * @brief Forget the password of an account
 *
 * @param inAccount account whose password should be forgotten
 */
- (void)forgetPasswordForAccount:(AIAccount *)inAccount
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	[keychain deleteInternetPasswordForServer:[self _passKeyForAccount:inAccount]
		account:[self _accountNameForAccount:inAccount]
		protocol:FOUR_CHAR_CODE('AdIM')
		error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not delete password for account %@: %@ returned %i (%@)", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

/*!
 * @brief Retrieve the password of an account
 * 
 * @param inAccount account whose password is desired
 * @return account password, or nil if the password is not available
 */
- (NSString *)passwordForAccount:(AIAccount *)inAccount
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	NSString	*password = [keychain internetPasswordForServer:[self _passKeyForAccount:inAccount]
														account:[self _accountNameForAccount:inAccount]
													   protocol:FOUR_CHAR_CODE('AdIM')
														  error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not retrieve password for account %@: %@ returned %i (%@)", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
	return password;
}

/*!
 * @brief Retrieve the password of an account, prompting the user if necessary
 *
 * @param inAccount account whose password is desired
 * @param inTarget target to notify when password is available
 * @param inSelector selector to notify when password is available
 * @param inContext context passed to target
 */
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	NSString	*password = [keychain internetPasswordForServer:[self _passKeyForAccount:inAccount]
														account:[self _accountNameForAccount:inAccount]
													   protocol:FOUR_CHAR_CODE('AdIM')
														  error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not retrieve password for account %@: %@ returned %i (%@)", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
	
	if (password && [password length] != 0) {
		//Invoke the target right away
		[inTarget performSelector:inSelector withObject:password withObject:inContext afterDelay:0.0001];
	} else {
		//Prompt the user for their password
		[ESAccountPasswordPromptController showPasswordPromptForAccount:inAccount
														notifyingTarget:inTarget
															   selector:inSelector
																context:inContext];
	}
}

//Proxy Servers --------------------------------------------------------------------------------------------------------
#pragma mark Proxy Servers

/*!
 * @brief Set the password for a proxy server
 *
 * @param inPassword password to store
 * @param server proxy server name
 * @param userName proxy server user name
 *
 * XXX - This is inconsistent.  Above we have a separate forget method, here we forget when nil is passed...
 */
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName
{
	NSError *error = nil;
	[[AIKeychain defaultKeychain_error:&error] setInternetPassword:inPassword
														 forServer:[self _passKeyForProxyServer:server]
														   account:[self _accountNameForProxyServer:server 
																						   userName:userName]
														  protocol:FOUR_CHAR_CODE('AdIM')
															 error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't ignore it if we're trying to set the password, though (because that would be strange).
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (inPassword || (err != errSecItemNotFound)) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not %@ password for proxy server %@: %@ returned %i (%@)",
			      inPassword ? @"set" : @"remove",
			      [self _accountNameForProxyServer:server
				                          userName:userName],
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
				  err,
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

/*!
 * @brief Retrieve the password for a proxy server
 * 
 * @param server proxy server name
 * @param userName proxy server user name
 * @return proxy server password, or nil if the password is not available
 */
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	NSString	*password = [keychain internetPasswordForServer:[self _passKeyForProxyServer:server]
														account:[self _accountNameForProxyServer:server 
																						userName:userName]
													   protocol:FOUR_CHAR_CODE('AdIM')
														  error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not retrieve password for proxy server %@: %@ returned %i (%@)",
				  [self _accountNameForProxyServer:server
				                          userName:userName],
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
				  err,
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
	return password;
}

/*!
 * @brief Retrieve the password for a proxy server, prompting the user if necessary
 *
 * @param server proxy server name
 * @param userName proxy server user name
 * @param inTarget target to notify when password is available
 * @param inSelector selector to notify when password is available
 * @param inContext context passed to target
 */
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	NSString	*password = [keychain internetPasswordForServer:[self _passKeyForProxyServer:server]
														account:[self _accountNameForProxyServer:server 
																						userName:userName]
													   protocol:FOUR_CHAR_CODE('AdIM')
														  error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not retrieve password for proxy server %@: %@ returned %i (%@)",
				  [self _accountNameForProxyServer:server
				                          userName:userName],
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
				  err,
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
	
	if (password && [password length] != 0) {
		//Invoke the target right away
		[inTarget performSelector:inSelector withObject:password withObject:inContext afterDelay:0.0001];    
	} else {
		//Prompt the user for their password
		[ESProxyPasswordPromptController showPasswordPromptForProxyServer:server
																 userName:userName
														  notifyingTarget:inTarget
																 selector:inSelector
																  context:inContext];
	}
}


//Password Keys --------------------------------------------------------------------------------------------------------
#pragma mark Password Keys

/*!
 * @brief Keychain identifier for an account
 */
- (NSString *)_accountNameForAccount:(AIAccount *)inAccount{
	return [NSString stringWithFormat:@"%@.%@",[[inAccount service] serviceID],[inAccount internalObjectID]];
}
- (NSString *)_passKeyForAccount:(AIAccount *)inAccount{
	if ([[[adium loginController] userArray] count] > 1) {
		return [NSString stringWithFormat:@"Adium.%@.%@",[[adium loginController] currentUser],[self _accountNameForAccount:inAccount]];
	} else {
		return [NSString stringWithFormat:@"Adium.%@",[self _accountNameForAccount:inAccount]];
	}
}

/*!
 * @brief Keychain identifier for a proxy server
 */
- (NSString *)_accountNameForProxyServer:(NSString *)proxyServer userName:(NSString *)userName{
	return [NSString stringWithFormat:@"%@.%@",proxyServer,userName];
}
- (NSString *)_passKeyForProxyServer:(NSString *)proxyServer{
	if ([[[adium loginController] userArray] count] > 1) {
		return [NSString stringWithFormat:@"Adium.%@.%@",[[adium loginController] currentUser],proxyServer];
	} else {
		return [NSString stringWithFormat:@"Adium.%@",proxyServer];	
	}
}


//Upgrade --------------------------------------------------------------------------------------------------------------
#pragma mark Upgrade
/*!
 * @brief Upgraded password storage format (v0.70 -> v0.80) for ability with custom keychain software
 */
- (void)upgradePasswords
{
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber		*didPasswordUpgrade = [userDefaults objectForKey:@"Adium:Did Password Upgrade"];
	
	if (!didPasswordUpgrade || ![didPasswordUpgrade boolValue]) {
		[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"Adium:Did Password Upgrade"];
		[userDefaults synchronize];
		
		NSArray			*accounts = [[adium accountController] accounts];

		if ([accounts count]) {
			AIAccount		*account;
			NSEnumerator	*enumerator;

			NSRunInformationalAlertPanel(@"Adium Version Upgrade",
										 @"This version of Adium fixes a common crash related to secure storage of your instant messaging passwords.  When you press OK below, Adium will automatically update any stored passwords to the new, more stable system.\n\nThis process will only occur once and will take a moment; you may be prompted to allow access for one or more passwords.\n\nIf Adium crashes during this upgrade, simply relaunch Adium; the process will not occur again.",nil,nil,nil);

			enumerator = [accounts objectEnumerator];
			while ((account = [enumerator nextObject])) {
				NSString	*passKey = [self _passKeyForAccount:account];
				NSString	*accountName = [self _accountNameForAccount:account];
				
				//Get from old
				NSString	*password = [AIKeychainOld getPasswordFromKeychainForService:passKey account:accountName];
				
				//Store in new
				if (password) {
					NSError *error = nil;
					[[AIKeychain defaultKeychain_error:&error] addInternetPassword:password
																		 forServer:passKey
																		   account:accountName
																		  protocol:FOUR_CHAR_CODE('AdIM')
																			 error:&error];
					if (error) {
						NSDictionary *userInfo = [error userInfo];
						NSLog(@"could not upgrade password for account %@: %@ returned %i (%@)", [self _accountNameForAccount:account], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], [error code], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
					}
				}
			}
		}
	}
}

@end
