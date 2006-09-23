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

#import <Adium/AIAbstractAccount.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISystemNetworkDefaults.h>

#define FILTERED_STRING_REFRESH    30.0    //delay in seconds between refresh of our attributed string statuses when needed

#define	ACCOUNT_DEFAULTS			@"AccountDefaults"

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
    if ((self = [super initWithUID:inUID service:inService])) {
		NSString	*accountModifiedUID;

		internalObjectID = [inInternalObjectID retain];
		isTemporary = NO;

		accountModifiedUID = [self accountWillSetUID:UID];
		if (accountModifiedUID != UID) {
			[UID release];
			UID = [accountModifiedUID retain];
		}
		
		namesAreCaseSensitive = [[self service] caseSensitive];

		//Register the defaults
		static NSDictionary	*defaults = nil;

		if (!defaults) {
			defaults = [[NSDictionary dictionaryNamed:ACCOUNT_DEFAULTS
											 forClass:[AIAccount class]] retain];
		}

		[[adium preferenceController] registerDefaults:defaults
											  forGroup:GROUP_ACCOUNT_STATUS
												object:self];
		
		enabled = [[self preferenceForKey:KEY_ENABLED group:GROUP_ACCOUNT_STATUS] boolValue];

		autoRefreshingKeys = [[NSMutableSet alloc] init];
		dynamicKeys = [[NSMutableSet alloc] init];
		attributedRefreshTimer = nil;
		delayedUpdateStatusTimer = nil;
		delayedUpdateStatusTarget = nil;
		silenceAllContactUpdatesTimer = nil;
		disconnectedByFastUserSwitch = NO;

		//Register to be notified of dynamic content updates
		[[adium notificationCenter] addObserver:self
									   selector:@selector(requestImmediateDynamicContentUpdate:)
										   name:Adium_RequestImmediateDynamicContentUpdate
										 object:nil];	

		//Some actions must wait until Adium is finished loading so that all plugins are available
		[[adium notificationCenter] addObserver:self
									   selector:@selector(adiumDidLoad:)
										   name:Adium_CompletedApplicationLoad
										 object:nil];

		//Handle the preference changed monitoring (for account status) for our subclass
		[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
		
		//Update our display name and formattedUID immediately
		[self updateStatusForKey:@"FormattedUID"];
		
		//Init the account
		[self initFUSDisconnecting];
		[self initAccount];
    }
	
    return self;
}

- (void)dealloc
{
	[delayedUpdateStatusTarget release];
	[delayedUpdateStatusTimer invalidate]; [delayedUpdateStatusTimer release];

	/* Our superclass releases internalObjectID in its dealloc, so we should set it to nil when do.
	 * We could just depend upon its implementation, but this is more robust.
	 */
	[internalObjectID release]; internalObjectID = nil; 

	[self _stopAttributedRefreshTimer];
	[autoRefreshingKeys release]; autoRefreshingKeys = nil;
	
    [[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
    [super dealloc];
}

- (void)adiumDidLoad:(NSNotification *)inNotification
{
	[self updateStatusForKey:KEY_ACCOUNT_DISPLAY_NAME];

	[[adium notificationCenter] removeObserver:self 
										  name:Adium_CompletedApplicationLoad
										object:nil];
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
	return internalObjectID;
}

/*!
 * @brief Improved description for NSLog
 */
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@:%@",[super description],[self UID]];
}

/*!
 * @brief Custom path for account preferences
 *
 * Store our account preferences in a separate folder from object preferences to keep things clean
 */
- (NSString *)pathToPreferences
{
    return ACCOUNT_PREFS_PATH;
}

/*!
 * @brief User icon
 *
 * Method for accessing the user icon data for this account. This should always be used to retrieve the account's image data.
 * @return NSData for this account's user icon
 */
- (NSData *)userIconData
{
	NSData	*userIconData = nil;

	if ([[self preferenceForKey:KEY_USE_USER_ICON group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:isTemporary] boolValue]) {
		userIconData = [self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:isTemporary];
		if (!userIconData && !isTemporary) {
			userIconData = [self preferenceForKey:KEY_DEFAULT_USER_ICON group:GROUP_ACCOUNT_STATUS];
		}
	} else {
		//Globally, we're not using an icon; however, the account may specify its own, overriding that.
		userIconData = [self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES];		
	}

	return userIconData;
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
	return [self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Connect Port
 *
 * Convenience method for retrieving the connect port for this account
 */
- (int)port
{
	return [[self preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS] intValue];
}

/*!
 * @brief Is this account enabled?
 */
- (BOOL)enabled
{
	return enabled;
}

/*!
 * @brief Set if this account is enabled
 */
- (void)setEnabled:(BOOL)inEnabled
{
	enabled = inEnabled;

	[self setPreference:[NSNumber numberWithBool:inEnabled]
				 forKey:KEY_ENABLED
				  group:GROUP_ACCOUNT_STATUS];
	
	//We don't update the display name unless we're enabled, so update it now
	[self updateStatusForKey:KEY_ACCOUNT_DISPLAY_NAME];
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
	if (![newProposedUID isEqualToString:[self UID]]) {
		[UID release];
		UID = [newProposedUID retain];

		//Inform the account controller of the changed UID
		[[adium accountController] accountDidChangeUID:self];

		didChangeUID = YES;
	}

	//Set our formatted UID if necessary
	if (![newProposedFormattedUID isEqualToString:[self formattedUID]]) {
		[self setPreference:newProposedFormattedUID
					 forKey:@"FormattedUID"
					  group:GROUP_ACCOUNT_STATUS];
	}
	
	if (didChangeUID) {
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
	if (!object || object == self) {
		if ([[self supportedPropertyKeys] containsObject:key]) {
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
	
	if (silenceAllContactUpdatesTimer) {
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
	if (!delayedUpdateStatusTimer) {
		//Update this contact's status immediately.
		[self delayedUpdateContactStatus:inContact];
		
		//Guard against subsequent updates
		delayedUpdateStatusTarget = nil;
		delayedUpdateStatusTimer = [[NSTimer scheduledTimerWithTimeInterval:[self delayedUpdateStatusInterval]
																	 target:self
																   selector:@selector(_delayedUpdateStatusTimer:)
																   userInfo:nil
																	repeats:NO] retain];
	} else {
		//If there is an outstanding delay, set this contact as the target
		[delayedUpdateStatusTarget release]; delayedUpdateStatusTarget = [inContact retain];
	}
}
- (void)_delayedUpdateStatusTimer:(NSTimer *)inTimer
{
	if (delayedUpdateStatusTarget) {
		[self delayedUpdateContactStatus:delayedUpdateStatusTarget];
		[delayedUpdateStatusTarget release]; delayedUpdateStatusTarget = nil;
	}
	[delayedUpdateStatusTimer invalidate];
	[delayedUpdateStatusTimer release];
	delayedUpdateStatusTimer = nil;
}

- (void)updateLocalDisplayNameTo:(NSAttributedString *)attributedDisplayName
{
	NSString	*displayName = [attributedDisplayName string];
	if ([displayName length] == 0) displayName = nil;
	
	//Apply the display name for local display
	[[self displayArrayForKey:@"Display Name"] setObject:displayName
											   withOwner:self];
	
	//Note the actual value we've set in CurrentDisplayName so we can compare against it later
	[self setStatusObject:displayName
				   forKey:@"CurrentDisplayName"
				   notify:NotifyNever];
	
	//Notify
	[[adium contactController] listObjectAttributesChanged:self
											  modifiedKeys:[NSSet setWithObject:@"Display Name"]];	
}

/*!
 * @brief Current display name, post filtering
 *
 * This might be used to see if a new display name needs to be sent to the server or if it is the same as the old one.
 */
- (NSString *)currentDisplayName
{
	return [self statusObjectForKey:@"CurrentDisplayName"];
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
    if ([key isEqualToString:@"Online"]) {
        if ([self shouldBeOnline] &&
			[self enabled]) {
            if (!areOnline && ![[self statusObjectForKey:@"Connecting"] boolValue]) {
				if ([[self service] requiresPassword] && !password) {
					//Retrieve the user's password and then call connect
					[[adium accountController] passwordForAccount:self 
												  notifyingTarget:self
														 selector:@selector(passwordReturnedForConnect:context:)
														  context:nil];
				} else {
					/* Connect immediately without retrieving a password because we either don't need one or
					 * already have one.
					 */
					[self connect];
				}
				
            }
        } else {
            if ((areOnline || ([[self statusObjectForKey:@"Connecting"] boolValue])) && 
			   (![[self statusObjectForKey:@"Disconnecting"] boolValue])) {
                //Disconnect
                [self disconnect];
            }
        }
		
    } else if ([key isEqualToString:@"StatusState"]) {
		if (areOnline) {
			//Set the status state after filtering its statusMessage as appropriate
			[self autoRefreshingOutgoingContentForStatusKey:@"StatusState"
												   selector:@selector(gotFilteredStatusMessage:forStatusState:)
													context:[self statusObjectForKey:@"StatusState"]];
		} else {
			//Check if account is 'enabled' in the accounts preferences.  If so, bring it online in the specified state.
			[self setShouldBeOnline:YES];
		}

    } else if ([key isEqualToString:KEY_ACCOUNT_DISPLAY_NAME]) {
		if ([self enabled]) {
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(gotFilteredDisplayName:)];
		}

	} else if ([key isEqualToString:@"FormattedUID"]) {
		//Transfer formatted UID to status dictionary
		[self setStatusObject:[self preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS]
					   forKey:@"FormattedUID"
					   notify:NotifyNow];
		
	} else if ([key isEqualToString:@"Enabled"]) {
		//Set a status object so observers are notified
		[self setStatusObject:[NSNumber numberWithBool:enabled]
					   forKey:@"Enabled"
					   notify:NotifyNow];
		
		//We are now enabled so should go online, or we are now disabled so should disconnect
		[self setShouldBeOnline:enabled];
	}
}

#pragma mark Status States

- (BOOL)handleOfflineAsStatusChange
{
	return NO;
}

/*!
 * @brief Set the account to a specified statusState
 *
 * This is the entry point for setting an AIAccount to a specified state.
 */
- (void)setStatusState:(AIStatus *)statusState
{
	if (([statusState statusType] == AIOfflineStatusType) &&
		![self handleOfflineAsStatusChange]) {
		[self setShouldBeOnline:NO];
		
	} else {
		//Store the status state as a status object so it can be easily used elsewhere
		[self setStatusObject:statusState forKey:@"StatusState" notify:NotifyLater];
		
		//Update us to the new state
		[self updateStatusForKey:@"StatusState"];
		
		/* Set our IdleSince time if appropriate... this will just be set when the state is selected; the account
		 * is thereafter responsible for updating any serverside settings as needed.  All of our current services will handle
		 * updating idle time as it changes automatically. This is a per-account preference setting; it will override
		 * any global idle setting for this account but won't change it. */	
		if ([[self supportedPropertyKeys] containsObject:@"IdleSince"]) {
			NSDate	*idleSince;
			
			idleSince = ([statusState shouldForceInitialIdleTime] ?
						 [NSDate dateWithTimeIntervalSinceNow:-([statusState forcedInitialIdleTime]+1)] :
						 nil);

			if ([self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] != idleSince) {
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

	if ([[self supportedPropertyKeys] containsObject:@"IdleSince"]) {
		NSDate	*idleSince;
		
		idleSince = ([statusState shouldForceInitialIdleTime] ?
					 [NSDate dateWithTimeIntervalSinceNow:-[statusState forcedInitialIdleTime]] :
					 nil);
		
		if ([self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] != idleSince) {
			[self setPreference:idleSince forKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
		}		
	}
}

/*!
 * @brief Callback from the threaded filter performed in [self updateStatusForKey:@"StatusState"]
 */
- (void)gotFilteredStatusMessage:(NSAttributedString *)statusMessage forStatusState:(AIStatus *)statusState
{
	[statusState setFilteredStatusMessage:[statusMessage string]];
	
	[self setStatusState:statusState
	  usingStatusMessage:statusMessage];
}

- (AIStatusSummary)statusSummary
{
	AIStatusType	statusType = [[self statusState] statusType];
	
	if (statusType == AIOfflineStatusType) {
		return AIOfflineStatus;
	} else {
		if (statusType == AIAwayStatusType) {
			if ([self statusObjectForKey:@"IdleSince"]) {
				return AIAwayAndIdleStatus;
			} else {
				return AIAwayStatus;
			}

		} else if ([self statusObjectForKey:@"IdleSince"]) {
			return AIIdleStatus;

		} else {
			return AIAvailableStatus;

		}
	}
}

- (AIStatus *)statusState
{
	if ([self integerStatusObjectForKey:@"Online"]) {
		AIStatus	*statusState = [self statusObjectForKey:@"StatusState"];
		if (!statusState) {
			statusState = [[adium statusController] defaultInitialStatusState];
			[self setStatusStateAndRemainOffline:statusState];		
		}
		
		return statusState;
	} else {
		AIStatus	*statusState = [self statusObjectForKey:@"StatusState"];
		if (statusState && [statusState statusType] == AIOfflineStatusType) {
			//We're in an actual offline status; return it
			return statusState;
		} else {
			//We're offline, but our status is keeping track of what we'll be when we sign back on. Return the generic offline status.
			return [[adium statusController] offlineStatusState];
		}
	}
}

/*!
 * @brief The status state this account is set to regardless of whether or not it is online
 */
- (AIStatus *)actualStatusState
{
	return [self statusObjectForKey:@"StatusState"];
}

- (NSString *)statusName
{
	return [[self statusState] statusName];
}

- (AIStatusType)statusType
{
	return [[self statusState] statusType];
}

- (NSAttributedString *)statusMessage
{
	return [[self statusState] statusMessage];
}

/*!
 * @brief Are sounds for this acount muted?
 */
- (BOOL)soundsAreMuted
{
	return [[self statusState] mutesSound];
}

#pragma mark Passwords

/*!
 * @brief Store in memory (but nowhere else) the password for this account
 */
- (void)setPasswordTemporarily:(NSString *)inPassword
{
	if (password != inPassword) {
		[password release]; password = [inPassword retain];
	}	
}

/*!
 * @brief Password entered callback
 *
 * Callback after the user enters her password for connecting; finish the connect process.
 */
- (void)passwordReturnedForConnect:(NSString *)inPassword context:(id)inContext
{
    //If a password was returned, and we're still waiting to connect
    if (inPassword && [inPassword length] != 0) {
		if (![[self statusObjectForKey:@"Online"] boolValue] &&
		   ![[self statusObjectForKey:@"Connecting"] boolValue]) {
			[self setPasswordTemporarily:inPassword];

			//Tell the account to connect
			[self connect];
		}

    } else {
		[self setShouldBeOnline:NO];
	}
}

- (void)serverReportedInvalidPassword
{
	[[adium accountController] forgetPasswordForAccount:self];
	[self setPasswordTemporarily:nil];
}

//Auto-Refreshing Status String ----------------------------------------------------------------------------------------
#pragma mark Auto-Refreshing Status String
/*!
 * @brief Schedule/Unschedule a status string for auto-refreshing if it contains dynamic content
 *
 * Tests an attributed status string.  If the string contains dynamic content, the key is noted.  If it also requires
 * periodic polling to refresh its value, it will be scheduled for automatic refreshing and periodically updated.
 *
 * If the string does not contain dynamic content any existing scheduling for it will be removed.  Call this method when the
 * value of an attributed status that supports automatic refreshing is changed by the user.
 *
 * @param key Status key to check for auto-refreshing content
 * @result The current value of the auto-refreshing string for you to use.
 */
- (NSAttributedString *)autoRefreshingOutgoingContentForStatusKey:(NSString *)key
{
	NSAttributedString	*originalValue = [self autoRefreshingOriginalAttributedStringForStatusKey:key];
	NSAttributedString  *filteredValue;
	NSString			*originalValueString = [originalValue string];
	
	filteredValue = [[adium contentController] filterAttributedString:originalValue
													  usingFilterType:AIFilterContent
															direction:AIFilterOutgoing
															  context:self];

	//Refresh periodically if the filtered string is different from the original one
	if (originalValue && (![originalValueString isEqualToString:[filteredValue string]])) {
		[self startAutoRefreshingStatusKey:key forOriginalValueString:originalValueString];
	} else {
		[self stopAutoRefreshingStatusKey:key];
	}

	return filteredValue;
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
	
	if (originalValue) {
		[contextDict setObject:originalValue forKey:@"originalValue"];
	}
	
	if (originalContext) {
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
	
	if ([key isEqualToString:@"StatusState"]) {
		originalValue = [[self statusState] statusMessage];

	} else {
		originalValue = [[self preferenceForKey:key group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:isTemporary] attributedString];				
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
	
	NSString			*originalValueString = [originalValue string];
	
	//Refresh periodically if the filtered string is different from the original one
	if (originalValue && (![originalValueString isEqualToString:[filteredValue string]])) {
		[self startAutoRefreshingStatusKey:key forOriginalValueString:originalValueString];
	} else {
		[self stopAutoRefreshingStatusKey:key];
	}
	
	//
	if (originalContext) {
		[self performSelector:selector
				   withObject:filteredValue
				   withObject:originalContext];
	} else {
		[self performSelector:selector
				   withObject:filteredValue];
	}
}

/*!
 * @brief Start auto-refreshing a status key
 *
 * If polling is necessary, add the key to autoRefreshingKeys and start our timer.  Whether polling is needed or not,
 * note that the key is dynamic.
 */
- (void)startAutoRefreshingStatusKey:(NSString *)key forOriginalValueString:(NSString *)originalValueString
{
	[dynamicKeys addObject:key];

	if ([[adium contentController] shouldPollToUpdateString:originalValueString]) {
		[autoRefreshingKeys addObject:key];
		[self _startAttributedRefreshTimer];
	}
}

/*!
 * @brief Stop auto-refreshing a status key
 *
 * Stops an account status string from auto-refreshing
 *
 * @param key The key to stop auto-refreshing, or nil to stop all keys
 */
- (void)stopAutoRefreshingStatusKey:(NSString *)key
{
	if (key) {
		[dynamicKeys removeObject:key];
		[autoRefreshingKeys removeObject:key];

	} else {
		[dynamicKeys removeAllObjects];
		[autoRefreshingKeys removeAllObjects];
	}

	if ([autoRefreshingKeys count] == 0) [self _stopAttributedRefreshTimer];
}

/*!
 * @brief Suspend auto-refreshing timer when disconnected
 *
 * Here we suspend the auto-refreshing timer when the account goes offline, and restart it when the account goes back
 * online.  This prevents us from running the timer for offline accounts.
 */
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	if ([key isEqualToString:@"Online"]) {
		if ([value boolValue]) {
			if ([autoRefreshingKeys count])	[self _startAttributedRefreshTimer];
		} else {
			[self _stopAttributedRefreshTimer];
		}
	} else if ([key isEqualToString:@"Disconnecting"]) {
		if ([value boolValue]) {
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
	if (!attributedRefreshTimer) {
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
	if (attributedRefreshTimer) {
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
    while ((key = [keyEnumerator nextObject])) {
		if ([self shouldUpdateAutorefreshingAttributedStringForKey:key]) {
			[self updateStatusForKey:key];
		}
    }
}

//We were informed that some of our dynamic content may have just changed; update it
- (void)requestImmediateDynamicContentUpdate:(NSNotification *)notification
{
	if ([dynamicKeys count]) {
		NSEnumerator    *enumerator;
		NSString        *key;
		
		enumerator = [dynamicKeys objectEnumerator];
		while ((key = [enumerator nextObject])) {
			[self updateStatusForKey:key];
		}
		
		//Move the next fire date forward since we just updated them all
		if (attributedRefreshTimer) {
			[attributedRefreshTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:FILTERED_STRING_REFRESH]];
		}
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
	return [[adium contactController] allContactsInGroup:nil
												subgroups:YES
												onAccount:self];
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
	if (!namesAreCaseSensitive) {
		sourceUID = [sourceUID compactedString];
	}
	
	return [[adium contactController] contactWithService:service
												 account:self
													 UID:sourceUID];
}


//Connectivity ---------------------------------------------------------------------------------------------------------
#pragma mark Connectivity

/*!
 * @brief Should the account be online?
 *
 * This indicates whether the user desires the account to be online, not the actual online state.
 */
- (BOOL)shouldBeOnline
{
	return [[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue];
}

/*!
 * @brief Set if this account should be online
 *
 * This is how the account should be informed that the user's desired online/offline status for the account
 * changed; this may be called as a result of a status change, for example.
 *
 * If shouldBeOnline is YES, the account will be brought online in the status state it was in last.
 * If shouldBeOnline is NO, the account will be disconnected.
 */
- (void)setShouldBeOnline:(BOOL)shouldBeOnline
{
	[self setPreference:[NSNumber numberWithBool:shouldBeOnline]
				 forKey:@"Online"
				  group:GROUP_ACCOUNT_STATUS];
	
	/* If the users says we should no longer be online, clear out any stored password.
	 * Note that we can de disconnected via -[AIAccount disconnect] without going through this method; this is how we will be disconnected
	 * in an automatic fashoin, such as if network connectivity drops. This allows us, when reconnected after such a disconnection, to still
	 * have the password 'on tap' for use at that time.
	 */
	if (!shouldBeOnline) {
		[self setPasswordTemporarily:nil];
	}
}

- (void)toggleOnline
{
	BOOL    online = [self online];
	BOOL	connecting = [[self statusObjectForKey:@"Connecting"] boolValue];
	
	//If online or connecting set the account offline, otherwise set it to online
	[self setShouldBeOnline:!(online || connecting)]; 	
}

/*!
 * @brief The account did connect
 *
 * Subclasses should call this on self after connecting
 */
- (void)didConnect
{
    //We are now online
    [self setStatusObject:nil forKey:@"Connecting" notify:NotifyLater];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NotifyLater];
	[self setStatusObject:nil forKey:@"ConnectionProgressString" notify:NotifyLater];
	[self setStatusObject:nil forKey:@"ConnectionProgressPercent" notify:NotifyLater];	

	//Apply any changes
	[self notifyOfChangedStatusSilently:NO];

	//Update our status and idle status to ensure our newly connected account is in the states we want it to be
	if ([[self statusState] statusType] == AIOfflineStatusType) {
		/* If our account thinks it's still in an offline status, that means it went offline previously via an offline status.
		 * Set to the status being used by other accounts if possible; otherwise, set to our default initiate status.
		 */
		AIStatus *newStatus = [[adium statusController] activeStatusState];
		if ([newStatus statusType] == AIOfflineStatusType) {
			newStatus = [[adium statusController] defaultInitialStatusState];
		}
		
		[self setStatusState:newStatus];

	} else {
		[self updateStatusForKey:@"StatusState"];
	}
	[self updateStatusForKey:@"IdleSince"];	
}

- (void)cancelAutoReconnect
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(performAutoreconnect)
											   object:nil];
}

/*!
 * @brief Autoreconnect after delay
 *
 * Attempts to auto-reconnect after a delay
 * @param delayNumber Delay in seconds
 */
- (void)autoReconnectAfterDelay:(NSTimeInterval)delay
{
	[self performSelector:@selector(performAutoreconnect)
			   withObject:nil
			   afterDelay:delay];
}
- (void)performAutoreconnect
{
	//If we still want to be online, and we're not yet online, continue with the reconnect
    if ([self shouldBeOnline] &&
	   ![self online] && ![[self statusObjectForKey:@"Connecting"] boolValue]) {
		[self updateStatusForKey:@"Online"];
    }
}

/*!
 * @brief Remove the status objects from a listContact which we placed there
 *
 * Called for each contact to reduce our memory footprint after a contact signs off or an account disconnects.
 */
- (void)removeStatusObjectsFromContact:(AIListContact *)listContact silently:(BOOL)silent
{
	NSEnumerator	*enumerator = [[self contactStatusObjectKeys] objectEnumerator];
	NSString		*key;
	
	while ((key = [enumerator nextObject])) {
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
	while ((listContact = [enumerator nextObject])) {
		[listContact setRemoteGroupName:nil];
		[self removeStatusObjectsFromContact:listContact silently:YES];
	}
	
	[[adium contactController] endListObjectNotificationsDelay];
}

/*!
 * @brief Contact status object keys
 *
 * @result An NSSet of the keys we should clear from contacts when signing off
 */
- (NSSet *)contactStatusObjectKeys
{
	static NSSet *_contactStatusObjectKeys = nil;
	
	if (!_contactStatusObjectKeys)
		_contactStatusObjectKeys = [[NSSet alloc] initWithObjects:@"Online",@"Warning",@"IdleSince",
			@"Idle",@"IsIdle",@"Signon Date",@"StatusName",@"StatusType",@"StatusMessage",@"Client",KEY_TYPING,nil];
	
	return _contactStatusObjectKeys;
}

/*!
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
	
	//Stop all autorefreshing keys
	[self stopAutoRefreshingStatusKey:nil];
	
	//Apply any changes
    [self notifyOfChangedStatusSilently:NO];
}

/*!
 * @brief Applescript connect
 *
 * Connect method for applescript support.  Sets the online flag to YES for this account, invoking a connect.
 */
- (void)connectScriptCommand:(NSScriptCommand *)command
{
	[self setShouldBeOnline:YES];
}

/*!
 * @brief Applescript disconnect
 *
 * Disconnect method for applescript support.  Sets the online flag to NO for this account, invoking a disconnect.
 */
- (void)disconnectScriptCommand:(NSScriptCommand *)command
{
	[self setShouldBeOnline:NO];
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
	if ([self disconnectOnFastUserSwitch]) {
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
	if ([self online]) {
		[self setShouldBeOnline:NO];
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
	if (disconnectedByFastUserSwitch) {
		[self setShouldBeOnline:YES];
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
	if ([displayName length] == 0) displayName = nil; 
	
	[self setPreference:(displayName ?
						 [[NSAttributedString stringWithString:displayName] dataRepresentation] :
						 nil)
				 forKey:KEY_ACCOUNT_DISPLAY_NAME
				  group:GROUP_ACCOUNT_STATUS];
}	

#pragma mark Proxy Configuration Retrieval

/*!
 * @brief Retrieve the proxy configuration information for this account
 *
 * This should be used by the AIAccount subclass before initiating its connect process if it supports proxies.
 *
 * target will be notified via selector, which must take two arguments,
 * the first of which will be an NSDictionary of information and the second of which will be the passed context.
 *
 * The NSDictionary which is returned will have the following key/object pairs:
 *	@"AdiumProxyType"	an NSNumber containing an AdiumProxyType value
 *  @"Host"				an NSString
 *  @"Port"				an NSNumber
 *  @"Username"			an NSString (potentially nil)
 *  @"Password"			an NSString (relevant only if Username is non-nil)
 */
- (void)getProxyConfigurationNotifyingTarget:(id)target selector:(SEL)selector context:(id)context
{
	NSMutableDictionary *proxyConfiguration = [NSMutableDictionary dictionary];
	BOOL				notifyTargetNow = YES;
	
	if ([[self preferenceForKey:KEY_ACCOUNT_PROXY_ENABLED group:GROUP_ACCOUNT_STATUS] boolValue]) {
		NSNumber		*proxyPref = [self preferenceForKey:KEY_ACCOUNT_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
		AdiumProxyType	proxyType = (proxyPref ? [proxyPref intValue] : Adium_Proxy_Default_SOCKS5);

		NSNumber		*port = nil;
		NSString		*host = nil, *username = nil, *proxyPassword = nil;
		BOOL			promptForPassword = NO;

		if ((proxyType == Adium_Proxy_Default_SOCKS5) || 
			(proxyType == Adium_Proxy_Default_HTTP) || 
			(proxyType == Adium_Proxy_Default_SOCKS4)) {
			NSDictionary	*systemProxySettingsDictionary;
			ProxyType		systemConfigurationProxyType = Proxy_None;

			if (proxyType == Adium_Proxy_Default_SOCKS5) {
				systemConfigurationProxyType = Proxy_SOCKS5;
				
			} else if (proxyType == Adium_Proxy_Default_HTTP) {
				systemConfigurationProxyType = Proxy_HTTP;
				
			} else /*if (proxyType == Adium_Proxy_Default_SOCKS4) */{
				systemConfigurationProxyType = Proxy_SOCKS4;
			}
			
			if ((systemProxySettingsDictionary = [AISystemNetworkDefaults systemProxySettingsDictionaryForType:systemConfigurationProxyType])) {
				host = [systemProxySettingsDictionary objectForKey:@"Host"];
				port = [systemProxySettingsDictionary objectForKey:@"Port"];
				
				username = [systemProxySettingsDictionary objectForKey:@"Username"];
				proxyPassword = [systemProxySettingsDictionary objectForKey:@"Password"];
				if ((username && [username length]) &&
					(!proxyPassword || ![proxyPassword length])) {
					promptForPassword = YES;
				}
			}
		} else {
			host = [self preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
			port = [self preferenceForKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
			
			if (host && [host length]) {
				//If we need to authenticate, request the password and finish setting up the proxy in gotProxyServerPassword:proxyConfiguration:
				username = [self preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
				if (username && [username length]) {
					promptForPassword = YES;					
				}
			}
		}
		
		if (host) {
			[proxyConfiguration setObject:host forKey:@"Host"];
			
			if (port) [proxyConfiguration setObject:port forKey:@"Port"];
			if (username) [proxyConfiguration setObject:username forKey:@"Username"];
			if (proxyPassword) [proxyConfiguration setObject:proxyPassword forKey:@"Password"];
			
			[proxyConfiguration setObject:[NSNumber numberWithInt:proxyType]
								   forKey:@"AdiumProxyType"];
		} else {
			[proxyConfiguration setObject:[NSNumber numberWithInt:Adium_Proxy_None]
								   forKey:@"AdiumProxyType"];
		}
		
		if (promptForPassword) {
			if (target) [proxyConfiguration setObject:target forKey:@"NotificationTarget"];
			if (selector) [proxyConfiguration setObject:NSStringFromSelector(selector) forKey:@"NotificationSelector"];
			if (context) [proxyConfiguration setObject:context forKey:@"NotificationContext"];
			
			[[adium accountController] passwordForProxyServer:host 
													 userName:username 
											  notifyingTarget:self 
													 selector:@selector(gotProxyServerPassword:proxyConfiguration:)
													  context:proxyConfiguration];
			
			//gotProxyServerPassword:proxyConfiguration: is responsible for notifying the target
			notifyTargetNow = NO;
		}
		
	} else {
		[proxyConfiguration setObject:[NSNumber numberWithInt:Adium_Proxy_None]
							   forKey:@"AdiumProxyType"];
	}
	
	if (notifyTargetNow) {
		[target performSelector:selector
					 withObject:proxyConfiguration
					 withObject:context];
	}
}

/*!
 * @brief Callback for the accountController's passwordForProxyServer:... method
 *
 * @param inPassword The retrieved password
 * @param proxyConfiguration The proxy configuration dictionary, which also includes the original target/selector/context passed to getProxyConfigurationNotifyingTarget:selector:context:
 */
- (void)gotProxyServerPassword:(NSString *)inPassword proxyConfiguration:(NSMutableDictionary *)proxyConfiguration
{
	if (inPassword) {
		id target = [proxyConfiguration objectForKey:@"NotificationTarget"];
		SEL selector = NSSelectorFromString([proxyConfiguration objectForKey:@"NotificationSelector"]);
		id context = [proxyConfiguration objectForKey:@"NotificationContext"];
		
		[proxyConfiguration setObject:inPassword forKey:@"Password"];
		
		[target performSelector:selector
					 withObject:proxyConfiguration
					 withObject:context];
		
	} else {
		//If passed a nil password, cancel the connection attempt
		[self disconnect];
	}
}

#pragma mark Temporary Accounts

- (BOOL)isTemporary
{
	return isTemporary;
}
- (void)setIsTemporary:(BOOL)inIsTemporary;
{
	isTemporary = inIsTemporary;
}

@end
