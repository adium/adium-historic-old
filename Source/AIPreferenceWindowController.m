/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id$

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
#define PREFERENCE_WINDOW_TITLE					@"Preferences"
#define PREFERENCE_PANE_ARRAY					@"PaneArray"
#define PREFERENCE_GROUP_NAME					@"GroupName"
#define ADVANCED_PANE_HEIGHT					350
#define ADVANCED_PANE_TABVIEW_IDENTIFIER		@"9"

@interface AIPreferenceWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)configureToolbarItems;
- (void)_sizeWindowToFitTabView:(NSTabView *)tabView;
- (void)_sizeWindowToFitFlatView:(AIModularPaneCategoryView *)view;
- (void)_sizeWindowForContentHeight:(int)height;
- (IBAction)restoreDefaults:(id)sender;
- (NSDictionary *)_createGroupNamed:(NSString *)inName forCategory:(PREFERENCE_CATEGORY)category;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;

- (void)configureAdvancedPreferencesTable;
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
		case AIPref_General: tabIdentifier = 1;
		case AIPref_ContactList: tabIdentifier = 2; break;
		case AIPref_Messages: tabIdentifier = 3; break;
		case AIPref_Events: tabIdentifier = 4; break;
		case AIPref_Dock: tabIdentifier = 5; break;
		case AIPref_Emoticons: tabIdentifier = 6; break;
		case AIPref_FileTransfer: tabIdentifier = 7; break;
		case AIPref_Advanced_ContactList:
		case AIPref_Advanced_Messages:
		case AIPref_Advanced_Status:
		case AIPref_Advanced_Service:
		case AIPref_Advanced_Other: tabIdentifier = 8; break;
			
		default: tabIdentifier = 1; break;
	}
	tabViewItem = [tabView_category tabViewItemWithIdentifier:[NSString stringWithFormat:@"%i",tabIdentifier]];
	[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
	[tabView_category selectTabViewItem:tabViewItem];

}

- (void)showAdvancedPane:(NSString *)paneName inCategory:(PREFERENCE_CATEGORY)category
{
	NSArray				*advancedPrefArray;
	NSEnumerator		*enumerator;
	AIPreferencePane	*pane;
	NSTabViewItem		*tabViewItem;
	BOOL				shouldContinue = YES;
	int					row;
	
	advancedPrefArray = [self _panesInCategory:category];
	enumerator = [advancedPrefArray objectEnumerator];
	
	[self window];
	
	while( shouldContinue && (pane = [enumerator nextObject]) ) {
		if( [paneName caseInsensitiveCompare:[pane label]] == NSOrderedSame ) {
			shouldContinue = NO;
		}
	}
	
	if( shouldContinue == NO ) {
		
		// Open the Advanced Prefs category
		tabViewItem = [tabView_category tabViewItemWithIdentifier:ADVANCED_PANE_TABVIEW_IDENTIFIER];
		[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
		[tabView_category selectTabViewItem:tabViewItem];
		
		// Open the pane
		[self configureAdvancedPreferencesForPane:pane];
		
		// Select the correct row in the outline view
		row = [[self advancedCategoryArray] indexOfObject:pane];
		if([self tableView:tableView_advanced shouldSelectRow:row]){
			[tableView_advanced selectRow:row byExtendingSelection:NO];
		}
	}
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}


//Internal -------------------------------------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    //Retain our owner
    loadedPanes = [[NSMutableArray alloc] init];
    _advancedCategoryArray = nil;
    loadedAdvancedPanes = nil;

    return(self);    
}

- (void)dealloc
{
	[self configureAdvancedPreferencesForPane:nil];

    [loadedPanes release];
	[loadedAdvancedPanes release];
	[_advancedCategoryArray release];
	
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    int             selectedTab;
    NSTabViewItem   *tabViewItem;
	
	[super windowDidLoad];

	//
    [coloredBox_advancedTitle setColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.15]];
 
    //Select the previously selected category
    selectedTab = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_SELECTED_CATEGORY] intValue];
    if(selectedTab < 0 || selectedTab >= [tabView_category numberOfTabViewItems]) selectedTab = 0;

    tabViewItem = [tabView_category tabViewItemAtIndex:selectedTab];
    [self tabView:tabView_category willSelectTabViewItem:tabViewItem];
    [tabView_category selectTabViewItem:tabViewItem];    

 	//Enable the "Restore Defaults" Button
	[button_restoreDefaults setEnabled:YES];
	
	//Hide the toolbar toggle button, since this window needs a toolbar to be functional
	[[[self window] standardWindowButton:NSWindowToolbarButton] setFrame:NSMakeRect(0,0,0,0)];

	[[self window] setTitle:AILocalizedString(@"Preferences",nil)];

	[self configureAdvancedPreferencesTable];

    //Center the window
	[[self window] betterCenter];
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
	
	//Save selection
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[tableView_advanced selectedRow]]
										 forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
										  group:PREF_GROUP_WINDOW_POSITIONS];
	
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];

    //Save the selected category
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfTabViewItem:[tabView_category selectedTabViewItem]]] forKey:KEY_PREFERENCE_SELECTED_CATEGORY group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Close all open panes
    enumerator = [loadedPanes objectEnumerator];
    while(pane = [enumerator nextObject]){
        [pane closeView];
    }
	
	[super windowShouldClose:sender];

    //autorelease the shared instance
    [sharedPreferenceInstance autorelease]; sharedPreferenceInstance = nil;

    return(YES);
}

/*
- (NSString *)adiumFrameAutosaveName
{
	return(@"PreferencesWindow");
}
*/

//
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    int	identifier = [[tabViewItem identifier] intValue];

    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
    
    if(tabView == tabView_category){
        switch(identifier){
			case 1:
				[view_General setPanes:[self _panesInCategory:AIPref_General]];
			break;
            case 2:
                [view_ContactList setPanes:[self _panesInCategory:AIPref_ContactList]];
            break;
            case 3:
                [view_Messages setPanes:[self _panesInCategory:AIPref_Messages]];
            break;
            case 4:
				[view_Events setPanes:[self _panesInCategory:AIPref_Events]];
            break;
            case 5:
				[view_Dock setPanes:[self _panesInCategory:AIPref_Dock]];
            break;
            case 6:
				[view_Emoticons setPanes:[self _panesInCategory:AIPref_Emoticons]];
			break;
			case 7:
				[view_FileTransfer setPanes:[self _panesInCategory:AIPref_FileTransfer]];
				break;
            case 8:
                [tableView_advanced reloadData];
				
                //Select the previously selected row
				int row = [[[adium preferenceController] preferenceForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
																	group:PREF_GROUP_WINDOW_POSITIONS] intValue];
				if(row < 0 || row >= [tableView_advanced numberOfRows]) row = 1;
					
				[tableView_advanced selectRow:row byExtendingSelection:NO];
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

- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	return([NSImage imageNamed:[NSString stringWithFormat:@"pref%@",[tabViewItem identifier]] forClass:[self class]]);
}

- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem
{
	switch([[tabViewItem identifier] intValue]){
		case 1: return([view_General desiredHeight]); break;
		case 2: return([view_ContactList desiredHeight]); break;
		case 3: return([view_Messages desiredHeight]); break;
		case 4: return([view_Events desiredHeight]); break;
		case 5: return([view_Dock desiredHeight]); break;
		case 6: return([view_Emoticons desiredHeight]); break;
		case 7: return([view_FileTransfer desiredHeight]); break;
		case 8: return(ADVANCED_PANE_HEIGHT); break;
		default: return(0); break;
	}
}


//Advanced Preferences -------------------------------------------------------------------------------------------------
#pragma mark Advanced Preferences
//Restore everything the AIPreferencePane wants restored
- (IBAction)restoreDefaults:(id)sender
{
	int	selectedRow = [tableView_advanced selectedRow];
	[[adium preferenceController] resetPreferencesInPane:[[self advancedCategoryArray] objectAtIndex:selectedRow]];
}

//Set the displayed advanced pane
- (void)configureAdvancedPreferencesForPane:(AIPreferencePane *)preferencePane
{
	NSEnumerator		*enumerator;
	AIPreferencePane	*pane;
	
	//Close open panes
	enumerator = [loadedAdvancedPanes objectEnumerator];
	while(pane = [enumerator nextObject]){
		[pane closeView];
	}
	[view_Advanced removeAllSubviews];
	[loadedAdvancedPanes release]; loadedAdvancedPanes = nil;
	
	//Load new panes
	if(preferencePane){
		loadedAdvancedPanes = [[NSArray arrayWithObject:preferencePane] retain];
		[view_Advanced setPanes:loadedAdvancedPanes];
		[textField_advancedTitle setStringValue:[preferencePane label]];
	}

	//Disable the "Restore Defaults" button if there's nothing to restore
	[button_restoreDefaults setEnabled:([preferencePane restorablePreferences] != nil)];
}

//Returns the advanced preference categories
- (NSArray *)advancedCategoryArray
{
    if(!_advancedCategoryArray){
        _advancedCategoryArray = [[NSMutableArray alloc] init];
        
        //Load our advanced categories
		/*
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Contact List" forCategory:AIPref_Advanced_ContactList]];
		 [_advancedCategoryArray addObject:[self _createGroupNamed:@"Messages" forCategory:AIPref_Advanced_Messages]];
		 [_advancedCategoryArray addObject:[self _createGroupNamed:@"Status" forCategory:AIPref_Advanced_Status]];
		 [_advancedCategoryArray addObject:[self _createGroupNamed:@"Service" forCategory:AIPref_Advanced_Service]];
		 [_advancedCategoryArray addObject:[self _createGroupNamed:@"Other" forCategory:AIPref_Advanced_Other]];
		 */
		[_advancedCategoryArray addObjectsFromArray:[self _panesInCategory:AIPref_Advanced_ContactList]];
		[_advancedCategoryArray addObjectsFromArray:[self _panesInCategory:AIPref_Advanced_Messages]];
		[_advancedCategoryArray addObjectsFromArray:[self _panesInCategory:AIPref_Advanced_Status]];
		[_advancedCategoryArray addObjectsFromArray:[self _panesInCategory:AIPref_Advanced_Service]];
		[_advancedCategoryArray addObjectsFromArray:[self _panesInCategory:AIPref_Advanced_Other]];
		
		//Alphabetize them
		[_advancedCategoryArray sortUsingSelector:@selector(compare:)];
    }
    
    return(_advancedCategoryArray);
}

/*
//
- (NSDictionary *)_createGroupNamed:(NSString *)inName forCategory:(PREFERENCE_CATEGORY)category
{
    return([NSDictionary dictionaryWithObjectsAndKeys:
		inName, PREFERENCE_GROUP_NAME,
		[self _panesInCategory:category], PREFERENCE_PANE_ARRAY,
		nil]);
}
*/

//Loads, alphabetizes, and caches prefs for the speficied category
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory
{
    NSMutableArray		*paneArray = [NSMutableArray array];
    NSEnumerator		*enumerator = [[[adium preferenceController] paneArray] objectEnumerator];
    AIPreferencePane	*pane;
    
    //Get the panes for this category
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


//Advanced Preferences (Outline View) ----------------------------------------------------------------------------------
#pragma mark Advanced Preferences (Outline View)
- (void)configureAdvancedPreferencesTable
{
    AIImageTextCell			*cell;
	
    //Configure our tableView
    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:12]];
    [[tableView_advanced tableColumnWithIdentifier:@"description"] setDataCell:cell];
	[cell release];
	
    [scrollView_advanced setAutoHideScrollBar:YES];
	[tableView_advanced reloadData];
	
	//Force select the first row
	//XXX - Remembering the the selected advanced pane would be nice here -ai
	if([self tableView:tableView_advanced shouldSelectRow:0]){
		[tableView_advanced selectRow:0 byExtendingSelection:NO];
	}
}

//Return the number of accounts
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([[self advancedCategoryArray] count]);
}

//Return the account description or image
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return([(AIPreferencePane *)[[self advancedCategoryArray] objectAtIndex:row] label]);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	AIPreferencePane	*pane = [[self advancedCategoryArray] objectAtIndex:row];
	[cell setImage:[pane image]];
	[cell setSubString:nil];
	[cell setDrawsGradientHighlight:YES];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if(row >= 0 && row < [[self advancedCategoryArray] count]){		
		[self configureAdvancedPreferencesForPane:[[self advancedCategoryArray] objectAtIndex:row]];
		return(YES);
    }else{
		return(NO);
	}
}

@end
