//
//  ESAccountNetworkConnectivityPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 8/10/04.
//

#import "ESAccountNetworkConnectivityPlugin.h"

@interface ESAccountNetworkConnectivityPlugin (PRIVATE)
- (void)autoConnectAccounts;
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable;

//10.3 and above
- (void)accountListChanged:(NSNotification *)notification;
- (void)networkConnectivityChanged:(NSNotification *)notification;
@end

@implementation ESAccountNetworkConnectivityPlugin

static NSMutableSet							*accountsToConnect = nil;

- (void)installPlugin
{
	accountsToConnect = [[NSMutableSet alloc] init];
	
	//Register our observers
    [[adium contactController] registerListObjectObserver:self];
	
	//Wait for Adium to finish launching to handle autoconnecting accounts
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];

	//Monitor system sleep so we can cleanly disconnect / reconnect our accounts
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkConnectivityChanged:)
                                                 name:AINetwork_ConnectivityChanged
                                               object:nil];	
	
	//Monitor system sleep so we can cleanly disconnect / reconnect our accounts
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systemWillSleep:)
                                                 name:AISystemWillSleep_Notification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systemDidWake:)
                                                 name:AISystemDidWake_Notification
                                               object:nil];	
}

- (void)uninstallPlugin
{
	[accountsToConnect release]; accountsToConnect = nil;
	
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Holding shift skips autoconnection.
	if(![NSEvent shiftKey]){
		[self autoConnectAccounts];
	}
}

- (void)networkConnectivityChanged:(NSNotification *)notification
{
	BOOL networkIsReachable;
	
	if (notification){
		networkIsReachable = [[notification object] boolValue];
	}else{
		networkIsReachable = [AINetworkConnectivity networkIsReachable];
	}
	
	NSEnumerator	*enumerator = [[[adium accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while (account = [enumerator nextObject]){
		if ([account connectivityBasedOnNetworkReachability]){
			[self handleConnectivityForAccount:account reachable:networkIsReachable];
		}
	}	
}

#pragma mark Connecting/Disconnecting Accounts
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable
{
	if (reachable){
		//If we are now online and are waiting to connect this account, do it if the account hasn't already
		//been taken care of.
		if ([accountsToConnect containsObject:account]){
			if(![account integerStatusObjectForKey:@"Online"] &&
			   ![account integerStatusObjectForKey:@"Connecting"]){

				[account setPreference:[NSNumber numberWithBool:YES] 
							forKey:@"Online"
							 group:GROUP_ACCOUNT_STATUS];	
			}
		}
	}else{
		//If we are no longer online and this account is connected, disconnect it.
		if (([account integerStatusObjectForKey:@"Online"] ||
			 [account integerStatusObjectForKey:@"Connecting"]) &&
			![account integerStatusObjectForKey:@"Disconnecting"]){

			[account setPreference:[NSNumber numberWithBool:NO] 
							forKey:@"Online"
							 group:GROUP_ACCOUNT_STATUS];
			[accountsToConnect addObject:account];
		}
	}
}

#pragma mark Update List Object
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{ 
	if ([inObject isKindOfClass:[AIAccount class]]){
		if ([inModifiedKeys containsObject:@"Online"] &&
			[inObject integerStatusObjectForKey:@"Online"]){

			//When an account successfully goes online, take it off our list of accounts to connect
			//so that we won't reconnect it after the user disconnects it manually
			[accountsToConnect removeObject:inObject];
		}
	}
	
	return nil;
}

//Autoconnect
#pragma mark Autoconnecting Accounts (at startup)
//Automatically connect to accounts flagged with an auto connect property as soon as a network connection is available
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
		/*
		[NSTimer scheduledTimerWithTimeInterval:2.0
										 target:[AINetworkConnectivity class]
									   selector:@selector(refreshReachabilityAndNotify)
									   userInfo:nil
										repeats:NO];
		 */
	}
}

//Disconnect / Reconnect on sleep --------------------------------------------------------------------------------------
#pragma mark Disconnect/Reconnect On Sleep
//System is sleeping
- (void)systemWillSleep:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;

    //Process each account, looking for any that are online
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
           [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){

			//Disconnect the account and add it to our list to reconnect
			[account setPreference:[NSNumber numberWithBool:NO] 
							forKey:@"Online"
							 group:GROUP_ACCOUNT_STATUS];
			[accountsToConnect addObject:account];
        }
    }
}

//System is waking
- (void)systemDidWake:(NSNotification *)notification
{
	//Immediately connect accounts which are ignoring the server reachability
	{
		NSMutableSet	*newAccountsToConnect = nil;
		NSEnumerator	*enumerator = [accountsToConnect objectEnumerator];
		AIAccount		*account;
		
		while (account = [enumerator nextObject]){
			if (![account connectivityBasedOnNetworkReachability]){
				[account setPreference:[NSNumber numberWithBool:YES] 
								forKey:@"Online"
								 group:GROUP_ACCOUNT_STATUS];
				
				//Remove the account from the array of accounts we are monitoring, for efficiency (since we don't want
				//to rack up a whole mess of accounts we'll never connect in response to network activity).
				if (!newAccountsToConnect) newAccountsToConnect = [accountsToConnect mutableCopy];
				[newAccountsToConnect removeObject:account];
			}
		}
		
		if (newAccountsToConnect){
			[accountsToConnect release];
			accountsToConnect = newAccountsToConnect;
		}
	}
	
	if ([accountsToConnect count]){
		//XXX
		/* If the network is configured via DHCP, this won't connect, but we will get notified
		   when the IP is grabbed from the DHCP server.  If it is configured manually, we won't
		   get an IP changed notification but this will be succesful so long as we delay long enough
		   for the network to be up. We don't always receive the 10.3 callbacks upon waking, so we just use
		   the check 'em all 10.2 method just in case - it can't hurt. */
		
		//It is not certain what order the networkConnectivityDidChange and systemDidWake calls will be made.
		//Ensure that we reconnect accounts as needed after adding them to the accountsToConnect array.
		[self networkConnectivityChanged:nil];

		/*
		[NSTimer scheduledTimerWithTimeInterval:2.0
										 target:[AINetworkConnectivity class]
									   selector:@selector(refreshReachabilityAndNotify)
									   userInfo:nil
										repeats:NO];
		 */
	}
}

#pragma mark Custom servers for accounts in 10.3 and greater
- (void)accountListChanged:(NSNotification *)notification
{
	/*
	NSEnumerator	*enumerator = [[[adium accountController] accountArray] objectEnumerator];
	AIAccount		*account;

	//Remove all current custom observers
	if (customReachabilityRefArray){
		NSEnumerator				*reachabilityEnumerator = [customReachabilityRefArray objectEnumerator];
		SCNetworkReachabilityRef	reachabilityRef;
		
		while (reachabilityRef = (SCNetworkReachabilityRef)[reachabilityEnumerator nextObject]){
			
			//Remove the callback and unschedule it from the run loop
			SCNetworkReachabilitySetCallback(reachabilityRef, NULL, NULL);
			SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, 
													   CFRunLoopGetCurrent(),
													   kCFRunLoopDefaultMode);
			
			//Release it
			CFRelease(reachabilityRef);
		}
		
		[customReachabilityRefArray release]; customReachabilityRefArray = nil;
	}
	
	//For each account, if the account uses custom reachability, add it
	while (account = [enumerator nextObject]){
		const char *customServer = [account customServerToCheckForReachability];
		if (customServer){
			[self scheduleReachabilityCheckFor:customServer account:account];
		}
	}
	*/
}

	
@end