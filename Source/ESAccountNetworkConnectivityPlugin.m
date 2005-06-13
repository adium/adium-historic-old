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
#import "AIContactController.h"
#import "ESAccountNetworkConnectivityPlugin.h"
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIHostReachabilityMonitor.h>
#import <AIUtilities/AISleepNotification.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>

@interface ESAccountNetworkConnectivityPlugin (PRIVATE)
- (void)autoConnectAccounts;
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable;
- (BOOL)_accountsAreOnlineOrDisconnecting;
@end

/*!
 * @class ESAccountNetworkConnectivityPlugin
 * @brief Handle account connection and disconnection
 *
 * Accounts are automatically connected and disconnected based on:
 *	- Per-account autoconnect preferences (at Adium launch if the network is available)
 *  - Network connectivity (disconnect when the Internet is not available and connect when it is available again)
 *  - System sleep (disconnect when the system sleeps and connect when it wakes up)
 *
 * Uses AIHostReachabilityMonitor and AISleepNotification from AIUtilities.
 */
@implementation ESAccountNetworkConnectivityPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	//Wait for Adium to finish launching to handle autoconnecting accounts
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	//Monitor system sleep so we can cleanly disconnect / reconnect
    [notificationCenter addObserver:self
						   selector:@selector(systemWillSleep:)
							   name:AISystemWillSleep_Notification
							 object:nil];
    [notificationCenter addObserver:self
						   selector:@selector(systemDidWake:)
							   name:AISystemDidWake_Notification
							 object:nil];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	[[adium           notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium contactController] unregisterListObjectObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[accountsToConnect    release];
	[accountsToNotConnect release];

	[super dealloc];
}

/*!
 * @brief Adium finished launching
 *
 * Attempt to autoconnect accounts if shift is not being pressed
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	if (![NSEvent shiftKey]) {
		AIHostReachabilityMonitor *monitor = [AIHostReachabilityMonitor defaultMonitor];

		NSArray *accounts = [[adium accountController] accounts];

		//start off forbidding all accounts from auto-connecting.
		accountsToConnect    = [[NSMutableSet alloc] initWithArray:accounts];
		accountsToNotConnect = [accountsToConnect mutableCopy];

		//add ourselves to the default host-reachability monitor as an observer for each account's host.
		//at the same time, weed accounts that are to be auto-connected out of the accountsToNotConnect set.
		NSEnumerator *accountsEnum = [accounts objectEnumerator];
		AIAccount *account;
		while ((account = [accountsEnum nextObject])) {
			if ([account connectivityBasedOnNetworkReachability]) {
				NSString *host = [account host];
				if (host && ![knownHosts containsObject:host]) {
					[monitor addObserver:self forHost:host];
					[knownHosts addObject:host];
				}

				//if this is an account we should auto-connect, remove it from accountsToNotConnect so that we auto-connect it.
				if ([[account supportedPropertyKeys] containsObject:@"Online"]
				&& [[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue])
				{
					[accountsToNotConnect removeObject:account];
					continue; //prevent the account from being removed from accountsToConnect.
				}
			}
			[accountsToConnect removeObject:account];
		}

	}
}

/*!
 * @brief Network connectivity changed
 *
 * Connect or disconnect accounts as appropriate to the new network state.
 *
 * @param networkIsReachable Indicates whether the given host is now reachable.
 * @param host The host that is now reachable (or not).
 */
- (void)hostReachabilityChanged:(BOOL)networkIsReachable forHost:(NSString *)host
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	//Connect or disconnect accounts in response to the connectivity change
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if (networkIsReachable && [accountsToNotConnect containsObject:account]) {
			[accountsToNotConnect removeObject:account];
		} else {
			if ([[account host] isEqualToString:host]) {
				[self handleConnectivityForAccount:account reachable:networkIsReachable];
			}
		}
	}
}

#pragma mark AIHostReachabilityObserver compliance

- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsReachable:(NSString *)host {
	[self hostReachabilityChanged:YES forHost:host];
}
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsNotReachable:(NSString *)host {
	[self hostReachabilityChanged:NO forHost:host];
}

#pragma mark Connecting/Disconnecting Accounts
/*!
 * @brief Connect or disconnect an account as appropriate to a new network reachable state
 *
 * This method uses the accountsToConnect collection to track which accounts were disconnected and should therefore be
 * later reconnected.
 *
 * @param account The account to change if appropriate
 * @param reachable The new network reachable state
 */
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable
{
	if (reachable) {
		//If we are now online and are waiting to connect this account, do it if the account hasn't already
		//been taken care of.
		if ([accountsToConnect containsObject:account]) {
			if (![account integerStatusObjectForKey:@"Online"] &&
			   ![account integerStatusObjectForKey:@"Connecting"] &&
			   ![[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]) {

				[account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];	
				[accountsToConnect removeObject:account];
			}
		}
	} else {
		//If we are no longer online and this account is connected, disconnect it.
		if (([account integerStatusObjectForKey:@"Online"] ||
			 [account integerStatusObjectForKey:@"Connecting"]) &&
			![account integerStatusObjectForKey:@"Disconnecting"] &&
			[[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]) {

			[account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
			[accountsToConnect addObject:account];
		}
	}
}

#if 0
//Autoconnecting Accounts (at startup) ---------------------------------------------------------------------------------
#pragma mark Autoconnecting Accounts (at startup)
/*!
 * @brief Auto connect accounts
 *
 * Automatically connect to accounts flagged with an auto connect property as soon as a network connection is available
 */
- (void)autoConnectAccounts
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
	
	//Determine the accounts which want to be autoconnected
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([[account supportedPropertyKeys] containsObject:@"Online"] &&
		   [[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]) {

			//If basing connectivity on the network, add it to our array of accounts to connect;
			//otherwise, sign it on immediately
			if ([account connectivityBasedOnNetworkReachability]) {
				[accountsToConnect addObject:account];
			} else {
				[account setPreference:[NSNumber numberWithBool:YES] 
								forKey:@"Online"
								 group:GROUP_ACCOUNT_STATUS];
			}
		}
	}
}
#endif //0

//Disconnect / Reconnect on sleep --------------------------------------------------------------------------------------
#pragma mark Disconnect/Reconnect On Sleep
/*!
 * @brief System is sleeping
 */
- (void)systemWillSleep:(NSNotification *)notification
{
	//Disconnect all online accounts
	if ([self _accountsAreOnlineOrDisconnecting]) {
		NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
		AIAccount		*account;
		
		while ((account = [enumerator nextObject])) {
			if ([[account supportedPropertyKeys] containsObject:@"Online"] &&
			   [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]) {

				//Disconnect the account and add it to our list to reconnect
				[account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
				[accountsToConnect addObject:account];
			}
		}
	}
		
	//While some accounts disconnect immediately, others may need a second or two to finish the process.  For
	//these accounts we'll want to hold system sleep until they are ready.  We monitor account status changes
	//and will lift the hold once all accounts are finished.
	if ([self _accountsAreOnlineOrDisconnecting]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AISystemHoldSleep_Notification object:nil];
	    [[adium contactController] registerListObjectObserver:self];
	}
}

/*!
 * @brief Invoked when our accounts change status
 *
 * Once all accounts are offline we will remove our hold on system sleep
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]] && [inModifiedKeys containsObject:@"Online"]) {
		if (![self _accountsAreOnlineOrDisconnecting]) {
			[[adium contactController] unregisterListObjectObserver:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:AISystemContinueSleep_Notification object:nil];
		}
	}
	
	return(nil);
}

/*!
 * @brief Returns YES if any accounts are currently in the process of disconnecting
 */
- (BOOL)_accountsAreOnlineOrDisconnecting
{
    NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;
    
	while ((account = [enumerator nextObject])) {
		if ([[account statusObjectForKey:@"Online"] boolValue] ||
		   [[account statusObjectForKey:@"Disconnecting"] boolValue]) {
			return(YES);
		}
	}
	
	return(NO);
}

/*!
 * @brief System is waking from sleep
 */
- (void)systemDidWake:(NSNotification *)notification
{
	NSEnumerator	*enumerator;
	AIAccount		*account;

	//Immediately re-connect accounts which are ignoring the server reachability
	enumerator = [[[adium accountController] accounts] objectEnumerator];	
	while ((account = [enumerator nextObject])) {
		if (![account connectivityBasedOnNetworkReachability] && [accountsToConnect containsObject:account]) {
			[account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
			[accountsToConnect removeObject:account];
		}
	}
}

@end
