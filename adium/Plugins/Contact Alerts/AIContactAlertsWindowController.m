//
//  AIContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
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
- (NSMenu *)soundListMenu;
- (NSMenu *)behaviorListMenu;
- (NSMenu *)actionListMenu;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)shouldSelectRow:(int)inRow;
- (id)initWithOwner:(id)inOwner forPlugin:(id)inPlugin;
- (void)configureView;
- (void)saveEventActionArray;
- (void)configureForTextDetails:(NSString *)instructions;
- (void)configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu;
- (NSMenuItem *)eventMenuItem:(NSString *)event withDisplay:(NSString *)displayName;
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name;
@end

@implementation AIContactAlertsWindowController
//Open a new info window
static AIContactAlertsWindowController *sharedInstance = nil;
+ (id)showContactAlertsWindowWithOwner:(id)inOwner forObject:(AIListObject *)inContact
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_ALERT_WINDOW_NIB owner:inOwner];
    }

    [sharedInstance configureWindowforObject:inContact];
    [sharedInstance showWindow:nil];

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
        //Save the window position
        [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                             forKey:KEY_CONTACT_ALERTS_WINDOW_FRAME
                                              group:PREF_GROUP_WINDOW_POSITIONS];
        [[self window] close];
    }
}


//Configure the actions window for the specified contact
- (void)configureWindowforObject:(AIListObject *)inContact
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

    //Build the action menu
    actionMenu = [self actionListMenu];
    
    //Configure the 'Action' table column
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:actionMenu];
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

    [popUp_actionDetails setEnabled:NO];
    [textField_actionDetails setEnabled:NO];
    [textField_actionDetails setDelegate:self];

    eventActionArray =  [[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:activeContactObject];

    if(eventActionArray) //saved array
        if ([eventActionArray count]) [tableView_actions selectRow:0 byExtendingSelection:NO];
    else
        eventActionArray = [[NSMutableArray alloc] init];
   
    //Update the outline view
    [tableView_actions reloadData];
}

//Actions!
- (NSMenu *)actionListMenu //menu of possible actions
{
    NSMenu		*actionListMenu = [[NSMenu alloc] init];
    NSMenuItem		*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Play a sound"
                                           target:self
                                           action:@selector(actionPlaySound:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Sound"];
    [actionListMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Send a message"
                                           target:self
                                           action:@selector(actionSendMessage:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Message"];
    [actionListMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Show an alert"
                                           target:self
                                           action:@selector(actionDisplayAlert:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Alert"];
    [actionListMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Bounce the dock"
                                           target:self
                                           action:@selector(actionBounceDock:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Bounce"];
    [actionListMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Speak text"
                                           target:self
                                           action:@selector(actionSpeakText:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:@"Speak"];
    [actionListMenu addItem:menuItem];
    
    return(actionListMenu);
}

//setup display for sending a message
- (IBAction)actionSendMessage:(id)sender
{	[self configureForTextDetails:@"Message to send:"];	}

//setup display for displaying an alert
- (IBAction)actionDisplayAlert:(id)sender
{	[self configureForTextDetails:@"Alert text:"];		}

//setup display for speaking text
- (IBAction)actionSpeakText:(id)sender
{    [self configureForTextDetails:@"Text to speak:"];		}

//setup display for playing a sound
- (IBAction)actionPlaySound:(id)sender
{    [self configureForMenuDetails:@"Sound to play:" menuToDisplay:[self soundListMenu]];	}

//setup display for bouncing the dock
- (IBAction)actionBounceDock:(id)sender
{    [self configureForMenuDetails:@"Dock behavior:" menuToDisplay:[self behaviorListMenu]];	}

//Builds and returns an event menu
- (NSMenu *)eventMenu
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
    
    return(eventMenu);
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
    [eventActionArray addObject:actionDict];

    //Save event preferences
    [self saveEventActionArray];

    //Update the outline view
    [tableView_actions reloadData];

}

- (void)testSelectedEvent
{
    //action to take when action is double-clicked in the window
}


- (void) configureForTextDetails:(NSString *)instructions
{
    int row = [tableView_actions selectedRow];
    NSString *details;

    details = [NSString alloc];
    
    if (row != -1)
        details = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS];

    [textField_description_textField setStringValue:instructions];
    [textField_description_popUp setStringValue:@""];
    [popUp_actionDetails setEnabled:NO];
    [textField_actionDetails setEnabled:YES];

    [textField_actionDetails setStringValue:(details ? details : @"")];
}

- (void) configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu
{
    int row = [tableView_actions selectedRow];
    [textField_description_popUp setStringValue:instructions];
    [textField_description_textField setStringValue:@""];
    [popUp_actionDetails setEnabled:YES];
    [textField_actionDetails setEnabled:NO];
    [popUp_actionDetails setMenu:detailsMenu];
    if (row != -1)
    {
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS]]];
    }
}

//used for each item of the eventMenu
- (NSMenuItem *)eventMenuItem:(NSString *)event withDisplay:(NSString *)displayName
{
    NSMenuItem *menuItem;
    NSMutableDictionary *menuDict;

    menuItem = [[[NSMenuItem alloc] initWithTitle:displayName
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    menuDict = [[NSMutableDictionary alloc] init];
    [menuDict setObject:displayName 	forKey:KEY_EVENT_DISPLAYNAME];
    [menuDict setObject:event 		forKey:KEY_EVENT_NOTIFICATION];
    [menuItem setRepresentedObject:menuDict];
    return menuItem;
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

//Builds and returns a dock behavior list menu
- (NSMenu *)behaviorListMenu
{
//    NSMenu		*behaviorMenu = [[[NSMenu alloc] init] autorelease];
    NSMenu		*behaviorMenu = [[NSMenu alloc] init];

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
    [menuItem setRepresentedObject:[[NSNumber numberWithInt:behavior] stringValue]];

    return(menuItem);
}

//The user selected a behavior
- (IBAction)selectBehavior:(id)sender
{
    NSString	*behavior = [sender representedObject];
    int row = [tableView_actions selectedRow];
    
    NSMutableDictionary	*selectedActionDict;

    selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    [selectedActionDict setObject:behavior forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    //Save event sound preferences
    [self saveEventActionArray];
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
        NSString	*event;
        NSString	*displayName;

        //Get the event string
        actionDict = [eventActionArray objectAtIndex:row];
        event = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];

        //Get that event's display name
        displayName = [actionDict objectForKey:KEY_EVENT_DISPLAYNAME];
        return(displayName ? displayName : event);

    }else if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSDictionary	*actionDict;
        NSString	*action;
        
        //Get the action string
        actionDict = [eventActionArray objectAtIndex:row];
        action = [actionDict objectForKey:KEY_EVENT_ACTION];

        return(action);

    }else{
        return(nil);
    }
}

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

        [self saveEventActionArray]; 
    }
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteEventAction:nil]; //Delete it
}

//selection changed; update the view
- (void)tableViewSelectionDidChange:(NSNotification *)aNotfication
{
    int row = [tableView_actions selectedRow];
    if (row != -1)
    {
        NSString *action = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_ACTION];
        [actionMenu performActionForItemAtIndex:[actionMenu indexOfItemWithRepresentedObject:action]];
    }
}

//editing is over
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    int row = [tableView_actions selectedRow];
    NSMutableDictionary	*selectedActionDict;

    selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    [selectedActionDict setObject:[textField_actionDetails stringValue] forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    [self saveEventActionArray];
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

- (void)dealloc
{
    [owner release];
    [activeContactObject release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_ALERTS_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

}
@end
