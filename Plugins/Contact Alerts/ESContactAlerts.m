//
//  ESContactAlerts.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
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


int alphabeticalGroupOfflineSort_contactAlerts(id objectA, id objectB, void *context);
int eventActionSort_contactAlerts(id objectA, id objectB, void *context);

@implementation ESContactAlerts

#pragma mark Creation

- (id)initWithDetailsView:(NSView *)inView withTable:(AIAlternatingRowTableView*)inTable withPrefView:(NSView *)inPrefView
{
    [super init];

    actionListMenu_cached = nil;
    eventActionArray = nil;
    activeContactObject = nil;
    
    cachedAlertsDict = [[NSMutableDictionary alloc] init];
    
    tableView_actions = inTable;
    [tableView_actions retain];
    //    [tableView_actions setDoubleAction:@selector(testSelectedEvent)];
    
    view_pref = inPrefView;
    [view_pref retain];
    
    view_blank = [[NSView alloc] init];
    
	[self setMainView:inView];
	
    //nothing's selected, obviously, so row = -1
    row = -1;
    
    //let the controller know that we exist
    [[adium contactAlertsController] createAlertsArrayWithOwner:self];
    
    return self;
}

- (void)dealloc
{
    //let the controller know that we are done
    [[adium contactAlertsController] destroyAlertsArrayWithOwner:self];
    
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

#pragma mark Window and Preference Pane Info Functions
//--Configuration and modification--
- (void)configForObject:(AIListObject *)inObject
{
    [activeContactObject release];
    activeContactObject = [inObject retain];
    
    [self reload:activeContactObject usingCache:YES];
}
- (void)currentRowIs:(int)currentRow
{
    row = currentRow;
    if (row != -1) selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    
    //inform the controller
    [[adium contactAlertsController] updateOwner:self toRow:row];
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
        NSString        *uniqueObjectID = [object uniqueObjectID];
        
        //Load our cached array if available
        if(useCache){
            newActionArray = [cachedAlertsDict objectForKey:uniqueObjectID];
        }
        
        //If no cache is available (or we're not using the cache), load the array
        if(!newActionArray){
            newActionArray = [object preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS ignoreInheritedValues:YES]; //load from prefs
            
            //Update the cache
            if(newActionArray){
                newActionArray = [[newActionArray mutableCopy] autorelease];
                [cachedAlertsDict setObject:newActionArray forKey:uniqueObjectID]; //cache it
            }else{
                [cachedAlertsDict removeObjectForKey:uniqueObjectID]; //pref is now clear - remove from our cache
            }
        }
        
        //If this is our currently active contact
        if([[object uniqueObjectID] compare:[activeContactObject uniqueObjectID]] == 0) {
            if (!newActionArray) {
                newActionArray = [[[NSMutableArray alloc] init] autorelease]; //Create a new, empty action array   
            }
            [eventActionArray release]; eventActionArray = [newActionArray retain];
            
            [eventActionArray sortUsingFunction:eventActionSort_contactAlerts context:nil];
			//inform the controller
            [[adium contactAlertsController] updateOwner:self toArray:eventActionArray forObject:object];
        }
    }
}

#pragma mark Accessing Information
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
- (NSWindow *)activeWindow
{   return [view_main window];                          }

#pragma mark Actions
- (NSMenu *)actionListMenu //menu of possible actions
{
    if (!actionListMenu_cached) {
        actionListMenu_cached = [[[adium contactAlertsController] actionListMenuWithOwner:self] retain];
    }
    return actionListMenu_cached;
}

- (void)actionChangedTo:(NSString *)inAction
{
	NSMutableDictionary     *actionDict;
	
	actionDict = [[self dictAtIndex:row] mutableCopy];
	
	[actionDict setObject:inAction forKey:KEY_EVENT_ACTION];
	[self replaceDictAtIndex:row withDict:actionDict];	
}

#pragma mark Saving
//Save the event actions (contact context sensitive)
- (void)saveEventActionArray
{
    [activeContactObject setPreference:eventActionArray forKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS];
}

#pragma mark Events
//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    if (!eventMenu_cached)
    {
        NSMenu		*eventMenu = [[NSMenu alloc] init];
        
        //Add a menu item for each event
        [eventMenu addItem:[self eventMenuItem:@"Signed On" withDisplay:AILocalizedString(@"Signs On",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"Signed Off" withDisplay:AILocalizedString(@"Signs Off",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"Away" withDisplay:AILocalizedString(@"Goes Away",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"!Away" withDisplay:AILocalizedString(@"Comes Back From Away",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"Idle" withDisplay:AILocalizedString(@"Becomes Idle",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"!Idle" withDisplay:AILocalizedString(@"Becomes Unidle",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"Typing" withDisplay:AILocalizedString(@"Is Typing",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"UnviewedContent" withDisplay:AILocalizedString(@"Has Unviewed Content",nil)]];
        [eventMenu addItem:[self eventMenuItem:@"Warning" withDisplay:AILocalizedString(@"Is Warned",nil)]];
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
                                           action:@selector(changeEvent:)
                                    keyEquivalent:@""] autorelease];
    //EDS    menuDict = [[[NSMutableDictionary alloc] init] retain];
    menuDict = [[[NSMutableDictionary alloc] init] autorelease];
    [menuDict setObject:displayName 	forKey:KEY_EVENT_DISPLAYNAME];
    [menuDict setObject:event 		forKey:KEY_EVENT_NOTIFICATION];
    [menuItem setRepresentedObject:menuDict];
    return menuItem;
}

//Readies the New Alert pane
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*actionDict = [[NSMutableDictionary alloc] init];

	NSLog(@"Creating a new event for %@", [[self activeObject] UID]);
	
    //Add the new event
    [actionDict setObject:AILocalizedString(@"Signs On",nil) forKey:KEY_EVENT_DISPLAYNAME];
    [actionDict setObject:@"Signed On" forKey:KEY_EVENT_NOTIFICATION];
    [actionDict setObject:@"Sound" forKey:KEY_EVENT_ACTION]; //Sound is default action
    [actionDict setObject:[NSNumber numberWithInt:NSOffState] forKey:KEY_EVENT_DELETE]; //default to recurring events
    [actionDict setObject:[NSNumber numberWithInt:NSOffState] forKey:KEY_EVENT_ACTIVE]; //default to ignore active/inactive
    [eventActionArray addObject:actionDict];
    [actionDict release];
	
	[self currentRowIs:[self count] - 1];
	
	[self saveEventActionArray];
}

- (IBAction)changeEvent:(id)sender
{
	NSMutableDictionary	*actionDict = [self dictAtIndex:[self currentRow]];
	
	[actionDict setObject:[[sender representedObject] objectForKey:KEY_EVENT_NOTIFICATION] forKey:KEY_EVENT_NOTIFICATION];
	[actionDict setObject:[[sender representedObject] objectForKey:KEY_EVENT_DISPLAYNAME] forKey:KEY_EVENT_DISPLAYNAME];

	[self saveEventActionArray];
}

/*//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*actionDict = [[NSMutableDictionary alloc] init];
    NSString * event = [[sender representedObject] objectForKey:KEY_EVENT_NOTIFICATION];
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
*/
#pragma mark Views

- (void)setMainView:(NSView *)inView
{
	if (view_main) {
		[view_main release];
		view_main = nil;
	}
	view_main = [inView retain];
	
	if ( view_main && [[view_main subviews] count] == 0 ) //there are no subviews yet
        [view_main addSubview:view_blank];
}
- (NSView *)mainView
{
	return view_main;
}

#pragma mark Subview Management

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
#pragma mark Table Events

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
                 [[adium soundController] playSoundAtPath:sound]; //Play the sound
             }
         }
     }
 }
 */

#pragma mark Generic Buttons 

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

#pragma mark Notification Handling

// Update when a one time event fires while we're open
- (void)oneTimeEventFired:(NSNotification *)notification
{
    [self reload:[notification object] usingCache:NO];
    
    if ([[tableView_actions dataSource] respondsToSelector:@selector(anInstanceChanged:)])
        [[tableView_actions dataSource] performSelector:@selector(anInstanceChanged:) withObject:nil];
    [tableView_actions reloadData];
}

#pragma mark Comparison Testing

//determine if two instances of ESContactAlerts refer to the same contact
- (BOOL)isEqual:(id)inInstance
{
    BOOL contactTest = ( [inInstance isKindOfClass:[self class]] && [[activeContactObject uniqueObjectID] compare:[[inInstance activeObject] uniqueObjectID]] == 0 );
    return contactTest;
}
//hash string is simply based on the uniqueObjectID's NSString hash
- (unsigned)hash
{
    return ( [[activeContactObject uniqueObjectID] hash] );
}

//sorts the event action array by event, then action
int eventActionSort_contactAlerts(id objectA, id objectB, void *context)
{
	int sorter = [(NSString *)[objectA objectForKey:KEY_EVENT_NOTIFICATION] compare:(NSString *)[objectB objectForKey:KEY_EVENT_NOTIFICATION]];
	if (sorter != 0) {
		return(sorter);
	}
	return ([(NSString *)[objectA objectForKey:KEY_EVENT_ACTION] compare:(NSString *)[objectB objectForKey:KEY_EVENT_ACTION]]);
}

#warning This sort function no longer works properly after the group changes
//Sorting function
int alphabeticalGroupOfflineSort_contactAlerts(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] intValue];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] intValue];
    BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
    
    
//    NSString  	*groupNameA = [[objectA containingGroup] displayName];
//    NSString  	*groupNameB = [[objectB containingGroup] displayName];
    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }
//    else if ([groupNameA compare:groupNameB] == 0)
//    {
    else
        if(invisibleA && !invisibleB){
            return(NSOrderedDescending);
        }else if(!invisibleA && invisibleB){
            return(NSOrderedAscending);
        }else{
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }
//    }
//    else
//        return([groupNameA caseInsensitiveCompare:groupNameB]);
}

@end