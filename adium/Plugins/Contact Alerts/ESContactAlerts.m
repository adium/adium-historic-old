//
//  ESContactAlerts.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
// notes: saveEventActionArray is probably being called too often

#import "ESContactAlerts.h"
#import "ESContactAlertsPlugin.h"

#define CONTACT_ALERT_ACTIONS_NIB 	@"ContactAlertsActions"

#define EVENT_SOUND_PREF_TITLE		@"Sounds"
#define SOUND_MENU_ICON_SIZE		16

@interface ESContactAlerts (PRIVATE)
- (void)configureForTextDetails:(NSString *)instructions;
- (void)configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu;
- (void)configureWithSubview:(NSView *)view_inView;
- (void)saveEventActionArray;
- (void)testSelectedEvent;

- (NSMenu *)accountMenu;
- (NSMenu *)accountForOpenMessageMenu;
- (NSMenu *)behaviorListMenu;
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name;
- (NSMenuItem *)eventMenuItem:(NSString *)event withDisplay:(NSString *)displayName;
- (NSMenu *)sendToContactMenu;
- (NSMenu *)soundListMenu;
- (void)autosizeAndCenterPopUpButton:(NSPopUpButton *)button;
@end


int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context);

@implementation ESContactAlerts

- (id)initWithDetailsView:(NSView *)inView withTable:(AIAlternatingRowTableView*)inTable withPrefView:(NSView *)inPrefView owner:(id)inOwner
{
    actionListMenu_cached = nil;
    cachedAlertsDict = [[NSMutableDictionary alloc] init];
    
    owner = inOwner;
    [owner retain];
    
    tableView_actions = inTable;
    [tableView_actions retain];
    //    [tableView_actions setDoubleAction:@selector(testSelectedEvent)];
    
    view_main = inView;
    [view_main retain];
    
    view_pref = inPrefView;
    [view_pref retain];
    
    view_blank = [[NSView alloc] init];
    
    if ( view_main && [[view_main subviews] count] == 0 ) //there are no subviews yet
        [view_main addSubview:view_blank];
    
    //nothing's selected, obviously, so row = -1
    row = -1;
    
    //let the controller know that we exist
    [[owner contactAlertsController] createAlertsArrayWithOwner:self];
    
    [super init];
    return self;
}

- (void)dealloc
{
    //let the controller know that we are done
    [[owner contactAlertsController] destroyAlertsArrayWithOwner:self];
    
    [owner release]; owner = nil;
    [activeContactObject release]; activeContactObject = nil;
    [eventActionArray release]; eventActionArray = nil;
    
    //views
    [view_main release]; view_main = nil;
    [view_pref release]; view_pref = nil;
    [view_blank release]; view_blank = nil;
    
    //caches
    [cachedAlertsDict release]; cachedAlertsDict = nil;
    [actionListMenu_cached release]; actionListMenu_cached = nil;
    [eventMenu_cached release]; eventMenu_cached = nil;
    [soundMenu_cached release]; soundMenu_cached = nil;
}

// Functions for the window and preference pane to learn about our contact's alerts ---------------------------------------

//--Configuration and modification--
- (void)configForObject:(AIListObject *)inObject
{
    [activeContactObject release];
    activeContactObject = inObject;
    [activeContactObject retain];
    
    [self reload:activeContactObject usingCache:YES];
}
- (void)currentRowIs:(int)currentRow
{
    row = currentRow;
    if (row != -1) selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    
    //inform the controller
    [[owner contactAlertsController] updateOwner:self toRow:row];
}
- (void)replaceDictAtIndex:(int)inRow withDict:(NSDictionary *)newDict
{
    [eventActionArray replaceObjectAtIndex:inRow withObject:newDict];
    [self saveEventActionArray];
}
//Refresh the event action array we have for an object
- (void)reload:(AIListObject *)object usingCache:(BOOL)useCache
{
    if (object) //nil objects can't be loaded, clearly
    {
        NSMutableArray  *newActionArray =  nil;
        NSString        *UID = [object UID];
        
        //Load our cached array if available
        if(useCache){
            newActionArray = [cachedAlertsDict objectForKey:UID];
        }
        
        //If no cache is available (or we're not using the cache), load the array
        if(!newActionArray){
            newActionArray = [[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:object]; //load from prefs
            
            //Update the cache
            if(newActionArray){
                [cachedAlertsDict setObject:newActionArray forKey:UID]; //cache it
            }else{
                [cachedAlertsDict removeObjectForKey:UID]; //pref is now clear - remove from our cache
                newActionArray = [NSMutableArray array]; //Create a new, empty action array
            }
        }
        
        //If this is our currently active contact
        if([[object UID] compare:[activeContactObject UID]] == 0) {
            [eventActionArray release]; eventActionArray = [newActionArray retain];
            
            //inform the controller
            [[owner contactAlertsController] updateOwner:self toArray:eventActionArray forObject:object];
        }
    }
}

//--Accessing information--
- (int)currentRow
{   return row;                                         }
- (NSMutableArray *)eventActionArray
{   return eventActionArray;                            }
- (NSMutableDictionary *)dictAtIndex:(int)inRow
{   return ([eventActionArray objectAtIndex:inRow]);    }
-(BOOL)hasAlerts
{   return ([eventActionArray count] > 0);              }
-(int)count
{   return ([eventActionArray count]);                  }
- (AIListObject *)activeObject
{   return activeContactObject;                         }

    // Actions! ---------------------------------------------------------------------------------------------------------------------
- (NSMenu *)actionListMenu //menu of possible actions
{
    if (!actionListMenu_cached) {
        actionListMenu_cached = [[[owner contactAlertsController] actionListMenuWithOwner:self] retain];
    }
    return actionListMenu_cached;
}

// Saving --------------------------------------------------------------------------------------------------------------------------------
//Save the event actions (contact context sensitive)
- (void)saveEventActionArray
{
    [[owner preferenceController] setPreference:eventActionArray forKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:activeContactObject];
}

//--Events--
//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    if (!eventMenu_cached)
    {
        NSMenu		*eventMenu = [[NSMenu alloc] init];
        
        //Add the static/display menu item
        [eventMenu addItemWithTitle:@"Add Event�" target:nil action:nil keyEquivalent:@""];
        
        //Add a menu item for each event
        [eventMenu addItem:[self eventMenuItem:@"Signed On" withDisplay:@"Signed On"]];
        [eventMenu addItem:[self eventMenuItem:@"Signed Off" withDisplay:@"Signed Off"]];
        [eventMenu addItem:[self eventMenuItem:@"Away" withDisplay:@"Went Away"]];
        [eventMenu addItem:[self eventMenuItem:@"!Away" withDisplay:@"Came Back From Away"]];
        [eventMenu addItem:[self eventMenuItem:@"Idle" withDisplay:@"Became Idle"]];
        [eventMenu addItem:[self eventMenuItem:@"!Idle" withDisplay:@"Became Unidle"]];
        [eventMenu addItem:[self eventMenuItem:@"Typing" withDisplay:@"Is Typing"]];
        [eventMenu addItem:[self eventMenuItem:@"UnviewedContent" withDisplay:@"Has Unviewed Content"]];
        [eventMenu addItem:[self eventMenuItem:@"Warning" withDisplay:@"Was Warned"]];
        eventMenu_cached = eventMenu;
    }
    return(eventMenu_cached);
}
//Used for each item of the eventMenu
-(NSMenuItem *)eventMenuItem:(NSString *)event withDisplay:(NSString *)displayName
{
    NSMenuItem *menuItem;
    NSMutableDictionary *menuDict;
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:displayName
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    //EDS    menuDict = [[[NSMutableDictionary alloc] init] retain];
    menuDict = [[[NSMutableDictionary alloc] init] autorelease];
    [menuDict setObject:displayName 	forKey:KEY_EVENT_DISPLAYNAME];
    [menuDict setObject:event 		forKey:KEY_EVENT_NOTIFICATION];
    [menuItem setRepresentedObject:menuDict];
    return menuItem;
}
//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*actionDict;
    NSString * event = [[sender representedObject] objectForKey:KEY_EVENT_NOTIFICATION];
    actionDict = [[NSMutableDictionary alloc] init];
    if ( [event hasPrefix:@"!"] ) //negative status
    {
        event = [event stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"!"]];
        [actionDict setObject:@"0" forKey:KEY_EVENT_STATUS];
    }
    else
        [actionDict setObject:@"1" forKey:KEY_EVENT_STATUS];
    
    //Add the new event
    [actionDict setObject:[[sender representedObject] objectForKey:KEY_EVENT_DISPLAYNAME] forKey:KEY_EVENT_DISPLAYNAME];
    [actionDict setObject:event forKey:KEY_EVENT_NOTIFICATION];
    [actionDict setObject:@"Sound" forKey:KEY_EVENT_ACTION]; //Sound is default action
    [actionDict setObject:[NSNumber numberWithInt:NSOffState] forKey:KEY_EVENT_DELETE]; //default to recurring events
    [actionDict setObject:[NSNumber numberWithInt:NSOffState] forKey:KEY_EVENT_ACTIVE]; //default to ignore active/inactive
    [eventActionArray addObject:actionDict];
    [actionDict release];
    
    [self saveEventActionArray];
    
    if ([[tableView_actions dataSource] respondsToSelector:@selector(addedEvent:)])
        [[tableView_actions dataSource] performSelector:@selector(addedEvent:) withObject:self];
}


// Subview management -------------------------------------------------------------------------------------
//Swap out subviews
- (void)configureWithSubview:(NSView *)view_inView
{
    if (!view_inView) view_inView = view_blank; //pass nil to signify the blank subview
    
    int 	heightChange = [view_inView frame].size.height - [[[view_main subviews] objectAtIndex:0] frame].size.height;
    NSView * oldView = [[view_main subviews] objectAtIndex:0];
    [view_main replaceSubview:oldView with:view_blank];
    
    NSRect	containerFrame = [[view_main window] frame];
    
    NSSize	minimumSize = [[view_main window] minSize];
    containerFrame.size.height += heightChange;
    containerFrame.origin.y -= heightChange;
    minimumSize.height += heightChange;
    
    [[view_main window] setFrame:containerFrame display:YES animate:NO];
    [[view_main window] setMinSize:minimumSize];
    
    if (view_pref != nil) //we're inside the preference pane
    {
        containerFrame = [view_pref frame];
        containerFrame.size.height += heightChange;
        containerFrame.origin.y -= heightChange;
        [view_pref setFrame:containerFrame];
        
        containerFrame = [[[view_pref superview] superview] frame];
        containerFrame.size.height += heightChange;
        [[[view_pref superview] superview] setFrame:containerFrame];
        [view_pref setFrameOrigin:NSMakePoint(0,0)];
        [[[view_pref superview] superview] setNeedsDisplay:YES];
    }
    [view_main replaceSubview:view_blank with:view_inView];
    [view_main setFrameSize:[view_inView frame].size];
    [view_main setNeedsDisplay:YES];
}
//Clear a view of all subviews
- (void)removeAllSubviews:(NSView *)view
{
    NSArray   * subviewsArray = [view subviews];
    NSEnumerator * enumerator = [subviewsArray objectEnumerator];
    NSView    * theSubview;
    NSRect    containerFrame = [[view_main window] frame];
    NSSize    minimumSize = [[view_main window] minSize];
    int               heightChange;
    
    while (theSubview = [enumerator nextObject])
    {
        heightChange = -[theSubview frame].size.height;
        containerFrame.size.height += heightChange;
        containerFrame.origin.y -= heightChange;
        minimumSize.height += heightChange;
        [theSubview removeFromSuperviewWithoutNeedingDisplay];
    }
    [[view_main window] setFrame:containerFrame display:YES animate:YES];
    [[view_main window] setMinSize:minimumSize];
}
// Table events -----------------------------------------------------------------------------------------

//Delete the selected action
-(IBAction)deleteEventAction:(id)sender
{
    //Remove the event
    [eventActionArray removeObjectAtIndex:row];
    
    //Save the event action array
    [self saveEventActionArray];
}

/*
 //Double-click response
 - (void)testSelectedEvent
 {
     if (row != -1) {
         if ([(NSString *)[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_ACTION] compare:@"Sound"] == 0) {
             NSString * sound = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS];
             if (sound && [sound length] != 0) {
                 [[owner soundController] playSoundAtPath:sound]; //Play the sound
             }
         }
     }
 }
 */

// The generic buttons -----------------------------------------------------------------------------------

- (void)oneTimeEvent:(NSButton *)inButton
{
    [selectedActionDict setObject:[NSNumber numberWithInt:[inButton state]] forKey:KEY_EVENT_DELETE];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    
    [self saveEventActionArray];
}
- (void)onlyWhileActive:(NSButton *)inButton
{
    [selectedActionDict setObject:[NSNumber numberWithInt:[inButton state]] forKey:KEY_EVENT_ACTIVE];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    
    [self saveEventActionArray];
}

// Notification handling -----------

// Update when a one time event fires while we're open
- (void)oneTimeEventFired:(NSNotification *)notification
{
    [self reload:[notification object] usingCache:NO];
    
    if ([[tableView_actions dataSource] respondsToSelector:@selector(anInstanceChanged:)])
        [[tableView_actions dataSource] performSelector:@selector(anInstanceChanged:) withObject:nil];
    [tableView_actions reloadData];
}

// Comparison testing of ESContactAlerts instances -----------------------------------------------------------------

//determine if two instances of ESContactAlerts refer to the same contact
- (BOOL)isEqual:(id)inInstance
{
    BOOL contactTest = ( [[activeContactObject UIDAndServiceID] compare:[[inInstance activeObject] UIDAndServiceID]] == 0 );
    return contactTest;
}
//hash string is simply based on the UIDAndServiceID's NSString hash
- (unsigned)hash
{
    return ( [[activeContactObject UIDAndServiceID] hash] );
}

//Sorting function
int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
    
    
    NSString  	*groupNameA = [[objectA containingGroup] displayName];
    NSString  	*groupNameB = [[objectB containingGroup] displayName];
    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }
    else if ([groupNameA compare:groupNameB] == 0)
    {
        if(invisibleA && !invisibleB){
            return(NSOrderedDescending);
        }else if(!invisibleA && invisibleB){
            return(NSOrderedAscending);
        }else{
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }
    }
    else
        return([groupNameA caseInsensitiveCompare:groupNameB]);
}

@end