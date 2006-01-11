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
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable;
- (BOOL)_accountsAreOnlineOrDisconnecting;
@end

/*!
 * @class ESAccountNetworkConnectivityPlugin
 * @brief Handle account connection and disconnection
 *
 * Accounts are automatically connected and disconnected based on:
 *	- If the account is enabled (at Adium launch if the network is available)
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
	//Wait for Adium to finish launching to handle autoconnecting enabled accounts
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

- (BOOL)shouldAutoconnectAllEnabled
{
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber		*didAutoconnectAll = [userDefaults objectForKey:@"Adium 1.0 First Time:Autoconnected All"];
	BOOL			shouldAutoconnectAllEnabled = NO;
	
	if (!didAutoconnectAll) {
		[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"Adium 1.0 First Time:Autoconnected All"];
		[userDefaults synchronize];
		shouldAutoconnectAllEnabled = YES;
	}
	
	return shouldAutoconnectAllEnabled;
}

/*!
 * @brief Adium finished launching
 *
 * Attempt to autoconnect accounts if shift is not being pressed
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	NSArray						*accounts = [[adium accountController] accounts];
	AIHostReachabilityMonitor	*monitor = [AIHostReachabilityMonitor defaultMonitor];
	BOOL						shouldAutoconnectAll = [self shouldAutoconnectAllEnabled];
	BOOL						shiftHeld = [NSEvent shiftKey];
	
	//Start off forbidding all accounts from auto-connecting.
	accountsToConnect    = [[NSMutableSet alloc] initWithArray:accounts];
	accountsToNotConnect = [accountsToConnect mutableCopy];
	knownHosts			 = [[NSMutableSet alloc] init];
	
	/* Add ourselves to the default host-reachability monitor as an observer for each account's host.
	 * At the same time, weed accounts that are to be auto-connected out of the accountsToNotConnect set.
	 */
	NSEnumerator	*accountsEnum;
	AIAccount		*account;
	
	accountsEnum = [accounts objectEnumerator];
	while ((account = [accountsEnum nextObject])) {
		if ([account connectivityBasedOnNetworkReachability]) {
			NSString *host = [account host];
			if (host && ![knownHosts containsObject:host]) {
				[monitor addObserver:self forHost:host];
				[knownHosts addObject:host];
			}
			
			//If this is an account we should auto-connect, remove it from accountsToNotConnect so that we auto-connect it.
			if (!shiftHeld  &&
				[account enabled] &&
				([account shouldBeOnline] ||
				 shouldAutoconnectAll)) {
				[accountsToNotConnect removeObject:account];
				continue; //prevent the account from being removed from accountsToConnect.
			}
			
		}  else if ([[account supportedPropertyKeys] containsObject:@"Online"]
					&& [account enabled]) {
			/* This account does not connect based on network reachability, but can go online
			 * and should autoconnect.  Connect it immediately.
			 */
			[account setShouldBeOnline:YES];
		}
		
		[accountsToConnect removeObject:account];
	}
	
	[knownHosts release];
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
	AILog(@"handleConnectivityForAccount: %@ reachable: %i",account,reachable);

	if (reachable) {
		//If we are now online and are waiting to connect this account, do it if the account hasn't already
		//been taken care of.
		if ([accountsToConnect containsObject:account]) {
			if (![account online] &&
				![account integerStatusObjectForKey:@"Connecting"]) {
				[account setShouldBeOnline:YES];
				[accountsToConnect removeObject:account];
			}
		}
	} else {
		//If we are no longer online and this account is connected, disconnect it.
		if (([account online] ||
			 [account integerStatusObjectForKey:@"Connecting"]) &&
			![account integerStatusObjectForKey:@"Disconnecting"]) {
			[account disconnect];
			[accountsToConnect addObject:account];
		}
	}
}

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
			if ([account online]) {
				//Disconnect the account and add it to our list to reconnect
				[account disconnect];
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
	
	return nil;
}

/*!
 * @brief Returns YES if any accounts are currently in the process of disconnecting
 */
- (BOOL)_accountsAreOnlineOrDisconnecting
{
    NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;
    
	while ((account = [enumerator nextObject])) {
		if ([account online] ||
		   [[account statusObjectForKey:@"Disconnecting"] boolValue]) {
			return YES;
		}
	}
	
	return NO;
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
			[account setShouldBeOnline:YES];
			[accountsToConnect removeObject:account];
		}
	}
}

@end
