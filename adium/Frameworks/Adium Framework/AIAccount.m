/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

// $Id: AIAccount.m,v 1.58 2004/05/19 12:19:56 adamiser Exp $

#import "AIAccount.h"

#define FILTERED_STRING_REFRESH    30.0    //delay in seconds between refresh of our attributed string statuses when needed

@interface AIAccount (PRIVATE)
- (void)_setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)_setAccountProfileTo:(NSAttributedString *)profile;
- (void)_startAttributedRefreshTimer;
- (void)_stopAttributedRefreshTimer;
- (void)_startStringRefreshTimer;
- (void)_stopStringRefreshTimer;
@end

@implementation AIAccount

//-------------------
//  Public Methods
//-----------------------
//Init the connection
- (id)initWithUID:(NSString *)inUID service:(id <AIServiceController>)inService objectID:(int)inObjectID
{
	uniqueObjectID = [[NSString stringWithFormat:@"%i",inObjectID] retain];
	
    [super initWithUID:inUID serviceID:[[inService handleServiceType] identifier]];
    service = [inService retain];

    //Handle the preference changed monitoring (for account status) for our subclass
    [[adium notificationCenter] addObserver:self
								   selector:@selector(_accountPreferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    	
    //Clear the online state.  'Auto-Connect' values are used, not the previous online state.
    [self setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	[self updateStatusForKey:@"Handle"];
    [self updateStatusForKey:@"FullNameAttr"];
    [self updateStatusForKey:@"FormattedUID"];
    
    autoRefreshingKeys = [[NSMutableArray alloc] init];
    attributedRefreshTimer = nil;
	
	reconnectTimer = nil;

	delayedUpdateStatusTimer = nil;
	delayedUpdateStatusTarget = nil;
	
	disconnectedByFastUserSwitch = NO;
	
	if([self disconnectOnFastUserSwitch] && [NSApp isOnPantherOrBetter]) //only install on Panther
    {
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(switchHandler:) 
																   name:NSWorkspaceSessionDidBecomeActiveNotification 
																 object:nil];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
															   selector:@selector(switchHandler:) 
																   name:NSWorkspaceSessionDidResignActiveNotification
																 object:nil];
    }
	
    //Init the account
    [self initAccount];
    
    return(self);
}

//Dealloc
- (void)dealloc
{
	[delayedUpdateStatusTarget release];
	[delayedUpdateStatusTimer invalidate]; [delayedUpdateStatusTimer release];
	[reconnectTimer invalidate]; [reconnectTimer release];
	
	[self _stopAttributedRefreshTimer];
	[self _stopStringRefreshTimer];
	[autoRefreshingKeys release]; autoRefreshingKeys = nil;
	
    [[adium notificationCenter] removeObserver:self];
    [service release];
	[uniqueObjectID release];
    
    [super dealloc];
}

//Return the service that spawned this account
- (id <AIServiceController>)service
{
    return(service);
}

//Our unique object ID is the number associated with this account
- (NSString *)uniqueObjectID
{
	return(uniqueObjectID);
}

//Preferences ----------------------------------------------------------------------------------------------------------
#pragma mark Preferences
//Store our account prefs in a separate folder to keep things clean
- (NSString *)pathToPreferences
{
    return(ACCOUNT_PREFS_PATH);
}

//Monitor preferences changed for account status keys, and pass these to our subclass
- (void)_accountPreferencesChanged:(NSNotification *)notification
{
    //Ignore changes directed at another account
    if([notification object] == nil || [notification object] == self){
        NSString    *group = [[notification userInfo] objectForKey:@"Group"];
        
        //For convenience, we let the account know when a status key for it has changed
        if([group compare:GROUP_ACCOUNT_STATUS] == 0){
            NSString	*key = [[notification userInfo] objectForKey:@"Key"];
            
            [self updateStatusForKey:key];
        }
    }
}

- (BOOL)requiresPassword
{
	return YES;
}

//Callback after the user enters their password for connecting
- (void)passwordReturnedForConnect:(NSString *)inPassword
{
    //If a password was returned, and we're still waiting to connect
    if(inPassword && [inPassword length] != 0 &&
       ![[self statusObjectForKey:@"Online"] boolValue] &&
       ![[self statusObjectForKey:@"Connecting"] boolValue]){
        //Save the new password
        if(password != inPassword){
            [password release]; password = [inPassword copy];
        }
        
        //Tell the account to connect
        [self connect];
    }
}

- (BOOL)disconnectOnFastUserSwitch
{
	return NO;
}
- (void)switchHandler:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification]) {
		//Deactivation
		if ([[self statusObjectForKey:@"Online"] boolValue]){
			[self setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
			disconnectedByFastUserSwitch = YES;
		}
		
	}else if (disconnectedByFastUserSwitch){
		//Activation and we disconnected before because of a fast user switch
        [self setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
		disconnectedByFastUserSwitch = NO;
	}
}
//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Enable and disable the refresh timers as our account goes online and offline; 
//if we get informed that we are disconnecting, stop them sooner than later.
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify
{
	if([key isEqualToString:@"Online"]){
		if([value boolValue]){
			if([autoRefreshingKeys count])	[self _startAttributedRefreshTimer];
		}else{
			[self _stopAttributedRefreshTimer];
		}
	}else if ([key isEqualToString:@"Disconnecting"]){
		if ([value boolValue]){
			[self _stopAttributedRefreshTimer];	
		}
	}
	
	[super setStatusObject:value forKey:key notify:notify];
}

//Update this account's status
//Status keys that are used by every account (Or used by the majority of accounts and harmless to others) should be
//placed here, instead of duplicated in each account plugin.
- (void)updateStatusForKey:(NSString *)key
{
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];
    
    //Online status changed
    //Call connect or disconnect as appropriate
    if([key compare:@"Online"] == 0){
        if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            if(!areOnline && ![[self statusObjectForKey:@"Connecting"] boolValue]){
				if ([self requiresPassword]){
					//Retrieve the user's password and then call connect
					[[adium accountController] passwordForAccount:self 
												  notifyingTarget:self
														 selector:@selector(passwordReturnedForConnect:)];
				}else{
					//Connect immediately without retrieving a password
					[self connect];
				}
				
            }
        }else{
            if(areOnline && ![[self statusObjectForKey:@"Disconnecting"] boolValue]){
                //Disconnect
                [self disconnect];
            }
        }
		
    }else if([key compare:@"FullNameAttr"] == 0) {
        //Account's full name (alias) formatting changed
        //Update the display name for this account
		NSString	*displayName = [[[self preferenceForKey:@"FullNameAttr" group:GROUP_ACCOUNT_STATUS] attributedString] string];
		if([displayName length] == 0) displayName = nil;
		
		[[self displayArrayForKey:@"Display Name"] setObject:displayName
												   withOwner:self];
		//notify
		[[adium contactController] listObjectAttributesChanged:self
												  modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
		
    }else if([key compare:@"FormattedUID"] == 0){
		//Transfer formatted UID to status dictionary
		[self setStatusObject:[self preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS]
					   forKey:@"FormattedUID"
					   notify:YES];

	} 
}
- (void)updateStatusForAutoRefreshingKey:(NSString *)key
{
	//
}


//Auto-Refreshing Status String ----------------------------------------------------------------------------------------
//Tests an attributed status string.  If the string contains dynamic content it will be scheduled for automatic
//refreshing and periodically updated.  If the string does not contain dynamic content any existing scheduling for
//it will be removed.  Call this method when the value of an attributed status that supports automatic refreshing
//is changed by the user.  This method returns the current value of the auto-refreshing string for you to use.
- (NSAttributedString *)autoRefreshingOutgoingContentForStatusKey:(NSString *)key
{
	NSAttributedString	*originalValue = [[self preferenceForKey:key group:GROUP_ACCOUNT_STATUS] attributedString];
	NSAttributedString  *filteredValue = nil;
    BOOL 				refreshPeriodically;
	NSData				*data;
	
	//Filter the content
	filteredValue = [[adium contentController] filterAttributedString:originalValue
													  usingFilterType:AIFilterContent
															direction:AIFilterOutgoing
															  context:self];
	
	//Refresh periodically if the filtered string is different from the original one
	if(originalValue && (![[originalValue string] isEqualToString:[filteredValue string]])){
		if(![autoRefreshingKeys containsObject:key]){
			[autoRefreshingKeys addObject:key];
			[self _startAttributedRefreshTimer];
		}
	}else{
		[autoRefreshingKeys removeObject:key];
		if([autoRefreshingKeys count] == 0) [self _stopAttributedRefreshTimer];
	}

	return(filteredValue);
}

//Refilter the raw attributed string and call setAttributedStatusString:forKey:
- (void)_refreshAttributedStrings:(NSTimer *)inTimer
{
    NSEnumerator    *keyEnumerator = [autoRefreshingKeys objectEnumerator];
    NSString        *key;
    while(key = [keyEnumerator nextObject]){
		[self updateStatusForKey:key];
    }
}

//Start/stop timer
- (void)_startAttributedRefreshTimer
{
	if(!attributedRefreshTimer){
		attributedRefreshTimer = [[NSTimer scheduledTimerWithTimeInterval:FILTERED_STRING_REFRESH
																   target:self
																 selector:@selector(_refreshAttributedStrings:) 
																 userInfo:nil
																  repeats:YES] retain];
	}
}
- (void)_stopAttributedRefreshTimer
{
	if(attributedRefreshTimer){
		[attributedRefreshTimer invalidate];
		[attributedRefreshTimer release];
		attributedRefreshTimer = nil;
	}
}


//Subclasses -----------------------------------------------------------------------------------------------------------
#pragma mark Subclasses
//Functions for subclasses to override
- (void)initAccount{};
- (void)connect{};
- (void)disconnect{};
- (NSArray *)supportedPropertyKeys{return([NSArray array]);}

//Functions subclasses may choose to override
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    return([inAttributedString string]);
}


//Contact Status -------------------------------------------------------------------------------------------------------
#pragma mark Contact Status
//If an account wants to, it can implement delayedUpdateContactStatus to protect itself from flooding
//While updateContactStatus may be called rapidly, delayedUpdateContactStatus will be called no quicker
//than the delay specified by delayedUpdateStatusInterval.
- (void)updateContactStatus:(AIListContact *)inContact
{
	//If there is no outstanding delay
	if(!delayedUpdateStatusTimer){
		//Update this contact's status immediately.
		[self delayedUpdateContactStatus:inContact];
		
		//Guard against subsequent updates
		delayedUpdateStatusTarget = nil;
		delayedUpdateStatusTimer = [[NSTimer scheduledTimerWithTimeInterval:[self delayedUpdateStatusInterval]
																	 target:self
																   selector:@selector(_delayedUpdateStatusTimer:)
																   userInfo:nil
																	repeats:NO] retain];
	}else{
		//If there is an outstanding delay, set this contact as the target
		[delayedUpdateStatusTarget release]; delayedUpdateStatusTarget = [inContact retain];
	}
}

- (void)_delayedUpdateStatusTimer:(NSTimer *)inTimer
{
	if(delayedUpdateStatusTarget){
		[self delayedUpdateContactStatus:delayedUpdateStatusTarget];
		[delayedUpdateStatusTarget release]; delayedUpdateStatusTarget = nil;
	}
	[delayedUpdateStatusTimer invalidate];
	[delayedUpdateStatusTimer release];
	delayedUpdateStatusTimer = nil;
}

//Implement these methods instead of updateContactStatus: if rapid updates are a problem
- (void)delayedUpdateContactStatus:(AIListContact *)inContact{
	//Guarded update
}
- (float)delayedUpdateStatusInterval{
	return(3.0); //5 Seconds default
}

//Contacts -------------------------------------------------------------------------------------------------------------
#pragma mark Contacts
- (AIListContact *)_contactWithUID:(NSString *)sourceUID
{
	AIListContact *contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
																 accountID:[self uniqueObjectID]
																	   UID:sourceUID];
	return contact;
}

//Auto-Reconnect -------------------------------------------------------------------------------------------------------
#pragma mark Auto-Reconnect
//Attempts to auto-reconnect (after an X second delay)
- (void)autoReconnectAfterNumberDelay:(NSNumber *)delayNumber
{
	[self autoReconnectAfterDelay:[delayNumber intValue]];
}
- (void)autoReconnectAfterDelay:(int)delay
{
    //Install a timer to autoreconnect after a delay
	[reconnectTimer invalidate]; [reconnectTimer release];
    reconnectTimer = [[NSTimer scheduledTimerWithTimeInterval:delay
													   target:self
													 selector:@selector(autoReconnectTimer:)
													 userInfo:nil
													  repeats:NO] retain];
}

//Perform the auto-reconnect
- (void)autoReconnectTimer:(NSTimer *)inTimer
{
	//Clean up the timer
	[reconnectTimer invalidate];
	[reconnectTimer release];
	reconnectTimer = nil;

    //If we still want to be online, and we're not yet online, continue with the reconnect
    if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue] &&
	   ![[self statusObjectForKey:@"Online"] boolValue] && ![[self statusObjectForKey:@"Connecting"] boolValue]){
        NSLog(@"Attempting Auto-Reconnect");
		[self setPreference:[NSNumber numberWithBool:YES] 
					 forKey:@"Online" 
					  group:GROUP_ACCOUNT_STATUS];
    }
}


//Update Silencing -----------------------------------------------------------------------------------------------------
#pragma mark Update Silencing
//Silence update for the specified interval
- (void)silenceAllHandleUpdatesForInterval:(NSTimeInterval)interval
{
    silentAndDelayed = YES;
	
    [NSTimer scheduledTimerWithTimeInterval:interval
									 target:self
								   selector:@selector(_endSilenceAllUpdates)
								   userInfo:nil
									repeats:NO];
}

//Stop silencing 
- (void)_endSilenceAllUpdates
{
    silentAndDelayed = NO;
}

@end
