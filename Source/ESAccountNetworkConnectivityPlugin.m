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
#import <AIUtilities/AINetworkConnectivity.h>
#import <AIUtilities/AISleepNotification.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>

@interface ESAccountNetworkConnectivityPlugin (PRIVATE)
- (void)autoConnectAccounts;
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable;
- (BOOL)_accountsAreOnlineOrDisconnecting;
- (void)networkConnectivityChanged:(NSNotification *)notification;
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
 * Uses AINetworkConnectivity and AISleepNotification from AIUtilities.
 */
@implementation ESAccountNetworkConnectivityPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	accountsToConnect = [[NSMutableSet alloc] init];
	
	//Wait for Adium to finish launching to handle autoconnecting accounts
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];

	//Monitor network connectivity changes so we can cleanly disconnect / reconnect
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkConnectivityChanged:)
                                                 name:AINetwork_ConnectivityChanged
                                               object:nil];	
	
	//Monitor system sleep so we can cleanly disconnect / reconnect
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systemWillSleep:)
                                                 name:AISystemWillSleep_Notification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systemDidWake:)
                                                 name:AISystemDidWake_Notification
                                               object:nil];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[[adium contactController] unregisterListObjectObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[accountsToConnect release]; accountsToConnect = nil;

	[super dealloc];
}

/*!
 * @brief Adium finished launching
 *
 * Attempt to autoconnect accounts if shift is not being pressed
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	if(![NSEvent shiftKey]){
		[self autoConnectAccounts];
	}
}

/*!
 * @brief Network connectivity changed
 *
 * Connect or disconnect accounts as appropriate to the new network state.
 *
 * @param notification The object of the notification is an NSNumber indicating if the network is now available.
 */
- (void)networkConnectivityChanged:(NSNotification *)notification
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	BOOL 			networkIsReachable;

	//
	if(notification){
		networkIsReachable = [[notification object] boolValue];
	}else{
		networkIsReachable = [AINetworkConnectivity networkIsReachable];
	}
	
	//Connect or disconnect accounts in response to the connectivity change
	enumerator = [[[adium accountController] accountArray] objectEnumerator];
	while((account = [enumerator nextObject])){
		if([account connectivityBasedOnNetworkReachability]){
			[self handleConnectivityForAccount:account reachable:networkIsReachable];
		}
	}	
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
	if(reachable){
		//If we are now online and are waiting to connect this account, do it if the account hasn't already
		//been taken care of.
		if([accountsToConnect containsObject:account]){
			if(![account integerStatusObjectForKey:@"Online"] &&
			   ![account integerStatusObjectForKey:@"Connecting"] &&
			   ![[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){

				[account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];	
				[accountsToConnect removeObject:account];
			}
		}
	}else{
		//If we are no longer online and this account is connected, disconnect it.
		if (([account integerStatusObjectForKey:@"Online"] ||
			 [account integerStatusObjectForKey:@"Connecting"]) &&
			![account integerStatusObjectForKey:@"Disconnecting"] &&
			[[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){

			[account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
			[accountsToConnect addObject:account];
		}
	}
}


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
	enumerator = [[[adium accountController] accountArray] objectEnumerator];
	while((account = [enumerator nextObject])){
		if([[account supportedPropertyKeys] containsObject:@"Online"] &&
		   [[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]){

			//If basing connectivity on the network, add it to our array of accounts to connect;
			//otherwise, sign it on immediately
			if ([account connectivityBasedOnNetworkReachability]){
				[accountsToConnect addObject:account];
			}else{
				[account setPreference:[NSNumber numberWithBool:YES] 
								forKey:@"Online"
								 group:GROUP_ACCOUNT_STATUS];
			}
		}
	}

	//Attempt to connect them immediately; if this fails, they will be connected when the network
	//becomes available.
	if ([accountsToConnect count]){			
		[self networkConnectivityChanged:nil];
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
	if([self _accountsAreOnlineOrDisconnecting]){
		NSEnumerator	*enumerator = [[[adium accountController] accountArray] objectEnumerator];
		AIAccount		*account;
		
		while((account = [enumerator nextObject])){
			if([[account supportedPropertyKeys] containsObject:@"Online"] &&
			   [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){

				//Disconnect the account and add it to our list to reconnect
				[account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
				[accountsToConnect addObject:account];
			}
		}
	}
		
	//While some accounts disconnect immediately, others may need a second or two to finish the process.  For
	//these accounts we'll want to hold system sleep until they are ready.  We monitor account status changes
	//and will lift the hold once all accounts are finished.
	if([self _accountsAreOnlineOrDisconnecting]){
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
	if([inObject isKindOfClass:[AIAccount class]] && [inModifiedKeys containsObject:@"Online"]){
		if(![self _accountsAreOnlineOrDisconnecting]){
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
    NSEnumerator	*enumerator = [[[adium accountController] accountArray] objectEnumerator];
	AIAccount		*account;
    
	while((account = [enumerator nextObject])){
		if([[account statusObjectForKey:@"Online"] boolValue] ||
		   [[account statusObjectForKey:@"Disconnecting"] boolValue]){
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
	enumerator = [[[adium accountController] accountArray] objectEnumerator];	
	while((account = [enumerator nextObject])){
		if([account connectivityBasedOnNetworkReachability] && [accountsToConnect containsObject:account]){
			[account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
			[accountsToConnect removeObject:account];
		}
	}
	
	//Accounts which consider server reachability will re-connect when connectivity becomes available.
	//Our callback is not always invoked upon waking, so call it manually to be safe.
	if([accountsToConnect count]){
		[self networkConnectivityChanged:nil];
	}
}

@end
