//
//  ESContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsWindowController.h"
#import "ESContactAlerts.h"
#import "ESContactAlertsPlugin.h"
#import "CSNewContactAlertWindowController.h"

#define CONTACT_ALERT_WINDOW_NIB	@"ContactAlerts"
#define TABLE_COLUMN_ACTION		@"action"
#define TABLE_COLUMN_EVENT		@"event"

@interface ESContactAlertsWindowController (PRIVATE)
- (void)initialWindowConfig;
-(void)rebuildAlertContactsArray;
- (void)rebuildActionsArray;
- (void)configureWindowforObject:(AIListObject *)inContact;
- (void)configureView;

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)shouldSelectRow:(int)inRow;
- (id)initForPlugin:(id)inPlugin;
- (void)buildToolbar;
@end

extern int alphabeticalGroupOfflineSort_contactAlerts(id objectA, id objectB, void *context);

@implementation ESContactAlertsWindowController
//Open a new info window
static ESContactAlertsWindowController *sharedAlertsWindowInstance = nil;
+ (id)showContactAlertsWindowForObject:(AIListObject *)inContact
{
    if(!sharedAlertsWindowInstance){
        sharedAlertsWindowInstance = [[self alloc] initWithWindowNibName:CONTACT_ALERT_WINDOW_NIB];
        [sharedAlertsWindowInstance initialWindowConfig];
    }

    [sharedAlertsWindowInstance showWindow:nil];

    return(sharedAlertsWindowInstance);
}

//Close the alerts window
+ (void)closeContactAlertsWindow
{
    if(sharedAlertsWindowInstance){
        [sharedAlertsWindowInstance closeWindow:nil];
    }
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){

        [[adium notificationCenter] removeObserver:self]; //remove all observers

        //[instance removeAllSubviews:view_main];
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

    instance = [[ESContactAlerts alloc] initWithDetailsView:nil withTable:nil withPrefView:nil];
    [instance retain];
	
	[self rebuildAlertContactsArray];
    
	AIImageTextCell			*sourceCell, *actionsCell;
	
	[self buildToolbar];
	
    //Configure our tableView
    sourceCell = [[[AIImageTextCell alloc] init] autorelease];
    [sourceCell setFont:[NSFont systemFontOfSize:12]];
	actionsCell = [[[AIImageTextCell alloc] init] autorelease];
    [actionsCell setFont:[NSFont systemFontOfSize:12]];
    [[tableView_source tableColumnWithIdentifier:@"description"] setDataCell:sourceCell];
	[[tableView_actions tableColumnWithIdentifier:@"description"] setDataCell:actionsCell];
    //Configure the table view
    [tableView_source setDataSource:self];
	[tableView_source setDelegate:self];
	[tableView_actions setDataSource:self];
	[tableView_actions setDelegate:self];
	
	if ([alertContacts count])
		[self configureWindowforObject:[alertContacts objectAtIndex:0]];
}

-(void)rebuildAlertContactsArray
{
    int thisInstanceCount;
    NSMutableArray *contactArray =  [[adium contactController] allContactsInGroup:nil subgroups:YES];
    [contactArray sortUsingFunction:alphabeticalGroupOfflineSort_contactAlerts context:nil];
    
    NSEnumerator    *enumerator = [contactArray objectEnumerator];
	// NSString        *groupName = nil;
	
    [alertContacts release]; alertContacts = [[NSMutableArray alloc] init];
	
    AIListContact * contact;
    while (contact = [enumerator nextObject]) {
        [instance configForObject:contact];
        thisInstanceCount = [instance count];
        if (thisInstanceCount) {
			[alertContacts addObject:contact];
        }
    }
	
	[tableView_source reloadData];
}

- (void)rebuildActionsArray
{
	int i, c;
	NSDictionary *actionDict;
	NSMutableString *currentEvent = [NSMutableString string];

	if (actionsArray) {
		[actionsArray release];
		actionsArray = nil;
	}
	actionsArray = [[NSMutableArray alloc] init];
	
	c = [instance count];
	if (c) {
		for (i=0;i<c;i++) {
			NSMutableDictionary *rowDict = [NSMutableDictionary dictionary];
			
			actionDict = [instance dictAtIndex:i];
			if ([currentEvent caseInsensitiveCompare:[actionDict objectForKey:KEY_EVENT_NOTIFICATION]] != 0)
			{
				NSMutableDictionary *eventDict = [NSMutableDictionary dictionary];
				[eventDict setObject:[NSNumber numberWithInt:-1] forKey:@"row"];
				[eventDict setObject:[NSString stringWithFormat:@"When %@ %@:", [[instance activeObject] displayName], [actionDict objectForKey:KEY_EVENT_DISPLAYNAME]]
							  forKey:@"display"];
				
				[currentEvent setString:[actionDict objectForKey:KEY_EVENT_NOTIFICATION]];
				[actionsArray addObject:eventDict];
			}
			[rowDict setObject:[NSNumber numberWithInt:i] forKey:@"row"];
			[rowDict setObject:[actionDict objectForKey:KEY_EVENT_ACTION] forKey:@"display"];
			[actionsArray addObject:rowDict];
		}
	}
}

//Configure the actions window for the specified contact
- (void)configureWindowforObject:(AIListObject *)inContact
{

    //Remember who we're displaying actions for
    [activeContactObject release]; activeContactObject = [inContact retain];
    //Observers
    [[adium notificationCenter] removeObserver:self]; //remove any previous observers

    //Observe account changes
	/*
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(accountListChanged:) 
									   name:Account_ListChanged 
									 object:nil];
*/

    [[adium notificationCenter] addObserver:self
								   selector:@selector(externalChangedAlerts:) 
									   name:One_Time_Event_Fired 
									 object:nil];

    //Set window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@'s %@",[activeContactObject displayName],AILocalizedString(@"Alerts",nil)]];

    [instance configForObject:activeContactObject];
	[self rebuildActionsArray];
	
    //Update the outline view
    [tableView_actions reloadData];
}

#pragma mark Actions

- (IBAction)addAlert:(id)sender
{
	CSNewContactAlertWindowController *windowController = [[CSNewContactAlertWindowController alloc] initWithInstance:instance editing:NO];
	
	[windowController setDelegate:self];
	[NSApp beginSheet:[windowController window]
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
    //[NSApp runModalForWindow:[windowController window]];
}

- (IBAction)editAlert:(id)sender
{
	CSNewContactAlertWindowController *windowController = [[CSNewContactAlertWindowController alloc] initWithInstance:instance editing:YES];
	
	[windowController setDelegate:self];
	[NSApp beginSheet:[windowController window]
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)deleteAlert:(id)sender
{
	[instance deleteEventAction:self];
}

#pragma mark NewAlert delegate methods

- (void)contactAlertWindowFinished:(id)sender didCreate:(BOOL)created
{
	//[NSApp stopModal];
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];

	if (created)
	{
		[self rebuildAlertContactsArray];
		[self configureWindowforObject:[instance activeObject]];
	}
}

#pragma mark Toolbar

- (void)buildToolbar
{
	toolbar_editing = [[NSToolbar alloc] initWithIdentifier:@"alertwin"];
	toolbarItems = [[NSMutableDictionary alloc] init];
	
	addItem = [[[NSToolbarItem alloc] initWithItemIdentifier:@"addItem"] autorelease];
	[addItem setLabel:@"New Alert"]; //should be localized?
	[addItem setPaletteLabel:@"Add New Alert"];
	[addItem setImage:[NSImage imageNamed:@"newAlert" forClass:[self class]]];
	[addItem setTarget:self];
	[addItem setAction:@selector(addAlert:)];
	[toolbarItems setObject:addItem forKey:@"addItem"];
	
	editItem = [[[NSToolbarItem alloc] initWithItemIdentifier:@"editItem"] autorelease];
	[editItem setLabel:@"Edit Alert"]; //should be localized?
	[editItem setPaletteLabel:@"Edit Alert"];
	[editItem setImage:[NSImage imageNamed:@"editAlert" forClass:[self class]]];
	[editItem setTarget:self];
	[editItem setAction:@selector(editAlert:)];
	[toolbarItems setObject:editItem forKey:@"editItem"];
	
	deleteItem = [[[NSToolbarItem alloc] initWithItemIdentifier:@"deleteItem"] autorelease];
	[deleteItem setLabel:@"Delete"]; //should be localized?
	[deleteItem setPaletteLabel:@"Delete Alert"];
	[deleteItem setImage:[NSImage imageNamed:@"deleteAlert" forClass:[self class]]];
	[deleteItem setTarget:self];
	[deleteItem setAction:@selector(deleteAlert:)];
	[toolbarItems setObject:deleteItem forKey:@"deleteItem"];
	
	[toolbar_editing setDelegate:self];
		
	[[self window] setToolbar:toolbar_editing];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if (theItem != addItem) {
		return ([tableView_actions selectedRow] != -1);
	}
	return YES;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
	return [toolbarItems objectForKey:itemIdent];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [toolbarItems allKeys];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:@"addItem", @"editItem", @"deleteItem"];
}

#pragma mark TableView Data Sources
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tableView_source) {
		return [alertContacts count];
	} else if (tableView == tableView_actions) {
		return [actionsArray count];
	}
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (tableView == tableView_source) {
		return [[alertContacts objectAtIndex:row] displayName];
	} else if (tableView == tableView_actions) {
        NSString	*action;
	
        action = [[actionsArray objectAtIndex:row] objectForKey:@"display"];
		return action;
	}
	return(@"");
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	
    if (tableView == tableView_source) {
		AIListObject *oldContact = [instance activeObject];
		
		[instance configForObject:[alertContacts objectAtIndex:row]];
		[cell setSubString:[NSString stringWithFormat:@"%d Alert%@", [instance count], (([instance count] > 1) ? @"s" : @"")]];
		[cell setDrawsGradientHighlight:YES];
		[instance configForObject:oldContact];
	} else if (tableView == tableView_actions) {
		int instanceRow = [[[actionsArray objectAtIndex:row] objectForKey:@"row"] intValue];
		[cell setImage:nil];
		if (instanceRow == -1) {
			[cell setEnabled:NO];
		} else {
			[cell setEnabled:YES];
			[cell setImage:[[adium contactAlertsController] iconForAction:[[instance dictAtIndex:instanceRow] objectForKey:KEY_EVENT_ACTION]]];
		}
	}
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
}

//selection changed; update the view
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == tableView_source) {
		[self configureWindowforObject:[alertContacts objectAtIndex:[tableView_source selectedRow]]];
		[tableView_actions deselectAll:nil];
	} else if ([aNotification object] == tableView_actions) {
		if ([tableView_actions selectedRow] > -1)
			[instance currentRowIs:[[[actionsArray objectAtIndex:[tableView_actions selectedRow]] objectForKey:@"row"] intValue]];
		[toolbar_editing validateVisibleItems];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if (aTableView == tableView_actions) {
		return ([[[actionsArray objectAtIndex:rowIndex] objectForKey:@"row"] intValue] != -1);
	}
    return(YES);
}

#pragma mark Private

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    return(self);
}

- (void)dealloc
{
    [activeContactObject release]; activeContactObject = nil;
    //[popUp_addEvent release]; popUp_addEvent = nil;
    [instance release]; instance = nil;
    //[dataCell release]; dataCell = nil;
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

-(void)externalChangedAlerts:(NSNotification *)notification
{
    [instance reload:activeContactObject usingCache:NO];
    [self rebuildAlertContactsArray];
	[self rebuildActionsArray];
	[tableView_actions reloadData];
	if ([alertContacts count]) {
		[self configureWindowforObject:[alertContacts objectAtIndex:[tableView_source selectedRow]]];
	}
}

- (IBAction)switchToContact:(id)sender
{
    [sharedAlertsWindowInstance configureWindowforObject:[sender representedObject]];
}
- (void)testSelectedEvent:(id)sender
{
    //action to take when action is double-clicked in the window
}


@end