//
//  ESContactAlertsController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//  $Id$


#import "ESContactAlertsController.h"

@interface ESContactAlertsController (PRIVATE)
- (NSMutableArray *)appendEventsForObject:(AIListObject *)listObject eventID:(NSString *)eventID toArray:(NSMutableArray *)events;
- (void)addMenuItemsForEventHandlers:(NSDictionary *)inEventHandlers toArray:(NSMutableArray *)menuItemArray withTarget:(id)target forGlobalMenu:(BOOL)global;
- (void)removeAllAlertsFromListObject:(AIListObject *)listObject;
@end

@implementation ESContactAlertsController

int eventMenuItemSort(id menuItemA, id menuItemB, void *context);

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
	[globalOnlyEventHandlers release]; globalOnlyEventHandlers = nil;
	[eventHandlers release]; eventHandlers = nil;
	[actionHandlers release]; actionHandlers = nil;
}


//Events ---------------------------------------------------------------------------------------------------------------
#pragma mark Events
//Register a potential event
- (void)registerEventID:(NSString *)eventID withHandler:(id <AIEventHandler>)handler
{
	[eventHandlers setObject:handler forKey:eventID];
}

- (void)registerEventID:(NSString *)eventID withHandler:(id <AIEventHandler>)handler globalOnly:(BOOL)global
{
	if (global){
		[globalOnlyEventHandlers setObject:handler forKey:eventID];
	}else{
		[self registerEventID:eventID withHandler:handler];
	}
}

//Return all available events
- (NSDictionary *)eventHandlers
{
	return(eventHandlers);
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
	menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
	//Create an array of menu items
	NSMutableArray *menuItemArray = [NSMutableArray array];
	
	[self addMenuItemsForEventHandlers:eventHandlers toArray:menuItemArray withTarget:target forGlobalMenu:global];
	if (global) [self addMenuItemsForEventHandlers:globalOnlyEventHandlers toArray:menuItemArray withTarget:target forGlobalMenu:global];
	
	//Sort the array of menuItems alphabetically by title
	[menuItemArray sortUsingFunction:eventMenuItemSort context:nil];
	
	enumerator = [menuItemArray objectEnumerator];
	while((item = [enumerator nextObject])){
		//Insert a menu item for each available event
        [menu addItem:item];
	}
	
	return([menu autorelease]);
}	

- (void)addMenuItemsForEventHandlers:(NSDictionary *)inEventHandlers toArray:(NSMutableArray *)menuItemArray withTarget:(id)target forGlobalMenu:(BOOL)global
{	
	NSEnumerator		*enumerator;
	NSString			*eventID;
	NSMenuItem			*item;
		
	enumerator = [inEventHandlers keyEnumerator];
	while((eventID = [enumerator nextObject])){
		id <AIEventHandler>	eventHandler = [inEventHandlers objectForKey:eventID];		
		
        item = [[[NSMenuItem alloc] initWithTitle:(global ? [eventHandler globalShortDescriptionForEventID:eventID] : [eventHandler shortDescriptionForEventID:eventID])
										   target:target 
										   action:@selector(selectEvent:) 
									keyEquivalent:@""] autorelease];
        [item setRepresentedObject:eventID];
		[menuItemArray addObject:item];
    }
}

//Generate an event
- (void)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject userInfo:(id)userInfo;
{
	NSArray			*alerts = [self appendEventsForObject:listObject eventID:eventID toArray:nil];
	
	if(alerts && [alerts count]){
		NSEnumerator		*enumerator;
		NSDictionary		*alert;
		NSMutableArray		*performedActionIDs = [NSMutableArray array];
		
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
	
	[[owner notificationCenter] postNotificationName:eventID
											  object:listObject 
											userInfo:userInfo];
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
	id				preferenceSource;

	//If we don't have an object, we use the preference controller to get the global alerts
	preferenceSource = listObject;
	if (!preferenceSource) preferenceSource = [owner preferenceController];

	// AILog(@"appendEventsForObject: %@ eventID: %@ toArray: %@",preferenceSource,eventID,events);

	//Add events for this object (replacing any inherited from the containing object so that this object takes precendence)
	newEvents = [[preferenceSource preferenceForKey:KEY_CONTACT_ALERTS
											  group:PREF_GROUP_CONTACT_ALERTS
							  ignoreInheritedValues:YES] objectForKey:eventID];

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
	NSString *defaultEventID = [[owner preferenceController] preferenceForKey:KEY_DEFAULT_EVENT_ID
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

	if (eventHandler){
		return [eventHandler globalShortDescriptionForEventID:eventID];
	}
	
	eventHandler = [globalOnlyEventHandlers objectForKey:eventID];
	if (eventHandler){
		return [eventHandler globalShortDescriptionForEventID:eventID];
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
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
    //Insert a menu item for each available action
	enumerator = [actionHandlers keyEnumerator];
	while((actionID = [enumerator nextObject])){
		id <AIActionHandler> actionHandler = [actionHandlers objectForKey:actionID];		
		
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[actionHandler shortDescriptionForActionID:actionID]
														target:target 
														action:@selector(selectAction:) 
												 keyEquivalent:@""] autorelease];
        [item setRepresentedObject:actionID];
        [menu addItem:item];
    }
	
	return([menu autorelease]);
}	

- (NSString *)defaultActionID
{
	NSString *defaultActionID = [[owner preferenceController] preferenceForKey:KEY_DEFAULT_ACTION_ID
																		 group:PREF_GROUP_CONTACT_ALERTS];
	if (![actionHandlers objectForKey:defaultActionID]){
		defaultActionID = [[actionHandlers allKeys] objectAtIndex:0];
	}
	
	return defaultActionID;
}

//Alerts ---------------------------------------------------------------------------------------------------------------
#pragma mark Alerts
//Returns an array of all the alerts of a given list object
- (NSArray *)alertsForListObject:(AIListObject *)listObject
{
	id  preferenceSource = listObject;
	if (!preferenceSource) preferenceSource = [owner preferenceController];
	
	NSDictionary	*contactAlerts = [preferenceSource preferenceForKey:KEY_CONTACT_ALERTS
																  group:PREF_GROUP_CONTACT_ALERTS
												  ignoreInheritedValues:YES];
	NSMutableArray	*alertArray = [NSMutableArray array];
	NSEnumerator	*groupEnumerator;
	NSString		*alertID;
	
	//Flatten the alert dict into an array
	groupEnumerator = [contactAlerts keyEnumerator];
	while(alertID = [groupEnumerator nextObject]){
		NSEnumerator	*alertEnumerator;
		NSDictionary	*alert;
		
		alertEnumerator = [[contactAlerts objectForKey:alertID] objectEnumerator];
		while(alert = [alertEnumerator nextObject]){
			[alertArray addObject:alert];
		}
	}	
	
	return(alertArray);
}

//Add an alert (passed as a dictionary) to a list object
- (void)addAlert:(NSDictionary *)newAlert toListObject:(AIListObject *)listObject
{
	NSString			*newAlertEventID = [newAlert objectForKey:KeyEventID];
	NSMutableDictionary	*contactAlerts;
	NSMutableArray		*eventArray;
	
	id  preferenceSource = listObject;
	if (!preferenceSource) preferenceSource = [owner preferenceController];
	
	[[owner preferenceController] delayPreferenceChangedNotifications:YES];
	
	//Get the alerts for this list object
	contactAlerts = [[preferenceSource preferenceForKey:KEY_CONTACT_ALERTS
												  group:PREF_GROUP_CONTACT_ALERTS
								  ignoreInheritedValues:YES] mutableCopy];
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
		[preferenceSource setPreference:contactAlerts
								 forKey:KEY_CONTACT_ALERTS 
								  group:PREF_GROUP_CONTACT_ALERTS];
	}
	[contactAlerts release];
	
	//Update the default events if we were setting a listObject-specific contact alert
	if (listObject){
		[[owner preferenceController] setPreference:newAlertEventID
											 forKey:KEY_DEFAULT_EVENT_ID
											  group:PREF_GROUP_CONTACT_ALERTS];
		[[owner preferenceController] setPreference:[newAlert objectForKey:KeyActionID]
											 forKey:KEY_DEFAULT_ACTION_ID
											  group:PREF_GROUP_CONTACT_ALERTS];	
	}
	
	[[owner preferenceController] delayPreferenceChangedNotifications:NO];
}

- (void)addGlobalAlert:(NSDictionary *)newAlert
{
	[self addAlert:newAlert toListObject:nil];
}

//Remove the alert (passed as a dictionary, must be an exact = match) form a list object
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject
{
	id  preferenceSource = listObject;
	if (!preferenceSource) preferenceSource = [owner preferenceController];
	
	NSMutableDictionary	*contactAlerts = [[preferenceSource preferenceForKey:KEY_CONTACT_ALERTS 
																	   group:PREF_GROUP_CONTACT_ALERTS
													   ignoreInheritedValues:YES] mutableCopy];
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
	
	[preferenceSource setPreference:contactAlerts
							 forKey:KEY_CONTACT_ALERTS
							  group:PREF_GROUP_CONTACT_ALERTS];
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
	NSDictionary		*contactAlerts = [[owner preferenceController] preferenceForKey:KEY_CONTACT_ALERTS 
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
	
	[[owner preferenceController] setPreference:newContactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS];
	[newContactAlerts release];
}

- (void)mergeAndMoveContactAlertsFromListObject:(AIListObject *)oldObject intoListObject:(AIListObject *)newObject
{
	NSArray				*oldAlerts = [self alertsForListObject:oldObject];
	NSEnumerator		*enumerator = [oldAlerts objectEnumerator];
	NSDictionary		*alertDict;
	
	[[owner preferenceController] delayPreferenceChangedNotifications:YES];
	
	//Add each alert to the target (addAlert:toListObject: will ensure identical alerts aren't added more than once)
	while (alertDict  = [enumerator nextObject]){
		[self addAlert:alertDict toListObject:newObject];
	}
	
	//Remove the alerts from the originating list object
	[self removeAllAlertsFromListObject:oldObject];
	
	[[owner preferenceController] delayPreferenceChangedNotifications:NO];
}

@end
