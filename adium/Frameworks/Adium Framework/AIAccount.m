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

// $Id: AIAccount.m,v 1.39 2004/02/02 07:57:39 evands Exp $

#import "AIAccount.h"

#define ATTRIBUTED_STRING_REFRESH    30.0    //delay in seconds between refresh of our attributed string statuses when needed

@interface AIAccount (PRIVATE)
- (void)_setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)_setAccountProfileTo:(NSAttributedString *)profile;
- (void)_startRefreshTimer;
- (void)_stopRefreshTimer;
@end

@implementation AIAccount

//-------------------
//  Public Methods
//-----------------------
//Init the connection
- (id)initWithUID:(NSString *)inUID service:(id <AIServiceController>)inService
{
    [super initWithUID:inUID serviceID:[[inService handleServiceType] identifier]];

    //Get our service
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
    
    refreshDict = [[NSMutableDictionary alloc] init];
    refreshTimer = nil;
	
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
	[self _stopRefreshTimer];
	
    [[adium notificationCenter] removeObserver:self];
    [service release];
	    
    [super dealloc];
}

//Return the service that spawned this account
- (id <AIServiceController>)service
{
    return(service);
}

#pragma mark Preferences
//Store our account prefs in a separate folder to keep things clean
- (NSString *)pathToPreferences
{
    return([[[adium loginController] userDirectory] stringByAppendingPathComponent:ACCOUNT_PREFS_PATH]);
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

#pragma mark Status

//Enable and disable the refresh timers as our account goes online and offline
- (void)setStatusObject:(id)value withOwner:(id)owner forKey:(NSString *)key notify:(BOOL)notify
{
	if([key compare:@"Online"] == 0){
		if([value boolValue]){
			if([refreshDict count])	[self _startRefreshTimer];
		}else{
			[self _stopRefreshTimer];
		}
	}
	
	[super setStatusObject:value withOwner:owner forKey:key notify:notify];
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
                //Retrieve the user's password and then call connect
                [[adium accountController] passwordForAccount:self 
                                              notifyingTarget:self
                                                     selector:@selector(passwordReturnedForConnect:)];
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
    }else if([key compare:@"Handle"] == 0){
		//Account's screen name formatting changed
        [self setStatusObject:[self preferenceForKey:@"Handle" group:GROUP_ACCOUNT_STATUS]
                       forKey:@"Display Name"
                       notify:YES];
	}
}

//Set our away state and message (Pass nil for no away), setting up a refresh timer if the filters changed the string
- (void)updateAttributedStatusString:(NSAttributedString *)status forKey:(NSString *)key
{
    BOOL refreshPeriodically;
    NSAttributedString  *filteredMessage = [[adium contentController] filteredAttributedString:status
																			 listObjectContext:self
                                                                                    isOutgoing:YES];
    //refresh periodically if the filtered string is different from the original one
    refreshPeriodically = (status && (![[status string] isEqualToString:[filteredMessage string]]));
    
    if(refreshPeriodically){
        [refreshDict setObject:status forKey:key];
		[self _startRefreshTimer];

    }else{
        [refreshDict removeObjectForKey:key];
        if([refreshDict count] == 0) [self _stopRefreshTimer];

    }

    //Set the status in account code
    [self setAttributedStatusString:filteredMessage forKey:key];
}
//Refilter the raw away message and call setAccountAwayTo:
- (void)_refreshAttributedStrings:(NSTimer *)inTimer
{
    NSEnumerator    *keyEnumerator = [refreshDict keyEnumerator];
    NSString        *key;
    while (key = [keyEnumerator nextObject]){
        NSAttributedString *filteredMessage = [[adium contentController] filteredAttributedString:[refreshDict objectForKey:key]
																				listObjectContext:self
                                                                                   isOutgoing:YES];
        [self setAttributedStatusString:filteredMessage forKey:key];
    }
}

- (void)_startRefreshTimer
{
	if(!refreshTimer){
		refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:ATTRIBUTED_STRING_REFRESH
														 target:self
													   selector:@selector(_refreshAttributedStrings:) 
													   userInfo:nil repeats:YES] retain];
	}
}

- (void)_stopRefreshTimer
{
	if(refreshTimer){
		[refreshTimer invalidate];
		[refreshTimer release];
		refreshTimer = nil;
	}
}



//Return the account-specific user icon, or the default user icon from the account controlelr if none exists (thee default user icon returns nil if none is set)
//- (NSImage *)userIcon {
//    if (userIcon)
//        return userIcon;
//    else
//        return [[adium accountController] defaultUserIcon];
//}
//
//- (void)setUserIcon:(NSImage *)inUserIcon {
//    [userIcon release];
//    userIcon = [inUserIcon retain];
//}

#pragma mark Subclasses
//Functions for subclasses to override
- (void)initAccount{};
- (void)connect{};
- (void)disconnect{};
- (NSView *)accountView{return(nil);};
- (NSArray *)supportedPropertyKeys{return([NSArray array]);}
- (void)setAttributedStatusString:(NSAttributedString *)inAttributedString forKey:(NSString *)key{};

//Functions subclasses may choose to override
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    return([inAttributedString string]);
		   
		   /*[AIHTMLDecoder encodeHTML:inAttributedString
                              headers:YES
                             fontTags:YES   closeFontTags:YES
                            styleTags:YES   closeStyleTagsOnFontChange:YES
                       encodeNonASCII:NO
                           imagesPath:nil]*/
}


//Contact Status -------------------------------------------------------------------------------------
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






//Auto-Reconnect -------------------------------------------------------------------------------------
#pragma mark Auto-Reconnect
//Attempts to auto-reconnect (after an X second delay)
- (void)autoReconnectAfterDelay:(int)delay
{
    //Install a timer to autoreconnect after a delay
	[reconnectTimer invalidate]; [reconnectTimer release];
    reconnectTimer = [[NSTimer scheduledTimerWithTimeInterval:delay
													   target:self
													 selector:@selector(autoReconnectTimer:)
													 userInfo:nil
													  repeats:NO] retain];
	
    NSLog(@"Auto-Reconnect in %i seconds",delay);
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
        [self connect];
    }
}


//Update Silencing --------------------------------------------------------------------------------------------

//Silence update for the specified interval
- (void)silenceAllHandleUpdatesForInterval:(NSTimeInterval)interval
{
    silentAndDelayed = YES;
	
    [[NSTimer scheduledTimerWithTimeInterval:interval
									  target:self
									selector:@selector(_endSilenceAllUpdates)
									userInfo:nil
									 repeats:NO] retain];
}

//Stop silencing 
- (void)_endSilenceAllUpdates
{
    silentAndDelayed = NO;
}

@end
