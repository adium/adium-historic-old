//
//  ESContactAlertsPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

#import "ESContactAlertsPreferences.h"
#import "ESContactAlertsPlugin.h"
#import "ESContactAlerts.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define	ALERTS_PREF_NIB			@"ContactAlertsPrefs"
#define ALERTS_PREF_TITLE		@"Contact Alerts"

#define TABLE_COLUMN_CONTACT		@"contact"
#define TABLE_COLUMN_ACTION		@"action"
#define TABLE_COLUMN_EVENT		@"event"


@interface ESContactAlertsPreferences (PRIVATE)
-(id)initWithOwner:(id)inOwner;
-(void)configureView;
-(void)configureViewForContact:(AIListObject *)inContact;
-(void)rebuildPrefAlertsArray;
-(NSMenu *)switchContactMenu;
@end

int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context);
int alphabeticalSort(id objectA, id objectB, void *context);

@implementation ESContactAlertsPreferences
+ (ESContactAlertsPreferences *)contactAlertsPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Alerts withDelegate:self label:ALERTS_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:ALERTS_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;

}

//Configures our view for the current preferences, jumping to the indicated contact
- (void)configureView
{
    activeContactObject = nil;
    //Build the contact list
    [popUp_contactList setMenu:[self switchContactMenu]];

#warning is the next bit needed?
    ESContactAlerts * thisInstance = [[ESContactAlerts alloc] init];
    //Build the event menu

    [popUp_addEvent setMenu:[thisInstance eventMenu]];
    //Build the action menu

    actionMenu = [thisInstance actionListMenu];


    //Configure the 'Action' table column
    NSPopUpButtonCell			*dataCell;
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:actionMenu];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_actions tableColumnWithIdentifier:TABLE_COLUMN_ACTION] setDataCell:dataCell];



    [self rebuildPrefAlertsArray]; //needs to happen before any table commands

    //Configure the table view
    [tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_actions setTarget:self];
    [tableView_actions setDoubleAction:@selector(testSelectedEvent:)];
    [tableView_actions setDataSource:self];
    [tableView_actions retain];

    [button_delete setEnabled:NO];
    [button_oneTime setEnabled:NO];

    if ([prefAlertsArray count]) //no specific contact, but some alerts do exist
    {
        [tableView_actions selectRow:0 byExtendingSelection:NO];
        [self tableViewSelectionIsChanging:nil];
    }

    //Update the outline view
    [tableView_actions reloadData];

}

-(void)configureViewForContact:(AIListObject *)inContact
{
    if (inContact) //we've been passed a contact to jump to or begin editing
    {
        [activeContactObject release]; activeContactObject = inContact; [activeContactObject retain];
        [popUp_contactList selectItemAtIndex:[popUp_contactList indexOfItemWithRepresentedObject:activeContactObject]];

        instance = [[ESContactAlerts alloc] initForObject:inContact withDetailsView:view_main withTable:tableView_actions withPrefView:view_prefView owner:owner];
        int firstIndex = [prefAlertsArray indexOfObject:instance];
        if (firstIndex == NSNotFound)
        {
            [popUp_addEvent setMenu:[instance eventMenu]];
        }
        else
        {
            [tableView_actions selectRow:firstIndex byExtendingSelection:NO];
            [self tableViewSelectionIsChanging:nil];
        }
    }
    else //got nil
    {
        [tableView_actions selectRow:0 byExtendingSelection:NO];
        [self tableViewSelectionIsChanging:nil];
    }
}

-(void)rebuildPrefAlertsArray
{
    int offset = 0;
    int arrayCounter;
    NSMutableArray *contactArray =  [[owner contactController] allContactsInGroup:nil subgroups:YES];
    [contactArray sortUsingFunction:alphabeticalSort context:nil];
    NSEnumerator 	*enumerator = 	[contactArray objectEnumerator];

    [prefAlertsArray release];
    prefAlertsArray = [[NSMutableArray alloc] init];
    [prefAlertsArray retain];

    AIListContact * contact;
    while (contact = [enumerator nextObject])
    {
        ESContactAlerts * thisInstance = [[ESContactAlerts alloc] initForObject:contact withDetailsView:view_main withTable:tableView_actions withPrefView:view_prefView owner:owner];
        [thisInstance setOffset:offset];
        //    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[plugin,[contact UID]];
        for (arrayCounter=0 ; arrayCounter<[thisInstance count] ; arrayCounter++)
        {
            [prefAlertsArray addObject:thisInstance];
        }
        offset += [thisInstance count];
    }
}

-(IBAction)oneTimeEvent:(id)sender
{
    [instance oneTimeEvent:button_oneTime];
}

-(IBAction)deleteEventAction:(id)sender
{

    int index = [prefAlertsArray indexOfObject:instance];
    [prefAlertsArray removeObjectAtIndex:index]; //take one instance for this contact out of our array
    index += [instance count] - 1;
    NSLog(@"indexofobject %i ; instance count %i ; index %i ; currentRow %i",[prefAlertsArray indexOfObject:instance],[instance count],index,[instance currentRow]);
    NSRange theRange;

    theRange.length = [prefAlertsArray count] - index;
    if (theRange.length > 0) //this isn't the last one
    {
        theRange.location = index;

        NSMutableSet * prefAlertsSet = [[NSMutableSet alloc] init];
        [prefAlertsSet addObjectsFromArray:[prefAlertsArray subarrayWithRange:theRange]]; //each instance past the instance we just modified is now in prefAlertsSet


        ESContactAlerts * thisInstance;
        NSEnumerator * enumerator = [prefAlertsSet objectEnumerator];
        while (thisInstance = [enumerator nextObject])
        {
            [thisInstance changeOffsetBy:1]; //tell each instance it has one less offset
        }
    }
    [instance deleteEventAction:nil]; //delete the event from the instance

    [self tableViewSelectionIsChanging:nil];

}

//optimize me!! -eds
-(IBAction)addedEvent:(id)sender
{
    [self rebuildPrefAlertsArray];
    [tableView_actions reloadData];

    int firstIndex = [prefAlertsArray indexOfObject:instance];
    [tableView_actions selectRow:(firstIndex + [instance count] - 1) byExtendingSelection:NO];
    [self tableViewSelectionIsChanging:nil];

    //Update the outline view

}

//TableView datasource --------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([prefAlertsArray count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*actionDict;
        NSString	*event;
        NSString	*displayName;
        ESContactAlerts * thisInstance = [prefAlertsArray objectAtIndex:row];
        //Get the event string
        actionDict = [thisInstance dictAtIndex:row];
        event = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];

        //Get that event's display name
        displayName = [actionDict objectForKey:KEY_EVENT_DISPLAYNAME];
        return(displayName ? displayName : event);

    }else if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSDictionary	*actionDict;
        NSString	*action;
        ESContactAlerts * thisInstance = [prefAlertsArray objectAtIndex:row];

        //Get the action string
        actionDict = [thisInstance dictAtIndex:row];
        action = [actionDict objectForKey:KEY_EVENT_ACTION];

        return(action);

    }else if([identifier compare:TABLE_COLUMN_CONTACT] == 0){
        NSString *contact;
        ESContactAlerts * thisInstance = [prefAlertsArray objectAtIndex:row];
        contact = [[thisInstance activeObject] displayName]; //just the display name for now
        return (contact);
    }else
    {
        return(nil);
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    if([identifier compare:TABLE_COLUMN_ACTION] == 0){

        ESContactAlerts * thisInstance = [prefAlertsArray objectAtIndex:row];
        [cell selectItemWithRepresentedObject:[[thisInstance dictAtIndex:row] objectForKey:KEY_EVENT_ACTION]];
    }
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSMenuItem		*selectedMenuItem;
        NSMutableDictionary	*selectedActionDict;
        NSString		*newAction;

        ESContactAlerts * thisInstance = [prefAlertsArray objectAtIndex:row];

        selectedMenuItem = [[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedActionDict = [[thisInstance dictAtIndex:row] mutableCopy];
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
//- (void)tableViewSelectionDidChange:(NSNotification *)aNotfication
- (void)tableViewSelectionIsChanging:(NSNotification *)aNotfication
{
    int row = [tableView_actions selectedRow];
    NSLog(@"row = %d",row);

    if (row != -1) //a row is selected
    {
        instance = [prefAlertsArray objectAtIndex:row];

        [instance currentRowIs:row]; //tell the instance which row is selected

        //(re)Build the event menu
        [popUp_addEvent setMenu:[instance eventMenu]];

        //(re)Build the action menu
        actionMenu = [instance actionListMenu];

        //(re)Configure the 'Action' table column
        NSPopUpButtonCell			*dataCell;
        dataCell = [[AITableViewPopUpButtonCell alloc] init];
        [dataCell setMenu:actionMenu];
        [dataCell setControlSize:NSSmallControlSize];
        [dataCell setFont:[NSFont menuFontOfSize:11]];
        [dataCell setBordered:NO];
        [[tableView_actions tableColumnWithIdentifier:TABLE_COLUMN_ACTION] setDataCell:dataCell];

        NSDictionary * selectedActionDict = [instance dictAtIndex:row];
        NSString *action = [selectedActionDict objectForKey:KEY_EVENT_ACTION];
        [actionMenu performActionForItemAtIndex:[actionMenu indexOfItemWithRepresentedObject:action]]; //will appply appropriate subview in the process
        [button_oneTime setState:[[selectedActionDict objectForKey:KEY_EVENT_DELETE] intValue]];

        [button_delete setEnabled:YES];
        [button_oneTime setEnabled:YES];

        //Update the outline view
        [tableView_actions reloadData];
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

- (void)dealloc
{
    [owner release];
    [activeContactObject release];
    [popUp_addEvent release];
    [super dealloc];
}

//builds an alphabetical menu of contacts for all online accounts; online contacts are sorted to the top and seperated
//from offline ones by a seperator reading "Offline"
//uses alphabeticalGroupOfflineSort and calls switchToContact: when a selection is made
- (NSMenu *)switchContactMenu
{
    NSMenu		*contactMenu = [[NSMenu alloc] init];
    //Build the menu items
    NSMutableArray		*contactArray =  [[owner contactController] allContactsInGroup:nil subgroups:YES];
    if ([contactArray count])
    {
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
    }
    return contactMenu;
}


- (IBAction) switchToContact:(id) sender
{
    [self configureViewForContact:[sender representedObject]];
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
