//
//  AIContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactAlertsWindowController.h"
#import "AIContactAlertsPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define	EVENT_SOUND_PREF_NIB		@"EventSoundPrefs"
#define EVENT_SOUND_PREF_TITLE		@"Sounds"
#define SOUND_MENU_ICON_SIZE		16

#define CONTACT_ALERT_WINDOW_NIB	@"ContactAlerts"
#define TABLE_COLUMN_ACTION		@"action"
#define TABLE_COLUMN_EVENT		@"event"



@interface AIContactAlertsWindowController (PRIVATE)
- (NSMenu *)eventMenu;
- (NSMenu *)soundSetMenu;
- (NSMenu *)soundListMenu;
- (NSMenu *)actionListMenu;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)shouldSelectRow:(int)inRow;
- (id)initWithOwner:(id)inOwner forPlugin:(id)inPlugin;
- (void)configureView;
//- (void)preferencesChanged:(NSNotification *)notification;
- (void)saveEventActionArray;
- (void) configureForTextDetails:(NSString *)instructions;
- (void) configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu;
@end

@implementation AIContactAlertsWindowController
//Open a new info window
static AIContactAlertsWindowController *sharedInstance = nil;
+ (id)showContactAlertsWindowWithOwner:(id)inOwner forContact:(AIListContact *)inContact
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_ALERT_WINDOW_NIB owner:inOwner];
    }

    //Allow for groups?
//    if([inContact isKindOfClass:[AIListContact class]]){ //Only allow this for contacts
        //Show the window and configure it for the contact
        [sharedInstance configureWindowForContact:inContact];
        [sharedInstance showWindow:nil];
//    }

    return(sharedInstance);
}

//Close the alerts window
+ (void)closeContactAlertsWindow
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

/*
- (NSDictionary *)eventNotifications
{
    return(eventNotifications);
}
*/

//Configure the actions window for the specified contact
- (void)configureWindowForContact:(AIListContact *)inContact
{

    //Make sure our window is loaded
    [self window];

    //Remember who we're displaying actions for
    [activeContactObject release]; activeContactObject = [inContact retain];

    //Set window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@'s Alerts",[activeContactObject displayName]]];

    NSPopUpButtonCell			*dataCell;

    //Build the event menu
    [popUp_addEvent setMenu:[self eventMenu]];

    //Configure the 'Action' table column
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:[self actionListMenu]];
//    [dataCell setMenu:[self soundListMenu]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_actions tableColumnWithIdentifier:TABLE_COLUMN_ACTION] setDataCell:dataCell];

    //Configure the table view
    [tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_actions setTarget:self];
    [tableView_actions setDoubleAction:@selector(testSelectedEvent:)];
    [tableView_actions setDataSource:self];
    
    //  eventSoundArray = [[preferenceDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET] mutableCopy]; //Load the user's custom set
    eventActionArray =  [[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:activeContactObject];

    if(!eventActionArray) eventActionArray = [[NSMutableArray alloc] init];

    //Update the outline view
    [tableView_actions reloadData];
}

//Builds and returns an event menu
- (NSMenu *)eventMenu
{
//    NSDictionary	*eventDict;
    NSMenu		*eventMenu = [[NSMenu alloc] init];

    //Add the static/display menu item
    [eventMenu addItemWithTitle:@"Add Event…" target:nil action:nil keyEquivalent:@""];
/*
    online = [[inObject statusArrayForKey:@"Online"] greatestIntegerValue];
  */  
    //Add a menu item for each event
    NSMenuItem	*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Signed On"
                                               target:self
                                               action:@selector(newEvent:)
                                        keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Signed On"];
    [eventMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Signed Off"
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Signed Off"];
    [eventMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Went Away"
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Away"];
    [eventMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Became Idle"
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Idle"];
    [eventMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Typing"
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Typing"];
    [eventMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Has Unviewed Content"
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"UnviewedContent"];
    [eventMenu addItem:menuItem];
    
    return(eventMenu);
}

//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*actionDict;

    //Add the new event
    actionDict = [[NSMutableDictionary alloc] init];
    [actionDict setObject:[sender representedObject] forKey:KEY_EVENT_NOTIFICATION];
    [actionDict setObject:@"WhatShouldTheDefaultSoundBe!?" forKey:KEY_EVENT_ACTION];
    [eventActionArray addObject:actionDict];

    //Save event preferences
    [self saveEventActionArray];

    //Update the outline view
    [tableView_actions reloadData];

}


- (void)testSelectedEvent
{
    //action to take when action is selected in the window
}

//Delete the selected action
- (IBAction)deleteEventAction:(id)sender
{
    
    //Remove the event
    [eventActionArray removeObjectAtIndex:[tableView_actions selectedRow]];

    //Save event sound preferences
    [self saveEventActionArray];
    
    //Update the outline view
    [tableView_actions reloadData];
}


//Save the event actions (contact context sensitive)
- (void)saveEventActionArray
{
    [[owner preferenceController] setPreference:eventActionArray forKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:activeContactObject];
}

//Builds and returns a sound list menu - from AIEventSoundsPreferences.m
- (NSMenu *)soundListMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*soundSetDict;
    NSMenu		*soundMenu = [[NSMenu alloc] init];

    enumerator = [[[owner soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSEnumerator	*soundEnumerator;
        NSString	*soundSetPath;
        NSString	*soundPath;
        NSMenuItem	*menuItem;

        //Add an item for the set
        if([soundMenu numberOfItems] != 0){
            [soundMenu addItem:[NSMenuItem separatorItem]]; //Divider
        }
        soundSetPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        menuItem = [[[NSMenuItem alloc] initWithTitle:[soundSetPath lastPathComponent]
                                               target:nil
                                               action:nil
                                        keyEquivalent:@""] autorelease];
        [menuItem setEnabled:NO];
        [soundMenu addItem:menuItem];

        //Add an item for each sound
        soundEnumerator = [[soundSetDict objectForKey:KEY_SOUND_SET_CONTENTS] objectEnumerator];
        while((soundPath = [soundEnumerator nextObject])){
            NSImage	*soundImage;
            NSString	*soundTitle;

            //Get the sound title and image
            soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
            soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
            [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];

            //Build the menu item
            menuItem = [[[NSMenuItem alloc] initWithTitle:soundTitle
                                                   target:self
                                                   action:@selector(selectSound:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:soundPath];
            [menuItem setImage:soundImage];

            [soundMenu addItem:menuItem];
        }
    }

    [soundMenu setAutoenablesItems:NO];

    return(soundMenu);
}
//Select a sound from one of the sound popUp menus
- (IBAction)selectSound:(id)sender
{
    NSString	*soundPath = [sender representedObject];
    int row = [tableView_actions selectedRow];
    
    if(soundPath != nil && [soundPath length] != 0){
        [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
    }

    NSMutableDictionary	*selectedActionDict;

    selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    [selectedActionDict setObject:soundPath forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    //Save event sound preferences
    [self saveEventActionArray];
        
}

//called by textfield_actionDetails when editing is over
- (IBAction)endEditing:(id)sender
{
    int row = [tableView_actions selectedRow];
    NSMutableDictionary	*selectedActionDict;
    
    selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    [selectedActionDict setObject:[textField_actionDetails stringValue] forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    NSLog(@"Ended editing the field.");
    [self saveEventActionArray];
}

//Actions!
- (NSMenu *)actionListMenu //menu of possible actions
{
    NSMenu		*actionListMenu = [[NSMenu alloc] init];
    NSMenuItem	*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Send a message"
                                           target:self
                                           action:@selector(actionSendMessage:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Message"];
    [menuItem setEnabled:YES];
    [actionListMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Play a sound"
                                           target:self
                                           action:@selector(actionPlaySound:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Sound"]; //Sound
        [menuItem setEnabled:YES];
    [actionListMenu addItem:menuItem];

    return(actionListMenu);

}

//setup display for sending a message
- (IBAction)actionSendMessage:(id)sender
{
    [self configureForTextDetails:@"Message to send:"];
}

//setup display for playing a sound
- (IBAction)actionPlaySound:(id)sender
{
    [self configureForMenuDetails:@"Sound to play:" menuToDisplay:[self soundListMenu]];
 }

- (void) configureForTextDetails:(NSString *)instructions
{
    int row = [tableView_actions selectedRow];
    [textField_description_textField setStringValue:instructions];
    [textField_description_popUp setStringValue:@""];
    [popUp_actionDetails setEnabled:NO];
    [textField_actionDetails setEnabled:YES];
    [textField_actionDetails setDrawsBackground:YES];
    [textField_actionDetails setStringValue:[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS]];
}

- (void) configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu
{
    int row = [tableView_actions selectedRow];
    [textField_description_popUp setStringValue:instructions];
    [textField_description_textField setStringValue:@""];
    [popUp_actionDetails setEnabled:YES];
    [textField_actionDetails setEnabled:NO];
    [popUp_actionDetails setMenu:detailsMenu];
    [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS]]];
    
}


//TableView datasource --------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([eventActionArray count]); 
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*actionDict;
        NSString	*notification;
        NSDictionary	*eventDict;
        NSString	*displayName;

        //Get the notification string
        actionDict = [eventActionArray objectAtIndex:row];
        notification = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];

        //Get that notification's display name
        eventDict = [[owner eventNotifications] objectForKey:notification];
        displayName = [eventDict objectForKey:KEY_EVENT_DISPLAY_NAME];

        return(displayName ? displayName : notification);

    }else if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSDictionary	*actionDict;
        NSString	*action;
        //Get the action string
        actionDict = [eventActionArray objectAtIndex:row];
        action = [actionDict objectForKey:KEY_EVENT_ACTION];

        return(action);

    }else {
        
        return(nil);

    }
}

//
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        [cell selectItemWithRepresentedObject:[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_ACTION]];
    }
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
   
    if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSMenuItem		*selectedMenuItem;
        NSMutableDictionary	*selectedActionDict;
        NSString		*newAction;

        selectedMenuItem = [[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
        newAction = [selectedMenuItem representedObject];

        [selectedActionDict setObject:newAction forKey:KEY_EVENT_ACTION];
        [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
        //Save event sound preferences
        [self saveEventActionArray]; 
    }
}


//
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteEventAction:nil]; //Delete it
}

//selection changed; update the view
- (void)tableViewSelectionDidChange:(NSNotification *)aNotfication
{
    int row = [tableView_actions selectedRow];
    NSMenu * actionsMenu = [[self actionListMenu] autorelease];
    NSString *action = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_ACTION];

    [actionsMenu performActionForItemAtIndex:[actionsMenu indexOfItemWithRepresentedObject:action]];
}

- (BOOL)shouldSelectRow:(int)inRow
{

    [button_delete setEnabled:(inRow != -1)]; //Enable/disable the delete button correctly

    return(YES);
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    //init
    owner = [inOwner retain];
    return(self);
}

//
- (void)dealloc
{
    [owner release];
    [activeContactObject release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
 /*   NSString	*savedFrame;

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_TEXT_PROFILE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
*/
}


@end
