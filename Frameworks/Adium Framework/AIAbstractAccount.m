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

#import "AIAbstractAccount.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIStatusController.h"
#import "AIListContact.h"
#import "AIPreferenceController.h"
#import "AIService.h"
#import "AIStatus.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AISleepNotification.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>

#define FILTERED_STRING_REFRESH    30.0    //delay in seconds between refresh of our attributed string statuses when needed

/*!
 * @class AIAbstractAccount
 * @brief Abstract AIAccount methods
 *
 * This category exists to move as much 'meat' as possible out of <tt>AIAccount</tt> for simplification.  The methods
 * here provide default and common behavior for account code.
 */
@implementation AIAccount(Abstract)

/*!
 * @brief Init an account
 */
- (id)initWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID service:(AIService *)inService
{
	NSString	*accountModifiedUID;
	
    self = [super initWithUID:inUID service:inService];

	internalObjectID = [inInternalObjectID retain];
	
	accountModifiedUID = [self accountWillSetUID:UID];
	if(accountModifiedUID != UID){
		[UID release];
		UID = [accountModifiedUID retain];
	}
	
	namesAreCaseSensitive = [[self service] caseSensitive];
	
    //Handle the preference changed monitoring (for account status) for our subclass
 	[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
   	
    //Clear the online state.  'Auto-Connect' values are used, not the previous online state.
    [self setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
    [self updateStatusForKey:@"FullNameAttr"];
    [self updateStatusForKey:@"FormattedUID"];
	
    autoRefreshingKeys = [[NSMutableArray alloc] init];
    attributedRefreshTimer = nil;
	reconnectTimer = nil;
	delayedUpdateStatusTimer = nil;
	delayedUpdateStatusTarget = nil;
	silenceAllContactUpdatesTimer = nil;
	disconnectedByFastUserSwitch = NO;
	
    //Init the account
	[self initFUSDisconnecting];
    [self initAccount];
    
    return(self);
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	[delayedUpdateStatusTarget release];
	[delayedUpdateStatusTimer invalidate]; [delayedUpdateStatusTimer release];
	[reconnectTimer invalidate]; [reconnectTimer release];
	[internalObjectID release];
	
	[self _stopAttributedRefreshTimer];
	[autoRefreshingKeys release]; autoRefreshingKeys = nil;
	
    [[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
    [super dealloc];
}

/*!
 * @brief Use our account number as internalObjectID
 *
 * Each user account is assigned a unique number for identification.  AIObject will use our UID and ServiceID as the
 * internalObjectID by default.  But for accounts we'll want to use our account number instead, since UID and ServiceID
 * may change and we want to use the same preferences even if they do.
 */
- (NSString *)internalObjectID
{
	return(internalObjectID);
}

/*!
 * @brief Improved description for NSLog
 */
- (NSString *)description
{
	return([NSString stringWithFormat:@"%@:%@",[super description],[self UID]]);
}

/*!
 * @brief Custom path for account preferences
 *
 * Store our account preferences in a separate folder from object preferences to keep things clean
 */
- (NSString *)pathToPreferences
{
    return(ACCOUNT_PREFS_PATH);
}

/*!
 * @brief User icon
 *
 * Convenience method for accessing the user icon (from the status preferences) for this account.
 * @return NSData for this account's user icon
 */
- (NSData *)userIconData
{
	return([self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]);	
}

/*!
 * @brief Set user icon
 *
 * Convenience method for setting the user icon (into the status preferences) for this account.
 * @param inData NSData for this account's user icon
 */
- (void)setUserIconData:(NSData *)inData
{
	[self setPreference:inData
				 forKey:KEY_USER_ICON
				  group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 */
- (NSString *)host
{
	return([self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS]);
}

/*!
 * @brief Connect Port
 *
 * Convenience method for retrieving the connect port for this account
 */
- (int)port
{
	return([[self preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS] intValue]);
}

/*!
 * @brief Change the UID of this account
 */
- (void)filterAndSetUID:(NSString *)inUID
{
	//Filter our UID both with and without removing ignored characters
	NSString	*newProposedUID = [[self service] filterUID:inUID removeIgnoredCharacters:YES];
	NSString	*newProposedFormattedUID = [[self service] filterUID:inUID removeIgnoredCharacters:NO];
	BOOL		didChangeUID = NO;

	//Give the account a chance to modify the UID
	newProposedUID = [self accountWillSetUID:newProposedUID];

	//Set our UID first (since [self formattedUID] uses the UID as necessary)
	if(![newProposedUID isEqualToString:[self UID]]){
		[UID release];
		UID = [newProposedUID retain];
		
		//Save our changed UID
		[[adium accountController] saveAccounts];
		
		didChangeUID = YES;
	}

	//Set our formatted UID if necessary
	if(![newProposedFormattedUID isEqualToString:[self formattedUID]]){
		[self setPreference:newProposedFormattedUID
					 forKey:@"FormattedUID"
					  group:GROUP_ACCOUNT_STATUS];
	}
	
	if(didChangeUID){
		[self didChangeUID];
	}
}

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
/*!
 * @brief Catch status changes for this account
 *
 * For convenience, we let the account know when an account status preference for it has changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(!object || object == self){
		if([[self supportedPropertyKeys] containsObject:key]){
			[self updateStatusForKey:key];
		}
	}
}

/*!
 * @brief Silence contact status updates
 *
 * Instructs the account code to keep contact status updates silent for the specified interval.  This greatly increases
 * performance while connecting or perfoming an action that will generate a large number of contact status updates.
 * Account code should honor the silentAndDelayed flag where-ever possible.
 */
- (void)silenceAllContactUpdatesForInterval:(NSTimeInterval)interval
{
    silentAndDelayed = YES;
	
	if(silenceAllContactUpdatesTimer){
		[silenceAllContactUpdatesTimer invalidate];
		[silenceAllContactUpdatesTimer release]; silenceAllContactUpdatesTimer = nil;
	}
    silenceAllContactUpdatesTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
																	  target:self
																	selector:@selector(_endSilenceAllUpdates)
																	userInfo:nil
																	 repeats:NO] retain];
}
- (void)_endSilenceAllUpdates
{
	[silenceAllContactUpdatesTimer release]; silenceAllContactUpdatesTimer = nil;
    silentAndDelayed = NO;
}

/*!
 * @brief Update a contact's status
 *
 * Adium is requesting that the account update a contact's status.  This method is primarily called by the get info
 * window.  Here we implement a guard to limit the rate at which contact info is looked up, which account code can use
 * via the delayedUpdateContactStatus method at their convenience.
 */
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

/*!
 * @brief Handle common account status updates
 *
 * We handle some common account status updates here for convenience.  Things that the majority of protocols will use
 * such as online state, full name, and display name.
 */
- (void)updateCommonStatusForKey:(NSString *)key
{
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];
    
    //Online status changed
    //Call connect or disconnect as appropriate
    if([key isEqualToString:@"Online"]){
        if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            if(!areOnline && ![[self statusObjectForKey:@"Connecting"] boolValue]){
				if ([self requiresPassword]){
					//Retrieve the user's password and then call connect
					[[adium accountController] passwordForAccount:self 
												  notifyingTarget:self
														 selector:@selector(passwordReturnedForConnect:context:)
														  context:nil];
				}else{
					//Connect immediately without retrieving a password
					[self connect];
				}
				
            }
        }else{
            if((areOnline || ([[self statusObjectForKey:@"Connecting"] boolValue])) && 
			   (![[self statusObjectForKey:@"Disconnecting"] boolValue])){
                //Disconnect
                [self disconnect];
            }
        }
		
    }else if([key isEqualToString:@"StatusState"]){

		if(areOnline){
			//Set the status state after filtering its statusMessage as appropriate
			[self autoRefreshingOutgoingContentForStatusKey:@"StatusState"
												   selector:@selector(gotFilteredStatusMessage:forStatusState:)
													context:[self statusObjectForKey:@"StatusState"]];
		}else{
			//XXX behavior for setting a status when account is currently offline:
			//Check if account is 'enabled' in the accounts preferences.  If so, bring it online in the specified state.
			[self setPreference:[NSNumber numberWithBool:YES]
						 forKey:@"Online"
						  group:GROUP_ACCOUNT_STATUS];
		}
		
	}else if([key isEqualToString:@"FullNameAttr"]) {
		//Update the display name for this account
		NSString	*displayName = [[[self preferenceForKey:@"FullNameAttr" group:GROUP_ACCOUNT_STATUS] attributedString] string];
		if([displayName length] == 0) displayName = nil;
		
		[[self displayArrayForKey:@"Display Name"] setObject:displayName
												   withOwner:self];
		//notify
		[[adium contactController] listObjectAttributesChanged:self
												  modifiedKeys:[NSSet setWithObject:@"Display Name"]];

    }else if([key isEqualToString:@"FormattedUID"]){
		//Transfer formatted UID to status dictionary
		[self setStatusObject:[self preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS]
					   forKey:@"FormattedUID"
					   notify:YES];
		
	} 
}

#pragma mark Status States

/*!
 * @brief Set the account to a specified statusState
 *
 * This is the entry point for setting an AIAccount to a specified state.
 */
- (void)setStatusState:(AIStatus *)statusState
{
	if([statusState statusType] == AIOfflineStatusType){
		[self setPreference:[NSNumber numberWithBool:NO] 
					 forKey:@"Online"
					  group:GROUP_ACCOUNT_STATUS];
		
	}else{
		//Store the status state as a status object so it can be easily used elsewhere
		[self setStatusObject:statusState forKey:@"StatusState" notify:NotifyLater];
		
		//Update us to the new state
		[self updateStatusForKey:@"StatusState"];
		
		/* Set our IdleSince time if appropriate... this will just be set when the state is selected; the account
			* is thereafter responsible for updating any serverside settings as needed.  All of our current services will handle
			* updating idle time as it changes automatically. This is a per-account preference setting; it will override
			* any global idle setting for this account but won't change it. */	
		if([[self supportedPropertyKeys] containsObject:@"IdleSince"]){
			NSDate	*idleSince;
			
			idleSince = ([statusState shouldForceInitialIdleTime] ?
						 [NSDate dateWithTimeIntervalSinceNow:-([statusState forcedInitialIdleTime]+1)] :
						 nil);

			if([self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] != idleSince){
				[self setPreference:idleSince forKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			}
		}
		
		[self notifyOfChangedStatusSilently:YES];
	}
}

/*!
 * @brief Set a status state without going online
 *
 * Set the status state as a status object so that if we sign on later we will update to the proper state.
 * Do not ask the account to actually switch to the state; do not perform any notifications about the change.
 * This is intended for use by the statusController only.
 */
- (void)setStatusStateAndRemainOffline:(AIStatus *)statusState
{
	//Store the status state as a status object so it can be easily used elsewhere
	[self setStatusObject:statusState forKey:@"StatusState" notify:NotifyNever];

	if([[self supportedPropertyKeys] containsObject:@"IdleSince"]){
		NSDate	*idleSince;
		
		idleSince = ([statusState shouldForceInitialIdleTime] ?
					 [NSDate dateWithTimeIntervalSinceNow:-[statusState forcedInitialIdleTime]] :
					 nil);
		
		if([self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] != idleSince){
			[self setPreference:idleSince forKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
		}		
	}
}

/*!
 * @brief Callback from the threaded filter performed in [self updateStatusForKey:@"StatusState"]
 */
- (void)gotFilteredStatusMessage:(NSAttributedString *)statusMessage forStatusState:(AIStatus *)statusState
{
	[self setStatusState:statusState
	  usingStatusMessage:statusMessage];
}

- (AIStatusSummary)statusSummary
{
	AIStatusType	statusType = [[self statusState] statusType];
	
	if(statusType == AIOfflineStatusType){
		return AIOfflineStatus;
	}else{
		if(statusType == AIAwayStatusType){
			if ([self statusObjectForKey:@"IdleSince"]){
				return AIAwayAndIdleStatus;
			}else{
				return AIAwayStatus;
			}

		}else if([self statusObjectForKey:@"IdleSince"]){
			return AIIdleStatus;

		}else{
			return AIAvailableStatus;

		}
	}
}

- (AIStatus *)statusState
{
	if ([self integerStatusObjectForKey:@"Online"]){
		AIStatus	*statusState = [self statusObjectForKey:@"StatusState"];
		if(!statusState){
			statusState = [[adium statusController] defaultInitialStatusState];
			[self setStatusStateAndRemainOffline:statusState];		
		}
		
		return(statusState);
	}else{
		return([[adium statusController] offlineStatusState]);
	}
}

- (NSString *)statusName
{
	return([[self statusState] statusName]);
}

- (AIStatusType)statusType
{
	return([[self statusState] statusType]);
}

- (NSAttributedString *)statusMessage
{
	return([[self statusState] statusMessage]);
}



#pragma mark Passwowrds

/*!
 * @brief Password entered callback
 *
 * Callback after the user enters her password for connecting; finish the connect process.
 */
- (void)passwordReturnedForConnect:(NSString *)inPassword context:(id)inContext
{
    //If a password was returned, and we're still waiting to connect
    if(inPassword && [inPassword length] != 0){
		if(![[self statusObjectForKey:@"Online"] boolValue] &&
		   ![[self statusObjectForKey:@"Connecting"] boolValue]){
			//Save the new password
			if(password != inPassword){
				[password release]; password = [inPassword retain];
			}
			
			//Tell the account to connect
			[self connect];
		}

    }else{
		[self setPreference:nil
					 forKey:@"Online"
					  group:GROUP_ACCOUNT_STATUS];
	}
}


//Auto-Refreshing Status String ----------------------------------------------------------------------------------------
#pragma mark Auto-Refreshing Status String
/*!
 * @brief Schedule/Unschedule a status string for auto-refreshing if it contains dynamic content
 *
 * Tests an attributed status string.  If the string contains dynamic content it will be scheduled for automatic
 * refreshing and periodically updated.  If the string does not contain dynamic content any existing scheduling for
 * it will be removed.  Call this method when the value of an attributed status that supports automatic refreshing
 * is changed by the user.  This method returns the current value of the auto-refreshing string for you to use.
 * @param key Status key to check for auto-refreshing content
 */
- (NSAttributedString *)autoRefreshingOutgoingContentForStatusKey:(NSString *)key
{
	NSAttributedString	*originalValue = [self autoRefreshingOriginalAttributedStringForStatusKey:key];
	NSAttributedString  *filteredValue;
	
	filteredValue = [[adium contentController] filterAttributedString:originalValue
													  usingFilterType:AIFilterContent
															direction:AIFilterOutgoing
															  context:self];
	
	//Refresh periodically if the filtered string is different from the original one
	if(originalValue && (![[originalValue string] isEqualToString:[filteredValue string]])){
		[self startAutoRefreshingStatusKey:key];
	}else{
		[self stopAutoRefreshingStatusKey:key];
	}

	return (filteredValue);
}

/*!
 * @brief threaded autoRefreshingOutgoingContentForStatusKey
 *
 * Same as autoRefreshingOutgoingContentForStatusKey: but does its filtering in the contentController filterThread,
 * sending back the filtered attributedString to self on selector "selector" whenever it's complete.
 * @param key Status key to check for auto-refreshing content
 * @param selector Selector to call when status string is updated
 * @param context Context to use for filtering the status string (Optional)
 */
- (void)autoRefreshingOutgoingContentForStatusKey:(NSString *)key selector:(SEL)selector
{
	[self autoRefreshingOutgoingContentForStatusKey:key selector:selector context:nil];
}
- (void)autoRefreshingOutgoingContentForStatusKey:(NSString *)key selector:(SEL)selector context:(id)originalContext
{
	NSAttributedString	*originalValue = [self autoRefreshingOriginalAttributedStringForStatusKey:key];
	NSMutableDictionary	*contextDict;
	
	contextDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:NSStringFromSelector(selector), @"selectorString",
		key, @"key", nil];
	
	if(originalValue){
		[contextDict setObject:originalValue forKey:@"originalValue"];
	}
	
	if(originalContext){
		[contextDict setObject:originalContext forKey:@"originalContext"];
	}
	
	//Filter the content
	[[adium contentController] filterAttributedString:originalValue
									  usingFilterType:AIFilterContent
											direction:AIFilterOutgoing
										filterContext:self
									  notifyingTarget:self
											 selector:@selector(gotFilteredOutgoingContent:context:)
											  context:contextDict];
}

/*!
 * @brief Provide the NSAttributedString which will be filtered for a given status key
 *
 * In general, returns the preference for the key as an attributed string.
 * For statuses, returns the status message of the current statusState.
 */
- (NSAttributedString *)autoRefreshingOriginalAttributedStringForStatusKey:(NSString *)key
{
	NSAttributedString	*originalValue;
	
	if([key isEqualToString:@"StatusState"]){
		originalValue = [[self statusState] statusMessage];

	}else{
		originalValue = [[self preferenceForKey:key group:GROUP_ACCOUNT_STATUS] attributedString];		
	}

	return originalValue;
}

/*!
 * @brief Callback for threaded filtering
 *
 * Called once threaded filtering of a status string is complete
 * @param filteredValue Filtered attributed string
 * @param contextDict Context used for filtering
 */
- (void)gotFilteredOutgoingContent:(NSAttributedString *)filteredValue context:(NSDictionary *)contextDict
{
	NSAttributedString	*originalValue = [contextDict objectForKey:@"originalValue"];
	NSString			*key = [contextDict objectForKey:@"key"];
	
	SEL					selector = NSSelectorFromString([contextDict objectForKey:@"selectorString"]);
	id					originalContext = [contextDict objectForKey:@"originalContext"];
	
	//Refresh periodically if the filtered string is different from the original one
	if(originalValue && (![[originalValue string] isEqualToString:[filteredValue string]])){
		[self startAutoRefreshingStatusKey:key];
	}else{
		[self stopAutoRefreshingStatusKey:key];
	}
	
	//
	if(originalContext){
		[self performSelector:selector
				   withObject:filteredValue
				   withObject:originalContext];
	}else{
		[self performSelector:selector
				   withObject:filteredValue];
	}
}

/*!
 * @brief Start auto-refreshing a status key
 *
 * Starts auto-refreshing one of our account status attributed strings.  The string will be automatically reprocessed
 * and updated when any dynamic content it contains changes.
 */
- (void)startAutoRefreshingStatusKey:(NSString *)key
{
	if(![autoRefreshingKeys containsObject:key]){
		[autoRefreshingKeys addObject:key];
		[self _startAttributedRefreshTimer];
	}
}

/*!
 * @brief Stop auto-refreshing a status key
 *
 * Stops an account status string from auto-refreshing
 */
- (void)stopAutoRefreshingStatusKey:(NSString *)key
{
	[autoRefreshingKeys removeObject:key];
	if([autoRefreshingKeys count] == 0) [self _stopAttributedRefreshTimer];
}

/*!
 * @brief Suspend auto-refreshing timer when disconnected
 *
 * Here we suspend the auto-refreshing timer when the account goes offline, and restart it when the account goes back
 * online.  This prevents us from running the timer for offline accounts.
 */
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
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

/*!
 * @brief Start the auto-refreshing status timer
 */
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

/*!
 * @brief Stop the auto-refreshing status timer
 */
- (void)_stopAttributedRefreshTimer
{
	if(attributedRefreshTimer){
		[attributedRefreshTimer invalidate];
		[attributedRefreshTimer release];
		attributedRefreshTimer = nil;
	}
}

/*!
 * @brief Refresh auto-refreshing strings
 *
 * This is the auto-refreshing timer method, it refreshes all auto-refreshing account status strings on an interval.
 */
- (void)_refreshAttributedStrings:(NSTimer *)inTimer
{
    NSEnumerator    *keyEnumerator = [autoRefreshingKeys objectEnumerator];
    NSString        *key;
    while((key = [keyEnumerator nextObject])){
		[self updateStatusForKey:key];
    }
}


//Contacts -------------------------------------------------------------------------------------------------------------
#pragma mark Contacts
/*!
 * @brief All contacts on this account
 *
 * Returns an array of all the AIListContact objects on this account
 */
- (NSArray *)contacts
{
	return ([[adium contactController] allContactsInGroup:nil
												subgroups:YES
												onAccount:self]);
}

/*!
 * @brief Retrieve a contact by UID
 *
 * Quickly finds an AIListContact object on this account by UID.  If the contact does not exist it will be created.
 * @param sourceUID NSString name of the desired contact
 * @return AIListContact with the desired UID
 */
- (AIListContact *)contactWithUID:(NSString *)sourceUID
{	
	if (!namesAreCaseSensitive){
		sourceUID = [sourceUID compactedString];
	}
	
	return([[adium contactController] contactWithService:service
												 account:self
													 UID:sourceUID]);
}


//Connectivity ---------------------------------------------------------------------------------------------------------
#pragma mark Connectivity

/*!
 * @brief The account did connect
 *
 * Subclasses should call this on self after connecting
 */
- (void)didConnect
{
    //We are now online
    [self setStatusObject:nil forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressString" notify:NO];
	[self setStatusObject:nil forKey:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];

	//Update our status and idle status
	[self updateStatusForKey:@"StatusState"];
	[self updateStatusForKey:@"IdleSince"];	
}

/*!
 * @brief Autoreconnect after delay
 *
 * Attempts to auto-reconnect after a delay
 * @param delayNumber Delay in seconds
 */
- (void)autoReconnectAfterDelay:(int)delay
{
	//We could use performSelector:afterDelay here, but using a timer allows us to cancel it.
	[reconnectTimer invalidate]; [reconnectTimer release];
    reconnectTimer = [[NSTimer scheduledTimerWithTimeInterval:delay
													   target:self
													 selector:@selector(_autoReconnectTimer:)
													 userInfo:nil
													  repeats:NO] retain];
}
- (void)_autoReconnectTimer:(NSTimer *)inTimer
{
	//If we still want to be online, and we're not yet online, continue with the reconnect
    if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue] &&
	   ![[self statusObjectForKey:@"Online"] boolValue] && ![[self statusObjectForKey:@"Connecting"] boolValue]){
		[self setPreference:[NSNumber numberWithBool:YES] 
					 forKey:@"Online" 
					  group:GROUP_ACCOUNT_STATUS];
    }
	
	//Clean up the timer
	[reconnectTimer invalidate];
	[reconnectTimer release];
	reconnectTimer = nil;
}

/*
 * @brief Allow the system to sleep if it wants to
 *
 * Removes the hold on system sleep placed previously
 */
- (void)allowSystemToSleep
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AISystemContinueSleep_Notification
														object:nil];	
}

/*
 * @brief Remove the status objects from a listContact which we placed there
 *
 * Called for each contact to reduce our memory footprint after a contact signs off or an account disconnects.
 */
- (void)removeStatusObjectsFromContact:(AIListContact *)listContact silently:(BOOL)silent
{
	NSEnumerator	*enumerator = [[self contactStatusObjectKeys] objectEnumerator];
	NSString		*key;
	
	while((key = [enumerator nextObject])){
		[listContact setStatusObject:nil forKey:key notify:NotifyLater];
	}
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silent];
}

/*!
* @brief Remove all contacts owned by this account and clear their status objects set by this account
 */
- (void)removeAllContacts
{
	NSEnumerator    *enumerator;
	AIListContact	*listContact;
	
	[[adium contactController] delayListObjectNotifications];
	
	//Clear status flags on all contacts for this account, and set their remote group to nil
	enumerator = [[[adium contactController] allContactsInGroup:nil
													  subgroups:YES 
													  onAccount:self] objectEnumerator];
	while((listContact = [enumerator nextObject])){
		[listContact setRemoteGroupName:nil];
		[self removeStatusObjectsFromContact:listContact silently:YES];
	}
	
	[[adium contactController] endListObjectNotificationsDelay];
}

/*
 * @brief Contact status object keys
 *
 * @result An NSSet of the keys we should clear from contacts when signing off
 */
- (NSSet *)contactStatusObjectKeys
{
	static NSSet *_contactStatusObjectKeys = nil;
	
	if (!_contactStatusObjectKeys)
		_contactStatusObjectKeys = [[NSSet alloc] initWithObjects:@"Online",@"Warning",@"IdleSince",
			@"Idle",@"IsIdle",@"Signon Date",@"StatusName",@"StatusType",@"StatusMessage",@"Client",nil];
	
	return _contactStatusObjectKeys;
}

/*
 * @brief Did disconnect
 */
- (void)didDisconnect
{
	//Remove all contacts
	[self removeAllContacts];
	
	//We are now offline
    [self setStatusObject:nil forKey:@"Disconnecting" notify:NO];
    [self setStatusObject:nil forKey:@"Connecting" notify:NO];
    [self setStatusObject:nil forKey:@"Online" notify:NO];
	
	//Apply any changes
    [self notifyOfChangedStatusSilently:NO];

	//Cancel our sleep hold timeout
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(allowSystemToSleep)
											   object:nil];
	//And allow sleep
	[self allowSystemToSleep];
}

/*!
 * @brief Applescript connect
 *
 * Connect method for applescript support.  Sets the online flag to YES for this account, invoking a connect.
 */
- (void)connectScriptCommand:(NSScriptCommand *)command
{
	[self setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];	
}

/*!
 * @brief Applescript disconnect
 *
 * Disconnect method for applescript support.  Sets the online flag to NO for this account, invoking a disconnect.
 */
- (void)disconnectScriptCommand:(NSScriptCommand *)command
{
	[self setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];	
}

//Fast user switch disconnecting ---------------------------------------------------------------------------------------
#pragma mark Fast user switch disconnecting
/*!
 * @brief Init FUS disconnecting/reconnecting
 *
 * Init disconnecting and reconnecting in response to FUS events.
 */
- (void)initFUSDisconnecting
{
	if([self disconnectOnFastUserSwitch] && [NSApp isOnPantherOrBetter]){
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
															   selector:@selector(fastUserSwitchLeave:) 
																   name:NSWorkspaceSessionDidResignActiveNotification
																 object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(fastUserSwitchReturn:) 
																   name:NSWorkspaceSessionDidBecomeActiveNotification 
																 object:nil];
	}
}

/*!
 * @brief User leave
 *
 * System is switching to another user, disconnect this account
 */
- (void)fastUserSwitchLeave:(NSNotification *)notification
{
	if([self online]){
		[self setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
		disconnectedByFastUserSwitch = YES;
	}
}

/*!
 * @brief User return
 *
 * System is returning to our original user, reconnect this account
 */
- (void)fastUserSwitchReturn:(NSNotification *)notification
{
	if (disconnectedByFastUserSwitch){
		[self setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
		disconnectedByFastUserSwitch = NO;
	}
}

/*!
 * @brief Set display name
 *
 * Set the display name which is used for this account locally (and remotely if supported by the protocol)
 */
- (void)setDisplayName:(NSString *)displayName
{
	if([displayName length] == 0) displayName = nil; 
	
	[self setPreference:(displayName ?
						 [[NSAttributedString stringWithString:displayName] dataRepresentation] :
						 nil)
				 forKey:@"FullNameAttr"
				  group:GROUP_ACCOUNT_STATUS];
}	

@end
