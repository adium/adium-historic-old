//
//  AIDockBehaviorPreferences.m
//  Adium
//
//  Created by Adam Atlas on Wed Jan 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIDockBehaviorPreferences.h"
#import "AIDockBehaviorPlugin.h"

#define DOCK_BEHAVIOR_PREF_NIB		@"DockBehaviorPreferences"
#define DOCK_BEHAVIOR_PREF_TITLE	@"Dock Behavior"

#define TABLE_COLUMN_BEHAVIOR		@"behavior"
#define TABLE_COLUMN_EVENT		@"event"

@interface AIDockBehaviorPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSMenu *)behaviorListMenu;
- (NSMenu *)behaviorSetMenu;
- (NSMenu *)eventMenu;
- (void)saveCustomBehavior;
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name;
@end

@implementation AIDockBehaviorPreferences

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner
{
    return [[[self alloc] initWithOwner:inOwner] autorelease];
}

//The user selected a behavior
- (IBAction)selectBehavior:(id)sender
{
    //Do nothing
    //Our tableview's set method is called as well, and handles the change
}

//The user selected a dock behavior preset
- (IBAction)selectBehaviorSet:(id)sender
{
    if(sender && [sender representedObject]){ //User selected a behavior set
        [[owner preferenceController] setPreference:[sender representedObject]
                                             forKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET
                                              group:PREF_GROUP_DOCK_BEHAVIOR];

    }else{ //User selected 'Custom...'
        [[owner preferenceController] setPreference:@""
                                             forKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET
                                              group:PREF_GROUP_DOCK_BEHAVIOR]; //Remove the set preference

    }
}

//Delete the selected event
- (IBAction)deleteEvent:(id)sender
{
    //Remove the event
    [behaviorArray removeObjectAtIndex:[tableView_events selectedRow]];

    //Save custom behavior
    [self saveCustomBehavior];
}

//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*eventDict;

    //If the user just modified a premade behavior set, save it as their custom set, and switch them to 'custom'.
    if(!usingCustomBehavior){
        [self saveCustomBehavior];
        [self selectBehaviorSet:nil];
    }

    //Add the new event
    eventDict = [[NSMutableDictionary alloc] init];
    [eventDict setObject:[sender representedObject] forKey:KEY_DOCK_EVENT_NOTIFICATION];
    [eventDict setObject:[NSNumber numberWithInt:0] forKey:KEY_DOCK_EVENT_BEHAVIOR];
    [behaviorArray addObject:eventDict];

    //Save custom behavior
    [self saveCustomBehavior];
}


//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:DOCK_BEHAVIOR_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:DOCK_BEHAVIOR_PREF_TITLE categoryName:PREFERENCE_CATEGORY_INTERFACE view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Configure the view and load our preferences
    [self configureView];
    [self preferencesChanged:nil];

    return self;
}

//configure our view
- (void)configureView
{
    NSPopUpButtonCell			*dataCell;

    //Build the event menu
    [popUp_addEvent setMenu:[self eventMenu]];

    //Build the behavior set menu
    [popUp_behaviorSet setMenu:[self behaviorSetMenu]];

    //Configure the 'Behavior' table column
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:[self behaviorListMenu]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_events tableColumnWithIdentifier:TABLE_COLUMN_BEHAVIOR] setDataCell:dataCell];

    //Configure the table view
    [tableView_events setDrawsAlternatingRows:YES];
    [tableView_events setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_events setTarget:self];

}

//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the Behavior set changed
        if(notification == nil || [key compare:KEY_DOCK_ACTIVE_BEHAVIOR_SET] == 0){
            NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
            NSString		*activeBehaviorSet = [preferenceDict objectForKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET];

            //Load the new behaviorSet
            [behaviorArray release]; behaviorArray = nil;
            if(activeBehaviorSet && [activeBehaviorSet length] != 0){ //preset
                behaviorArray = [[[preferenceDict objectForKey:KEY_DOCK_BEHAVIOR_SETS] objectForKey:activeBehaviorSet] retain];
                usingCustomBehavior = NO;
                [popUp_behaviorSet selectItemWithRepresentedObject:activeBehaviorSet];	//Update the set popUp

            }else{ //Custom
                behaviorArray = [[preferenceDict objectForKey:KEY_DOCK_CUSTOM_BEHAVIOR] mutableCopy];
                usingCustomBehavior = YES;
                [popUp_behaviorSet selectItemAtIndex:0];				//Update the set popUp

            }
            
        }

        //Update the outline view
        [tableView_events reloadData];
    }
}

//Save the custom behavior
- (void)saveCustomBehavior
{
    [[owner preferenceController] setPreference:behaviorArray forKey:KEY_DOCK_CUSTOM_BEHAVIOR group:PREF_GROUP_DOCK_BEHAVIOR];
}

//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*eventDict;
    NSMenu		*eventMenu = [[NSMenu alloc] init];

    //Add the static/display menu item
    [eventMenu addItemWithTitle:@"Add Event…" target:nil action:nil keyEquivalent:@""];

    //Add a menu item for each event
    enumerator = [[owner eventNotifications] objectEnumerator];
    while((eventDict = [enumerator nextObject])){
        NSMenuItem	*menuItem;

        menuItem = [[[NSMenuItem alloc] initWithTitle:[eventDict objectForKey:KEY_EVENT_DISPLAY_NAME]
                                               target:self
                                               action:@selector(newEvent:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[eventDict objectForKey:KEY_EVENT_NOTIFICATION]];

        [eventMenu addItem:menuItem];
    }

    return(eventMenu);
}

//Builds and returns a behavior set menu
- (NSMenu *)behaviorSetMenu
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
    NSDictionary	*behaviorSets;
    NSEnumerator	*enumerator;
    NSString		*behaviorSetName;
    NSMenu		*behaviorSetMenu;

    //Create the behavior set menu
    behaviorSetMenu = [[[NSMenu alloc] init] autorelease];

    //Add the custom option
    [behaviorSetMenu addItemWithTitle:@"Custom…" target:self action:@selector(selectBehaviorSet:) keyEquivalent:@""];
    [behaviorSetMenu addItem:[NSMenuItem separatorItem]];

    //Add all the premade behavior sets
    behaviorSets = [preferenceDict objectForKey:KEY_DOCK_BEHAVIOR_SETS];
    enumerator = [[behaviorSets allKeys] objectEnumerator];
    while((behaviorSetName = [enumerator nextObject])){
        NSMenuItem	*menuItem;

        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:behaviorSetName
                                               target:self
                                               action:@selector(selectBehaviorSet:)
                                        keyEquivalent:@""] autorelease];

        //
        [menuItem setRepresentedObject:behaviorSetName];
        [behaviorSetMenu addItem:menuItem];
    }

    return(behaviorSetMenu);
}

//Builds and returns a dock behavior list menu
- (NSMenu *)behaviorListMenu
{
    NSMenu		*behaviorMenu = [[[NSMenu alloc] init] autorelease];

    //Build the menu items
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_ONCE withName:@"Once"]];
    [behaviorMenu addItem:[NSMenuItem separatorItem]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_REPEAT withName:@"Repeatedly"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY5 withName:@"Every 5 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY10 withName:@"Every 10 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY15 withName:@"Every 15 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY30 withName:@"Every 30 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY60 withName:@"Every Minute"]];

    [behaviorMenu setAutoenablesItems:NO];

    return(behaviorMenu);
}

- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name
{
    NSMenuItem		*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:name
                                           target:self
                                           action:@selector(selectBehavior:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:behavior]];

    return(menuItem);
}



//TableView datasource --------------------------------------------------------
//
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([behaviorArray count]);
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*behaviorDict;
        NSString	*notification;
        NSDictionary	*eventDict;
        NSString	*displayName;

        //Get the notification string
        behaviorDict = [behaviorArray objectAtIndex:row];
        notification = [behaviorDict objectForKey:KEY_DOCK_EVENT_NOTIFICATION];

        //Get that notification's display name
        eventDict = [[owner eventNotifications] objectForKey:notification];
        displayName = [eventDict objectForKey:KEY_EVENT_DISPLAY_NAME];

        return(displayName ? displayName : notification);

    }else{
        return(nil);

    }
}

//
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_BEHAVIOR] == 0){
        NSMenuItem		*selectedMenuItem;
        NSMutableDictionary	*selectedEventDict;
        NSNumber		*newBehavior;

        //
        selectedMenuItem = [[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedEventDict = [[behaviorArray objectAtIndex:row] mutableCopy];
        newBehavior = [selectedMenuItem representedObject];

        if([newBehavior compare:[selectedEventDict objectForKey:KEY_DOCK_EVENT_BEHAVIOR]] != 0){ //Ignore a duplicate selection
            //If the user just modified a premade behavior set, save it as their custom set, and switch them to 'custom'.
            if(!usingCustomBehavior){
                [self saveCustomBehavior];
                [self selectBehaviorSet:nil];
            }

            //Set the new behavior
            [selectedEventDict setObject:newBehavior forKey:KEY_DOCK_EVENT_BEHAVIOR];
            [behaviorArray replaceObjectAtIndex:row withObject:selectedEventDict];

            //Save custom behavior
            [self saveCustomBehavior];
        }
    }
}

//
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_BEHAVIOR] == 0){
        [cell selectItemWithRepresentedObject:[[behaviorArray objectAtIndex:row] objectForKey:KEY_DOCK_EVENT_BEHAVIOR]];
    }
}

//
- (BOOL)shouldSelectRow:(int)inRow
{
    [button_delete setEnabled:(inRow != -1)]; //Enable/disable the delete button correctly

    return(YES);
}


@end
