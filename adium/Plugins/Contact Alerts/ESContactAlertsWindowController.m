//
//  ESContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsWindowController.h"
#import "ESContactAlerts.h"
#import "ESContactAlertsPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define CONTACT_ALERT_WINDOW_NIB	@"ContactAlerts"
#define TABLE_COLUMN_ACTION		@"action"
#define TABLE_COLUMN_EVENT		@"event"

@interface ESContactAlertsWindowController (PRIVATE)
- (void)configureWindowforObject:(AIListObject *)inContact;
- (void)configureView;
- (NSMenu *)switchContactMenu;

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)shouldSelectRow:(int)inRow;
- (id)initWithOwner:(id)inOwner forPlugin:(id)inPlugin;
@end

int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context);

@implementation ESContactAlertsWindowController
//Open a new info window
static ESContactAlertsWindowController *sharedInstance = nil;
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
        [instance removeAllSubviews:view_main];
        //Save the window position
        [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                             forKey:KEY_CONTACT_ALERTS_WINDOW_FRAME
                                              group:PREF_GROUP_WINDOW_POSITIONS];
        [instance release];
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

    //Build the contact list
    [popUp_contactList setMenu:[self switchContactMenu]];
    [popUp_contactList selectItemAtIndex:[popUp_contactList indexOfItemWithRepresentedObject:activeContactObject]];

    [instance release];
    instance = [[ESContactAlerts alloc] initForObject:activeContactObject withDetailsView:view_main withTable:tableView_actions withPrefView:nil owner:owner];
    [instance retain];

    //Build the event menu
    [popUp_addEvent setMenu:[instance eventMenu]];

    //Build the action menu
    actionMenu = [instance actionListMenu];

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
 //   [tableView_actions retain];

    [button_delete setEnabled:NO];
    [button_oneTime setEnabled:NO];

    if ([instance hasAlerts])
    {
        [tableView_actions selectRow:0 byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }

    //Update the outline view
    [tableView_actions reloadData];
}

-(IBAction)oneTimeEvent:(id)sender
{
    [instance oneTimeEvent:button_oneTime];
}

-(IBAction)deleteEventAction:(id)sender
{
    [instance deleteEventAction:nil];
    [self tableViewSelectionDidChange:nil];
}


//TableView datasource --------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([instance count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*actionDict;
        NSString	*event;
        NSString	*displayName;

        //Get the event string
        actionDict = [instance dictAtIndex:row];
        event = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];

        //Get that event's display name
        displayName = [actionDict objectForKey:KEY_EVENT_DISPLAYNAME];
        return(displayName ? displayName : event);

    }else if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSDictionary	*actionDict;
        NSString	*action;

        //Get the action string
        actionDict = [instance dictAtIndex:row];
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
        [cell selectItemWithRepresentedObject:[[instance dictAtIndex:row] objectForKey:KEY_EVENT_ACTION]];
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
        selectedActionDict = [[instance dictAtIndex:row] mutableCopy];
        newAction = [selectedMenuItem representedObject];

        [selectedActionDict setObject:newAction forKey:KEY_EVENT_ACTION];
        [instance replaceDictAtIndex:row withDict:selectedActionDict];
    }
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [instance deleteEventAction:nil]; //Delete it
}

//selection changed; update the view
- (void)tableViewSelectionDidChange:(NSNotification *)aNotfication
{
    int row = [tableView_actions selectedRow];
    [instance currentRowIs:row]; //tell the instance which row is selected

    if (row != -1) //a row is selected
    {
        NSDictionary * selectedActionDict = [instance dictAtIndex:row];
        NSString *action = [selectedActionDict objectForKey:KEY_EVENT_ACTION];
        [actionMenu performActionForItemAtIndex:[actionMenu indexOfItemWithRepresentedObject:action]]; //will appply appropriate subview in the process
        [button_oneTime setState:[[selectedActionDict objectForKey:KEY_EVENT_DELETE] intValue]];

        [button_delete setEnabled:YES];
        [button_oneTime setEnabled:YES];
    }
    else //no selection
    {
        [instance configureWithSubview:nil];
        [button_delete setEnabled:NO];
        [button_oneTime setEnabled:NO];
    }

}


- (BOOL)shouldSelectRow:(int)inRow
{
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
    [popUp_addEvent release];
    [instance release];
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Restore the window position
    NSSize minimum = [[self window] minSize];
    NSRect defaultFrame = [[self window] frame];
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_ALERTS_WINDOW_FRAME];

    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
        NSRect newFrame = [[self window] frame];
        //NSLog(@"1: %d  2: %d",newFrame.size.height,defaultFrame.size.height);
        newFrame.size.height = defaultFrame.size.height;
        [[self window] setFrame:newFrame display:YES];
        [[self window] setMinSize:minimum];
    }else{
        [[self window] center];
    }
}

//builds an alphabetical menu of contacts for all online accounts; online contacts are sorted to the top and seperated
//from offline ones by a seperator reading "Offline"
//uses alphabeticalGroupOfflineSort and calls switchToContact: when a selection is made
- (NSMenu *)switchContactMenu
{
    NSMenu		*contactMenu = [[NSMenu alloc] init];
    //Build the menu items
    NSMutableArray		*contactArray =  [[owner contactController] allContactsInGroup:nil subgroups:YES];
    [contactArray sortUsingFunction:alphabeticalGroupOfflineSort context:nil]; //online buddies will end up at the top, alphabetically

    NSEnumerator 	*enumerator = 	[contactArray objectEnumerator];
    AIListObject	*contact;
    BOOL		firstOfflineSearch = NO;

    contact = [contactArray objectAtIndex:0];
    if ( !([[contact statusArrayForKey:@"Online"] greatestIntegerValue]) ) //the first contact is offline
    {
        NSMenuItem	*separatorItem;
        separatorItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
                                                    target:nil
                                                    action:nil
                                             keyEquivalent:@""] autorelease];
        [separatorItem setEnabled:NO];
        [contactMenu addItem:separatorItem]; //add the group object manually
        firstOfflineSearch = YES; //start off adding the Offline object algorithmically
    }

    while (contact = [enumerator nextObject])
    {
        NSMenuItem		*menuItem;
        NSString	 	*itemDisplay;
        NSString		*itemUID = [contact UID];
        itemDisplay = [contact displayName];
        if ( !([itemDisplay compare:itemUID] == 0) ) //display name and screen name aren't the same
            itemDisplay = [NSString stringWithFormat:@"%@ (%@)",itemDisplay,itemUID]; //show the UID along with the display name
        menuItem = [[[NSMenuItem alloc] initWithTitle:itemDisplay
                                               target:self
                                               action:@selector(switchToContact:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:contact];
        if (firstOfflineSearch)
        {
            if ( !([[contact statusArrayForKey:@"Online"] greatestIntegerValue]) ) //look for the first offline contact
            {
                NSMenuItem	*separatorItem;
                separatorItem = [[[NSMenuItem alloc] initWithTitle:@"Offline"
                                                            target:nil
                                                            action:nil
                                                     keyEquivalent:@""] autorelease];
                [separatorItem setEnabled:NO];
                [contactMenu addItem:separatorItem];
                firstOfflineSearch = NO; //search for an online contact
            }
        }
        else
        {
            if ( ([[contact statusArrayForKey:@"Online"] greatestIntegerValue]) ) //look for the first online contact
            {
                NSMenuItem	*separatorItem;
                separatorItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
                                                            target:nil
                                                            action:nil
                                                     keyEquivalent:@""] autorelease];
                [separatorItem setEnabled:NO];
                [contactMenu addItem:separatorItem];
                firstOfflineSearch = YES; //start searching for an offline contact
            }
        }
        [contactMenu addItem:menuItem];
    }
    [contactMenu setAutoenablesItems:NO];

    return contactMenu;
}


- (IBAction) switchToContact:(id) sender
{
    [sharedInstance configureWindowforObject:[sender representedObject]];
}
- (void)testSelectedEvent
{
    //action to take when action is double-clicked in the window
}


@end