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

#import "AIDockCustomBehavior.h"
#import "AIDockBehaviorPlugin.h"

#define TABLE_COLUMN_BEHAVIOR		@"behavior"
#define TABLE_COLUMN_EVENT		@"event"
#define NIB_DOCK_BEHAVIOR_CUSTOM	@"DockBehaviorCustom"


@interface AIDockCustomBehavior (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin;
- (void)configureView;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSMenu *)behaviorSetMenu;
- (NSMenu *)eventMenu;
- (void)saveCustomBehavior;
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name;
@end

@implementation AIDockCustomBehavior

//
AIDockCustomBehavior	*sharedInstance = nil;
+ (id)showDockBehaviorCustomPanelWithPlugin:(id)inPlugin
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:NIB_DOCK_BEHAVIOR_CUSTOM plugin:inPlugin];
    }
    return(sharedInstance);
}

//
+ (void)closeDockBehaviorCustomPanel;
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
        [sharedInstance release]; sharedInstance = nil;
    }
}

//
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin
{
    [super initWithWindowNibName:windowNibName];

    plugin = inPlugin;
    [self showWindow:nil];

    return(self);
}

//
- (void)windowDidLoad
{
    NSPopUpButtonCell			*dataCell;

    //Center
    [[self window] center];

    //Build the event menu
    [popUp_addEvent setMenu:[self eventMenu]];

    //Configure the 'Behavior' table column
    dataCell = [[[AITableViewPopUpButtonCell alloc] init] autorelease];
    [dataCell setMenu:[AIDockBehaviorPlugin behaviorListMenuForTarget:self]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_events tableColumnWithIdentifier:TABLE_COLUMN_BEHAVIOR] setDataCell:dataCell];

    //Configure the table view
    [tableView_events setDrawsAlternatingRows:YES];
    [tableView_events setTarget:self];

    //Observer preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //
    [[adium notificationCenter] removeObserver:self];
    [behaviorArray release]; behaviorArray = nil;

    //Clean up shared instance
    [self autorelease];
    sharedInstance = nil;

    return(YES);
}

//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){

        //Load the custom behavior
        [behaviorArray release];
        behaviorArray = [[plugin customBehavior] mutableCopy];
        if(!behaviorArray) behaviorArray = [[NSMutableArray alloc] init];

        //Update the outline view
        [tableView_events reloadData];
    }
}

//The user selected a behavior
- (IBAction)selectBehavior:(id)sender
{
    //Do nothing
    //Our tableview's set method is called as well, and handles the change
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

    //Add the new event
    eventDict = [NSMutableDictionary dictionary];
    [eventDict setObject:[sender representedObject] forKey:KEY_DOCK_EVENT_NOTIFICATION];
    [eventDict setObject:[NSNumber numberWithInt:0] forKey:KEY_DOCK_EVENT_BEHAVIOR];
    [behaviorArray addObject:eventDict];

    //Save custom behavior
    [self saveCustomBehavior];
}

//Save the custom behavior
- (void)saveCustomBehavior
{
    [plugin setCustomBehavior:behaviorArray];
}

//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*eventDict;
    NSMenu		*eventMenu = [[NSMenu alloc] init];

    //Add the static/display menu item
    [eventMenu addItemWithTitle:AILocalizedString(@"Add EventÉ",nil) target:nil action:nil keyEquivalent:@""];

    //Add a menu item for each event
    enumerator = [[adium eventNotifications] objectEnumerator];
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
        eventDict = [[adium eventNotifications] objectForKey:notification];
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
        NSMenuItem			*selectedMenuItem;
        NSMutableDictionary	*selectedEventDict;
        NSNumber			*newBehavior;
		
        //
		if (object) {
			int		index = [object intValue];
			NSMenu  *menu = [[tableColumn dataCell] menu];
			
			if ((index > 0) && (index < [menu numberOfItems])) {
				selectedMenuItem = (NSMenuItem *)[menu itemAtIndex:index];
				selectedEventDict = [[[behaviorArray objectAtIndex:row] mutableCopy] autorelease];
				newBehavior = [selectedMenuItem representedObject];
				
				if([newBehavior compare:[selectedEventDict objectForKey:KEY_DOCK_EVENT_BEHAVIOR]] != 0){ //Ignore a duplicate selection
																										 //Set the new behavior
					[selectedEventDict setObject:newBehavior forKey:KEY_DOCK_EVENT_BEHAVIOR];
					[behaviorArray replaceObjectAtIndex:row withObject:selectedEventDict];
					
					//Save custom behavior
					[self saveCustomBehavior];
				}
			}
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

@end
