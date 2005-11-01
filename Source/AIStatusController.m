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
#import "AIEditStateWindowController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import "AdiumIdleManager.h"

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIStatusIcons.h>

//State menu
#define STATE_TITLE_MENU_LENGTH		30
#define STATUS_TITLE_CUSTOM			[AILocalizedString(@"Custom",nil) stringByAppendingEllipsis]
#define STATUS_TITLE_OFFLINE		AILocalizedString(@"Offline",nil)

#define BUILT_IN_STATE_ARRAY		@"BuiltInStatusStates"

#define TOP_STATUS_STATE_ID			@"TopStatusID"

@interface AIStatusController (PRIVATE)
- (NSArray *)builtInStateArray;

- (void)_saveStateArrayAndNotifyOfChanges;
- (void)_upgradeSavedAwaysToSavedStates;
- (void)_addStateMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)_removeStateMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (BOOL)removeIfNecessaryTemporaryStatusState:(AIStatus *)originalState;
- (NSString *)_titleForMenuDisplayOfState:(AIStatus *)statusState;

- (NSArray *)_menuItemsForStatusesOfType:(AIStatusType)type forServiceCodeUniqueID:(NSString *)inServiceCodeUniqueID withTarget:(id)target;
- (void)_addMenuItemsForStatusOfType:(AIStatusType)type
						  withTarget:(id)target
							 fromSet:(NSSet *)sourceArray
							 toArray:(NSMutableArray *)menuItems
				  alreadyAddedTitles:(NSMutableSet *)alreadyAddedTitles;
- (void)buildBuiltInStatusTypes;

@end

/*!
 * @class AIStatusController
 * @brief Core status & state methods
 *
 * This class provides a foundation for Adium's status and status state systems.
 */
@implementation AIStatusController

static 	NSMutableSet			*temporaryStateArray = nil;

/*!
 * Init the status controller
 */
- (id)init
{
	if ((self = [super init])) {
		stateMenuItemArraysDict = [[NSMutableDictionary alloc] init];
		stateMenuPluginsArray = [[NSMutableArray alloc] init];
		stateMenuItemsNeedingUpdating = [[NSMutableSet alloc] init];
		stateMenuUpdateDelays = 0;
		_sortedFullStateArray = nil;
		_activeStatusState = nil;
		_allActiveStatusStates = nil;
		temporaryStateArray = [[NSMutableSet alloc] init];
		
		accountsToConnect = [[NSMutableSet alloc] init];
		isProcessingGlobalChange = NO;
		
		idleManager = [[AdiumIdleManager alloc] init];
	}
	
	return self;
}

/*!
 * @brief Finish initing the status controller
 *
 * Set our initial status state, and restore our array of accounts to connect when a global state is selected.
 */
- (void)controllerDidLoad
{
	NSNotificationCenter	*adiumNotificationCenter = [adium notificationCenter];
	NSEnumerator			*enumerator;
	AIAccount				*account;

	//Update our state menus when the state array or status icon set changes
	[adiumNotificationCenter addObserver:self
								selector:@selector(rebuildAllStateMenus)
									name:AIStatusStateArrayChangedNotification
								  object:nil];
	[adiumNotificationCenter addObserver:self
								selector:@selector(rebuildAllStateMenus)
									name:AIStatusIconSetDidChangeNotification
								  object:nil];
	[[adium contactController] registerListObjectObserver:self];

	[self buildBuiltInStatusTypes];

	//Put each account into the status it was in last time we quit.
	BOOL		needToRebuildMenus = NO;
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		NSData		*lastStatusData = [account preferenceForKey:@"LastStatus"
														  group:GROUP_ACCOUNT_STATUS];
		AIStatus	*lastStatus = nil;
		if (lastStatusData) {
			lastStatus = [NSKeyedUnarchiver unarchiveObjectWithData:lastStatusData];
		}

		if (lastStatus) {
			AIStatus	*existingStatus;
			
			/* We want to use a loaded status instance if one exists.  This will be the case if the account
			 * was last in a built-in or user defined and saved state.  If the last state was unsaved, existingStatus
			 * will be nil.
			 */
			existingStatus = [self statusStateWithUniqueStatusID:[lastStatus uniqueStatusID]];
			
			if (existingStatus) {
				lastStatus = existingStatus;
			} else {
				//Add to our temporary status array
				[temporaryStateArray addObject:lastStatus];
				
				//And clear our full array so it will reflect this newly loaded status when next used
				[_sortedFullStateArray release]; _sortedFullStateArray = nil;
				needToRebuildMenus = YES;
			}
			
			[account setStatusStateAndRemainOffline:lastStatus];
		}
	}
	
	if (needToRebuildMenus) {
		//Clear the sorted menu items array since our state array changed.
		[_sortedFullStateArray release]; _sortedFullStateArray = nil;
		
		//Now rebuild our menus to include this temporary item
		[self rebuildAllStateMenus];
	}
}

/*!
 * @brief Begin closing the status controller
 *
 * Save the online accounts; they will be the accounts connected by a global status change
 *
 * Also save the current status state of each account so it can be restored on next launch.
 */
- (void)controllerWillClose
{
	NSEnumerator	*enumerator;
	AIAccount		*account;

	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		/* Store the current status state for use on next launch.
		 *
		 * We use the statusObjectForKey:@"StatusState" accessor rather than [account statusState]
		 * because we don't want anything besides the account's actual status state.  That is, we don't
		 * want the default available state if the account doesn't have a state yet, and we want the
		 * real last-state-which-was-set (not the offline one) if the account is offline.
		 */
		AIStatus	*currentStatus = [account statusObjectForKey:@"StatusState"];
		[account setPreference:((currentStatus && (currentStatus != offlineStatusState)) ?
								[NSKeyedArchiver archivedDataWithRootObject:currentStatus] :
								nil)
						forKey:@"LastStatus"
						 group:GROUP_ACCOUNT_STATUS];
	}
	
	[[adium preferenceController] setPreference:[NSKeyedArchiver archivedDataWithRootObject:[self stateArray]]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];

	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium contactController] unregisterListObjectObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[stateArray release]; stateArray = nil;
	[_sortedFullStateArray release]; _sortedFullStateArray = nil;
	[super dealloc];
}

#pragma mark Status registration
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
	if (!statusDictsByServiceCodeUniqueID[type]) statusDictsByServiceCodeUniqueID[type] = [[NSMutableDictionary alloc] init];
	if (!(statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:serviceCodeUniqueID])) {
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

#pragma mark Status menus
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
	AIStatusType	type;

	for (type = AIAvailableStatusType ; type < STATUS_TYPES_COUNT ; type++) {
		NSArray		*menuItemArray;

		menuItemArray = [self _menuItemsForStatusesOfType:type
								   forServiceCodeUniqueID:serviceCodeUniqueID
											   withTarget:target];

		//Add a separator between each type after available
		if ((type > AIAvailableStatusType) && [menuItemArray count]) {
			[menu addItem:[NSMenuItem separatorItem]];
		}

		//Add the items for this type
		enumerator = [menuItemArray objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			[menu addItem:menuItem];
		}
	}

	return [menu autorelease];
}

/*!
 * @brief Sort status menu items
 *
 * Sort alphabetically by title.
 */
int statusMenuItemSort(id menuItemA, id menuItemB, void *context)
{
	return [[menuItemA title] caseInsensitiveCompare:[menuItemB title]];
}

/*!
 * @brief Return an array of menu items for an AIStatusType and service
 *
 * @pram type The AIStatusType for which to return statuses
 * @param inServiceCodeUniqueID The service for which to return active statuses.  If nil, return all statuses for online services.
 * @param target The target for the menu items
 *
 * @result An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects.
 */
- (NSArray *)_menuItemsForStatusesOfType:(AIStatusType)type forServiceCodeUniqueID:(NSString *)inServiceCodeUniqueID withTarget:(id)target
{
	//Quick efficiency: If asked for the offline status type, just return nil as we have no offline statuses at present.
	if (type == AIOfflineStatusType) return nil;

	NSMutableArray  *menuItems = [[NSMutableArray alloc] init];
	NSMutableSet	*alreadyAddedTitles = [NSMutableSet set];

	//First, add our built-in items (so they will be at the top of the array and service-specific 'copies' won't replace them)
	[self _addMenuItemsForStatusOfType:type
							withTarget:target
							   fromSet:builtInStatusTypes[type]
							   toArray:menuItems
					alreadyAddedTitles:alreadyAddedTitles];

	//Now, add items for this service, or from all available services, as appropriate
	if (inServiceCodeUniqueID) {
		NSSet	*statusDicts;

		//Obtain the status dicts for this type and service code unique ID
		if ((statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:inServiceCodeUniqueID])) {
			//And add them
			[self _addMenuItemsForStatusOfType:type
									withTarget:target
									   fromSet:statusDicts
									   toArray:menuItems
							alreadyAddedTitles:alreadyAddedTitles];
		}

	} else {
		NSEnumerator	*enumerator;
		NSString		*serviceCodeUniqueID;
//		BOOL			oneOrMoreConnectedAccounts = [[adium accountController] oneOrMoreConnectedAccounts];

		//Insert a menu item for each available account
		enumerator = [statusDictsByServiceCodeUniqueID[type] keyEnumerator];
		while ((serviceCodeUniqueID = [enumerator nextObject])) {
			/* Obtain the status dicts for this type and service code unique ID if it is online or
			 * if no accounts are online but an account of this service code is configured
			 */
//			if ([[adium accountController] serviceWithUniqueIDIsOnline:serviceCodeUniqueID] ||
//				(!oneOrMoreConnectedAccounts && [[adium accountController] firstAccountWithService:[[adium accountController] serviceWithUniqueID:serviceCodeUniqueID]])) {
				NSSet	*statusDicts;

				//Obtain the status dicts for this type and service code unique ID
				if ((statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:serviceCodeUniqueID])) {
					//And add them
					[self _addMenuItemsForStatusOfType:type
											withTarget:target
											   fromSet:statusDicts
											   toArray:menuItems
									alreadyAddedTitles:alreadyAddedTitles];
				}
//			}
		}
	}

	[menuItems sortUsingFunction:statusMenuItemSort context:nil];

	return [menuItems autorelease];
}

/*!
 * @brief Add menu items for a particular type of status
 *
 * @param type The AIStatusType, used for determining the icon of the menu items
 * @param target The target of the created menu items
 * @param statusDicts An NSSet of NSDictionary objects, which should each represent a status of the passed type
 * @param menuItems The NSMutableArray to which to add the menuItems
 * @param alreadyAddedTitles NSMutableSet of NSString titles which have already been added and should not be duplicated. Will be updated as items are added.
 */
- (void)_addMenuItemsForStatusOfType:(AIStatusType)type
						  withTarget:(id)target
							 fromSet:(NSSet *)statusDicts
							 toArray:(NSMutableArray *)menuItems
				  alreadyAddedTitles:(NSMutableSet *)alreadyAddedTitles
{
	NSEnumerator	*statusDictEnumerator = [statusDicts objectEnumerator];
	NSDictionary	*statusDict;

	//Enumerate the status dicts
	while ((statusDict = [statusDictEnumerator nextObject])) {
		NSString	*title = [statusDict objectForKey:KEY_STATUS_DESCRIPTION];

		/*
		 * Only add if it has not already been added by another service.... Services need to use unique titles if they have
		 * unique state names, but are welcome to share common name/description combinations, which is why the #defines
		 * exist.
		 */
		if (![alreadyAddedTitles containsObject:title]) {
			NSImage		*image;
			NSMenuItem	*menuItem;

			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																			target:target
																			action:@selector(selectStatus:)
																	 keyEquivalent:@""];

			image = [AIStatusIcons statusIconForStatusName:[statusDict objectForKey:KEY_STATUS_NAME]
												  statusType:type
													iconType:AIStatusIconMenu
												   direction:AIIconNormal];

			[menuItem setRepresentedObject:statusDict];
			[menuItem setImage:image];
			[menuItem setEnabled:YES];
			[menuItems addObject:menuItem];
			[menuItem release];

			[alreadyAddedTitles addObject:title];
		}
	}
}

#pragma mark Status State Descriptions
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
	while ((set = [enumerator nextObject])) {
		NSEnumerator	*statusDictsEnumerator = [set objectEnumerator];
		NSDictionary	*statusDict;
		while ((statusDict = [statusDictsEnumerator nextObject])) {
			if ([[statusDict objectForKey:KEY_STATUS_NAME] isEqualToString:statusName]) {
				return [statusDict objectForKey:KEY_STATUS_DESCRIPTION];
			}
		}
	}

	return nil;
}

- (NSString *)localizedDescriptionForCoreStatusName:(NSString *)statusName
{
	static NSDictionary	*coreLocalizedStatusDescriptions = nil;
	if (!coreLocalizedStatusDescriptions) {
		coreLocalizedStatusDescriptions = [[NSDictionary dictionaryWithObjectsAndKeys:
			STATUS_DESCRIPTION_AVAILABLE, STATUS_NAME_AVAILABLE,
			STATUS_DESCRIPTION_FREE_FOR_CHAT, STATUS_NAME_FREE_FOR_CHAT,
			STATUS_DESCRIPTION_AVAILABLE_FRIENDS_ONLY, STATUS_NAME_AVAILABLE_FRIENDS_ONLY,
			STATUS_DESCRIPTION_AWAY, STATUS_NAME_AWAY,
			STATUS_DESCRIPTION_EXTENDED_AWAY, STATUS_NAME_EXTENDED_AWAY,
			STATUS_DESCRIPTION_AWAY_FRIENDS_ONLY, STATUS_NAME_AWAY_FRIENDS_ONLY,
			STATUS_DESCRIPTION_DND, STATUS_NAME_DND,
			STATUS_DESCRIPTION_NOT_AVAILABLE, STATUS_NAME_NOT_AVAILABLE,
			STATUS_DESCRIPTION_OCCUPIED, STATUS_NAME_OCCUPIED,
			STATUS_DESCRIPTION_BRB, STATUS_NAME_BRB,
			STATUS_DESCRIPTION_BUSY, STATUS_NAME_BUSY,
			STATUS_DESCRIPTION_PHONE, STATUS_NAME_PHONE,
			STATUS_DESCRIPTION_LUNCH, STATUS_NAME_LUNCH,
			STATUS_DESCRIPTION_NOT_AT_HOME, STATUS_NAME_NOT_AT_HOME,
			STATUS_DESCRIPTION_NOT_AT_DESK, STATUS_NAME_NOT_AT_DESK,
			STATUS_DESCRIPTION_NOT_IN_OFFICE, STATUS_NAME_NOT_IN_OFFICE,
			STATUS_DESCRIPTION_VACATION, STATUS_NAME_VACATION,
			STATUS_DESCRIPTION_STEPPED_OUT, STATUS_NAME_STEPPED_OUT,
			STATUS_DESCRIPTION_INVISIBLE, STATUS_NAME_INVISIBLE,
			STATUS_DESCRIPTION_OFFLINE, STATUS_NAME_OFFLINE,
			nil] retain];
	}

	return [coreLocalizedStatusDescriptions objectForKey:statusName];
}



/*!
 * @brief The status name to use by default for a passed type
 *
 * This is the name which will be used for new AIStatus objects of this type.
 */
- (NSString *)defaultStatusNameForType:(AIStatusType)statusType
{
	//Set the default status name
	switch (statusType) {
		case AIAvailableStatusType:
			return STATUS_NAME_AVAILABLE;
			break;
		case AIAwayStatusType:
			return STATUS_NAME_AWAY;
			break;
		case AIInvisibleStatusType:
			return STATUS_NAME_INVISIBLE;
			break;
		case AIOfflineStatusType:
			return STATUS_NAME_OFFLINE;
			break;
	}

	return nil;
}

#pragma mark Setting Status States
/*!
 * @brief Set the active status state
 *
 * Sets the currently active status state.  This applies throughout Adium and to all accounts.  The state will become
 * effective immediately.
 */
- (void)setActiveStatusState:(AIStatus *)statusState
{
	//Apply the state to our accounts and notify (delay to the next run loop to improve perceived speed)
	[self performSelector:@selector(applyState:toAccounts:)
			   withObject:statusState
			   withObject:[[adium accountController] accounts]
			   afterDelay:0];
}

/*!
 * @brief Return the <tt>AIStatus</tt> to be used by accounts as they are created
 */
- (AIStatus *)defaultInitialStatusState
{
	return [[self builtInStateArray] objectAtIndex:0];
}

/*!
 * @brief Reset the active status state
 *
 * All active status states cache will also reset.  Posts an active status changed notification.  The active state
 * will be regenerated the next time it is requested.
 */
- (void)_resetActiveStatusState
{
	//Clear the active status state.  It will be rebuilt next time it is requested
	[_activeStatusState release]; _activeStatusState = nil;
	[_allActiveStatusStates release]; _allActiveStatusStates = nil;

	//Let observers know the active state has changed
	[[adium notificationCenter] postNotificationName:AIStatusActiveStateChangedNotification object:nil];
}

/*!
 * @brief Apply a state to multiple accounts
 */
- (void)applyState:(AIStatus *)statusState toAccounts:(NSArray *)accountArray
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	AIStatus		*aStatusState;
	BOOL			shouldRebuild = NO;

	isProcessingGlobalChange = YES;
	[self setDelayStateMenuUpdates:YES];
	
	enumerator = [accountArray objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account enabled]) {
			[account setStatusState:statusState];

		} else {
			[account setStatusStateAndRemainOffline:statusState];			
		}
	}

	//Any objects in the temporary state array which aren't the state we just set should now be removed.
	enumerator = [[[temporaryStateArray copy] autorelease] objectEnumerator];
	while ((aStatusState = [enumerator nextObject])) {
		if (aStatusState != statusState) {
			[temporaryStateArray removeObject:aStatusState];
			shouldRebuild = YES;
		}
	}

	isProcessingGlobalChange = NO;

	if (shouldRebuild) {
		//Manually decrease the update delays counter as we don't want to call [self updateAllStateMenuSelections]
		stateMenuUpdateDelays--;
		[self rebuildAllStateMenus];
	} else {
		/* Allow setDelayStateMenuUpdates to decreate the counter and call
		 * [self updateAllStateMenuSelections] as appropriate.
		 */
		[self setDelayStateMenuUpdates:NO];				
	}
}

#pragma mark Retrieving Status States
/*!
 * @brief Access to Adium's user-defined states
 *
 * Returns an array of available user-defined states, which are AIStatus objects
 */
- (NSArray *)stateArray
{
	if (!stateArray) {
		NSData	*savedStateArrayData = [[adium preferenceController] preferenceForKey:KEY_SAVED_STATUS
																				group:PREF_GROUP_SAVED_STATUS];
		if (savedStateArrayData) {
			stateArray = [[NSKeyedUnarchiver unarchiveObjectWithData:savedStateArrayData] mutableCopy];
		}

		if (!stateArray) stateArray = [[NSMutableArray alloc] init];

		//Upgrade Adium 0.7x away messages
		[self _upgradeSavedAwaysToSavedStates];
	}

	return stateArray;
}

/*!
 * @brief Return the array of built-in states
 *
 * These are basic Available and Away states which should always be visible and are (by convention) immutable.
 * The first state in BUILT_IN_STATE_ARRAY will be used as the default for accounts as they are created.
 */
- (NSArray *)builtInStateArray
{
	if (!builtInStateArray) {
		NSArray			*savedBuiltInStateArray = [NSArray arrayNamed:BUILT_IN_STATE_ARRAY forClass:[self class]];
		NSEnumerator	*enumerator;
		NSDictionary	*dict;

		builtInStateArray = [[NSMutableArray alloc] initWithCapacity:[savedBuiltInStateArray count]];

		enumerator = [savedBuiltInStateArray objectEnumerator];
		while ((dict = [enumerator nextObject])) {
			AIStatus	*status = [AIStatus statusWithDictionary:dict];
			[builtInStateArray addObject:status];

			//Store a reference to our offline state if we just loaded it
			if ([status statusType] == AIOfflineStatusType) {
				[offlineStatusState release];
				offlineStatusState = [status retain];
			}
		}
	}

	return builtInStateArray;
}

- (AIStatus *)offlineStatusState
{
	//Ensure the built in states have been loaded
	[self builtInStateArray];

	NSAssert(offlineStatusState != nil, @"Nil offline status state");
	return offlineStatusState;
}

//Sort the status array
int _statusArraySort(id objectA, id objectB, void *context)
{
	AIStatusType statusTypeA = [objectA statusType];
	AIStatusType statusTypeB = [objectB statusType];

	//We treat Invisible statuses as being the same as Away for purposes of the menu
	if (statusTypeA == AIInvisibleStatusType) statusTypeA = AIAwayStatusType;
	if (statusTypeB == AIInvisibleStatusType) statusTypeB = AIAwayStatusType;

	if (statusTypeA > statusTypeB) {
		return NSOrderedDescending;
	} else if (statusTypeB > statusTypeA) {
		return NSOrderedAscending;
	} else {
		AIStatusMutabilityType	mutabilityTypeA = [objectA mutabilityType];
		AIStatusMutabilityType	mutabilityTypeB = [objectB mutabilityType];
		BOOL					isLockedMutabilityTypeA = (mutabilityTypeA == AILockedStatusState);
		BOOL					isLockedMutabilityTypeB = (mutabilityTypeB == AILockedStatusState);

		//Put locked (built in) statuses at the top
		if (isLockedMutabilityTypeA && !isLockedMutabilityTypeB) {
			return NSOrderedAscending;
			
		} else if (!isLockedMutabilityTypeA && isLockedMutabilityTypeB) {
			return NSOrderedDescending;

		} else {
			/* Check to see if either is temporary; temporary items go above saved ones and below
			 * built-in ones.
			 */
			BOOL	isTemporaryA = [temporaryStateArray containsObject:objectA];
			BOOL	isTemporaryB = [temporaryStateArray containsObject:objectB];

			if (isTemporaryA && !isTemporaryB) {
				return NSOrderedAscending;
				
			} else if (isTemporaryB && !isTemporaryA) {
				return NSOrderedDescending;
				
			} else {
				BOOL	isSecondaryMutabilityTypeA = (mutabilityTypeA == AISecondaryLockedStatusState);
				BOOL	isSecondaryMutabilityTypeB = (mutabilityTypeB == AISecondaryLockedStatusState);

				//Put secondary locked statuses at the bottom
				if (isSecondaryMutabilityTypeA && !isSecondaryMutabilityTypeB) {
					return NSOrderedDescending;
					
				} else if (!isSecondaryMutabilityTypeA && isSecondaryMutabilityTypeB) {
					return NSOrderedAscending;

				} else {
					NSArray	*originalArray = (NSArray *)context;
					
					//Return them in the same relative order as the original array if they are of the same type
					int indexA = [originalArray indexOfObjectIdenticalTo:objectA];
					int indexB = [originalArray indexOfObjectIdenticalTo:objectB];
					
					if (indexA > indexB) {
						return NSOrderedDescending;
					} else {
						return NSOrderedAscending;
					}
				}
			}
		}
	}
}

/*!
 * @brief Return a sorted state array for use in menu item creation
 *
 * The array is created by adding the built in states to the user states, then sorting using _statusArraySort
 *
 * @result A cached NSArray which is sorted by status type (available, away), built-in vs. user-made, and then original ordering.
 */
- (NSArray *)sortedFullStateArray
{
	if (!_sortedFullStateArray) {
		NSArray			*originalStateArray = [self stateArray];
		NSMutableArray	*tempArray = [originalStateArray mutableCopy];
		[tempArray addObjectsFromArray:[self builtInStateArray]];
		[tempArray addObjectsFromArray:[temporaryStateArray allObjects]];
		
		//Pass the original array so its indexes can be used for comparison of saved state ordering
		[tempArray sortUsingFunction:_statusArraySort context:originalStateArray];

		_sortedFullStateArray = tempArray;
	}

	return _sortedFullStateArray;
}

/*!
 * @brief Retrieve active status state
 *
 * @result The currently active status state.
 *
 * This is defined as the status state which the most accounts are currently using.  The behavior in case of a tie
 * is currently undefined but will yield one of the tying states.
 */
- (AIStatus *)activeStatusState
{
	if (!_activeStatusState) {
		NSEnumerator		*enumerator = [[[adium accountController] accounts] objectEnumerator];
		NSCountedSet		*statusCounts = [NSCountedSet set];
		AIAccount			*account;
		AIStatus			*statusState;
		unsigned			 highestCount = 0;
		BOOL				 accountsAreOnline = [[adium accountController] oneOrMoreConnectedOrConnectingAccounts];

		if (accountsAreOnline) {
			AIStatus	*bestStatusState = nil;

			while ((account = [enumerator nextObject])) {
				if ([account online]) {
					AIStatus *accountStatusState = [account statusState];
					[statusCounts addObject:(accountStatusState ?
											 accountStatusState :
											 [self defaultInitialStatusState])];
				}
			}

			enumerator = [statusCounts objectEnumerator];
			while ((statusState = [enumerator nextObject])) {
				unsigned thisCount = [statusCounts countForObject:statusState];
				if (thisCount > highestCount) {
					bestStatusState = statusState;
					highestCount = thisCount;
				}
			}

			_activeStatusState = [bestStatusState retain];
		} else {
			_activeStatusState = [offlineStatusState retain];
		}
	}

	return _activeStatusState;
}

/*
 * @brief Find the 'active' AIStatusType
 *
 * The active type is the one used by the largest number of accounts.  In case of a tie, the order of the AIStatusType
 * enum is respected
 *
 * @param invisibleIsAway If YES, AIInvisibleStatusType is trated as AIAwayStatusType
 * @result The active AIStatusType for online accounts, or AIOfflineStatusType if all accounts are  offline
 */
- (AIStatusType)activeStatusTypeTreatingInvisibleAsAway:(BOOL)invisibleIsAway
{
	NSEnumerator		*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount			*account;
	int					statusTypeCount[STATUS_TYPES_COUNT];
	AIStatusType		activeStatusType = AIOfflineStatusType;
	unsigned			highestCount = 0;

	unsigned i;
	for (i = 0 ; i < STATUS_TYPES_COUNT ; i++) {
		statusTypeCount[i] = 0;
	}

	while ((account = [enumerator nextObject])) {
		if ([account online] || [account integerStatusObjectForKey:@"Connecting"]) {
			AIStatusType statusType = [[account statusState] statusType];

			//If invisibleIsAway, pretend that invisible is away
			if (invisibleIsAway && (statusType == AIInvisibleStatusType)) statusType = AIAwayStatusType;

			statusTypeCount[statusType]++;
		}
	}

	for (i = 0 ; i < STATUS_TYPES_COUNT ; i++) {
		if (statusTypeCount[i] > highestCount) {
			activeStatusType = i;
			highestCount = statusTypeCount[i];
		}
	}

	return activeStatusType;
}

/*!
 * @brief All active status states
 *
 * A status state is active if any online account is currently in that state.
 *
 * The return value of this method is cached.
 *
 * @result An <tt>NSSet</tt> of <tt>AIStatus</tt> objects
 */
- (NSSet *)allActiveStatusStates
{
	if (!_allActiveStatusStates) {
		_allActiveStatusStates = [[NSMutableSet alloc] init];
		NSEnumerator		*enumerator = [[[adium accountController] accounts] objectEnumerator];
		AIAccount			*account;

		while ((account = [enumerator nextObject])) {
			if ([account enabled] &&
				([account online] || [account integerStatusObjectForKey:@"Connecting"])) {
				[_allActiveStatusStates addObject:[account statusState]];
			}
		}
	}

	return _allActiveStatusStates;
}

/*!
 * @brief Return the set of all unavailable statuses in use by online or connection accounts
 *
 * @param activeUnvailableStatusType Pointer to an AIStatusType; returns by reference the most popular unavailable type
 * @param activeUnvailableStatusName Pointer to an NSString*; returns by reference a status name if all states are in the same name, or nil if they differ
 * @param allOnlineAccountsAreUnvailable Pointer to a BOOL; returns by reference YES is all online accounts are unavailable, NO if one or more is available
 */
- (NSSet *)activeUnavailableStatusesAndType:(AIStatusType *)activeUnvailableStatusType withName:(NSString **)activeUnvailableStatusName allOnlineAccountsAreUnvailable:(BOOL *)allOnlineAccountsAreUnvailable
{
	NSEnumerator		*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount			*account;
	NSMutableSet		*activeUnvailableStatuses = [NSMutableSet set];
	BOOL				foundStatusName = NO;
	int					statusTypeCount[STATUS_TYPES_COUNT];

	statusTypeCount[AIAwayStatusType] = 0;
	statusTypeCount[AIInvisibleStatusType] = 0;
	
	//Assume all accounts are unavailable until proven otherwise
	if (allOnlineAccountsAreUnvailable != NULL) {
		*allOnlineAccountsAreUnvailable = YES;
	}
	
	while ((account = [enumerator nextObject])) {
		if ([account online] || [account integerStatusObjectForKey:@"Connecting"]) {
			AIStatus	*statusState = [account statusState];
			AIStatusType statusType = [statusState statusType];
			
			if ((statusType == AIAwayStatusType) || (statusType == AIInvisibleStatusType)) {
				NSString	*statusName = [statusState statusName];
				
				[activeUnvailableStatuses addObject:statusState];
				
				statusTypeCount[statusType]++;
				
				if (foundStatusName) {
					//Once we find a status name, we only want to return it if all our status names are the same.
					if ((activeUnvailableStatusName != NULL) &&
					   (*activeUnvailableStatusName != nil) && 
					   ![*activeUnvailableStatusName isEqualToString:statusName]) {
						*activeUnvailableStatusName = nil;
					}
				} else {
					//We haven't found a status name yet, so store this one as the active status name
					if (activeUnvailableStatusName != NULL) {
						*activeUnvailableStatusName = [statusState statusName];
					}
					foundStatusName = YES;
				}
			} else {
				//An online account isn't unavailable
				if (allOnlineAccountsAreUnvailable != NULL) {
					*allOnlineAccountsAreUnvailable = NO;
				}
			}
		}
	}
	
	if (activeUnvailableStatusType != NULL) {
		if (statusTypeCount[AIAwayStatusType] > statusTypeCount[AIInvisibleStatusType]) {
			*activeUnvailableStatusType = AIAwayStatusType;
		} else {
			*activeUnvailableStatusType = AIInvisibleStatusType;		
		}
	}
	
	return activeUnvailableStatuses;
}


/*!
 * @brief Next available unique status ID
 */
- (NSNumber *)nextUniqueStatusID
{
	NSNumber	*nextUniqueStatusID;

	//Retain and autorelease since we'll be replacing this value (and therefore releasing it) via the preferenceController.
	nextUniqueStatusID = [[[[adium preferenceController] preferenceForKey:TOP_STATUS_STATE_ID
																  group:PREF_GROUP_SAVED_STATUS] retain] autorelease];
	if (!nextUniqueStatusID) nextUniqueStatusID = [NSNumber numberWithInt:1];

	[[adium preferenceController] setPreference:[NSNumber numberWithInt:([nextUniqueStatusID intValue] + 1)]
										 forKey:TOP_STATUS_STATE_ID
										  group:PREF_GROUP_SAVED_STATUS];

	return nextUniqueStatusID;
}

/*!
 * @brief Find the status state with the requested uniqueStatusID
 */
- (AIStatus *)statusStateWithUniqueStatusID:(NSNumber *)uniqueStatusID
{
	AIStatus		*statusState = nil;

	if (uniqueStatusID) {
		NSEnumerator	*enumerator = [[self sortedFullStateArray] objectEnumerator];

		while ((statusState = [enumerator nextObject])) {
			if ([[statusState uniqueStatusID] compare:uniqueStatusID] == NSOrderedSame)
				break;
		}
	}

	return statusState;
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
	AIStatusMutabilityType mutabilityType = [statusState mutabilityType];
	
	if ((mutabilityType == AILockedStatusState) ||
		(mutabilityType == AISecondaryLockedStatusState)) {
		//If we are adding a locked status, add it to the built-in statuses
		[(NSMutableArray *)[self builtInStateArray] addObject:statusState];

	} else {
		//Otherwise, add it to the user-created statuses
		[stateArray addObject:statusState];
	}

	//Either way, save any changes and notify observers that the status states changed
	[self _saveStateArrayAndNotifyOfChanges];
}

/*!
 * @brief Remove a state
 *
 * Remove a new state from Adium's state array.
 * @param state AIStatus to remove
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
 * @param state AIStatus to move
 * @param destIndex Destination index
 */
- (int)moveStatusState:(AIStatus *)statusState toIndex:(int)destIndex
{
    int sourceIndex = [stateArray indexOfObjectIdenticalTo:statusState];

    //Remove the state
    [statusState retain];
    [stateArray removeObject:statusState];

    //Re-insert the state
    if (destIndex > sourceIndex) destIndex -= 1;
    [stateArray insertObject:statusState atIndex:destIndex];
    [statusState release];

	[self _saveStateArrayAndNotifyOfChanges];

	return destIndex;
}

/*!
 * @brief Replace a state
 *
 * Replace a state in Adium's state array with another state.
 * @param oldState AIStatus state that is in Adium's state array
 * @param newState AIStatus state with which to replace oldState
 */
- (void)replaceExistingStatusState:(AIStatus *)oldStatusState withStatusState:(AIStatus *)newStatusState
{
	if (oldStatusState != newStatusState) {
		int index = [stateArray indexOfObject:oldStatusState];

		if (index >= 0 && index < [stateArray count]) {
			[stateArray replaceObjectAtIndex:index withObject:newStatusState];
		}
	}

	[self _saveStateArrayAndNotifyOfChanges];
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
	//Clear the sorted menu items array since our state array changed.
	[_sortedFullStateArray release]; _sortedFullStateArray = nil;

	[[adium preferenceController] setPreference:[NSKeyedArchiver archivedDataWithRootObject:[self stateArray]]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];
	[[adium notificationCenter] postNotificationName:AIStatusStateArrayChangedNotification object:nil];
}

- (void)statusStateDidSetUniqueStatusID
{
	[[adium preferenceController] setPreference:[NSKeyedArchiver archivedDataWithRootObject:[self stateArray]]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];
}

//Status state menu support ---------------------------------------------------------------------------------------------------
#pragma mark Status state menu support
/*!
 * @brief Register a state menu plugin
 *
 * A state menu plugin is the mitigator between our state menu items and a menu.  As states change the plugin
 * is told to add and remove items from the menu.  Everything else is handled by the status controller.
 * @param stateMenuPlugin The state menu plugin to register
 */
- (void)registerStateMenuPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber	*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];

	//Track this plugin
	[stateMenuItemArraysDict setObject:[NSMutableArray array] forKey:identifier];
	[stateMenuPluginsArray addObject:[NSValue valueWithNonretainedObject:stateMenuPlugin]];

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
	[stateMenuPluginsArray removeObject:[NSValue valueWithNonretainedObject:stateMenuPlugin]];
}

/*!
 * @brief Remove the status controller's tracking for a plugin's menu items
 *
 * This should be called in preparation for one or more plugin:didAddMenuItems: calls to clear out the current
 * tracking for the statusController generated menu items.
 */
- (void)removeAllMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber		*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	NSMutableArray  *menuItemArray = [stateMenuItemArraysDict objectForKey:identifier];

	//Remove the menu items from needing update
	[stateMenuItemsNeedingUpdating minusSet:[NSSet setWithArray:menuItemArray]];

	//Clear the array itself
	[menuItemArray removeAllObjects];
}

/*!
 * @brief A plugin created its own menu items it wants us to track and update
 */
- (void)plugin:(id <StateMenuPlugin>)stateMenuPlugin didAddMenuItems:(NSArray *)addedMenuItems
{
	NSNumber		*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	NSMutableArray  *menuItemArray = [stateMenuItemArraysDict objectForKey:identifier];

	[menuItemArray addObjectsFromArray:addedMenuItems];
	[stateMenuItemsNeedingUpdating addObjectsFromArray:addedMenuItems];
}

/*
 * @brief Generate the custom menu item for a status type
 */
- (NSMenuItem *)customMenuItemForStatusType:(AIStatusType)statusType
{
	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:STATUS_TITLE_CUSTOM
										  target:self
										  action:@selector(selectCustomState:)
								   keyEquivalent:@""];

	[menuItem setImage:[AIStatusIcons statusIconForStatusName:nil
												   statusType:statusType
													 iconType:AIStatusIconMenu
													direction:AIIconNormal]];
	[menuItem setTag:statusType];
	
	return [menuItem autorelease];
				
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
	AIStatusType			currentStatusType = AIAvailableStatusType;
	AIStatusMutabilityType	currentStatusMutabilityType = AILockedStatusState;

	/* Create a menu item for each state.  States must first be sorted such that states of the same AIStatusType
	 * are grouped together.
	 */
	enumerator = [[self sortedFullStateArray] objectEnumerator];
	while ((statusState = [enumerator nextObject])) {
		AIStatusType thisStatusType = [statusState statusType];
		AIStatusType thisStatusMutabilityType = [statusState mutabilityType];

		if ((currentStatusMutabilityType != AISecondaryLockedStatusState) &&
			(thisStatusMutabilityType == AISecondaryLockedStatusState)) {
			//Add the custom item, as we are ending this group
			[menuItemArray addObject:[self customMenuItemForStatusType:currentStatusType]];

			//Add a divider when we switch to a secondary locked group
			[menuItemArray addObject:[NSMenuItem separatorItem]];
		}
		
		//We treat Invisible statuses as being the same as Away for purposes of the menu
		if (thisStatusType == AIInvisibleStatusType) thisStatusType = AIAwayStatusType;

		/* Add the "Custom..." state option and a separatorItem before beginning to add items for a new statusType
		 * Sorting the menu items before enumerating means that we know our statuses are sorted first by statusType
		 */
		if ((currentStatusType != thisStatusType) &&
		   (currentStatusType != AIOfflineStatusType)) {
			
			//Don't include a Custom item after the secondary locked group, as it was already included
			if ((currentStatusMutabilityType != AISecondaryLockedStatusState)) {
				[menuItemArray addObject:[self customMenuItemForStatusType:currentStatusType]];
			}
			
			//Add a divider
			[menuItemArray addObject:[NSMenuItem separatorItem]];

			currentStatusType = thisStatusType;
		}

		menuItem = [[NSMenuItem alloc] initWithTitle:[self _titleForMenuDisplayOfState:statusState]
											  target:self
											  action:@selector(selectState:)
									   keyEquivalent:@""];

		[menuItem setImage:[statusState menuIcon]];
		[menuItem setTag:currentStatusType];
		[menuItem setToolTip:[statusState statusMessageString]];
		[menuItem setRepresentedObject:[NSDictionary dictionaryWithObject:statusState
																   forKey:@"AIStatus"]];
		[menuItemArray addObject:menuItem];
		[menuItem release];
		
		currentStatusMutabilityType = thisStatusMutabilityType;
	}

	if (currentStatusType != AIOfflineStatusType) {
		/* Add the last "Custom..." state optior for the last statusType we handled,
		 * which didn't get a "Custom..." item yet.  At present, our last status type should always be
		 * our AIOfflineStatusType, so this will never be executed and just exists for completeness.
		 */
		[menuItemArray addObject:[self customMenuItemForStatusType:currentStatusType]];
	}

	//Now that we are done creating the menu items, tell the plugin about them
	[stateMenuPlugin addStateMenuItems:menuItemArray];

	//Update the selected menu item after giving the plugin a chance to do with the menu items as it wants
	[self updateStateMenuSelectionForPlugin:stateMenuPlugin];
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

	//Inform the plugin that we are removing the items in this array
	[stateMenuPlugin removeStateMenuItems:menuItemArray];

	//Remove the menu items from needing update
	[stateMenuItemsNeedingUpdating minusSet:[NSSet setWithArray:menuItemArray]];

	//Now clear the array
	[menuItemArray removeAllObjects];
}

/*!
 * @brief Completely rebuild all state menus
 *
 * Before doing so, clear the activeStatusState, which will be regenerated when next needed
 */
- (void)rebuildAllStateMenus
{
	//Clear the sorted menu items array since our state array changed.
	[_sortedFullStateArray release]; _sortedFullStateArray = nil;

	[self _resetActiveStatusState];

	NSEnumerator			*enumerator = [stateMenuPluginsArray objectEnumerator];
	NSValue					*stateMenuPluginValue;

	while ((stateMenuPluginValue = [enumerator nextObject])) {
		id <StateMenuPlugin> stateMenuPlugin = [stateMenuPluginValue nonretainedObjectValue];

		[self _removeStateMenuItemsForPlugin:stateMenuPlugin];
		[self _addStateMenuItemsForPlugin:stateMenuPlugin];
	}
}

/*!
 * @brief Completely rebuild all state menus for a single plugin
 */
- (void)rebuildAllStateMenusForPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	[self _removeStateMenuItemsForPlugin:stateMenuPlugin];
	[self _addStateMenuItemsForPlugin:stateMenuPlugin];
}

/*!
 * @brief Update the selected state in all state menus
 */
- (void)updateAllStateMenuSelections
{
	if (stateMenuUpdateDelays == 0) {
		NSEnumerator			*enumerator = [stateMenuPluginsArray objectEnumerator];
		NSValue					*stateMenuPluginValue;

		[self _resetActiveStatusState];

		while ((stateMenuPluginValue = [enumerator nextObject])) {
			id <StateMenuPlugin> stateMenuPlugin = [stateMenuPluginValue nonretainedObjectValue];
			[self updateStateMenuSelectionForPlugin:stateMenuPlugin];
		}

		/* Let any relevant plugins respond to the to-be-changed state menu selection. Technically we
		 * haven't changed it yet, since we'll do that in validateMenuItem:, but the fact that we will now
		 * need to change it is useful if, for example, key equivalents change in a menu alongside selection
		 * changes, since we need key equivalents set immediately.
		 */
		[[adium notificationCenter] postNotificationName:AIStatusStateMenuSelectionsChangedNotification
												  object:nil];
	}
}

/*!
 * @brief Delay state menu updates
 *
 * This should be called to prevent duplicative updates when multiple accounts are changing status simultaneously.
 */
- (void)setDelayStateMenuUpdates:(BOOL)shouldDelay
{
	if (shouldDelay)
		stateMenuUpdateDelays++;
	else
		stateMenuUpdateDelays--;

	if (stateMenuUpdateDelays == 0) {
		[self updateAllStateMenuSelections];
	}
}

/*!
 * @brief Update the selected state in a plugin's state menu
 *
 * Updates the selected state menu item to reflect the currently active state.
 * @param stateMenuPlugin The state menu plugin we're updating
 */
- (void)updateStateMenuSelectionForPlugin:(id <StateMenuPlugin>)stateMenuPlugin
{
	NSNumber		*identifier = [NSNumber numberWithInt:[stateMenuPlugin hash]];
	NSArray			*stateMenuItemArray = [stateMenuItemArraysDict objectForKey:identifier];
	[stateMenuItemsNeedingUpdating addObjectsFromArray:stateMenuItemArray];
}


/*!
 * @brief Account status changed.
 *
 * Rebuild all our state menus
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]) {

			[self _resetActiveStatusState];

			//Don't update the state menus if we are currently delaying
			if (stateMenuUpdateDelays == 0) [self updateAllStateMenuSelections];
		}
	}

    return nil;
}

/*!
 * @brief Menu validation
 *
 * Our state menu items should always be active, so always return YES for validation.
 *
 * Here we lazily set the state of our menu items if our stateMenuItemsNeedingUpdating set indicates it is needed.
 *
 * Random note: stateMenuItemsNeedingUpdating will almost never have a count of 0 because separatorItems
 * get included but never get validated.
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ([stateMenuItemsNeedingUpdating containsObject:menuItem]) {
		BOOL			noAccountsAreOnline = ![[adium accountController] oneOrMoreConnectedAccounts];
		NSDictionary	*dict = [menuItem representedObject];
		AIAccount		*account;
		AIStatus		*menuItemStatusState;
		BOOL			shouldSelectOffline;

		/* Search for the account or global status state as appropriate for this menu item.
		 * Also, determine if we are looking to select the Offline menu item
		 */
		if ((account = [dict objectForKey:@"AIAccount"])) {
			shouldSelectOffline = ![account online];
		} else {
			shouldSelectOffline = noAccountsAreOnline;
		}
		menuItemStatusState = [dict objectForKey:@"AIStatus"];

		if (shouldSelectOffline) {
			//If we should select offline, set all menu items which don't have the AIOfflineStatusType tag to be off.
			if ([menuItem tag] == AIOfflineStatusType) {
				if ([menuItem state] != NSOnState) [menuItem setState:NSOnState];
			} else {
				if ([menuItem state] != NSOffState) [menuItem setState:NSOffState];
			}

		} else {
			if (account) {
				/* Account-specific menu items */
				AIStatus		*appropiateActiveStatusState;
				appropiateActiveStatusState = [account statusState];

				/* Our "Custom..." menu choice has a nil represented object.  If the appropriate active search state is
				 * in our array of states from which we made menu items, we'll be searching to match it.  If it isn't,
				 * we have a custom state and will be searching for the custom item of the right type, switching all other
				 * menu items to NSOffState.
				 */
				if ([[self sortedFullStateArray] containsObjectIdenticalTo:appropiateActiveStatusState]) {
					//If the search state is in the array so is a saved state, search for the match
					if (menuItemStatusState == appropiateActiveStatusState) {
						if ([menuItem state] != NSOnState) [menuItem setState:NSOnState];
					} else {
						if ([menuItem state] != NSOffState) [menuItem setState:NSOffState];
					}
				} else {
					//If there is not a status state, we are in a Custom state. Search for the correct Custom item.
					if (menuItemStatusState) {
						//If the menu item has an associated state, it's always off.
						if ([menuItem state] != NSOffState) [menuItem setState:NSOffState];
					} else {
						//If it doesn't, check the tag to see if it should be on or off.
						if ([menuItem tag] == [appropiateActiveStatusState statusType]) {
							if ([menuItem state] != NSOnState) [menuItem setState:NSOnState];
						} else {
							if ([menuItem state] != NSOffState) [menuItem setState:NSOffState];
						}
					}
				}
			} else {
				/* General menu items */
				NSSet	*allActiveStatusStates = [self allActiveStatusStates];
				int		onState = (([allActiveStatusStates count] == 1) ? NSOnState : NSMixedState);

				if (menuItemStatusState) {
					//If this menu item has a status state, set it to the right on state if that state is active
					if ([allActiveStatusStates containsObject:menuItemStatusState]) {
						if ([menuItem state] != onState) [menuItem setState:onState];
					} else {
						if ([menuItem state] != NSOffState) [menuItem setState:NSOffState];
					}
				} else {
					//If it doesn't, check the tag to see if it should be on or off by looking for a matching custom state
					NSEnumerator	*activeStatusStatesEnumerator = [allActiveStatusStates objectEnumerator];
					NSArray			*sortedFullStateArray = [self sortedFullStateArray];
					AIStatus		*statusState;
					BOOL			foundCorrectStatusState = NO;

					while (!foundCorrectStatusState && (statusState = [activeStatusStatesEnumerator nextObject])) {
						/* We found a custom match if our array of menu item states doesn't contain this state and
						 * its statusType matches the menuItem's tag.
						 */
						foundCorrectStatusState = (![sortedFullStateArray containsObjectIdenticalTo:statusState] &&
												   ([menuItem tag] == [statusState statusType]));
					}

					if (foundCorrectStatusState) {
						if ([menuItem state] != NSOnState) [menuItem setState:onState];
					} else {
						if ([menuItem state] != NSOffState) [menuItem setState:NSOffState];
					}
				}
			}
		}

		[stateMenuItemsNeedingUpdating removeObject:menuItem];
	}

	return YES;
}

/*!
 * @brief Select a state menu item
 *
 * Invoked by a state menu item, sets the state corresponding to the menu item as the active state.
 *
 * If the representedObject NSDictionary has an @"AIAccount" object, set the state just for the appropriate AIAccount.
 * Otherwise, set the state globally.
 */
- (void)selectState:(id)sender
{
	NSDictionary	*dict = [sender representedObject];
	AIStatus		*statusState = [dict objectForKey:@"AIStatus"];
	AIAccount		*account = [dict objectForKey:@"AIAccount"];

	/* Random undocumented feature of the moment... hold option and select a state to bring up the custom status window
	 * for modifying and then setting it.
	 */
	if ([NSEvent optionKey]) {
		[AIEditStateWindowController editCustomState:statusState
											 forType:[statusState statusType]
										  andAccount:account
									  withSaveOption:YES
											onWindow:nil
									 notifyingTarget:self];

	} else {
		if (account) {
			BOOL shouldRebuild;
			
			shouldRebuild = [self removeIfNecessaryTemporaryStatusState:[account statusState]];
			[account setStatusState:statusState];
			
			if (shouldRebuild) {
				//Rebuild our menus if there was a change
				[self rebuildAllStateMenus];
			}
			
		} else {
			[self setActiveStatusState:statusState];
		}
	}
}

/*!
 * @brief Select the custom state menu item
 *
 * Invoked by the custom state menu item, opens a custom state window.
 * If the representedObject NSDictionary has an @"AIAccount" object, configure just for the appropriate AIAccount.
 * Otherwise, configure globally.
 */
- (IBAction)selectCustomState:(id)sender
{
	NSDictionary	*dict = [sender representedObject];
	AIAccount		*account = [dict objectForKey:@"AIAccount"];
	AIStatusType	statusType = [sender tag];
	AIStatus		*baseStatusState;

	if (account) {
		baseStatusState = [account statusState];
	} else {
		baseStatusState = [self activeStatusState];
	}

	/* If we are going to a custom state of a different type, we don't want to prefill with baseStatusState as it stands.
	 * Instead, we load the last used status of that type.
	 */
	if (([baseStatusState statusType] != statusType)) {
		NSDictionary *lastStatusStates = [[adium preferenceController] preferenceForKey:@"LastStatusStates"
																				  group:PREF_GROUP_STATUS_PREFERENCES];

		NSData		*lastStatusStateData = [lastStatusStates objectForKey:[NSNumber numberWithInt:statusType]];
		AIStatus	*lastStatusStateOfThisType = (lastStatusStateData ?
												  [NSKeyedUnarchiver unarchiveObjectWithData:lastStatusStateData] :
												  nil);

		baseStatusState = [[lastStatusStateOfThisType retain] autorelease];
	}

	/* Don't use the current status state as a base, and when going from Away to Available, don't autofill the Available
	 * status message with the old away message.
	 */
	if ([baseStatusState statusType] != statusType) {
		baseStatusState = nil;
	}

	[AIEditStateWindowController editCustomState:baseStatusState
										 forType:statusType
									  andAccount:account
								  withSaveOption:YES
										onWindow:nil
								 notifyingTarget:self];
}

/*!
 * @brief Called when a state could potentially need to removed from the temporary (non-saved) list
 *
 * If originalState is in the temporary status array, and it is being used on one or zero accounts, it 
 * is removed from the temporary status array. This method should be used when one or more accounts have stopped
 * using a single status state to determine if that status state is both non-saved and unused.
 *
 * @result YES if the state was removed
 */
- (BOOL)removeIfNecessaryTemporaryStatusState:(AIStatus *)originalState
{
	BOOL didRemove = NO;
	
	/* If the original (old) status state is in our temporary array and is not being used in more than 1 account, 
	 * then we should remove it.
	 */
	if ([temporaryStateArray containsObject:originalState]) {
		NSEnumerator	*enumerator;
		AIAccount		*account;
		int				count = 0;
		
		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			if ([account actualStatusState] == originalState) {
				if (++count > 1) break;
			}
		}

		if (count <= 1) {
			[temporaryStateArray removeObject:originalState];
			didRemove = YES;
		}
	}
	
	return didRemove;
}
/*!
 * @brief Apply a custom state
 *
 * Invoked when the custom state window is closed by the user clicking OK.  In response this method sets the custom
 * state as the active state.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState forAccount:(AIAccount *)account
{
	BOOL shouldRebuild = NO;
	
	if (account) {
		shouldRebuild = [self removeIfNecessaryTemporaryStatusState:originalState];

		//Now set the newState for the account
		[account setStatusState:newState];
		
	} else {
		//Set the state for all accounts.  This will clear out the temporaryStatusArray as necessary.
		[self setActiveStatusState:newState];
	}

	if ([newState mutabilityType] != AITemporaryEditableStatusState) {
		[[adium statusController] addStatusState:newState];
	}

	NSMutableDictionary *lastStatusStates;

	lastStatusStates = [[[adium preferenceController] preferenceForKey:@"LastStatusStates"
																 group:PREF_GROUP_STATUS_PREFERENCES] mutableCopy];
	if (!lastStatusStates) lastStatusStates = [NSMutableDictionary dictionary];

	[lastStatusStates setObject:[NSKeyedArchiver archivedDataWithRootObject:newState]
						 forKey:[NSNumber numberWithInt:[newState statusType]]];

	[[adium preferenceController] setPreference:lastStatusStates
										 forKey:@"LastStatusStates"
										  group:PREF_GROUP_STATUS_PREFERENCES];

	//Add to our temporary status array if it's not in our state array
	if (shouldRebuild || (![[self stateArray] containsObjectIdenticalTo:newState])) {
		[temporaryStateArray addObject:newState];

		//Now rebuild our menus to include this temporary item
		[self rebuildAllStateMenus];
	}
}

/*!
 * @brief Determine a string to use as a menu title
 *
 * This method truncates a state title string for display as a menu item.
 * Wide menus aren't pretty and may cause crashing in certain versions of OS X, so all state
 * titles should be run through this method before being used as menu item titles.
 *
 * @param statusState The state for which we want a title
 *
 * @result An appropriate NSString title
 */
- (NSString *)_titleForMenuDisplayOfState:(AIStatus *)statusState
{
	NSString	*title = [statusState title];

	/* Why plus 3? Say STATE_TITLE_MENU_LENGTH was 7, and the title is @"ABCDEFGHIJ".
	 * The shortened title will be @"ABCDEFG..." which looks to be just as long - even
	 * if the ellipsis is an ellipsis character and therefore technically two characters
	 * shorter. Better to just use the full string, which appears as being the same length.
	 */
	if ([title length] > STATE_TITLE_MENU_LENGTH+3) {
		title = [title stringWithEllipsisByTruncatingToLength:STATE_TITLE_MENU_LENGTH];
	}

	return title;
}

/*!
 * @brief Create and add the built-in status types
 *
 * The built-in status types are basic, generic "Available" and "Away" states.
 */
- (void)buildBuiltInStatusTypes
{
	NSDictionary	*statusDict;

	builtInStatusTypes[AIAvailableStatusType] = [[NSMutableSet alloc] init];
	statusDict = [NSDictionary dictionaryWithObjectsAndKeys:
			STATUS_NAME_AVAILABLE, KEY_STATUS_NAME,
			STATUS_DESCRIPTION_AVAILABLE, KEY_STATUS_DESCRIPTION,
			[NSNumber numberWithInt:AIAvailableStatusType], KEY_STATUS_TYPE,
			nil];
	[builtInStatusTypes[AIAvailableStatusType] addObject:statusDict];

	builtInStatusTypes[AIAwayStatusType] = [[NSMutableSet alloc] init];
	statusDict = [NSDictionary dictionaryWithObjectsAndKeys:
		STATUS_NAME_AWAY, KEY_STATUS_NAME,
		STATUS_DESCRIPTION_AWAY, KEY_STATUS_DESCRIPTION,
		[NSNumber numberWithInt:AIAwayStatusType], KEY_STATUS_TYPE,
		nil];
	[builtInStatusTypes[AIAwayStatusType] addObject:statusDict];
}

- (NSMenu *)statusStatesMenu
{
	NSMenu			*statusStatesMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator;
	AIStatus		*statusState;
	AIStatusType	currentStatusType = AIAvailableStatusType;
	NSMenuItem		*menuItem;

	[statusStatesMenu setMenuChangedMessagesEnabled:NO];
	[statusStatesMenu setAutoenablesItems:NO];

	/* Create a menu item for each state.  States must first be sorted such that states of the same AIStatusType
	 * are grouped together.
	 */
	enumerator = [[self sortedFullStateArray] objectEnumerator];
	while ((statusState = [enumerator nextObject])) {
		AIStatusType thisStatusType = [statusState statusType];

		if (currentStatusType != thisStatusType) {
			//Add a divider between each type of status
			[statusStatesMenu addItem:[NSMenuItem separatorItem]];
			currentStatusType = thisStatusType;
		}

		menuItem = [[NSMenuItem alloc] initWithTitle:[self _titleForMenuDisplayOfState:statusState]
											  target:nil
											  action:nil
									   keyEquivalent:@""];

		[menuItem setImage:[statusState menuIcon]];
		[menuItem setTag:[statusState statusType]];
		[menuItem setRepresentedObject:[NSDictionary dictionaryWithObject:statusState
																   forKey:@"AIStatus"]];
		[statusStatesMenu addItem:menuItem];
		[menuItem release];
	}

	[statusStatesMenu setMenuChangedMessagesEnabled:YES];

	return statusStatesMenu;
}

#pragma mark Upgrade code
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

	if (savedAways) {
		NSEnumerator	*enumerator = [savedAways objectEnumerator];
		NSDictionary	*state;

		//Update all the away messages to states.
		while ((state = [enumerator nextObject])) {
			if ([[state objectForKey:@"Type"] isEqualToString:OLD_STATE_SAVED_AWAY]) {
				AIStatus	*statusState;

				//Extract the away message information from this old record
				NSData		*statusMessageData = [state objectForKey:OLD_STATE_AWAY];
				NSData		*autoReplyMessageData = [state objectForKey:OLD_STATE_AUTO_REPLY];
				NSString	*title = [state objectForKey:OLD_STATE_TITLE];

				//Create an AIStatus from this information
				statusState = [AIStatus status];

				//General category: It's an away type
				[statusState setStatusType:AIAwayStatusType];

				//Specific state: It's the generic away. Funny how that works out.
				[statusState setStatusName:STATUS_NAME_AWAY];

				//Set the status message (which is just the away message).
				[statusState setStatusMessage:[NSAttributedString stringWithData:statusMessageData]];

				//It has an auto reply.
				[statusState setHasAutoReply:YES];

				if (autoReplyMessageData) {
					//Use the custom auto reply if it was set.
					[statusState setAutoReply:[NSAttributedString stringWithData:autoReplyMessageData]];
				} else {
					//If no autoReplyMesssage, use the status message.
					[statusState setAutoReplyIsStatusMessage:YES];
				}

				if (title) [statusState setTitle:title];

				//Add the updated state to our state array.
				[stateArray addObject:statusState];
			}
		}

		//Save these changes and delete the old aways so we don't need to do this again.
		[self _saveStateArrayAndNotifyOfChanges];
		[[adium preferenceController] setPreference:nil
											 forKey:OLD_KEY_SAVED_AWAYS
											  group:OLD_GROUP_AWAY_MESSAGES];
	}
}

@end
