//
//  ESContactAlertsPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

#import "ESContactAlertsPreferences.h"
#import "ESContactAlertsPlugin.h"
#import "ESContactAlerts.h"

#define	ALERTS_PREF_NIB			@"ContactAlertsPrefs"
#define ALERTS_PREF_TITLE		AILocalizedString(@"Contact Alerts",nil)

#define TABLE_COLUMN_CONTACT		@"contact"
#define TABLE_COLUMN_ACTION		@"action"
#define TABLE_COLUMN_EVENT		@"event"

#define OFFLINE AILocalizedString(@"Offline",nil)

@interface ESContactAlertsPreferences (PRIVATE)
-(void)configureView;
-(void)configureViewForContact:(AIListObject *)inContact;
-(void)rebuildPrefAlertsArray;
-(NSMenu *)switchContactMenu;
@end

extern int alphabeticalGroupOfflineSort_contactAlerts(id objectA, id objectB, void *context);
int alphabeticalSort(id objectA, id objectB, void *context);

@implementation ESContactAlertsPreferences
+ (ESContactAlertsPreferences *)contactAlertsPreferences
{
    return([[[self alloc] init] autorelease]);
}

//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    //Init
    [super init];

    offsetDictionary = [[NSMutableDictionary alloc] init];
    
    instance = nil;
    ignoreSelectionChanges = NO;
    
    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Alerts withDelegate:self label:ALERTS_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:ALERTS_PREF_NIB owner:self];

        [view_prefView retain];

        //Configure our view
        [self configureView];

        [[adium notificationCenter] removeObserver:self];
        [[adium notificationCenter] addObserver:self selector:@selector(externalChangedAlerts:) name:Window_Changed_Alerts object:nil];
        [[adium notificationCenter] addObserver:self selector:@selector(externalChangedAlerts:) name:One_Time_Event_Fired object:nil];
        //Observe account changes
        [[adium notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [[adium notificationCenter] removeObserver:self];
    [view_prefView release]; view_prefView = nil;
    [prefAlertsArray release]; prefAlertsArray = nil;
    [activeContactObject release]; activeContactObject = nil;
    [instance release]; instance = nil;
}

- (void)dealloc
{
    [super dealloc];
}


//Configures our view for the current preferences, jumping to the indicated contact
- (void)configureView
{
    //Build the contact list
    [popUp_contactList setMenu:[self switchContactMenu]];
    if ([popUp_contactList numberOfItems]) {
        [popUp_contactList selectItemAtIndex:0];
        activeContactObject = [[popUp_contactList selectedItem] representedObject];
		NSLog(@"should be configuring for %@",[activeContactObject displayName]);
    }
    
    instance = [[ESContactAlerts alloc] initWithDetailsView:view_main withTable:tableView_actions withPrefView:view_prefView];

    [instance configForObject:activeContactObject];

    [actionColumn setInstance:instance];

    //Build the action menu
    actionMenu = [instance actionListMenu];

    [self rebuildPrefAlertsArray]; //needs to happen before any table commands

    //Configure the table view
    [tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setTarget:self];
    //    [tableView_actions setDoubleAction:@selector(testSelectedEvent:)];
    [tableView_actions setDataSource:self];

    [button_delete setEnabled:NO];
    [button_oneTime setEnabled:NO];
	[button_active setEnabled:NO];
		
    //Update the outline view
    [tableView_actions reloadData];

    //    [[[tableView_actions tableColumns] objectAtIndex:2] sizeToFit];
    //    [[[tableView_actions tableColumns] objectAtIndex:1] sizeToFit];
    //    [[[tableView_actions tableColumns] objectAtIndex:0] sizeToFit];

    if ([prefAlertsArray count]) { //some alerts do exist
        [tableView_actions selectRow:0 byExtendingSelection:NO];
    } else {
        //Build the event menu (for no contact)
        [popUp_addEvent setMenu:[instance eventMenu]];
    }

    [[view_prefView window] makeFirstResponder:tableView_actions]; //the table is a logical firstResponder for the all-alerts-at-once view
}

-(void)configureViewForContact:(AIListObject *)inContact
{
    if (inContact) //we've been passed a contact to jump to or begin editing
    {
        [activeContactObject release]; activeContactObject = inContact; [activeContactObject retain];
        [popUp_contactList selectItemAtIndex:[popUp_contactList indexOfItemWithRepresentedObject:activeContactObject]];

        int firstIndex = [prefAlertsArray indexOfObject:inContact];
        if (firstIndex == NSNotFound) {
            [instance configForObject:inContact];
            [popUp_addEvent setMenu:[instance eventMenu]];
        } else {
            [tableView_actions selectRow:firstIndex byExtendingSelection:NO];
        }
    }
    else { //got nil
        [tableView_actions selectRow:0 byExtendingSelection:NO];
    }
}

#warning Need to access contactList directly here in order to get groups in the commented-out area below
-(void)rebuildPrefAlertsArray
{
    int offset = 0;
    int arrayCounter;
    int thisInstanceCount;
    NSMutableArray *contactArray =  [[adium contactController] allContactsInGroup:nil subgroups:YES];
    [contactArray sortUsingFunction:alphabeticalGroupOfflineSort_contactAlerts context:nil];
    
    NSEnumerator    *enumerator = [contactArray objectEnumerator];
    NSString        *groupName = nil;
        
    [prefAlertsArray release]; prefAlertsArray = [[NSMutableArray alloc] init];

    AIListContact * contact;
    while (contact = [enumerator nextObject]) {
        /*
        AIListGroup * theGroup = [contact containingGroup];
        if ([[theGroup displayName] compare:groupName] != 0) {
            [instance configForObject:theGroup];
            thisInstanceCount = [instance count];
            if (thisInstanceCount) {
                [offsetDictionary setObject:[NSNumber numberWithInt:offset] forKey:[theGroup UID]];
                for (arrayCounter=0 ; arrayCounter < thisInstanceCount ; arrayCounter++) {
                    [prefAlertsArray addObject:theGroup];
                }
                offset += [instance count];
            }
            groupName = [theGroup displayName];
        }
        */
        
        [instance configForObject:contact];
        thisInstanceCount = [instance count];
        if (thisInstanceCount) {
			NSLog(@"setting %i for %@",offset,[contact UIDAndServiceID]);
            [offsetDictionary setObject:[NSNumber numberWithInt:offset] forKey:[contact UIDAndServiceID]];
            for (arrayCounter=0 ; arrayCounter < thisInstanceCount ; arrayCounter++) {
                [prefAlertsArray addObject:contact];
            }
            offset += [instance count];
        }
    }
}
-(IBAction)anInstanceChanged:(id)sender
{
    [self rebuildPrefAlertsArray];
    [self configureViewForContact:activeContactObject];
}

-(IBAction)oneTimeEvent:(id)sender
{
    [instance configForObject:activeContactObject];
    [instance oneTimeEvent:button_oneTime];
}

-(IBAction)onlyWhileActive:(id)sender
{
    [instance configForObject:activeContactObject];
    [instance onlyWhileActive:button_active];
}

-(IBAction)deleteEventAction:(id)sender
{    
	int currentRow = [instance currentRow];
    if (currentRow != -1)
    {
		int row = [tableView_actions selectedRow];
		
		[instance deleteEventAction:nil]; //delete the event from the instance
		[self rebuildPrefAlertsArray];
		[tableView_actions reloadData]; //necessary?
		
		if ( row < ([tableView_actions numberOfRows]-1) ) {
			[tableView_actions scrollRowToVisible:row];
			[tableView_actions selectRow:row byExtendingSelection:NO];   
			[self tableViewSelectionDidChange:nil]; //force it to realize the change
		}
		[[adium notificationCenter] postNotificationName:Pref_Changed_Alerts
												  object:activeContactObject
												userInfo:nil]; //notify that the change occured    
	}
}

//doesn't work for group yet because of contactInGroup
-(IBAction)addedEvent:(id)sender
{
/*    AIListObject * tempObject;
    NSString * UID = [activeContactObject UID];
    if ([activeContactObject isKindOfClass:[AIListContact class]]) {
        tempObject = [[adium contactController] contactWithService:[activeContactObject serviceID] UID:UID];
    } else {
        tempObject = [[adium contactController] groupInGroup:nil withUID:UID];
    }
*/
    ignoreSelectionChanges = YES;
    [self rebuildPrefAlertsArray];
    [tableView_actions reloadData];
    ignoreSelectionChanges = NO;
    
    [instance configForObject:activeContactObject];
    int index = [prefAlertsArray indexOfObjectIdenticalTo:activeContactObject] + [instance count] - 1;
    
    [tableView_actions scrollRowToVisible:index];
    [tableView_actions selectRow:index byExtendingSelection:NO];
    
    [self tableViewSelectionDidChange:nil]; //force it to realize the change
    
    [[adium notificationCenter] postNotificationName:Pref_Changed_Alerts
                                              object:[instance activeObject]
                                            userInfo:nil];
}

-(void)externalChangedAlerts:(NSNotification *)notification
{
    [self rebuildPrefAlertsArray];
    [tableView_actions reloadData]; //necessary?
}

-(void)accountListChanged:(NSNotification *)notification
{
    NSLog(@"account list changed");
    [popUp_contactList setMenu:[self switchContactMenu]];
    if ( activeContactObject && ([popUp_contactList indexOfItemWithRepresentedObject:activeContactObject] == -1) ) {
        if ([popUp_contactList numberOfItems] ) {
            [popUp_contactList selectItemAtIndex:0];
            activeContactObject = [[popUp_contactList selectedItem] representedObject];
        }
    }
}

//TableView datasource --------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([prefAlertsArray count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    AIListObject *object = [prefAlertsArray objectAtIndex:row];
    [instance configForObject:object];
    row -= [[offsetDictionary objectForKey:[object UIDAndServiceID]] intValue]; //acount for offset from here on out

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*actionDict;
        NSString	*displayName;
        actionDict = [instance dictAtIndex:row];
        //Get that event's display name
        displayName = [actionDict objectForKey:KEY_EVENT_DISPLAYNAME];

        [instance configForObject:activeContactObject];
        return(displayName);

    }else if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSDictionary	*actionDict;
        NSString	*action;
        //Get the action string
        actionDict = [instance dictAtIndex:row];
        action = [actionDict objectForKey:KEY_EVENT_ACTION];

        [instance configForObject:activeContactObject];
        return(action);

    }else if([identifier compare:TABLE_COLUMN_CONTACT] == 0){
        NSString *contact;
        contact = [[instance activeObject] longDisplayName]; //Milk switched to longDisplayName to differentiate people with two aliases.  (aliii?)

        [instance configForObject:activeContactObject];
        return (contact);
    }else{
        return(nil);
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        AIListObject *object = [prefAlertsArray objectAtIndex:row];
		
		//Configure the instance
        [instance configForObject:object];
		
		//Adjust row to be instance-relative
        row -= [[offsetDictionary objectForKey:[object UIDAndServiceID]] intValue];

		//Select the action in the menu
        [cell selectItemWithRepresentedObject:[[instance dictAtIndex:row] objectForKey:KEY_EVENT_ACTION]];

		//Reconfigure the instance to the active object
        [instance configForObject:activeContactObject];
    }
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
	
    if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSMenuItem			*selectedMenuItem;
        NSMutableDictionary	*selectedActionDict;
        NSString			*newAction;
        AIListObject		*listObject = [prefAlertsArray objectAtIndex:row];

        [instance configForObject:listObject];

        selectedMenuItem = (NSMenuItem *)[[[tableColumn dataCellForRow:row] menu] itemAtIndex:[object intValue]];

        row -= [[offsetDictionary objectForKey:[listObject UIDAndServiceID]] intValue]; //change row to account for offset
        selectedActionDict = [[instance dictAtIndex:row] mutableCopy];
        newAction = [selectedMenuItem representedObject];

        [selectedActionDict setObject:newAction forKey:KEY_EVENT_ACTION];
        [instance replaceDictAtIndex:row withDict:selectedActionDict]; //change the appropriate contact's alerts

        [instance currentRowIs:row]; //tell the instance which row is selected - setting the value will end up changing the row
        [instance configForObject:activeContactObject]; //switch back to our current contact (selectionDidChange should handle switching when necessary)
    }
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteEventAction:nil]; //Delete it, using the preferences view custom deleteEventAction (which calls the instance)
}

//selection changed; update the view
- (void)tableViewSelectionDidChange:(NSNotification *)aNotfication
{
    int row = [tableView_actions selectedRow];
    if (row != -1) { //a row is selected
		AIListObject	*object = [prefAlertsArray objectAtIndex:row];
		NSDictionary	*selectedActionDict;
		NSString		*action;
		int				actionIndex;
		
        activeContactObject = object;
		
		//Correct for the offset so that row is in terms the instance can handle
        row -= [[offsetDictionary objectForKey:[object UIDAndServiceID]] intValue];

        [popUp_contactList selectItemWithRepresentedObject:activeContactObject];

		//tell the instance which contact and relative row is selected
        [instance configForObject:activeContactObject];
        [instance currentRowIs:row]; 

        //rebuild the event menu to apply to this instance
        [popUp_addEvent setMenu:[instance eventMenu]];

		selectedActionDict = [[[instance dictAtIndex:row] copy] autorelease];
        action = [selectedActionDict objectForKey:KEY_EVENT_ACTION];

		//Find the action associated with the newly selected event and perform its action if possible
		actionIndex = [actionMenu indexOfItemWithRepresentedObject:action];
		if (actionIndex != -1)
			[[[actionColumn dataCellForRow:row] menu] performActionForItemAtIndex:actionIndex]; //will appply appropriate subview in the process
        
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
        [button_active setEnabled:NO];
    }

}

- (BOOL)shouldSelectRow:(int)inRow
{
    return(YES);
}

#warning Another copy of the Menu That Can Not Work
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
        NSString 	*groupName = [[[NSString alloc] init] autorelease];
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
            #ifdef MAC_OS_X_VERSION_10_3
            if ([menuItem respondsToSelector:@selector(setIndentationLevel:)])
                [menuItem setIndentationLevel:1];
            #endif
            [menuItem setRepresentedObject:contact];

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
                if ( !([[contact statusArrayForKey:@"Online"] intValue]) ) //look for the first offline contact
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

   //         groupName = [[contact containingGroup] displayName];
        }
        [contactMenu setAutoenablesItems:NO];
    }
    return contactMenu;
}


- (IBAction)switchToContact:(id) sender
{
    [self configureViewForContact:[sender representedObject]];
    activeContactObject = [sender representedObject];
}

- (void)testSelectedEvent
{
    //action to take when action is double-clicked in the window
}

int alphabeticalSort(id objectA, id objectB, void *context)
{
    BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];

    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }else{
        return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
    }
}

@end
