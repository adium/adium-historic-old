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

// $Id: AIAccount.m,v 1.56 2004/05/15 22:22:14 evands Exp $

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
    [self updateStatusForKey:@"FullName"];
    [self updateStatusForKey:@"FormattedUID"];
    
    attributedRefreshDict = [[NSMutableDictionary alloc] init];
    attributedRefreshTimer = nil;
	stringRefreshDict = [[NSMutableDictionary alloc] init];
	stringRefreshTimer = nil;
	
	reconnectTimer = nil;

	delayedUpdateStatusTimer = nil;
	delayedUpdateStatusTarget = nil;
	
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
	[attributedRefreshDict release]; attributedRefreshDict = nil;
	[stringRefreshDict release]; stringRefreshDict = nil;
	
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


//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Enable and disable the refresh timers as our account goes online and offline; 
//if we get informed that we are disconnecting, stop them sooner than later.
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify
{
	if([key isEqualToString:@"Online"]){
		if([value boolValue]){
			if([attributedRefreshDict count])	[self _startAttributedRefreshTimer];
			if([stringRefreshDict count])		[self _startStringRefreshTimer];
		}else{
			[self _stopAttributedRefreshTimer];
			[self _stopStringRefreshTimer];
		}
	}else if ([key isEqualToString:@"Disconnecting"]){
		if ([value boolValue]){
			[self _stopAttributedRefreshTimer];	
			[self _stopStringRefreshTimer];
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
    //
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
		
    }else if([key compare:@"FullName"] == 0) {
        //Account's full name (alias) formatting changed
        //Update the display name for this account
        //
		NSString *displayName = [self preferenceForKey:@"FullName" group:GROUP_ACCOUNT_STATUS];

		if (!displayName || ![displayName length])
			displayName = nil;
		
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

//Set an attributed status value (nil for no value), setting up a refresh timer if the filters changed the string
- (void)updateAttributedStatusString:(NSAttributedString *)status forKey:(NSString *)key
{
    BOOL refreshPeriodically;
    NSAttributedString  *filteredMessage = [[adium contentController] filteredAttributedString:status
																			 listObjectContext:self
                                                                                    isOutgoing:YES];
    //refresh periodically if the filtered string is different from the original one
    refreshPeriodically = (status && (![[status string] isEqualToString:[filteredMessage string]]));
    
    if(refreshPeriodically){
        [attributedRefreshDict setObject:status forKey:key];
		[self _startAttributedRefreshTimer];

    }else{
        [attributedRefreshDict removeObjectForKey:key];
        if([attributedRefreshDict count] == 0) [self _stopAttributedRefreshTimer];

    }

    //Set the status in account code
    [self setAttributedStatusString:filteredMessage forKey:key];
}
//Set an string status value (nil for no value), setting up a refresh timer if the filters changed the string
- (void)updateStatusString:(NSString *)status forKey:(NSString *)key
{
    BOOL refreshPeriodically;
    NSString  *filteredMessage = [[adium contentController] filteredString:status
														 listObjectContext:self];
	
    //refresh periodically if the filtered string is different from the original one
    refreshPeriodically = (status && (![status isEqualToString:filteredMessage]));
    
    if(refreshPeriodically){
        [stringRefreshDict setObject:status forKey:key];
		[self _startStringRefreshTimer];
		
    }else{
        [stringRefreshDict removeObjectForKey:key];
        if([stringRefreshDict count] == 0) [self _stopStringRefreshTimer];
		
    }
	
    //Set the status in account code
    [self setStatusString:filteredMessage forKey:key];
}

//Refilter the raw attributed string and call setAttributedStatusString:forKey:
- (void)_refreshAttributedStrings:(NSTimer *)inTimer
{
    NSEnumerator    *keyEnumerator = [attributedRefreshDict keyEnumerator];
    NSString        *key;
    while (key = [keyEnumerator nextObject]){
        NSAttributedString *filteredMessage = [[adium contentController] filteredAttributedString:[attributedRefreshDict objectForKey:key]
																				listObjectContext:self
                                                                                   isOutgoing:YES];
        [self setAttributedStatusString:filteredMessage forKey:key];
    }
}
//Refilter the raw string and call setStatusString:forKey:
- (void)_refreshStrings:(NSTimer *)inTimer
{
    NSEnumerator    *keyEnumerator = [stringRefreshDict keyEnumerator];
    NSString        *key;
    while (key = [keyEnumerator nextObject]){
        NSString *filteredMessage = [[adium contentController] filteredString:[stringRefreshDict objectForKey:key]
																	  listObjectContext:self];
        [self setStatusString:filteredMessage forKey:key];
    }
}

//Start timers
- (void)_startAttributedRefreshTimer
{
	if(!attributedRefreshTimer){
		attributedRefreshTimer = [[NSTimer scheduledTimerWithTimeInterval:FILTERED_STRING_REFRESH
														 target:self
													   selector:@selector(_refreshAttributedStrings:) 
													   userInfo:attributedRefreshDict repeats:YES] retain];
	}
}
- (void)_startStringRefreshTimer
{
	if(!stringRefreshTimer){
		stringRefreshTimer = [[NSTimer scheduledTimerWithTimeInterval:FILTERED_STRING_REFRESH
															   target:self
															 selector:@selector(_refreshStrings:) 
															 userInfo:stringRefreshDict repeats:YES] retain];
	}
}

//Stop timers
- (void)_stopAttributedRefreshTimer
{
	if(attributedRefreshTimer){
		[attributedRefreshTimer invalidate];
		[attributedRefreshTimer release];
		attributedRefreshTimer = nil;
	}
}
- (void)_stopStringRefreshTimer
{
	if(stringRefreshTimer){
		[stringRefreshTimer invalidate];
		[stringRefreshTimer release];
		stringRefreshTimer = nil;
	}
}


//Subclasses -----------------------------------------------------------------------------------------------------------
#pragma mark Subclasses
//Functions for subclasses to override
- (void)initAccount{};
- (void)connect{};
- (void)disconnect{};
- (NSArray *)supportedPropertyKeys{return([NSArray array]);}
- (void)setAttributedStatusString:(NSAttributedString *)inAttributedString forKey:(NSString *)key{};
- (void)setStatusString:(NSString *)inString forKey:(NSString *)key{};

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
