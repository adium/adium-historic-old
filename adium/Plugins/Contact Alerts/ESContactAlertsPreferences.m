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

    offsetDictionary = [[NSMutableDictionary alloc] init];
    
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

        [view_prefView retain];
        
        //Configure our view
        [self configureView];

        [[owner notificationCenter] addObserver:self selector:@selector(externalChangedAlerts:) name:Window_Changed_Alerts object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(externalChangedAlerts:) name:One_Time_Event_Fired object:nil];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [[owner notificationCenter] removeObserver:self];
    
    [view_prefView release]; view_prefView = nil;
    
    [prefAlertsArray release]; prefAlertsArray = nil;
    [activeContactObject release];
    [instance release];
}

//Configures our view for the current preferences, jumping to the indicated contact
- (void)configureView
{
    //Build the contact list
    [popUp_contactList setMenu:[self switchContactMenu]];
    if ([popUp_contactList numberOfItems] )
    {
        [popUp_contactList selectItemAtIndex:0];
        activeContactObject = [[popUp_contactList selectedItem] representedObject];
    }

    instance = [[ESContactAlerts alloc] initWithDetailsView:view_main withTable:tableView_actions withPrefView:view_prefView owner:owner];
    [instance retain];

    [instance configForObject:activeContactObject];
    
    [actionColumn setInstance:instance];
    
    //Build the action menu
    actionMenu = [instance actionListMenu];

    [self rebuildPrefAlertsArray]; //needs to happen before any table commands

    //Configure the table view
    [tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_actions setTarget:self];
//    [tableView_actions setDoubleAction:@selector(testSelectedEvent:)];
    [tableView_actions setDataSource:self];

    [button_delete setEnabled:NO];
    [button_oneTime setEnabled:NO];

    //Update the outline view
    [tableView_actions reloadData];
    
//    [[[tableView_actions tableColumns] objectAtIndex:2] sizeToFit];
//    [[[tableView_actions tableColumns] objectAtIndex:1] sizeToFit];
//    [[[tableView_actions tableColumns] objectAtIndex:0] sizeToFit];
    
    if ([prefAlertsArray count]) //some alerts do exist
    {
        [tableView_actions selectRow:0 byExtendingSelection:NO];
    }
    else
    {
        //Build the event menu (for no contact)
        [popUp_addEvent setMenu:[instance eventMenu]];
    }

}

-(void)configureViewForContact:(AIListObject *)inContact
{
    if (inContact) //we've been passed a contact to jump to or begin editing
    {
        [activeContactObject release]; activeContactObject = inContact; [activeContactObject retain];
        [popUp_contactList selectItemAtIndex:[popUp_contactList indexOfItemWithRepresentedObject:activeContactObject]];

        int firstIndex = [prefAlertsArray indexOfObject:inContact];
        if (firstIndex == NSNotFound)
        {
            [instance configForObject:inContact];
            [popUp_addEvent setMenu:[instance eventMenu]];
        }
        else
        {
            [tableView_actions selectRow:firstIndex byExtendingSelection:NO];
        }
    }
    else //got nil
    {
        [tableView_actions selectRow:0 byExtendingSelection:NO];
    }
}

-(void)rebuildPrefAlertsArray
{
    int offset = 0;
    int arrayCounter;
    int thisInstanceCount;
    NSMutableArray *contactArray =  [[owner contactController] allContactsInGroup:nil subgroups:YES];
    [contactArray sortUsingFunction:alphabeticalSort context:nil];
    NSEnumerator 	*enumerator = 	[contactArray objectEnumerator];

    [prefAlertsArray release];
    prefAlertsArray = [[NSMutableArray alloc] init];
    [prefAlertsArray retain];

    AIListContact * contact;
    while (contact = [enumerator nextObject])
    {
        [instance configForObject:contact];
        thisInstanceCount = [instance count];
        if (thisInstanceCount) 
        {
            [offsetDictionary setObject:[NSNumber numberWithInt:offset] forKey:[contact UID]];
            for (arrayCounter=0 ; arrayCounter < thisInstanceCount ; arrayCounter++)
            {
                [prefAlertsArray addObject:contact];
            }
            offset += [instance count];
        }
    }
}

-(IBAction)anInstanceChanged:(id)sender
{
//    AIListObject * object = [[instance activeObject] autorelease];
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
    if ([tableView_actions selectedRow] != -1) 
    {
        [instance configForObject:activeContactObject];
        
        AIListObject *activeObject = activeContactObject; //store it now so we'll be okay if deletion releases the instance

        int index = [prefAlertsArray indexOfObject:activeObject];

    [instance deleteEventAction:nil]; //delete the event from the instance
        int count = [instance count]; //store new count now
        
    [[owner notificationCenter] postNotificationName:Pref_Changed_Alerts
                                              object:activeObject
                                            userInfo:nil]; //notify that the change occured

    [prefAlertsArray removeObjectAtIndex:index]; //take one instance for this contact out of our array
    
    index += count;
    NSRange theRange;

    theRange.length = [prefAlertsArray count] - index;
    if (theRange.length > 0) //this isn't the last one
    {
        theRange.location = index;

        NSMutableSet * prefAlertsSet = [[NSMutableSet alloc] init];
        [prefAlertsSet addObjectsFromArray:[prefAlertsArray subarrayWithRange:theRange]]; //each instance past the instance we just modified is now in prefAlertsSet

        NSEnumerator * enumerator = [prefAlertsSet objectEnumerator];
        AIListObject * thisObject;
        while (thisObject = [enumerator nextObject])
        {
            NSString * UID = [thisObject UID];
            NSNumber * offset = [offsetDictionary objectForKey:UID];
            [offsetDictionary setObject:[NSNumber numberWithInt:([offset intValue] - 1)] forKey:UID];
        }
    }
    [self tableViewSelectionDidChange:nil];


    }
}

-(IBAction)addedEvent:(id)sender
{
    [self rebuildPrefAlertsArray];

    [instance configForObject:activeContactObject];
    int index = [prefAlertsArray indexOfObjectIdenticalTo:activeContactObject] + [instance count] - 1;
    [tableView_actions scrollRowToVisible:index];
    [tableView_actions selectRow:index byExtendingSelection:NO];

    [[owner notificationCenter] postNotificationName:Pref_Changed_Alerts
                                              object:[instance activeObject]
                                            userInfo:nil];
}

-(void)externalChangedAlerts:(NSNotification *)notification
{
        [self rebuildPrefAlertsArray];
        [tableView_actions reloadData]; //necessary?
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
    row -= [[offsetDictionary objectForKey:[object UID]] intValue]; //acount for offset from here on out
    
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
       contact = [[instance activeObject] displayName]; //just the display name for now

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
        [instance configForObject:object];
        row -= [[offsetDictionary objectForKey:[object UID]] intValue];
        
        [cell selectItemWithRepresentedObject:[[instance dictAtIndex:row] objectForKey:KEY_EVENT_ACTION]];
        
        [instance configForObject:activeContactObject];
    }
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    if([identifier compare:TABLE_COLUMN_ACTION] == 0){
        NSMenuItem		*selectedMenuItem;
        NSMutableDictionary	*selectedActionDict;
        NSString		*newAction;
        AIListObject *listObject = [prefAlertsArray objectAtIndex:row];

        [instance configForObject:listObject];
        
        selectedMenuItem = [[[tableColumn dataCellForRow:row] menu] itemAtIndex:[object intValue]];

        row -= [[offsetDictionary objectForKey:[listObject UID]] intValue]; //change row to account for offset
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
    if (row != -1) //a row is selected
    {
        AIListObject * object = [prefAlertsArray objectAtIndex:row];
        activeContactObject = object;
        row -= [[offsetDictionary objectForKey:[object UID]] intValue];
        [popUp_contactList selectItemWithRepresentedObject:activeContactObject];
        [instance configForObject:activeContactObject];

        [instance currentRowIs:row]; //tell the instance which row is selected

        //rebuild the event menu to apply to this instance
        [popUp_addEvent setMenu:[instance eventMenu]];

        NSDictionary * selectedActionDict = [[[instance dictAtIndex:row] copy] autorelease];
        NSString *action = [selectedActionDict objectForKey:KEY_EVENT_ACTION];
        
        [[[actionColumn dataCellForRow:row] menu] performActionForItemAtIndex:[actionMenu indexOfItemWithRepresentedObject:action]]; //will appply appropriate subview in the process
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

- (void)dealloc
{
    [owner release];
    [prefAlertsArray release];
    [activeContactObject release];
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
            [menuItem setRepresentedObject:contact];

            if ([groupName compare:[[contact containingGroup] displayName]] != 0)
            {
                NSMenuItem	*groupItem;
                if ([contactMenu numberOfItems] > 0) [contactMenu addItem:[NSMenuItem separatorItem]];
                groupItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
                                                            target:self
                                                            action:@selector(switchToContact:)
                                                     keyEquivalent:@""] autorelease];
                [groupItem setRepresentedObject:[contact containingGroup]];
                    [contactMenu addItem:groupItem];
                    firstOfflineSearch = YES; //start searching for an offline contact
            }

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
                    firstOfflineSearch = NO;
                }
            }

            [contactMenu addItem:menuItem];

groupName = [[contact containingGroup] displayName];
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
