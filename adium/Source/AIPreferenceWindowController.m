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

// $Id: AIPreferenceWindowController.m,v 1.39 2004/03/26 03:42:57 adamiser Exp $

#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"
#import "AIPreferenceController.h"

#define PREFERENCE_WINDOW_NIB					@"PreferenceWindow"	//Filename of the preference window nib
#define TOOLBAR_PREFERENCE_WINDOW				@"PreferenceWindow"	//Identifier for the preference toolbar
#define KEY_PREFERENCE_WINDOW_TOOLBAR_DISPLAY   @"Preference Window Toolbar Display Mode"
#define KEY_PREFERENCE_WINDOW_TOOLBAR_SIZE		@"Preference Window Toolbar Size Mode"
#define	KEY_PREFERENCE_WINDOW_FRAME				@"Preference Window Frame"
#define KEY_PREFERENCE_SELECTED_CATEGORY		@"Preference Selected Category"
#define KEY_ADVANCED_PREFERENCE_SELECTED_ROW    @"Preference Advanced Selected Row"
#define FLAT_PADDING_OFFSET                     45
#define PREFERENCE_WINDOW_TITLE					@"Preferences"
#define PREFERENCE_PANE_ARRAY					@"PaneArray"
#define PREFERENCE_GROUP_NAME					@"GroupName"
#define ADVANCED_PANE_HEIGHT					300

@interface AIPreferenceWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)configureToolbarItems;
- (void)installToolbar;
- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory intoView:(AIFlippedCategoryView *)inView showContainers:(BOOL)includeContainers;
- (void)_insertPanes:(NSArray *)paneArray intoView:(AIFlippedCategoryView *)inView showContainers:(BOOL)includeContainers;
- (void)_sizeWindowToFitTabView:(NSTabView *)tabView;
- (void)_sizeWindowToFitFlatView:(AIFlippedCategoryView *)view;
- (void)_sizeWindowForContentHeight:(int)height;
- (IBAction)restoreDefaults:(id)sender;
- (NSArray *)advancedCategoryArray;
- (NSDictionary *)_createGroupNamed:(NSString *)inName forCategory:(PREFERENCE_CATEGORY)category;
- (NSArray *)_prefsInCategory:(PREFERENCE_CATEGORY)category;
@end

@implementation AIPreferenceWindowController
//The shared instance guarantees (with as little work as possible) that only one preference controller can be open at a time.  It also makes handling releasing the window very simple.
static AIPreferenceWindowController *sharedPreferenceInstance = nil;
+ (AIPreferenceWindowController *)preferenceWindowController
{
    if(!sharedPreferenceInstance){
        sharedPreferenceInstance = [[self alloc] initWithWindowNibName:PREFERENCE_WINDOW_NIB];
    }
    
    return(sharedPreferenceInstance);
}

+ (void)closeSharedInstance
{
    if(sharedPreferenceInstance){
        [sharedPreferenceInstance closeWindow:nil];
    }
}

//Make the specified preference category visible
- (void)showCategory:(PREFERENCE_CATEGORY)inCategory
{
	int 			tabIdentifier;
	NSTabViewItem	*tabViewItem;
	
	//Ensure the window has loaded
	[self window];
	
	//Select the category
	switch(inCategory){
		case AIPref_Accounts: tabIdentifier = 1; break;
		case AIPref_Dock: tabIdentifier = 5; break;
		case AIPref_Sound: tabIdentifier = 6; break;
		case AIPref_Emoticons: tabIdentifier = 7; break;
		case AIPref_Alerts: tabIdentifier = 8; break;
		default: tabIdentifier = 1; break;
	}
	tabViewItem = [tabView_category tabViewItemWithIdentifier:[NSString stringWithFormat:@"%i",tabIdentifier]];
	[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
	[tabView_category selectTabViewItem:tabViewItem];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// Internal --------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    //Retain our owner
    toolbarItems = [[NSMutableDictionary dictionary] retain];
    loadedPanes = [[NSMutableArray alloc] init];
    _advancedCategoryArray = nil;
    loadedAdvancedPanes = nil;

    return(self);    
}

- (void)dealloc
{
    [toolbarItems release];
    [loadedPanes release];
    [loadedAdvancedPanes release];
    [_advancedCategoryArray release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString        *savedFrame;
    int             selectedTab;
    NSTabViewItem   *tabViewItem;
    
    //Remember the amount of vertical padding to our window's frame
    yPadding = [[self window] frame].size.height;

    //
    [self installToolbar];
    [outlineView_advanced setIndentationPerLevel:10];
    [coloredBox_advancedTitle setColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.15]];
 
    //Select the previously selected category
    selectedTab = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_SELECTED_CATEGORY] intValue];
    if(selectedTab < 0 || selectedTab > [tabView_category numberOfTabViewItems]) selectedTab = 0;

    tabViewItem = [tabView_category tabViewItemAtIndex:selectedTab];
    [self tabView:tabView_category willSelectTabViewItem:tabViewItem];
    [tabView_category selectTabViewItem:tabViewItem];    

	//Enable the "Restore Defaults" Button
	[button_restoreDefaults setEnabled:YES];
	
    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
	
    //Let everyone know we will open
    [[adium notificationCenter] postNotificationName:Preference_WindowWillOpen object:nil];
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
	
	//Save toolbar state
	NSToolbar *toolbar = [[self window] toolbar];

	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[toolbar displayMode]]
										 forKey:KEY_PREFERENCE_WINDOW_TOOLBAR_DISPLAY
										  group:PREF_GROUP_GENERAL];
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[toolbar sizeMode]]
										 forKey:KEY_PREFERENCE_WINDOW_TOOLBAR_SIZE
										  group:PREF_GROUP_GENERAL];
	
	
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];

    //Save the selected category
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfTabViewItem:[tabView_category selectedTabViewItem]]] forKey:KEY_PREFERENCE_SELECTED_CATEGORY group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame] forKey:KEY_PREFERENCE_WINDOW_FRAME group:PREF_GROUP_WINDOW_POSITIONS];

    //Close all open panes
    enumerator = [loadedPanes objectEnumerator];
    while(pane = [enumerator nextObject]){
        [pane closeView];
    }
    
    //Let everyone know we will close
    [[adium notificationCenter] postNotificationName:Preference_WindowDidClose object:nil];

    //autorelease the shared instance
    [sharedPreferenceInstance autorelease]; sharedPreferenceInstance = nil;

    return(YES);
}

//Install our toolbar
- (void)installToolbar
{
    NSToolbar *toolbar;

    //init the toolbar
    toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_PREFERENCE_WINDOW] autorelease];
    [self configureToolbarItems];
    
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
//    [toolbar setSizeMode: NSToolbarSizeModeRegular];
	
	[toolbar setDisplayMode:[[[adium preferenceController] preferenceForKey:KEY_PREFERENCE_WINDOW_TOOLBAR_DISPLAY
																	  group:PREF_GROUP_GENERAL] intValue]];
	[toolbar setSizeMode:[[[adium preferenceController] preferenceForKey:KEY_PREFERENCE_WINDOW_TOOLBAR_SIZE
																   group:PREF_GROUP_GENERAL] intValue]];
	
    //install it
    [[self window] setToolbar:toolbar];
}

//Configure the toolbar items
- (void)configureToolbarItems
{
    NSEnumerator	*enumerator;
    NSTabViewItem	*tabViewItem;
    
    enumerator = [[tabView_category tabViewItems] objectEnumerator];
    
    while((tabViewItem = [enumerator nextObject])){
        NSString 	*identifier = [tabViewItem identifier];
        NSString	*label = [tabViewItem label];

        if(![toolbarItems objectForKey:identifier]){
            [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:identifier
                                             label:label
                                      paletteLabel:label
                                           toolTip:label
                                            target:self
                                   settingSelector:@selector(setImage:)
                                               itemContent:[NSImage imageNamed:[NSString stringWithFormat:@"pref%@",identifier] forClass:[self class]]
                                            action:@selector(selectCategory:)
                                              menu:NULL];
        }
    }

    [[[self window] toolbar] setConfigurationFromDictionary:toolbarItems];
}

//Select the category that invoked this method
- (IBAction)selectCategory:(id)sender
{
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
    
    //Select the corresponding tab
    [tabView_category selectTabViewItemWithIdentifier:[sender itemIdentifier]];
}

//
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    int	identifier = [[tabViewItem identifier] intValue];

    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
    
    if(tabView == tabView_category){
        switch(identifier){
            case 1:
                [self _insertPanesForCategory:AIPref_Accounts intoView:view_Accounts showContainers:NO];
                [self _sizeWindowToFitFlatView:view_Accounts];
            break;
            case 2:
                [self _insertPanesForCategory:AIPref_ContactList_General intoView:view_ContactList_General showContainers:YES];
                [self _insertPanesForCategory:AIPref_ContactList_Groups intoView:view_ContactList_Groups showContainers:YES];
                [self _insertPanesForCategory:AIPref_ContactList_Contacts intoView:view_ContactList_Contacts showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_contactList];
            break;
            case 3:
                [self _insertPanesForCategory:AIPref_Messages_Display intoView:view_Messages_Display showContainers:YES];
                [self _insertPanesForCategory:AIPref_Messages_Sending intoView:view_Messages_Sending showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_messages];
            break;
            case 4:
                [self _insertPanesForCategory:AIPref_Status_Away intoView:view_Status_Away showContainers:YES];
                [self _insertPanesForCategory:AIPref_Status_Idle intoView:view_Status_Idle showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_status];
            break;
            case 5:
                [self _insertPanesForCategory:AIPref_Dock intoView:view_Dock showContainers:YES];
                [self _sizeWindowToFitFlatView:view_Dock];
            break;
            case 6:
                [self _insertPanesForCategory:AIPref_Sound intoView:view_Sound showContainers:YES];
                [self _sizeWindowToFitFlatView:view_Sound];
            break;
            case 7:
                [self _insertPanesForCategory:AIPref_Emoticons intoView:view_Emoticons showContainers:YES];
                [self _sizeWindowToFitFlatView:view_Emoticons];
                break;
            case 8:
                [self _insertPanesForCategory:AIPref_Alerts intoView:view_Alerts showContainers:YES];
                [self _sizeWindowToFitFlatView:view_Alerts];
            break;
            case 9:
                [self _sizeWindowForContentHeight:ADVANCED_PANE_HEIGHT];
                [outlineView_advanced reloadData];
                
                //Get the previously selected row
                int previousRow = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW] intValue];
                //Select it in the table
                [outlineView_advanced selectRow:previousRow byExtendingSelection:NO];
                //Force the view to update
                [self outlineView:outlineView_advanced shouldSelectItem:[outlineView_advanced itemAtRow:previousRow]];
                
            break;
                
        }

		//Update the selected toolbar item (10.3 or higher)
		if([[[self window] toolbar] respondsToSelector:@selector(setSelectedItemIdentifier:)]){
			[[[self window] toolbar] setSelectedItemIdentifier:[tabViewItem identifier]];
		}
    }

    //Update the window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@ : %@",PREFERENCE_WINDOW_TITLE,[tabViewItem label]]];    	
}

//Insert all the preference panes for the category into the passed view
- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory intoView:(AIFlippedCategoryView *)inView showContainers:(BOOL)includeContainers
{
    [self _insertPanes:[self _prefsInCategory:inCategory] intoView:inView showContainers:includeContainers];    
}

//Insert the passed preference panes into a view
- (void)_insertPanes:(NSArray *)paneArray intoView:(AIFlippedCategoryView *)inView showContainers:(BOOL)includeContainers
{
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    int			yPos = 0;
    
    //Add their views
    enumerator = [paneArray objectEnumerator];
    while(pane = [enumerator nextObject]){
        NSView	*paneView = ([pane isUpdated] ? [pane view] : [pane viewWithContainer:includeContainers]);
        
        //Add the view
        if([paneView superview] != inView){
            [inView addSubview:paneView];
            [paneView setFrameOrigin:NSMakePoint(0,yPos)];
        }
        
        //Move down for the next view
        yPos += [paneView frame].size.height;
    }
    
    //Set the desired height of this view
    [inView setDesiredHeight:yPos];
}

//Resize our window to fit the specified tabview
- (void)_sizeWindowToFitTabView:(NSTabView *)tabView
{
    NSEnumerator	*enumerator;
    NSTabViewItem	*tabViewItem;
    int			maxHeight = 0;

    //Determine the tallest view contained within this tab view.
    enumerator = [[tabView tabViewItems] objectEnumerator];
    while(tabViewItem = [enumerator nextObject]){
        NSEnumerator	*subViewEnumerator;
        NSView		*subView;

        subViewEnumerator = [[[tabViewItem view] subviews] objectEnumerator];
        while(subView = [subViewEnumerator nextObject]){
            int		height = [(AIFlippedCategoryView *)subView desiredHeight];

            if(height > maxHeight){
                maxHeight = height;
            }
        }
    }

    //Resize the window
    [self _sizeWindowForContentHeight:maxHeight];
}

//Resize our window to fit the specified non-tabbed view
- (void)_sizeWindowToFitFlatView:(AIFlippedCategoryView *)view
{
    [self _sizeWindowForContentHeight:([view desiredHeight] - FLAT_PADDING_OFFSET)];
}

//Resize our window to fit the specified content height
- (void)_sizeWindowForContentHeight:(int)height
{
    BOOL	isVisible = [[self window] isVisible];
    NSRect 	frame = [[self window] frame];

    //Add in window frame padding
    height += yPadding;

    if([tabView_category respondsToSelector:@selector(setHidden:)]){
        [tabView_category setHidden:YES];
    }
    
    //Adjust our window's frame
    frame.origin.y += frame.size.height - height;
    frame.size.height = height;
    [[self window] setFrame:frame display:isVisible animate:isVisible];

    if([tabView_category respondsToSelector:@selector(setHidden:)]){
        [tabView_category setHidden:NO];
    }
}

// Restore everything the AIPreferencePane wants restored
- (IBAction)restoreDefaults:(id)sender
{
	NSDictionary		*allDefaults;
	NSDictionary		*defaultsDict;
	NSString			*group;
	NSString			*key;
	
	//Get the previously selected row
	int previousRow = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] 
							objectForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW] intValue];
	
	// Get the restorable prefs dictionary of the pref pane at the active row
	allDefaults = [(AIPreferencePane *)[outlineView_advanced itemAtRow:previousRow] restorablePreferences];
	
	if( allDefaults ) {
		
		NSEnumerator	*enumerator = [allDefaults keyEnumerator];
		
		// They keys are preference groups, run through all of them
		while( group = (NSString *)[enumerator nextObject] ) {
			
			NSEnumerator	*keyEnum;
			
			// Get the pref dictionary for each pref goup
			defaultsDict = [allDefaults objectForKey:group];
			keyEnum = [defaultsDict keyEnumerator];
			
			while( key = (NSString *)[keyEnum nextObject] ) {
				//NSLog(@"----Key: %@, Value: %@, Group: %@",key,[defaultsDict objectForKey:key],group);
				[[adium preferenceController] setPreference:[defaultsDict objectForKey:key]
													 forKey:key
													  group:group];
			}
		}
		
		[self outlineView:outlineView_advanced shouldSelectItem:[outlineView_advanced itemAtRow:previousRow]];

	}
}

//Returns the advanced preference categories
- (NSArray *)advancedCategoryArray
{
    if(!_advancedCategoryArray){
        _advancedCategoryArray = [[NSMutableArray alloc] init];
        
        //Load our advanced categories
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Contact List" forCategory:AIPref_Advanced_ContactList]];
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Messages" forCategory:AIPref_Advanced_Messages]];
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Status" forCategory:AIPref_Advanced_Status]];
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Other" forCategory:AIPref_Advanced_Other]];
    }
    
    return(_advancedCategoryArray);
}

//
- (NSDictionary *)_createGroupNamed:(NSString *)inName forCategory:(PREFERENCE_CATEGORY)category
{
    return([NSDictionary dictionaryWithObjectsAndKeys:inName, PREFERENCE_GROUP_NAME, [self _prefsInCategory:category], PREFERENCE_PANE_ARRAY, nil]);
}

//Loads, alphabetizes, and caches prefs for the speficied category
- (NSArray *)_prefsInCategory:(PREFERENCE_CATEGORY)inCategory
{
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    NSMutableArray	*paneArray = [NSMutableArray array];
    
    //Get the panes for this category
    enumerator = [[[adium preferenceController] paneArray] objectEnumerator];
    while(pane = [enumerator nextObject]){
        if([pane category] == inCategory){
            [paneArray addObject:pane];
            [loadedPanes addObject:pane];
        }
    }
    
    //Alphabetize them
    [paneArray sortUsingSelector:@selector(compare:)];
    
    return(paneArray);
}

//Toolbar item methods
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return(YES);
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    NSMutableArray	*defaultArray;
    NSEnumerator	*enumerator;
    NSToolbarItem	*toolbarItem;
    
    defaultArray = [[NSMutableArray alloc] init];

    //Build a list of all our toolbar item identifiers
    enumerator = [toolbarItems objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        [defaultArray addObject:[toolbarItem itemIdentifier]];
    }

    //Sort
    [defaultArray sortUsingSelector:@selector(compare:)];
    
    return([defaultArray autorelease]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([self toolbarDefaultItemIdentifiers:toolbar]);
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return([self toolbarDefaultItemIdentifiers:toolbar]);
}


//Advanced outline view data source
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){ //Root
        return([[self advancedCategoryArray] objectAtIndex:index]);
    }else{
        return([[item objectForKey:PREFERENCE_PANE_ARRAY] objectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[NSDictionary class]]){ //Only groups are expandable
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){ //Root
        return([[self advancedCategoryArray] count]);
    }else{
        return([[item objectForKey:PREFERENCE_PANE_ARRAY] count]);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([item isKindOfClass:[NSDictionary class]]){
        return([[[NSAttributedString alloc] initWithString:[item objectForKey:PREFERENCE_GROUP_NAME]
                                                attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName]] autorelease]);
        
    }else if([item isKindOfClass:[AIPreferencePane class]]){
        float	cellWidth = [outlineView frameOfCellAtColumn:[outlineView indexOfTableColumn:tableColumn] row:[outlineView rowForItem:item]].size.width - 4;
        return([[(AIPreferencePane *)item label] stringByTruncatingTailToWidth:cellWidth]);
    }
    
    return(nil);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if([item isKindOfClass:[AIPreferencePane class]]){
        NSEnumerator		*enumerator;
        AIPreferencePane	*pane;
        
        //Close open panes
        enumerator = [loadedAdvancedPanes objectEnumerator];
        while(pane = [enumerator nextObject]){
            [pane closeView];
        }
        [loadedAdvancedPanes release]; loadedAdvancedPanes = nil;
        [view_Advanced removeAllSubviews];
        
        //Load new panes
            loadedAdvancedPanes = [[NSArray arrayWithObject:item] retain];
            [self _insertPanes:loadedAdvancedPanes intoView:view_Advanced showContainers:NO];
            [textField_advancedTitle setStringValue:[item label]];
			
			// Disable the "Restore Defaults" button if there's nothing to restore
			if( [item restorablePreferences] != nil ) {
				[button_restoreDefaults setEnabled:YES];
			} else {
				[button_restoreDefaults setEnabled:NO];
			}
		
        return(YES);
    }else{
        return(NO);
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    //Save the selected row number
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[[notification object] selectedRow]] forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW group:PREF_GROUP_WINDOW_POSITIONS];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return(YES);
}

- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    
}


@end
