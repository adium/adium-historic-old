/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"
#import "AIPreferenceController.h"

//Preferences
#define KEY_PREFERENCE_SELECTED_CATEGORY		@"Preference Selected Category"
#define KEY_ADVANCED_PREFERENCE_SELECTED_ROW    @"Preference Advanced Selected Row"

//Other
#define PREFERENCE_WINDOW_NIB					@"PreferenceWindow"	//Filename of the preference window nib
#define PREFERENCE_ICON_FORMAT					@"pref-%@"			//Format of the preference icon filenames
#define ADVANCED_PANE_HEIGHT					333+4				//Fixed advanced pane height
#define ADVANCED_PANE_IDENTIFIER				@"advanced"			//Identifier of advanced tab

//Localized strings
#define PREFERENCE_WINDOW_TITLE					@"Preferences"

@interface AIPreferenceWindowController (PRIVATE)
+ (AIPreferenceWindowController *)_preferenceWindowController;
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;
- (void)_saveControlChanges;
- (void)_configureAdvancedPreferencesTable;
@end

static AIPreferenceWindowController *sharedPreferenceInstance = nil;

/*!
 * @class AIPreferenceWindowController
 * @brief Adium preference window controller
 *
 * Implements the main preference window.  This window pulls the preference panes registered with the preference
 * controller by plugins and places, organizing them by category.
 */
@implementation AIPreferenceWindowController

/*
 * @brief Open the preference window
 */
+ (void)openPreferenceWindow
{
	[[self _preferenceWindowController] showWindow:nil];
}

/*
 * @brief Open the preference window to a specific category
 */
+ (void)openPreferenceWindowToCategory:(PREFERENCE_CATEGORY)category
{
	[[self _preferenceWindowController] selectCategory:category];
	[[self _preferenceWindowController] showWindow:nil];
}

/*
 * @brief Open the preference window to a specific advanced category
 */
+ (void)openPreferenceWindowToAdvancedPane:(NSString *)advancedPane
{
	[[self _preferenceWindowController] selectAdvancedPane:advancedPane];
	[[self _preferenceWindowController] showWindow:nil];
}

/*
 * @brief Close the preference window (if it is open)
 */
+ (void)closePreferenceWindow
{
	if(sharedPreferenceInstance) [sharedPreferenceInstance closeWindow:nil];
}

/*!
 * @brief Returns the shared preference window controller
 *
 * Loads (if necessary) and returns a shared instance of AIPreferenceWindowController.
 * This method is used by the varions openPreferenceWindow methods and shouldn't be called from
 * outside AIPreferenceWindowController.
 */
+ (AIPreferenceWindowController *)_preferenceWindowController
{
    if(!sharedPreferenceInstance){
        sharedPreferenceInstance = [[self alloc] initWithWindowNibName:PREFERENCE_WINDOW_NIB];
    }
    
    return(sharedPreferenceInstance);
}

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    loadedPanes = [[NSMutableArray alloc] init];
    loadedAdvancedPanes = nil;
    _advancedCategoryArray = nil;
	
    return(self);    
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{	
    [viewArray release];
    [loadedPanes release];
	[loadedAdvancedPanes release];
	[_advancedCategoryArray release];
	
    [super dealloc];
}

/*!
 * @brief Setup the window before it is displayed
 */
- (void)windowDidLoad
{
	[super windowDidLoad];

	//Configure window
	[[self window] center];
	[[self window] setTitle:AILocalizedString(@"Preferences",nil)];
	[[[self window] standardWindowButton:NSWindowToolbarButton] setFrame:NSMakeRect(0,0,0,0)];
	[self _configureAdvancedPreferencesTable];

	//Prepare our array of preference views.  We place these in an array to cut down on a ton of duplicate code.
	viewArray = [[NSArray arrayWithObjects:
		view_General,
		view_ContactList,
		view_Messages, 
		view_Events,
		view_Dock,
		view_Emoticons,
		view_FileTransfer,
		view_Advanced,
		nil] retain];
	
    //Make the previously selected category active
	[self selectCategory:[[[adium preferenceController] preferenceForKey:KEY_PREFERENCE_SELECTED_CATEGORY
																   group:PREF_GROUP_WINDOW_POSITIONS] intValue]];
}

/*!
 * @brief Invoked before the window closes
 *
 * We always allow closing of the preference window, so always return YES from this method.  We take this
 * opportunity to save the state of our window and clean up before the window closes.
 */
- (BOOL)windowShouldClose:(id)sender
{
	[super windowShouldClose:sender];

	//Save changes
	[self _saveControlChanges];
	
    //Save the selected category and advanced category
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfTabViewItem:[tabView_category selectedTabViewItem]]]
										 forKey:KEY_PREFERENCE_SELECTED_CATEGORY
										  group:PREF_GROUP_WINDOW_POSITIONS];
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[tableView_advanced selectedRow]]
										 forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
										  group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Close all panes and our shared instance
	[loadedPanes makeObjectsPerformSelector:@selector(closeView)];
    [sharedPreferenceInstance autorelease]; sharedPreferenceInstance = nil;
	
    return(YES);
}


//Panes ---------------------------------------------------------------------------------------------------------------
#pragma mark Panes 
/*!
 * @brief Select a preference category
 */
- (void)selectCategory:(PREFERENCE_CATEGORY)category
{
	NSTabViewItem	*tabViewItem;
	
    if(category < 0 || category >= [tabView_category numberOfTabViewItems]) category = 0;

	tabViewItem = [tabView_category tabViewItemAtIndex:category];

	[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
    [tabView_category selectTabViewItem:tabViewItem];    
}

/*!
 * @brief Select an advanced preference category
 */
- (void)selectAdvancedPane:(NSString *)advancedPane
{
	NSEnumerator		*enumerator = [[self advancedCategoryArray] objectEnumerator];
	AIPreferencePane	*pane;

    //First, select the advanced category
    [self selectCategory:AIPref_Advanced];

	//Search for the advanded pane
	while(pane = [enumerator nextObject]){
		if([advancedPane caseInsensitiveCompare:[pane label]] == NSOrderedSame) break;
	}

	//If it exists, make it active
	if(pane){
		int row = [[self advancedCategoryArray] indexOfObject:pane];
		if([self tableView:tableView_advanced shouldSelectRow:row]){
			[tableView_advanced selectRow:row byExtendingSelection:NO];
		}		
	}
}

/*!
 * @brief Loads and returns the AIPreferencePanes in the specified category
 */
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

/*!
 * @brief Save any preference changes
 *
 * This take focus away from any controls to ensure that any changes in the current pane are saved.
 * This isn't a problem for most controls, but can cause issues with text fields if the user switches panes
 * with a text field focused.
 */
- (void)_saveControlChanges
{
	[[self window] makeFirstResponder:tabView_category];
}


//Toolbar tab view -----------------------------------------------------------------------------------------------------
#pragma mark Toolbar tab view
/*!
 * @brief Tabview will select a new pane, load the views for that pane
 */
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{	
    if(tabView == tabView_category && ![[tabViewItem identifier] isEqualToString:@"loading"]){
		int selectedIndex = [tabView indexOfTabViewItem:tabViewItem];

		//Save changes
		[self _saveControlChanges];
		
		//Load the pane if it isn't already loaded
		if(![[tabViewItem identifier] isEqualToString:ADVANCED_PANE_IDENTIFIER]){
			AIModularPaneCategoryView *view = [viewArray objectAtIndex:selectedIndex];
			if([view isEmpty]) [view setPanes:[self _panesInCategory:selectedIndex]];
		}
		
		//Update the window title
		[[self window] setTitle:[NSString stringWithFormat:@"%@ : %@", PREFERENCE_WINDOW_TITLE, [tabViewItem label]]];    	
   }
}

/*!
 * @brief Returns the preference image associated with the tab view item
 */
- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	return([NSImage imageNamed:[NSString stringWithFormat:PREFERENCE_ICON_FORMAT, [tabViewItem identifier]] forClass:[self class]]);
}

/*!
 * @brief Returns the desired height for the tab view item
 */
- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem
{
	if(![[tabViewItem identifier] isEqualToString:ADVANCED_PANE_IDENTIFIER]){
		return([[viewArray objectAtIndex:[tabView indexOfTabViewItem:tabViewItem]] desiredHeight]);
	}else{
		return(ADVANCED_PANE_HEIGHT);
	}
}


//Advanced Preferences -------------------------------------------------------------------------------------------------
#pragma mark Advanced Preferences
/*!
 * @brief Displays the passed AIPreferencePane in the advanced preferences tab of our window
 */
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
	}

	//Disable the "Restore Defaults" button if there's nothing to restore
	[button_restoreDefaults setEnabled:([preferencePane restorablePreferences] != nil)];
}

/*!
 * @brief Returns an array containing all the available advanced preference views
 */
- (NSArray *)advancedCategoryArray
{
    if(!_advancedCategoryArray){
        _advancedCategoryArray = [[self _panesInCategory:AIPref_Advanced] retain];
    }
    
    return(_advancedCategoryArray);
}

/*!
 * @brief Restores all preferences on the currently active advanced pane to their defaults
 */
- (IBAction)restoreDefaults:(id)sender
{
	int	selectedRow = [tableView_advanced selectedRow];
	[[adium preferenceController] resetPreferencesInPane:[[self advancedCategoryArray] objectAtIndex:selectedRow]];
}


//Advanced Preferences (Outline View) ----------------------------------------------------------------------------------
#pragma mark Advanced Preferences (Outline View)
/*!
 * @brief Configure the advanced preference category table view
 */
- (void)_configureAdvancedPreferencesTable
{
    AIImageTextCell			*cell;
	
    //Configure our tableView
    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:12]];
	[cell setDrawsGradientHighlight:YES];
    [[tableView_advanced tableColumnWithIdentifier:@"description"] setDataCell:cell];
	[cell release];
	
    [scrollView_advanced setAutoHideScrollBar:YES];
	
	//Select the previously selected row
	int row = [[[adium preferenceController] preferenceForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
														group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	if(row < 0 || row >= [tableView_advanced numberOfRows]) row = 1;
	
	if([self tableView:tableView_advanced shouldSelectRow:row]){
		[tableView_advanced selectRow:row byExtendingSelection:NO];
	}
}

/*!
 * @brief Return the number of accounts
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([[self advancedCategoryArray] count]);
}

/*!
 * @brief Return the account description or image
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return([[[self advancedCategoryArray] objectAtIndex:row] label]);
}

/*!
 * @brief Set the category image before the cell is displayed
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	[cell setImage:[[[self advancedCategoryArray] objectAtIndex:row] image]];
	[cell setSubString:nil];
}

/*!
 * @brief Update our advanced preferences for the selected pane
 */
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