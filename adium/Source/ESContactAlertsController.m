//
//  ESContactAlertsController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//  $Id: ESContactAlertsController.m,v 1.21 2004/04/18 17:24:50 adamiser Exp $


#import "ESContactAlertsController.h"

@interface ESContactAlertsController (PRIVATE)
- (NSMutableDictionary *)appendEventsForObject:(AIListObject *)listObject toDictionary:(NSMutableDictionary *)events;
@end

@implementation ESContactAlertsController

//init and close
- (void)initController
{
	eventHandlers = [[NSMutableDictionary alloc] init];
	actionHandlers = [[NSMutableDictionary alloc] init];
}

- (void)closeController
{
	[eventHandlers release];
	[actionHandlers release];
}


//Events ---------------------------------------------------------------------------------------------------------------
#pragma mark Events
//Register a potential event
- (void)registerEventID:(NSString *)eventID withHandler:(id <AIEventHandler>)handler
{
	[eventHandlers setObject:handler forKey:eventID];
}

//Return all available events
- (NSDictionary *)eventHandlers
{
	return(eventHandlers);
}

//Returns a menu of all events
//- Selector called on event selection is selectEvent:
//- A menu item's represented object is the dictionary describing the event it represents
- (NSMenu *)menuOfEventsWithTarget:(id)target
{
    NSEnumerator		*enumerator;
	NSString			*eventID;

	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
    //Insert a menu item for each available event
	enumerator = [eventHandlers keyEnumerator];
	while((eventID = [enumerator nextObject])){
		id <AIEventHandler>	eventHandler = [eventHandlers objectForKey:eventID];		
		
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[eventHandler shortDescriptionForEventID:eventID]
														target:target 
														action:@selector(selectEvent:) 
												 keyEquivalent:@""] autorelease];
        [item setRepresentedObject:eventID];
        [menu addItem:item];
    }
	
	return([menu autorelease]);
}	

//Generate an event
- (void)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSDictionary	*dict = [self appendEventsForObject:listObject toDictionary:nil];
	NSArray			*alerts = [dict objectForKey:eventID];
	
	if(alerts && [alerts count]){
		NSEnumerator	*enumerator = [alerts objectEnumerator];
		NSDictionary	*alert;
		
		while(alert = [enumerator nextObject]){
			NSString				*actionID = [alert objectForKey:KEY_ACTION_ID];
			NSDictionary			*actionDetails = [alert objectForKey:KEY_ACTION_DETAILS];
			id <AIActionHandler>	actionHandler = [actionHandlers objectForKey:actionID];		

			[actionHandler performActionID:actionID forListObject:listObject withDetails:actionDetails];
		}
	}
}

//
- (NSMutableDictionary *)appendEventsForObject:(AIListObject *)listObject toDictionary:(NSMutableDictionary *)events
{
	//Get all events from the contanining object
	AIListObject	*enclosingGroup = [listObject containingGroup];
	if(enclosingGroup){
		events = [self appendEventsForObject:enclosingGroup toDictionary:events];
	}

	//Add events for this object (replacing any inherited from the containing object)
	NSDictionary	*newEvents = [listObject preferenceForKey:KEY_CONTACT_ALERTS group:PREF_GROUP_CONTACT_ALERTS];
	if(newEvents && [newEvents count]){
		if(!events) events = [NSMutableDictionary dictionary];
		[events addEntriesFromDictionary:newEvents];
	}
	
	return(events);
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


//Alerts ---------------------------------------------------------------------------------------------------------------
#pragma mark Alerts
//Returns an array of all the alerts of a given list object
- (NSArray *)alertsForListObject:(AIListObject *)listObject
{
	NSDictionary	*contactAlerts = [listObject preferenceForKey:@"Contact Alerts" group:@"Contact Alerts"];
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
	NSString			*newAlertEventID = [newAlert objectForKey:KEY_EVENT_ID];
	NSMutableDictionary	*contactAlerts;
	NSMutableArray		*eventArray;
	
	//Get the alerts for this list object
	contactAlerts = [[listObject preferenceForKey:KEY_CONTACT_ALERTS group:PREF_GROUP_CONTACT_ALERTS] mutableCopy];
	if(!contactAlerts) contactAlerts = [[NSMutableDictionary alloc] init];
	
	//Get the event array for the new alert, making a copy so we can modify it
	eventArray = [[contactAlerts objectForKey:newAlertEventID] mutableCopy];
	if(!eventArray) eventArray = [[NSMutableArray alloc] init];
	
	//Add the new alert
	[eventArray addObject:newAlert];
	
	//Put the modified event array back into the contact alert dict, and save our changes
	[contactAlerts setObject:[eventArray autorelease] forKey:newAlertEventID];
	[listObject setPreference:[contactAlerts autorelease] forKey:KEY_CONTACT_ALERTS group:PREF_GROUP_CONTACT_ALERTS];
}

//Remove the alert (passed as a dictionary, must be an exact = match) form a list object
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject
{
	NSMutableDictionary	*contactAlerts = [[listObject preferenceForKey:KEY_CONTACT_ALERTS group:PREF_GROUP_CONTACT_ALERTS] mutableCopy];
	NSString			*victimEventID = [victimAlert objectForKey:KEY_EVENT_ID];
	NSMutableArray		*eventArray;
	
	//Get the event array containing the victim alert, making a copy so we can modify it
	eventArray = [[contactAlerts objectForKey:victimEventID] mutableCopy];
	if(!eventArray) eventArray = [[NSMutableArray alloc] init];
	
	//Remove the victim
	[eventArray removeObject:victimAlert];
	
	//Put the modified event array back into the contact alert dict, and save our changes
	[contactAlerts setObject:[eventArray autorelease] forKey:victimEventID];
	[listObject setPreference:[contactAlerts autorelease] forKey:KEY_CONTACT_ALERTS group:PREF_GROUP_CONTACT_ALERTS];
}

@end
