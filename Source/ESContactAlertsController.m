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

#import "AIPreferenceController.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIListObject.h>

@interface ESContactAlertsController (PRIVATE)
- (NSMutableArray *)appendEventsForObject:(AIListObject *)listObject eventID:(NSString *)eventID toArray:(NSMutableArray *)events;
- (void)addMenuItemsForEventHandlers:(NSDictionary *)inEventHandlers toArray:(NSMutableArray *)menuItemArray withTarget:(id)target forGlobalMenu:(BOOL)global;
- (void)removeAllAlertsFromListObject:(AIListObject *)listObject;
@end

@implementation ESContactAlertsController

int eventMenuItemSort(id menuItemA, id menuItemB, void *context);
int actionMenuItemSort(id menuItemA, id menuItemB, void *context);

DeclareString(KeyActionID);
DeclareString(KeyEventID);
DeclareString(KeyActionDetails);
DeclareString(KeyOneTimeAlert);


//init and close
- (void)initController
{
	InitString(KeyActionID,KEY_ACTION_ID);
	InitString(KeyEventID,KEY_EVENT_ID);
	InitString(KeyActionDetails,KEY_ACTION_DETAILS);
	InitString(KeyOneTimeAlert,KEY_ONE_TIME_ALERT);

	globalOnlyEventHandlers = [[NSMutableDictionary alloc] init];
	eventHandlers = [[NSMutableDictionary alloc] init];
	actionHandlers = [[NSMutableDictionary alloc] init];
}

- (void)closeController
{
	
}

- (void)dealloc
{
	[globalOnlyEventHandlers release]; globalOnlyEventHandlers = nil;
	[eventHandlers release]; eventHandlers = nil;
	[actionHandlers release]; actionHandlers = nil;
	
	[super dealloc];
}


//Events ---------------------------------------------------------------------------------------------------------------
#pragma mark Events
//Register a potential event
- (void)registerEventID:(NSString *)eventID
			withHandler:(id <AIEventHandler>)handler
				inGroup:(AIEventHandlerGroupType)inGroup
			 globalOnly:(BOOL)global
{
	if (global){
		[globalOnlyEventHandlers setObject:handler forKey:eventID];
		
		if(!globalOnlyEventHandlersByGroup[inGroup]) globalOnlyEventHandlersByGroup[inGroup] = [[NSMutableDictionary alloc] init];
		[globalOnlyEventHandlersByGroup[inGroup] setObject:handler forKey:eventID];
		
	}else{
		[eventHandlers setObject:handler forKey:eventID];
		
		if(!eventHandlersByGroup[inGroup]) eventHandlersByGroup[inGroup] = [[NSMutableDictionary alloc] init];
		[eventHandlersByGroup[inGroup] setObject:handler forKey:eventID];
	}
}

//Return all event IDs for groups/contacts
- (NSArray *)allEventIDs
{
	return([[eventHandlers allKeys] arrayByAddingObjectsFromArray:[globalOnlyEventHandlers allKeys]]);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	id <AIEventHandler> handler;
	
	handler = [eventHandlers objectForKey:eventID];
	if(!handler) handler = [globalOnlyEventHandlers objectForKey:eventID];
	
	return([handler longDescriptionForEventID:eventID forListObject:listObject]);
}

//Returns a menu of all events
//- Selector called on event selection is selectEvent:
//- A menu item's represented object is the dictionary describing the event it represents
- (NSMenu *)menuOfEventsWithTarget:(id)target forGlobalMenu:(BOOL)global
{
	NSEnumerator		*enumerator;
	NSMenuItem			*item;
	NSMenu				*menu;

	//Prepare our menu
	menu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	[menu setAutoenablesItems:NO];
	
	enumerator = [[self arrayOfMenuItemsForEventsWithTarget:target forGlobalMenu:global] objectEnumerator];
	while(item = [enumerator nextObject]){
		[menu addItem:item];
	}
	
	return [menu autorelease];
}

- (NSArray *)arrayOfMenuItemsForEventsWithTarget:(id)target forGlobalMenu:(BOOL)global
{
	NSMutableArray		*menuItemArray = [NSMutableArray array];
	BOOL				addedItems = NO;
	int					i;
	
	for(i = 0; i < EVENT_HANDLER_GROUP_COUNT; i++){
		NSMutableArray		*groupMenuItemArray;

		//Create an array of menu items for this group
		groupMenuItemArray = [NSMutableArray array];
		
		[self addMenuItemsForEventHandlers:eventHandlersByGroup[i]
								   toArray:groupMenuItemArray
								withTarget:target
							 forGlobalMenu:global];
		if (global){
			[self addMenuItemsForEventHandlers:globalOnlyEventHandlersByGroup[i]
									   toArray:groupMenuItemArray
									withTarget:target
								 forGlobalMenu:global];
		}
		
		if([groupMenuItemArray count]){
			//Add a separator if we are adding a group and we have added before
			if(addedItems){
				[menuItemArray addObject:[NSMenuItem separatorItem]];
			}else{
				addedItems = YES;
			}
			
			//Sort the array of menuItems alphabetically by title within this group
			[groupMenuItemArray sortUsingFunction:eventMenuItemSort context:nil];
			
			[menuItemArray addObjectsFromArray:groupMenuItemArray];
		}
	}
	
	return(menuItemArray);
}	

- (void)addMenuItemsForEventHandlers:(NSDictionary *)inEventHandlers toArray:(NSMutableArray *)menuItemArray withTarget:(id)target forGlobalMenu:(BOOL)global
{	
	NSEnumerator		*enumerator;
	NSString			*eventID;
	NSMenuItem			*item;
	
	enumerator = [inEventHandlers keyEnumerator];
	while((eventID = [enumerator nextObject])){
		id <AIEventHandler>	eventHandler = [inEventHandlers objectForKey:eventID];		
		
        item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(global ? [eventHandler globalShortDescriptionForEventID:eventID] : [eventHandler shortDescriptionForEventID:eventID])
																	 target:target 
																	 action:@selector(selectEvent:) 
															  keyEquivalent:@""] autorelease];
        [item setRepresentedObject:eventID];
		[menuItemArray addObject:item];
    }
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	id <AIEventHandler>	eventHandler;
	
	eventHandler = [eventHandlers objectForKey:eventID];		
	if(!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];

	return([eventHandler imageForEventID:eventID]);
}

/*
 Generate an event, returning a set of the actionIDs which were performed.
 If perviouslyPerformedActionIDs is non-nil, it indicates a set of actionIDs which should be treated as if
	they had already been performed in this invocation.
*/
- (NSSet *)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject userInfo:(id)userInfo previouslyPerformedActionIDs:(NSSet *)previouslyPerformedActionIDs
{
	NSArray			*alerts = [self appendEventsForObject:listObject eventID:eventID toArray:nil];
	NSMutableSet	*performedActionIDs = nil;
	
	if(alerts && [alerts count]){
		NSEnumerator		*enumerator;
		NSDictionary		*alert;

		performedActionIDs = (previouslyPerformedActionIDs ?
							  [previouslyPerformedActionIDs mutableCopy] :
							  [NSMutableSet set]);
		
		//We go from contact->group->root; a given action will only fire once for this event
		enumerator = [alerts objectEnumerator];

		//Process each alert (There may be more than one for an event)
		while(alert = [enumerator nextObject]){
			NSString	*actionID;
			id <AIActionHandler>	actionHandler;			
			
			actionID = [alert objectForKey:KeyActionID];
			actionHandler = [actionHandlers objectForKey:actionID];		
			
			if((![performedActionIDs containsObject:actionID]) || ([actionHandler allowMultipleActionsWithID:actionID])){
				[actionHandler performActionID:actionID
								 forListObject:listObject
								   withDetails:[alert objectForKey:KeyActionDetails] 
							 triggeringEventID:eventID
									  userInfo:userInfo];
				
				//If this alert was a single-fire alert, we can delete it now
				if([[alert objectForKey:KeyOneTimeAlert] intValue]){
					[self removeAlert:alert fromListObject:listObject];
				}
				
				//We don't want to perform this action again for this event
				[performedActionIDs addObject:actionID];
			}
		}
	}
	
	[[adium notificationCenter] postNotificationName:eventID
											  object:listObject 
											userInfo:userInfo];
	
	return(performedActionIDs);
}

/*
 Append events for the passed object to the specified array.
	Create the array if passed nil.
	Return an array which contains the object's own events followed by its containingObject's events.
	If the object is nil, we retrieve the global preferences.
 
 This method is intended to be called recursively; it should generate an array which has alerts from:
	contact->metaContact->group->global preferences (skipping any which don't exist).
 */
- (NSMutableArray *)appendEventsForObject:(AIListObject *)listObject eventID:(NSString *)eventID toArray:(NSMutableArray *)events
{
	NSArray			*newEvents;

	// AILog(@"appendEventsForObject: %@ eventID: %@ toArray: %@",preferenceSource,eventID,events);

	//Add events for this object (replacing any inherited from the containing object so that this object takes precendence)
	newEvents = [[[adium preferenceController] preferenceForKey:KEY_CONTACT_ALERTS
														  group:PREF_GROUP_CONTACT_ALERTS
									  objectIgnoringInheritance:listObject] objectForKey:eventID];
	
	if(newEvents && [newEvents count]){
		if(!events) events = [NSMutableArray array];
		[events addObjectsFromArray:newEvents];
	}

	//Get all events from the contanining object if we have an object
	if(listObject){
		//If listObject doesn't have a containingObject, this will pass nil
		events = [self appendEventsForObject:[listObject containingObject]
									 eventID:eventID
									 toArray:events];
	}

	return(events);
}

- (NSString *)defaultEventID
{
	NSString *defaultEventID = [[adium preferenceController] preferenceForKey:KEY_DEFAULT_EVENT_ID
																		group:PREF_GROUP_CONTACT_ALERTS];
	if (![eventHandlers objectForKey:defaultEventID]){
		defaultEventID = [[eventHandlers allKeys] objectAtIndex:0];
	}
	
	return defaultEventID;
}

- (NSString *)eventIDForEnglishDisplayName:(NSString *)displayName
{
	NSEnumerator		*enumerator;
	NSString			*eventID;
	
	enumerator = [eventHandlers keyEnumerator];
	while((eventID = [enumerator nextObject])){
		id <AIEventHandler>	eventHandler = [eventHandlers objectForKey:eventID];		
		if ([[eventHandler englishGlobalShortDescriptionForEventID:eventID] isEqualToString:displayName]){
			return eventID;
		}
	}

	enumerator = [globalOnlyEventHandlers keyEnumerator];
	while((eventID = [enumerator nextObject])){
		id <AIEventHandler>	eventHandler = [globalOnlyEventHandlers objectForKey:eventID];		
		if ([[eventHandler englishGlobalShortDescriptionForEventID:eventID] isEqualToString:displayName]){
			return eventID;
		}
	}
	
	return nil;
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	id <AIEventHandler>	eventHandler;
	
	eventHandler = [eventHandlers objectForKey:eventID];
	if(!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];
	
	if (eventHandler){
		return [eventHandler globalShortDescriptionForEventID:eventID];
	}
	
	return @"";
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	id <AIEventHandler>	eventHandler;

	eventHandler = [eventHandlers objectForKey:eventID];
	if(!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];

	if(eventHandler){
		return([eventHandler naturalLanguageDescriptionForEventID:eventID
													   listObject:listObject
														 userInfo:userInfo
												   includeSubject:includeSubject]);
	}

	return @"";
}

int eventMenuItemSort(id menuItemA, id menuItemB, void *context){
	return ([[menuItemA title] caseInsensitiveCompare:[menuItemB title]]);
}


//Actions --------------------------------------------------------------------------------------------------------------
#pragma mark Actions
- (void)registerActionID:(NSString *)actionID withHandler:(id <AIActionHandler>)handler
{
	[actionHandlers setObject:handler forKey:actionID];
}

//Return all available actions
- (NSDictionary *)actionHandlers
{
	return(actionHandlers);
}

//Returns a menu of all actions
//- Selector called on action selection is selectAction:
//- A menu item's represented object is the dictionary describing the action it represents
- (NSMenu *)menuOfActionsWithTarget:(id)target
{
    NSEnumerator	*enumerator;
    NSString		*actionID;
	NSMenuItem		*item;
	NSMenu			*menu;
	NSMutableArray	*menuItemArray;
	
	//Prepare our menu
	menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
	menuItemArray = [NSMutableArray array];
	
    //Insert a menu item for each available action
	enumerator = [actionHandlers keyEnumerator];
	while((actionID = [enumerator nextObject])){
		id <AIActionHandler> actionHandler = [actionHandlers objectForKey:actionID];		
		
        item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[actionHandler shortDescriptionForActionID:actionID]
																	 target:target 
																	 action:@selector(selectAction:) 
															  keyEquivalent:@""] autorelease];
        [item setRepresentedObject:actionID];
		[item setImage:[[actionHandler imageForActionID:actionID] imageByScalingToSize:NSMakeSize(16,16)]];

        [menuItemArray addObject:item];
    }

	//Sort the array of menuItems alphabetically by title
	[menuItemArray sortUsingFunction:actionMenuItemSort context:nil];
	
	enumerator = [menuItemArray objectEnumerator];
	while(item = [enumerator nextObject]){
		[menu addItem:item];
	}
	
	return([menu autorelease]);
}	

- (NSString *)defaultActionID
{
	NSString *defaultActionID = [[adium preferenceController] preferenceForKey:KEY_DEFAULT_ACTION_ID
																		 group:PREF_GROUP_CONTACT_ALERTS];
	if (![actionHandlers objectForKey:defaultActionID]){
		defaultActionID = [[actionHandlers allKeys] objectAtIndex:0];
	}
	
	return defaultActionID;
}

int actionMenuItemSort(id menuItemA, id menuItemB, void *context){
	return ([[menuItemA title] caseInsensitiveCompare:[menuItemB title]]);
}

//Alerts ---------------------------------------------------------------------------------------------------------------
#pragma mark Alerts
//Returns an array of all the alerts of a given list object
- (NSArray *)alertsForListObject:(AIListObject *)listObject
{
	return([self alertsForListObject:listObject withEventID:nil actionID:nil]);
}

- (NSArray *)alertsForListObject:(AIListObject *)listObject withEventID:(NSString *)eventID actionID:(NSString *)actionID
{
	NSDictionary	*contactAlerts = [[adium preferenceController] preferenceForKey:KEY_CONTACT_ALERTS
																			  group:PREF_GROUP_CONTACT_ALERTS
														  objectIgnoringInheritance:listObject];
	NSMutableArray	*alertArray = [NSMutableArray array];

	if(eventID){
		/* If we have an eventID, just look at the alerts for this eventID */
		NSEnumerator	*alertEnumerator;
		NSDictionary	*alert;
		
		alertEnumerator = [[contactAlerts objectForKey:eventID] objectEnumerator];
		
		while(alert = [alertEnumerator nextObject]){
			//If we don't have a specific actionID, or this one is right, add it
			if(!actionID || [actionID isEqualToString:[alert objectForKey:KeyActionID]]){
				[alertArray addObject:alert];
			}
		}
		
	}else{
		/* If we don't have an eventID, look at all alerts */
		NSEnumerator	*groupEnumerator;
		NSString		*anEventID;
		
		//Flatten the alert dict into an array
		groupEnumerator = [contactAlerts keyEnumerator];
		while(anEventID = [groupEnumerator nextObject]){
			NSEnumerator	*alertEnumerator;
			NSDictionary	*alert;
			
			alertEnumerator = [[contactAlerts objectForKey:anEventID] objectEnumerator];
			while(alert = [alertEnumerator nextObject]){
				//If we don't have a specific actionID, or this one is right, add it
				if(!actionID || [actionID isEqualToString:[alert objectForKey:KeyActionID]]){
					[alertArray addObject:alert];
				}
			}
		}	
	}
	
	return(alertArray);	
}

//Add an alert (passed as a dictionary) to a list object
- (void)addAlert:(NSDictionary *)newAlert toListObject:(AIListObject *)listObject setAsNewDefaults:(BOOL)setAsNewDefaults
{
	NSString			*newAlertEventID = [newAlert objectForKey:KeyEventID];
	NSMutableDictionary	*contactAlerts;
	NSMutableArray		*eventArray;
	
	[[adium preferenceController] delayPreferenceChangedNotifications:YES];
	
	//Get the alerts for this list object
	contactAlerts = [[[adium preferenceController] preferenceForKey:KEY_CONTACT_ALERTS
															  group:PREF_GROUP_CONTACT_ALERTS
										  objectIgnoringInheritance:listObject] mutableCopy];
	if(!contactAlerts) contactAlerts = [[NSMutableDictionary alloc] init];
	
	//Get the event array for the new alert, making a copy so we can modify it
	eventArray = [[contactAlerts objectForKey:newAlertEventID] mutableCopy];
	if(!eventArray) eventArray = [[NSMutableArray alloc] init];
	
	//Avoid putting the exact same alert into the array twice
	if ([eventArray indexOfObject:newAlert] == NSNotFound){
		//Add the new alert
		[eventArray addObject:newAlert];
		
		//Put the modified event array back into the contact alert dict, and save our changes
		[contactAlerts setObject:[eventArray autorelease] forKey:newAlertEventID];
		[[adium preferenceController] setPreference:contactAlerts
											 forKey:KEY_CONTACT_ALERTS
											  group:PREF_GROUP_CONTACT_ALERTS
											 object:listObject];	
	}
	[contactAlerts release];
	
	//Update the default events if requested
	if(setAsNewDefaults){
		[[adium preferenceController] setPreference:newAlertEventID
											 forKey:KEY_DEFAULT_EVENT_ID
											  group:PREF_GROUP_CONTACT_ALERTS];
		[[adium preferenceController] setPreference:[newAlert objectForKey:KeyActionID]
											 forKey:KEY_DEFAULT_ACTION_ID
											  group:PREF_GROUP_CONTACT_ALERTS];	
	}
	
	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

- (void)addGlobalAlert:(NSDictionary *)newAlert
{
	[self addAlert:newAlert toListObject:nil setAsNewDefaults:NO];
}

//Remove the alert (passed as a dictionary, must be an exact = match) form a list object
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject
{
	NSMutableDictionary	*contactAlerts = [[[adium preferenceController] preferenceForKey:KEY_CONTACT_ALERTS
																				   group:PREF_GROUP_CONTACT_ALERTS
															   objectIgnoringInheritance:listObject] mutableCopy];
	NSString			*victimEventID = [victimAlert objectForKey:KeyEventID];
	NSMutableArray		*eventArray;
	
	//Get the event array containing the victim alert, making a copy so we can modify it
	eventArray = [[contactAlerts objectForKey:victimEventID] mutableCopy];
	
	//Remove the victim
	[eventArray removeObject:victimAlert];
	
	//Put the modified event array back into the contact alert dict, and save our changes
	if ([eventArray count]){
		[contactAlerts setObject:eventArray forKey:victimEventID];
	}else{
		[contactAlerts removeObjectForKey:victimEventID];	
	}
	
	[[adium preferenceController] setPreference:contactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS
										 object:listObject];
	[eventArray release];
	[contactAlerts release];
}

- (void)removeAllAlertsFromListObject:(AIListObject *)listObject
{
	[listObject setPreference:nil
					   forKey:KEY_CONTACT_ALERTS
						group:PREF_GROUP_CONTACT_ALERTS];
}

- (void)removeAllGlobalAlertsWithActionID:(NSString *)actionID
{
	NSDictionary		*contactAlerts = [[adium preferenceController] preferenceForKey:KEY_CONTACT_ALERTS 
																				  group:PREF_GROUP_CONTACT_ALERTS];
	NSMutableDictionary *newContactAlerts = [contactAlerts mutableCopy];
	NSEnumerator		*enumerator = [contactAlerts keyEnumerator];
	NSString			*victimEventID;
	NSEnumerator		*alertArrayEnumerator;
	NSArray				*eventArray;
	NSDictionary		*alertDict;
	
	//The contact alerts preference is a dictionary keyed by event.  Each event key yields an array of dictionaries;
	//each of these dictionaries represents an alert.  We want to remove all dictionaries which represent alerts with
	//the passed actionID
	while (victimEventID = [enumerator nextObject]){
		NSMutableArray  *newEventArray = nil;
	
		eventArray = [contactAlerts objectForKey:victimEventID];

		//Enumerate each alert for this event
		alertArrayEnumerator = [eventArray objectEnumerator];
		while (alertDict = [alertArrayEnumerator nextObject]){
			
			//We found an alertDict which needs to be removed
			if ([[alertDict objectForKey:KeyActionID] isEqualToString:actionID]){
				//If this is the first modification to the current eventArray, make a mutableCopy with which to work
				if (!newEventArray) newEventArray = [[eventArray mutableCopy] autorelease];
				[newEventArray removeObject:alertDict];
			}
		}
		
		//newEventArray will only be non-nil if we made changes; now that we have enumerated this eventArray, save them
		if (newEventArray){
			if ([newEventArray count]){
				[newContactAlerts setObject:newEventArray forKey:victimEventID];
			}else{
				[newContactAlerts removeObjectForKey:victimEventID];	
			}
		}
	}
	
	[[adium preferenceController] setPreference:newContactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS];
	[newContactAlerts release];
}

/*
 * @brief Remove all current global alerts and replace them with the alerts in allGlobalAlerts
 *
 * Used for setting a preset of events
 */
- (void)setAllGlobalAlerts:(NSArray *)allGlobalAlerts
{
	NSMutableDictionary	*contactAlerts = [[NSMutableDictionary alloc] init];;
	NSDictionary		*eventDict;
	NSEnumerator		*enumerator;
	
	[[adium preferenceController] delayPreferenceChangedNotifications:YES];
	
	enumerator = [allGlobalAlerts objectEnumerator];
	while(eventDict = [enumerator nextObject]){
		NSMutableArray		*eventArray;
		NSString			*eventID = [eventDict objectForKey:KeyEventID];

		/* Get the event array for this alert. Since we are creating the entire dictionary, we can be sure we are working
		 * with an NSMutableArray.
		 */
		eventArray = [contactAlerts objectForKey:eventID];
		if(!eventArray) eventArray = [[[NSMutableArray alloc] init] autorelease];		
		
		//Add the new alert
		[eventArray addObject:eventDict];
		
		//Put the modified event array back into the contact alert dict
		[contactAlerts setObject:eventArray forKey:eventID];		
	}
	
	[[adium preferenceController] setPreference:contactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS
										 object:nil];
	[contactAlerts release];

	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
	
}

- (void)mergeAndMoveContactAlertsFromListObject:(AIListObject *)oldObject intoListObject:(AIListObject *)newObject
{
	NSArray				*oldAlerts = [self alertsForListObject:oldObject];
	NSEnumerator		*enumerator = [oldAlerts objectEnumerator];
	NSDictionary		*alertDict;
	
	[[adium preferenceController] delayPreferenceChangedNotifications:YES];
	
	//Add each alert to the target (addAlert:toListObject:setAsNewDefaults: will ensure identical alerts aren't added more than once)
	while (alertDict  = [enumerator nextObject]){
		[self addAlert:alertDict toListObject:newObject setAsNewDefaults:NO];
	}
	
	//Remove the alerts from the originating list object
	[self removeAllAlertsFromListObject:oldObject];
	
	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

#pragma mark -
- (BOOL)isMessageEvent:(NSString *)eventID
{
	return(([eventHandlersByGroup[AIMessageEventHandlerGroup] objectForKey:eventID] != nil) ||
		   ([globalOnlyEventHandlersByGroup[AIMessageEventHandlerGroup] objectForKey:eventID] != nil));
}

@end
