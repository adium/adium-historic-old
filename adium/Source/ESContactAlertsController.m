//
//  ESContactAlertsController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//  $Id: ESContactAlertsController.m,v 1.17 2004/02/22 09:18:43 evands Exp $


/*
 What's going on here?
 We want to be able to have multiple instances of each contact alert - it needs to be possible to view both an individual contact alerts and all saved alerts simultaneously, without the views interfering (changing the view in one window should not affect both windows).  For this to happen, plugins must be able to supply a fresh instance of each contact alert on demand - hence ESContactAlertProvider, which provides an ESContactAlert.  Mutable owner arrays worked beautifully to streamline management of this process; an instance of ESContactAlerts, which is the data structure for the window and preference pane, requests its own array of alerts when it initializes and asks that it be destroyed when deallocing, so there is no additional overhead when just one or the other of the two possible UI forms is open.
 */


#import "ESContactAlertsController.h"

#define EVENT_ACTION_ARRAY  @"Event Action Array"
#define CURRENT_ROW         @"Current Row"
#define ACTIVE_OBJECT       @"Active Object"

@interface ESContactAlertsController (PRIVATE)
-(id <ESContactAlerts>)_ownerOfContactAlert:(ESContactAlert *)contactAlert;
- (void)processEventActionArray:(NSMutableArray *)eventActionArray forObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys;
@end

@implementation ESContactAlertsController
//init and close
- (void)initController
{
    completedActionTypes            =   [[NSMutableArray alloc] init];
    contactAlertProviderDictionary  =   [[NSMutableDictionary alloc] init];
    arrayOfStateDictionaries        =   [[AIMutableOwnerArray alloc] init];
    arrayOfAlertsArrays             =   [[AIMutableOwnerArray alloc] init];
    
    //Register as a contact observer
    [[owner contactController] registerListObjectObserver:self];
}

- (void)closeController
{
    [[owner contactController] unregisterListObjectObserver:self];
}

/***********
Plugin Contact Alert registration
************/

- (void)registerContactAlertProvider:(NSObject<ESContactAlertProvider> *)contactAlertProvider
{
 //Add to our array of contact alert providers
    [contactAlertProviderDictionary setObject:contactAlertProvider forKey:[contactAlertProvider identifier]];

    
}
- (void)unregisterContactAlertProvider:(NSObject<ESContactAlertProvider> *)contactAlertProvider
{
    //Remove from our array of contact alert providers
}


/***********
Communication between the contact alerts UI and plugins
************/

- (void)createAlertsArrayWithOwner:(NSObject<ESContactAlerts> *)inOwner;
{
    //create the alertsArray
    NSMutableArray *alertsArray = [[NSMutableArray alloc] init];
    id contactAlertProvider;
    
    NSEnumerator *providerEnumerator = [contactAlertProviderDictionary objectEnumerator];
    while (contactAlertProvider = [providerEnumerator nextObject]) {
        [alertsArray addObject:[contactAlertProvider contactAlert]];
    }

    //Sort?
    
    //store it into our mutableOwnerArray for alerts
    [arrayOfAlertsArrays setObject:alertsArray withOwner:inOwner];
    [alertsArray release];
    
    [arrayOfStateDictionaries setObject:[[[NSMutableDictionary alloc] init] autorelease] withOwner:inOwner];


}

- (void)destroyAlertsArrayWithOwner:(NSObject<ESContactAlerts> *)inOwner
{
    //Get the array with the requested owner
//    NSArray             *alertsArray = [arrayOfAlertsArrays objectWithOwner:owner];

    /*
    if (alertsArray) {
        //release all the internal objects
        [alertsArray makeObjectsPerformSelector:@selector(release)];
    }
     */
    
    //This will release the array which had the requested owner, releasing its contained objects in turn
    [arrayOfAlertsArrays setObject:nil withOwner:inOwner];
}

/******
Methods used by ESContactAlert instances
******/

//Used by a ContactAlert to tell its owner to display its details view
- (void)configureWithSubview:(NSView *)inView forContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    
    if (inOwner) {
        [(NSObject<ESContactAlerts> *)inOwner configureWithSubview:inView];   
    }
}
//The entire event action array of the active contact of contactAlert->owner
- (NSMutableArray *)eventActionArrayForContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    NSMutableDictionary *stateDictionary = [arrayOfStateDictionaries objectWithOwner:inOwner];
    return [stateDictionary objectForKey:EVENT_ACTION_ARRAY];
}
//The details dict for the selected action of contactAlert->owner
- (NSDictionary *)currentDictForContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    NSMutableDictionary *stateDictionary = [arrayOfStateDictionaries objectWithOwner:inOwner];
    NSNumber *row = [stateDictionary objectForKey:CURRENT_ROW];
    if (row)
        return ([[stateDictionary objectForKey:EVENT_ACTION_ARRAY] objectAtIndex:[row intValue]]);
    else
        return nil;
}
//The row for the selected action of contactAlert->owner - may be deprecated
- (int)rowForContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    NSMutableDictionary *stateDictionary = [arrayOfStateDictionaries objectWithOwner:inOwner];
    NSNumber *row = [stateDictionary objectForKey:CURRENT_ROW];
    if (row)
        return ([row intValue]);
    else
        return -1;
}
//The list object currently active in contactAlert->owner
- (AIListObject *)currentObjectForContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    NSMutableDictionary *stateDictionary = [arrayOfStateDictionaries objectWithOwner:inOwner];
    return [stateDictionary objectForKey:ACTIVE_OBJECT];
}
//The window in which the contactAlert is displaying
- (NSWindow *)currentWindowForContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    return [inOwner performSelector:@selector(activeWindow)];
}

//Save changes to an array of alerts
- (void)saveEventActionArrayForContactAlert:(ESContactAlert *)contactAlert
{
    id inOwner = [self _ownerOfContactAlert:contactAlert];
    [inOwner saveEventActionArray];
}
/*******
Methods used by ESContactAlerts
*******/

//menu of possible actions
- (NSMenu *)actionListMenuWithOwner:(id <ESContactAlerts>)inOwner {
    NSMenu              *actionListMenu = [[NSMenu alloc] init];
    NSArray             *alertsArray = [arrayOfAlertsArrays objectWithOwner:inOwner];
    NSEnumerator        *enumerator;
    ESContactAlert      *contactAlert;
    enumerator = [alertsArray objectEnumerator];
    
    while (contactAlert = [enumerator nextObject]) {
        [actionListMenu addItem:[contactAlert alertMenuItem]];   
    }
    return([actionListMenu autorelease]);
}

//an ESContactAlerts instance notifying the controller that its array or object changed
- (void)updateOwner:(id <ESContactAlerts>)inOwner toArray:(NSArray *)eventActionArray forObject:(AIListObject *)inObject
{
    NSMutableDictionary *stateDictionary = [arrayOfStateDictionaries objectWithOwner:inOwner];
    
    //the eventActionArray represents the actions which are set for the current contact
    [stateDictionary setObject:eventActionArray forKey:EVENT_ACTION_ARRAY];
    
    [stateDictionary setObject:inObject forKey:ACTIVE_OBJECT];
}
//an ESContactAlerts instance notifying the controller that its active row changed
- (void)updateOwner:(id <ESContactAlerts>)inOwner toRow:(int)row
{
    NSMutableDictionary *stateDictionary = [arrayOfStateDictionaries objectWithOwner:inOwner];
    
    //set the current object - the specific action being examined
    if (row != -1) {
        [stateDictionary setInt:row forKey:CURRENT_ROW];
    } else {
        [stateDictionary removeObjectForKey:CURRENT_ROW];   
    }
}

/********
Alert Execution
********/
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if (!silent) //We do things.  If silent, don't do them.
    {
        //To track actions which should only be done once, for the user if possible, then for the group is still needed
        //Such behaviors are dock bouncing and event bezel display
        [completedActionTypes removeAllObjects];
        
        NSArray         *allPrefs = [inObject allPreferencesForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS];
        NSEnumerator    *enumerator = [allPrefs objectEnumerator];
        NSMutableArray  *eventActionArray;
        
        while (eventActionArray = [enumerator nextObject]) {
            [self processEventActionArray:eventActionArray forObject:inObject keys:inModifiedKeys];
        }
    }
    return nil; //we don't change any attributes
}

- (void)processEventActionArray:(NSMutableArray *)eventActionArray forObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys
{
    NSEnumerator * actionsEnumerator;
    NSDictionary * actionDict;
    NSString * event;
    BOOL status, event_status;
    BOOL status_matches;
    
    actionsEnumerator = [eventActionArray objectEnumerator];
    while(actionDict = [actionsEnumerator nextObject])
    {
        NSString *action = [actionDict objectForKey:KEY_EVENT_ACTION];
        
        //if the action isn't in the completed action types yet
        if ([completedActionTypes indexOfObject:action] == NSNotFound) {
            event = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];
            status = [inObject integerStatusObjectForKey:event];
            event_status = [[actionDict objectForKey:KEY_EVENT_STATUS] intValue];
            status_matches = (status && event_status) || (!status && !event_status); //XOR
            
            if ( status_matches && [inModifiedKeys containsObject:event] ) {  //if an action with the appropriate triggering event and status is found
                
                //Only proceed if the action should proceed regardless of our active status -OR- we are active
                if (! [[actionDict objectForKey:KEY_EVENT_ACTIVE] intValue] || 
                    (![[owner preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] 
                     && ![[owner preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS])) {
                    
                    BOOL success = NO;
                    
                    id contactAlertProvider = [contactAlertProviderDictionary objectForKey:action];
                    if (contactAlertProvider) {
                        success = [(NSObject<ESContactAlertProvider> *)contactAlertProvider performActionWithDetails:[actionDict objectForKey:KEY_EVENT_DETAILS]
                                                                                                       andDictionary:[actionDict objectForKey:KEY_EVENT_DETAILS_DICT]
                                                                                                    triggeringObject:inObject
                                                                                                     triggeringEvent:event
                                                                                                         eventStatus:event_status
                                                                                                          actionName:[actionDict objectForKey:KEY_EVENT_DISPLAYNAME]];
                        if (success && [(NSObject<ESContactAlertProvider> *)contactAlertProvider shouldKeepProcessing]) {
                            [completedActionTypes addObject:action];
                        }
                    }
                    
                    //after all tests
                    if (success && [[actionDict objectForKey:KEY_EVENT_DELETE] intValue]) { //delete the action from the array if succesful and necessary
                        [eventActionArray removeObject:actionDict];
                        [inObject setPreference:eventActionArray forKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS];
                        
                        //Broadcast a one time event fired message
                        [[owner notificationCenter] postNotificationName:One_Time_Event_Fired
                                                                  object:inObject
                                                                userInfo:nil];
                    }
                } //close active
            } //close status_matches && containsKey
        } //close completeActionTypes
    } //close while
} //end function



/******
Internal
******/
-(id)_ownerOfContactAlert:(ESContactAlert *)contactAlert
{
	NSEnumerator	*enumerator = [arrayOfAlertsArrays objectEnumerator];
    NSArray 		*alertsArray = nil;
    
	while(alertsArray = [enumerator nextObject]){
        if([alertsArray containsObject:contactAlert]) break;
	}

    return(alertsArray);
}

@end
