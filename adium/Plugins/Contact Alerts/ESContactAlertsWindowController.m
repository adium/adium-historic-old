//
//  ESContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsWindowController.h"
#import "ESContactAlerts.h"
#import "ESContactAlertsPlugin.h"

#define CONTACT_ALERT_WINDOW_NIB	@"ContactAlerts"
#define TABLE_COLUMN_ACTION		@"action"
#define TABLE_COLUMN_EVENT		@"event"

#define OFFLINE AILocalizedString(@"Offline",nil)

@interface ESContactAlertsWindowController (PRIVATE)
- (void)initialWindowConfig;
- (void)configureWindowforObject:(AIListObject *)inContact;
- (void)configureView;
- (NSMenu *)switchContactMenu;

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)shouldSelectRow:(int)inRow;
- (id)initForPlugin:(id)inPlugin;
@end

extern int alphabeticalGroupOfflineSort_contactAlerts(id objectA, id objectB, void *context);

@implementation ESContactAlertsWindowController
//Open a new info window
static ESContactAlertsWindowController *sharedInstance = nil;
+ (id)showContactAlertsWindowForObject:(AIListObject *)inContact
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_ALERT_WINDOW_NIB];
        [sharedInstance initialWindowConfig];
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

        [[adium notificationCenter] removeObserver:self]; //remove all observers

        [instance removeAllSubviews:view_main];
        //Save the window position
        [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                             forKey:KEY_CONTACT_ALERTS_WINDOW_FRAME
                                              group:PREF_GROUP_WINDOW_POSITIONS];
        [instance release]; instance = nil;
        [[self window] close];
    }
}

- (void)initialWindowConfig
{
    //Make sure our window is loaded
    [self window];
    [popUp_contactList setMenu:[self switchContactMenu]];
    
    instance = [[ESContactAlerts alloc] initWithDetailsView:view_main withTable:tableView_actions withPrefView:nil];
    [instance retain];
    
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    
    //Configure the table view
    [tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setTarget:self];
    [tableView_actions setDoubleAction:@selector(testSelectedEvent:)];
    [tableView_actions setDataSource:self];
    [[self window] makeFirstResponder:tableView_actions];
}

//Configure the actions window for the specified contact
- (void)configureWindowforObject:(AIListObject *)inContact
{
    //Remember who we're displaying actions for
    [activeContactObject release]; activeContactObject = [inContact retain];
    //Observers
    [[adium notificationCenter] removeObserver:self]; //remove any previous observers

    //Observe account changes
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(accountListChanged:) 
									   name:Account_ListChanged 
									 object:nil];

    [[adium notificationCenter] addObserver:self
								   selector:@selector(externalChangedAlerts:) 
									   name:Pref_Changed_Alerts 
									 object:activeContactObject];
    [[adium notificationCenter] addObserver:self
								   selector:@selector(externalChangedAlerts:) 
									   name:One_Time_Event_Fired 
									 object:activeContactObject];

    //Set window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@'s %@",[activeContactObject displayName],AILocalizedString(@"Alerts",nil)]];

    //Build the contact list
	int index = [popUp_contactList indexOfItemWithRepresentedObject:activeContactObject];
	if (index != NSNotFound)
		[popUp_contactList selectItemAtIndex:index];

    [instance configForObject:activeContactObject];

    //Build the event menu
    [popUp_addEvent setMenu:[instance eventMenu]];

    //Build the action menu
    actionMenu = [instance actionListMenu];

    //Configure the 'Action' table column data cell
    [dataCell setMenu:actionMenu];
    [[tableView_actions tableColumnWithIdentifier:TABLE_COLUMN_ACTION] setDataCell:dataCell];

    [button_delete setEnabled:NO];
    [button_oneTime setEnabled:NO];
	[button_active setEnabled:NO];
		
    if ([instance hasAlerts])
    {
        [tableView_actions selectRow:0 byExtendingSelection:NO];
 //       [self tableViewSelectionDidChange:nil];
    }

    //Update the outline view
    [tableView_actions reloadData];


    //    [[[tableView_actions tableColumns] objectAtIndex:1] sizeToFit];
    //    [[[tableView_actions tableColumns] objectAtIndex:0] sizeToFit];
}

-(IBAction)oneTimeEvent:(id)sender
{
    [instance oneTimeEvent:button_oneTime];
}

-(IBAction)onlyWhileActive:(id)sender
{
    [instance onlyWhileActive:button_active];
}

-(IBAction)deleteEventAction:(id)sender
{
    int currentRow = [instance currentRow];
    if (currentRow != -1)
    {
		[instance deleteEventAction:nil];
		[tableView_actions reloadData];
		if (currentRow < [instance count]){
			[tableView_actions selectRow:currentRow byExtendingSelection:NO];
		} else if ([instance count]){
			[tableView_actions selectRow:([instance count]-1) byExtendingSelection:NO];
		} else {
			[tableView_actions deselectRow:currentRow]; }
		
        [[adium notificationCenter] postNotificationName:Window_Changed_Alerts
                                                  object:activeContactObject
                                                userInfo:nil];
    }
}

-(IBAction)addedEvent:(id)sender
{
    [tableView_actions reloadData];
    [tableView_actions selectRow:([instance count]-1) byExtendingSelection:NO]; //select the new event

    [[adium notificationCenter] postNotificationName:Window_Changed_Alerts
                                              object:activeContactObject
                                            userInfo:nil];
}

-(void)externalChangedAlerts:(NSNotification *)notification
{
    [instance reload:activeContactObject usingCache:NO];
    [tableView_actions reloadData];
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

        selectedMenuItem = (NSMenuItem *)[[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedActionDict = [[instance dictAtIndex:row] mutableCopy];
        newAction = [selectedMenuItem representedObject];

        [selectedActionDict setObject:newAction forKey:KEY_EVENT_ACTION];
        [instance replaceDictAtIndex:row withDict:selectedActionDict];
        [instance currentRowIs:row]; //tell the instance which row is selected - setting the value will end up changing the row
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

    [instance currentRowIs:row]; //tell the instance which row is selected

    if (row != -1) //a row is selected
    {
        NSDictionary * selectedActionDict = [instance dictAtIndex:row];
        NSString *action = [selectedActionDict objectForKey:KEY_EVENT_ACTION];

        [actionMenu performActionForItemAtIndex:[actionMenu indexOfItemWithRepresentedObject:action]]; //will appply appropriate subview in the process
        [button_oneTime setState:[[selectedActionDict objectForKey:KEY_EVENT_DELETE] intValue]];
        [button_active setState:[[selectedActionDict objectForKey:KEY_EVENT_ACTIVE] intValue]];

        [button_delete setEnabled:YES];
        [button_oneTime setEnabled:YES];
        [button_active setEnabled:YES];
    }

    else //no selection
    {
        [instance configureWithSubview:nil];
        [button_delete setEnabled:NO];
        [button_oneTime setEnabled:NO];
        [button_oneTime setState:NSOffState];
        [button_active setEnabled:NO];
        [button_active setState:NSOffState];
    }

}


- (BOOL)shouldSelectRow:(int)inRow
{
    return(YES);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    return(self);
}

- (void)dealloc
{
    [activeContactObject release]; activeContactObject = nil;
    [popUp_addEvent release]; popUp_addEvent = nil;
    [instance release]; instance = nil;
    [dataCell release]; dataCell = nil;
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Restore the window position
    NSSize minimum = [[self window] minSize];
    NSRect defaultFrame = [[self window] frame];
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_ALERTS_WINDOW_FRAME];

    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
        NSRect newFrame = [[self window] frame];
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
    NSMutableArray		*contactArray =  [[adium contactController] allContactsInGroup:nil subgroups:YES];
    if ([contactArray count])
    {
        [contactArray sortUsingFunction:alphabeticalGroupOfflineSort_contactAlerts context:nil]; //online buddies will end up at the top, alphabetically

        NSEnumerator 	*enumerator = 	[contactArray objectEnumerator];
        AIListObject	*contact;
//        NSString 	*groupName = [[[NSString alloc] init] autorelease];
        BOOL		firstOfflineSearch = NO;

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

            #ifdef MAC_OS_X_VERSION_10_3
            if ([menuItem respondsToSelector:@selector(setIndentationLevel:)])
                [menuItem setIndentationLevel:1];
            #endif

                    
#warning Groups can not go into the menu this way anymore...
            /*
            if ([groupName compare:[[contact containingGroup] displayName]] != 0)
            {
                NSMenuItem	*groupItem;
                if ([contactMenu numberOfItems] > 0) [contactMenu addItem:[NSMenuItem separatorItem]];
                groupItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
                                                        target:self
                                                        action:@selector(switchToContact:)
                                                 keyEquivalent:@""] autorelease];
                [groupItem setRepresentedObject:[contact containingGroup]];
                #ifdef MAC_OS_X_VERSION_10_3
                if ([menuItem respondsToSelector:@selector(setIndentationLevel:)])
                    [groupItem setIndentationLevel:0];
                 #endif
                [contactMenu addItem:groupItem];
                firstOfflineSearch = YES; //start searching for an offline contact
            }
*/
            if (firstOfflineSearch)
            {
                if ( !([contact integerStatusObjectForKey:@"Online"]) ) //look for the first offline contact
                {
                    NSMenuItem	*separatorItem;
                    separatorItem = [[[NSMenuItem alloc] initWithTitle:OFFLINE
                                                                target:nil
                                                                action:nil
                                                         keyEquivalent:@""] autorelease];
                    [separatorItem setEnabled:NO];
                    [contactMenu addItem:separatorItem];
                    firstOfflineSearch = NO;
                }
            }

            [contactMenu addItem:menuItem];

            //XXX EDS
//            groupName = [[contact containingGroup] displayName];
        }
        [contactMenu setAutoenablesItems:NO];
    }
    return contactMenu;
}

- (void)accountListChanged:(NSNotification *)notification
{
    //    NSLog(@"accountListChanged");
    [popUp_contactList setMenu:[self switchContactMenu]];
    if ( activeContactObject && ([popUp_contactList indexOfItemWithRepresentedObject:activeContactObject] == -1) ) {
        if ([popUp_contactList numberOfItems] ) {
            [popUp_contactList selectItemAtIndex:0];
            activeContactObject = [[popUp_contactList selectedItem] representedObject];
        }
    }
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