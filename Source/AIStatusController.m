/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIStatusController.h"

//Localized status titles
#define STATUS_TITLE_AWAY		@"Away"
#define STATUS_TITLE_IDLE		@"Idle"
#define STATUS_TITLE_INVISIBLE	@"Invisible"
#define STATUS_TITLE_AVAILABLE	@"Available"

//State menu
#define ELIPSIS_STRING				[NSString stringWithUTF8String:"…"]
#define STATE_TITLE_MENU_LENGTH		30

//Private idle function
extern double CGSSecondsSinceLastInputEvent(unsigned long evType);

@interface AIStatusController (PRIVATE)
- (void)_saveStateArrayAndNotifyOfChanges;
- (void)_applyStateToAllAccounts:(AIStatus *)state;
- (void)_upgradeSavedAwaysToSavedStates;
- (void)upgradeSVNSavedStatesToCurrent;
- (void)_setMachineIsIdle:(BOOL)inIdle;
- (void)_addStateMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)_removeStateMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)_updateStateMenuSelectionForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (NSString *)_titleForMenuDisplayOfState:(AIStatus *)statusState;

- (NSArray *)_menuItemsForStatusesOfType:(AIStatusType)type forServiceCodeUniqueID:(NSString *)inServiceCodeUniqueID withTarget:(id)target;
- (void)_addMenuItemsForStatusOfType:(AIStatusType)type
				 serviceCodeUniqueID:(NSString *)serviceCodeUniqueID
						  withTarget:(id)target
							 toArray:(NSMutableArray *)menuItems
				  alreadyAddedTitles:(NSMutableSet *)alreadyAddedTitles;
@end
									
/*!
 * @class AIStatusController
 * @brief Core status & state methods
 *
 * This class provides a foundation for Adium's status and state systems.
 */
@implementation AIStatusController

/*!
 * Init the status controller
 */
- (void)initController
{
	stateMenuItemArraysDict = [[NSMutableDictionary alloc] init];
	stateMenuPluginsArray = [[NSMutableArray alloc] init];
	
	//Init
	[self _setMachineIsIdle:NO];
	
	//Update our state menus when the state array or status icon set changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(rebuildAllStateMenus)
									   name:AIStatusStateArrayChangedNotification
									 object:nil];
	[[adium notificationCenter] addObserver:self
								   selector:@selector(rebuildAllStateMenus)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];

	//Update the selections in our state menus when the active state changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateAllStateMenuSelections)
									   name:AIActiveStatusStateChangedNotification
									 object:nil];
}

/*!
 * Close the status controller
 */
- (void)closeController
{
	[[adium notificationCenter] removeObserver:self];
	[stateArray release]; stateArray = nil;
	[activeStatusState release]; activeStatusState = nil;
}

/*!
 * @brief Register a status for a service
 *
 * Implementation note: Each AIStatusType has its own NSMutableDictionary, statusDictsByServiceCodeUniqueID.
 * statusDictsByServiceCodeUniqueID is keyed by serviceCodeUniqueID; each object is an NSMutableSet of NSDictionaries.
 * Each of these dictionaries has KEY_STATUS_NAME, KEY_STATUS_DESCRIPTION, and KEY_STATUS_TYPE.
 *
 * @param statusName A name which will be passed back to accounts of this service.  Internal use only.  Use the AIStatusController.h #defines where appropriate.
 * @param description A human-readable localized description which will be shown to the user.  Use the AIStatusController.h #defines where appropriate.
 * @param type An AIStatusType, the general type of this status.
 * @param service The AIService for which to register the status
 */
- (void)registerStatus:(NSString *)statusName withDescription:(NSString *)description ofType:(AIStatusType)type forService:(AIService *)service
{
	NSMutableSet	*statusDicts;
	NSString		*serviceCodeUniqueID = [service serviceCodeUniqueID];

	//Create the set if necessary
	if(!statusDictsByServiceCodeUniqueID[type]) statusDictsByServiceCodeUniqueID[type] = [[NSMutableDictionary alloc] init];
	if(!(statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:serviceCodeUniqueID])){
		statusDicts = [NSMutableSet set];
		[statusDictsByServiceCodeUniqueID[type] setObject:statusDicts
												   forKey:serviceCodeUniqueID];
	}

	//Create a dictionary for this status entry
	NSDictionary *statusDict = [NSDictionary dictionaryWithObjectsAndKeys:
		statusName, KEY_STATUS_NAME,
		description, KEY_STATUS_DESCRIPTION,
		[NSNumber numberWithInt:type], KEY_STATUS_TYPE,
		nil];
	
	[statusDicts addObject:statusDict];
}

/*!
 * @brief Generate and return a menu of status types (Away, Be right back, etc.)
 *
 * @param service The service for which to return a specific list of types, or nil to return all available types
 * @param target The target for the menu items, which will have an action of @selector(selectStatus:)
 *
 * @result The menu of statuses, separated by available and away status types
 */
- (NSMenu *)menuOfStatusesForService:(AIService *)service withTarget:(id)target
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
	NSString		*serviceCodeUniqueID = [service serviceCodeUniqueID];

	AIStatusType type;
	for(type = AIAvailableStatusType ; type < STATUS_TYPES_COUNT ; type++){
		//Add a separator between each type after available
		if (type > AIAvailableStatusType){
			[menu addItem:[NSMenuItem separatorItem]];
		}

		//Add the items for this type
		enumerator = [[self _menuItemsForStatusesOfType:type
								 forServiceCodeUniqueID:serviceCodeUniqueID
											 withTarget:target] objectEnumerator];
		while(menuItem = [enumerator nextObject]){
			[menu addItem:menuItem];
		}
	}

	return([menu autorelease]);
}


//Sort by title.  We may need to do more complex sorting to put certain defaults at the top?
int statusMenuItemSort(id menuItemA, id menuItemB, void *context)
{
	return [[menuItemA title] caseInsensitiveCompare:[menuItemB title]];
}

- (NSArray *)_menuItemsForStatusesOfType:(AIStatusType)type forServiceCodeUniqueID:(NSString *)inServiceCodeUniqueID withTarget:(id)target
{
	NSMutableArray  *menuItems = [[NSMutableArray alloc] init];
	NSMutableSet	*alreadyAddedTitles = [NSMutableSet set];
	
	if(inServiceCodeUniqueID){
		//Insert a menu item for each available account on this service
		[self _addMenuItemsForStatusOfType:type
					   serviceCodeUniqueID:inServiceCodeUniqueID
								withTarget:target
								   toArray:menuItems
						alreadyAddedTitles:alreadyAddedTitles];
		
	}else{
		NSEnumerator	*enumerator;
		NSString		*serviceCodeUniqueID;
		
		//Insert a menu item for each available account
		enumerator = [statusDictsByServiceCodeUniqueID[type] keyEnumerator];
		while(serviceCodeUniqueID = [enumerator nextObject]){
			//Obtain the status dicts for this type and service code unique ID if it is online
			if([[adium accountController] serviceWithUniqueIDIsOnline:serviceCodeUniqueID]){
				[self _addMenuItemsForStatusOfType:type
							   serviceCodeUniqueID:serviceCodeUniqueID
										withTarget:target
										   toArray:menuItems
								alreadyAddedTitles:alreadyAddedTitles];
			}
		}
	}
	
	[menuItems sortUsingFunction:statusMenuItemSort context:nil];
	
	return([menuItems autorelease]);
}

- (void)_addMenuItemsForStatusOfType:(AIStatusType)type
				 serviceCodeUniqueID:(NSString *)serviceCodeUniqueID
						  withTarget:(id)target
							 toArray:(NSMutableArray *)menuItems
				  alreadyAddedTitles:(NSMutableSet *)alreadyAddedTitles
{
	NSSet	*statusDicts;

	//Obtain the status dicts for this type and service code unique ID
	if(statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:serviceCodeUniqueID]){
		NSEnumerator	*statusDictEnumerator = [statusDicts objectEnumerator];
		NSDictionary	*statusDict;
		
		//Enumerate the status dicts
		while(statusDict = [statusDictEnumerator nextObject]){
			NSString	*title = [statusDict objectForKey:KEY_STATUS_DESCRIPTION];
			
			/*
			 * Only add if it has not already been added by another service.... Services need to use unique titles if they have
			 * unique state names, but are welcome to share common name/description combinations, which is why the #defines
			 * exist.
			 */
			if(![alreadyAddedTitles containsObject:title]){
				NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																							  target:target
																							  action:@selector(selectStatus:)
																					   keyEquivalent:@""] autorelease];
				[menuItem setRepresentedObject:statusDict];
				[menuItem setImage:[[[AIStatusIcons statusIconForStatusID:((type == AIAvailableStatusType) ? @"available" : @"away")
																	 type:AIStatusIconList
																direction:AIIconNormal] copy] autorelease]];
				[menuItem setEnabled:YES];
				[menuItems addObject:menuItem];
				[alreadyAddedTitles addObject:title];
			}
		}
	}
}

/*!
 * @brief Return the localized description for the sate of the passed status
 *
 * This could be stored with the statusState, but that would break if the locale changed.  This way, the nonlocalized
 * string is used to look up the appropriate localized one.
 *
 * @result A localized description such as @"Away" or @"Out to Lunch" of the state used by statusState
 */
- (NSString *)descriptionForStateOfStatus:(AIStatus *)statusState
{
	NSString		*statusName = [statusState statusName];
	AIStatusType	statusType = [statusState statusType];
	NSEnumerator	*enumerator = [statusDictsByServiceCodeUniqueID[statusType] objectEnumerator];
	NSSet			*set;
	while(set = [enumerator nextObject]){
		NSEnumerator	*statusDictsEnumerator = [set objectEnumerator];
		NSDictionary	*statusDict;
		while(statusDict = [statusDictsEnumerator nextObject]){
			if([[statusDict objectForKey:KEY_STATUS_NAME] isEqualToString:statusName]){
				return [statusDict objectForKey:KEY_STATUS_DESCRIPTION];
			}
		}
	}
	
	return nil;
}

/*!
 * @brief Access to Adium's user-defined states
 *
 * Returns an array of available user-defined states, which are AIStatus objects
 */
- (NSArray *)stateArray
{
	if(!stateArray){		
		NSData	*savedStateArrayData = [[adium preferenceController] preferenceForKey:KEY_SAVED_STATUS
																	   group:PREF_GROUP_SAVED_STATUS];
		if(savedStateArrayData){
			stateArray = [[NSKeyedUnarchiver unarchiveObjectWithData:savedStateArrayData] mutableCopy];
		}
		
		if(!stateArray) stateArray = [[NSMutableArray alloc] init];

/*
		//Convert the statuses to AIStatus objects
		enumerator = [savedStateArray objectEnumerator];
		while(statusData = [enumerator nextObject]){
			AIStatus	*status = [NSKeyedUnarchiver unarchiveObjectWithData:statusData];
			if(status){
				[stateArray addObject:status];
			}else{
				NSLog(@"bleh. %@ failed.",statusData);
			}
		}
*/
		//Update Adium 0.8svn saved states -- VERY TEMPORARY!
		[self upgradeSVNSavedStatesToCurrent];
			
		//Upgrade Adium 0.7x away messages
		[self _upgradeSavedAwaysToSavedStates];
	}

	return(stateArray);
}

/*!
 * @brief Set the active status state
 *
 * Sets the currently active status state.  This applies throughout Adium and to all accounts.  The state will become
 * effective immediately.  When the active state changes, an AIActiveStateChangedNotification is broadcast.
 */ 
- (void)setActiveStatusState:(AIStatus *)statusState
{
	if(activeStatusState != statusState){
		[activeStatusState release];
		activeStatusState = [statusState retain];

		//Apply the state to our accounts and notify
		[self _applyStateToAllAccounts:activeStatusState];
		[[adium notificationCenter] postNotificationName:AIActiveStatusStateChangedNotification
												  object:activeStatusState];
	}
}

/*!
 * @brief Retrieve active status state
 *
 * @result The currently active status state.
 */ 
- (AIStatus *)activeStatusState
{
	return(activeStatusState);
}

/*!
 * @brief Save changes to the state array and notify observers
 *
 * Saves any outstanding changes to the state array.  There should be no need to call this manually, since all the
 * state array modifying methods in this class call it automatically after making changes.
 *
 * After the state array is saved, observers are notified that is has changed.  Call after making any changes to the
 * state array from within the controller.
 */ 
- (void)_saveStateArrayAndNotifyOfChanges
{
	[[adium preferenceController] setPreference:[NSKeyedArchiver archivedDataWithRootObject:stateArray]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];
	[[adium notificationCenter] postNotificationName:AIStatusStateArrayChangedNotification object:nil];
}

/*!
 * @brief Apply a state to all accounts
 *
 * Applies the passed state to all accounts
 */ 
- (void)_applyStateToAllAccounts:(AIStatus *)statusState
{
	[[[adium accountController] accountArray] makeObjectsPerformSelector:@selector(setStatusState:)
															  withObject:statusState];
}

/*!
 * @brief Temporary upgrade code for 0.7x -> 0.8
 *
 * Versions 0.7x and prior stored their away messages in a different format.  This code allows a seamless
 * transition from 0.7x to 0.8.  We can easily recognize the old format because the away messages are of
 * type "Away" instead of type "State", which is used for all 0.8 and later saved states.
 * Since we are changing the array as we scan it, an enumerator will not work here.
 */
#define OLD_KEY_SAVED_AWAYS			@"Saved Away Messages"
#define OLD_GROUP_AWAY_MESSAGES		@"Away Messages"
#define OLD_STATE_SAVED_AWAY		@"Away"
#define OLD_STATE_AWAY				@"Message"
#define OLD_STATE_AUTO_REPLY		@"Autoresponse"
#define OLD_STATE_TITLE				@"Title"
- (void)_upgradeSavedAwaysToSavedStates
{
	NSArray	*savedAways = [[adium preferenceController] preferenceForKey:OLD_KEY_SAVED_AWAYS
																   group:OLD_GROUP_AWAY_MESSAGES];
	
	if(savedAways){
		NSEnumerator	*enumerator = [savedAways objectEnumerator];
		NSDictionary	*state;
		
		//Update all the away messages to states
		while(state = [enumerator nextObject]){
			if([[state objectForKey:@"Type"] isEqualToString:OLD_STATE_SAVED_AWAY]){
				AIStatus	*statusState;
				
				//Extract the away message information from this old record
				NSData		*statusMessage = [state objectForKey:OLD_STATE_AWAY];
				NSData		*autoReplyMessage = [state objectForKey:OLD_STATE_AUTO_REPLY];
				NSString	*title = [state objectForKey:OLD_STATE_TITLE];
				
				//Create an AIStatus from this information
				statusState = [AIStatus status];

				//General category: It's an away type
				[statusState setStatusType:AIAwayStatusType];

				//Specific state: It's the generic away. Funny how that work out.
				[statusState setStatusName:STATUS_NAME_AWAY];				

				//Set the status message (which is just the away message)
				[statusState setStatusMessageData:statusMessage];

				//It has an auto reply
				[statusState setHasAutoReply:YES];

				if(autoReplyMessage){
					//Use the custom auto reply if it was set
					[statusState setAutoReplyData:autoReplyMessage];
				}else{
					//If no autoReplyMesssage, use the status message
					[statusState setAutoReplyIsStatusMessage:YES];
				}

				if(title) [statusState setTitle:title];
	
				//Add the updated state to our state array
				[stateArray addObject:statusState];
			}
		}
		
		//Save these changes and delete the old aways so we don't need to do this again
		[self _saveStateArrayAndNotifyOfChanges];
		[[adium preferenceController] setPreference:nil
											 forKey:OLD_KEY_SAVED_AWAYS
											  group:OLD_GROUP_AWAY_MESSAGES];
	}
}


/*
 * @brief Upgrade saved states from January 2005 SVN to the new storage mechanism.
 *
 * This should be removed long before 0.8 ships.
 */
- (void)upgradeSVNSavedStatesToCurrent
{
	NSArray	*savedAways = [[adium preferenceController] preferenceForKey:@"Saved Status"
																   group:PREF_GROUP_SAVED_STATUS];

	if(savedAways){
		NSEnumerator	*enumerator = [savedAways objectEnumerator];
		NSDictionary	*state;

		//Update all the away messages to states
		while(state = [enumerator nextObject]){
			AIStatus	*statusState;

			//Create an AIStatus from this information
			statusState = [AIStatus statusWithDictionary:state];

			//Add the updated state to our state array
			[stateArray addObject:statusState];
		}

		//Save these changes and delete the old aways so we don't need to do this again
		[self _saveStateArrayAndNotifyOfChanges];
		[[adium preferenceController] setPreference:nil
											 forKey:@"Saved Status"
											  group:PREF_GROUP_SAVED_STATUS];
	}
}

//State Editing --------------------------------------------------------------------------------------------------------
#pragma mark State Editing
/*!
 * @brief Add a state
 *
 * Add a new state to Adium's state array.
 * @param state AIState to add
 */
- (void)addStatusState:(AIStatus *)statusState
{
	[stateArray addObject:statusState];
	[self _saveStateArrayAndNotifyOfChanges];
}

/*!
 * @brief Remove a state
 *
 * Remove a new state from Adium's state array.
 * @param state AIState to remove
 */
- (void)removeStatusState:(AIStatus *)statusState
{
	[stateArray removeObject:statusState];
	[self _saveStateArrayAndNotifyOfChanges];
}

/*!
 * @brief Move a state
 *
 * Move a state that already exists in Adium's state array to another index
 * @param state AIState to move
 * @param destIndex Destination index
 */
- (int)moveStatusState:(AIStatus *)statusState toIndex:(int)destIndex
{
    int sourceIndex = [stateArray indexOfObject:statusState];
    
    //Remove the state
    [statusState retain];
    [stateArray removeObject:statusState];
    
    //Re-insert the state
    if(destIndex > sourceIndex) destIndex -= 1;
    [stateArray insertObject:statusState atIndex:destIndex];
    [statusState release];
    
	[self _saveStateArrayAndNotifyOfChanges];
	
	return(destIndex);
}

/*!
 * @brief Replace a state
 *
 * Replace a state in Adium's state array with another state.
 * @param oldState AIState state that is in Adium's state array
 * @param newState AIState state with which to replace oldState
 */
- (void)replaceExistingStatusState:(AIStatus *)oldStatusState withStatusState:(AIStatus *)newStatusState
{
	if(oldStatusState != newStatusState){
		int index = [stateArray indexOfObject:oldStatusState];
		
		if(index >= 0 && index < [stateArray count]){
			[stateArray replaceObjectAtIndex:index withObject:newStatusState];
		}
	}

	[self _saveStateArrayAndNotifyOfChanges];
}


//Machine Activity -----------------------------------------------------------------------------------------------------
#pragma mark Machine Activity
#define MACHINE_IDLE_THRESHOLD			30 	//30 seconds of inactivity is considered idle
#define MACHINE_ACTIVE_POLL_INTERVAL	30	//Poll every 60 seconds when the user is active
#define MACHINE_IDLE_POLL_INTERVAL		1	//Poll every second when the user is idle
/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle.  The machine is idle when there are no input
 * events from the user (such as mouse movement or keyboard input).  In addition to this method, the status controller
 * sends out notifications when the machine becomes idle, stays idle, and returns to an active state.
 */
- (double)currentMachineIdle
{
    double idleTime = CGSSecondsSinceLastInputEvent(-1);
		
	//On MDD Powermacs, the above function will return a large value when the machine is active (perhaps a -1?).
	//Here we check for that value and correctly return a 0 idle time.
	if(idleTime >= 18446744000.0) idleTime = 0.0; //18446744073.0 is the lowest I've seen on my MDD -ai
	
    return(idleTime);
}

/*!
 * @brief Timer that checkes for machine idle
 *
 * This timer periodically checks the machine for inactivity.  When the machine has been inactive for atleast
 * MACHINE_IDLE_THRESHOLD seconds, a notification is broadcast.
 *
 * When the machine is active, this timer is called infrequently.  It's not important to notice that the user went
 * idle immediately, so we relax our CPU usage while waiting for an idle state to begin.
 *
 * When the machine is idle, the timer is called frequently.  It's important to notice immediately when the user
 * returns.
 */
- (void)_idleCheckTimer:(NSTimer *)inTimer
{
	double	currentIdle = [self currentMachineIdle];

	if(machineIsIdle){
		if(currentIdle < lastSeenIdle){
			//If the machine is less idle than the last time we recorded, it means that activity has occured and the
			//user is no longer idle.
			[self _setMachineIsIdle:NO];
		}else{
			//Periodically broadcast a 'MachineIdleUpdate' notification
			[[adium notificationCenter] postNotificationName:AIMachineIdleUpdateNotification
													  object:nil
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithDouble:currentIdle], @"Duration",
														[NSDate dateWithTimeIntervalSinceNow:-currentIdle], @"IdleSince",
														nil]];
		}
	}else{
		//If machine inactivity is over the threshold, the user has gone idle.
		if(currentIdle > MACHINE_IDLE_THRESHOLD) [self _setMachineIsIdle:YES];
	}
	
	lastSeenIdle = currentIdle;
}

/*!
 * @brief Sets the machine as idle or not
 *
 * This internal method updates the frequency of our idle timer depending on whether the machine is considered
 * idle or not.  It also posts the AIMachineIsIdleNotification and AIMachineIsActiveNotification notifications
 * based on the passed idle state
 */
- (void)_setMachineIsIdle:(BOOL)inIdle
{
	machineIsIdle = inIdle;
	
	//Post the appropriate idle or active notification
	if(machineIsIdle){
		[[adium notificationCenter] postNotificationName:AIMachineIsIdleNotification object:nil];
	}else{
		[[adium notificationCenter] postNotificationName:AIMachineIsActiveNotification object:nil];
	}
	
	//Update our timer interval for either idle or active polling
	[idleTimer invalidate];
	[idleTimer release];
	idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(machineIsIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL)
												  target:self
												selector:@selector(_idleCheckTimer:)
												userInfo:nil
												 repeats:YES] retain];
}


//State menu support ---------------------------------------------------------------------------------------------------
#pragma mark State menu support
/*!
 * @brief Register a state menu plugin
 *
 * A state menu plugin is the mitigator between our state menu items and a menu.  As states change the plugin
 * is told to add and remove items from the menu.  Everything else is handled by the status controller.
 * @param stateMenuPlugin The state menu plugin to dadam iregister
 */
- (void)registerStateMenuPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber	*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	
	//Track this plugin
	[stateMenuItemArraysDict setObject:[NSMutableArray array] forKey:identifier];
	[stateMenuPluginsArray addObject:stateMenuPlugin];
	
	//Start it out with a fresh set of menu items
	[self _addStateMenuItemsForPlugin:stateMenuPlugin];
}

/*!
 * @brief Unregister a state menu plugin
 *
 * All state menu items will be removed from the plugin when it unregisters
 * @param stateMenuPlugin The state menu plugin to unregister
 */
- (void)unregisterStateMenuPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber	*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];

	//Remove all the plugin's menu items
	[self _removeStateMenuItemsForPlugin:stateMenuPlugin];	
	
	//Stop tracking the plugin
	[stateMenuItemArraysDict removeObjectForKey:identifier];
	[stateMenuPluginsArray removeObjectIdenticalTo:stateMenuPlugin];
}
	
/*!
 * @brief Add state menu items
 *
 * Adds all the necessary state menu items to a plugin's state menu
 * @param stateMenuPlugin The state menu plugin we're updating
 */
- (void)_addStateMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber		*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	NSMutableArray  *menuItemArray = [stateMenuItemArraysDict objectForKey:identifier];
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
	AIStatus		*statusState;
	
	//Create a menu item for each state
	enumerator = [[[adium statusController] stateArray] objectEnumerator];
	while(statusState = [enumerator nextObject]){
		menuItem = [[NSMenuItem alloc] initWithTitle:[self _titleForMenuDisplayOfState:statusState]
											  target:self
											  action:@selector(selectState:)
									   keyEquivalent:@""];
		
		//NSMenuItem will call setFlipped: on the image we pass it, causing flipped drawing elsewhere if we pass it the
		//shared status icon.  So we pass it a copy of the shared icon that it's free to manipulate.
		[menuItem setImage:[[[statusState icon] copy] autorelease]];
		[menuItem setRepresentedObject:statusState];
		[menuItemArray addObject:menuItem];
		[menuItem release];
	}
	
	//Add the "Custom..." state option
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Custom..."
										  target:self
										  action:@selector(selectCustomState:)
								   keyEquivalent:@""];
	[menuItem setImage:[AIStatusIcons statusIconForStatusID:@"unknown"
													   type:AIStatusIconList
												  direction:AIIconNormal]];
	[menuItemArray addObject:menuItem];
	
	//Update the selected menu item
	[self _updateStateMenuSelectionForPlugin:stateMenuPlugin];
	
	//Now that we are done creating the menu items, tell the plugin about them
	[stateMenuPlugin addStateMenuItems:menuItemArray];
}

/*!
 * @brief Removes state menu items
 *
 * Removes all the state menu items from a plugin's state menu
 * @param stateMenuPlugin The state menu plugin we're updating
 */
- (void)_removeStateMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber		*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	NSMutableArray  *menuItemArray = [stateMenuItemArraysDict objectForKey:identifier];

	//Inform the plugin that we are removing the items in the this array 
	[stateMenuPlugin removeStateMenuItems:menuItemArray];
	
	//Now clear the array
	[menuItemArray removeAllObjects];
}

/*!
 * @brief Completely rebuild all state menus
 */
- (void)rebuildAllStateMenus
{
	NSEnumerator			*enumerator = [stateMenuPluginsArray objectEnumerator];
	id <StateMenuPlugin>	stateMenuPlugin;
	
	while(stateMenuPlugin = [enumerator nextObject]) {
		[self _removeStateMenuItemsForPlugin:stateMenuPlugin];
		[self _addStateMenuItemsForPlugin:stateMenuPlugin];
	}
}

/*!
 * @brief Update the selected state in all state menus
 */
- (void)updateAllStateMenuSelections
{
	NSEnumerator			*enumerator = [stateMenuPluginsArray objectEnumerator];
	id <StateMenuPlugin>	stateMenuPlugin;
	
	while(stateMenuPlugin = [enumerator nextObject]){
		[self _updateStateMenuSelectionForPlugin:stateMenuPlugin];
	}
}

/*!
 * @brief Update the selected state in a plugin's state menu
 *
 * Updates the selected state menu item to reflect the currently active state.
 * @param stateMenuPlugin The state menu plugin we're updating
 */
- (void)_updateStateMenuSelectionForPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber		*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	NSEnumerator	*enumerator = [[stateMenuItemArraysDict objectForKey:identifier] objectEnumerator];
	NSMenuItem		*menuItem;
	
	// Our "Custom..." menu choice has a nil represented object.  Here we check if the active state is in our
	// state array.  If it is not, that means the active state is a custom state, so we'll set searchState
	// to nil so our enumeration sets the "Custom..." menu choice as active.  Otherwise, set searchState to
	// our active state so we set the active state's menu item as active.
	AIStatus	*searchState = ([stateArray containsObject:activeStatusState] ? activeStatusState : nil);

	//Scan each menu item and correctly set it as active or non-active
	while(menuItem = [enumerator nextObject]){
		if([menuItem representedObject] == searchState){
			if([menuItem state] != NSOnState) [menuItem setState:NSOnState];
		}else{
			if([menuItem state] != NSOffState) [menuItem setState:NSOffState];
		}
	}
}

/*!
 * @brief Menu validation
 *
 * Our state menu items should always be active, so always return YES for validation.
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return(YES);
}

/*!
 * @brief Select a state menu item
 *
 * Invoked by a state menu item, sets the state corresponding to the menu item as the active state.
 */
- (void)selectState:(id)sender
{
	[self setActiveStatusState:[sender representedObject]];
}

/*!
 * @brief Select the custom state menu item
 *
 * Invoked by the custom state menu item, opens a custom state window.
 */
- (IBAction)selectCustomState:(id)sender
{
	[AIEditStateWindowController editCustomState:[self activeStatusState]
										onWindow:nil
								 notifyingTarget:self];
}

/*!
 * @brief Apply a custom state
 *
 * Invoked when the custom state window is closed by the user clicking OK.  In response this method sets the custom
 * state as the active state.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState
{
	[self setActiveStatusState:newState];
}

/*!
 * @brief Determine a string to use as a menu title
 *
 * This method truncates a state title string for display as a menu item.  It also strips newlines which can cause odd
 * menu item display.  Wide menus aren't pretty and may cause crashing in certain versions of OS X, so all state
 * titles should be run through this method before being used as menu item titles.
 *
 * @param statusState The state for which we want a title
 *
 * @result An appropriate NSString title
 */
- (NSString *)_titleForMenuDisplayOfState:(AIStatus *)statusState
{
	NSRange		fullRange = NSMakeRange(0,0);
	NSRange		trimRange;
	NSString	*title = [statusState title];
	
	//Strip newlines, they'll screw up menu display
	title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	//Truncate by length
	trimRange = [title lineRangeForRange:fullRange];
	if(!NSEqualRanges(trimRange, NSMakeRange(0, [title length]-1))){
		title = [title substringWithRange:trimRange];
	}
	if([title length] > STATE_TITLE_MENU_LENGTH){
		title = [[title substringToIndex:STATE_TITLE_MENU_LENGTH] stringByAppendingString:ELIPSIS_STRING];
	}
	
	return(title);
}

@end
