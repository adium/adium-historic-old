/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIDockBehaviorPreferences.h"
#import "AIDockBehaviorPlugin.h"

#define DOCK_BEHAVIOR_PREF_NIB		@"DockBehaviorPreferences"
#define DOCK_BEHAVIOR_PREF_TITLE	@"Dock Bouncing"

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
//
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
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Dock_General withDelegate:self label:DOCK_BEHAVIOR_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:DOCK_BEHAVIOR_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;

    //
    [[owner notificationCenter] removeObserver:self];
    [behaviorArray release]; behaviorArray = nil;
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
    dataCell = [[[AITableViewPopUpButtonCell alloc] init] autorelease];
    [dataCell setMenu:[self behaviorListMenu]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_events tableColumnWithIdentifier:TABLE_COLUMN_BEHAVIOR] setDataCell:dataCell];

    //Configure the table view
    [tableView_events setDrawsAlternatingRows:YES];
    [tableView_events setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_events setTarget:self];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
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
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteEvent:nil]; //Delete them
}

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
