/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"
#import "AIPreferenceController.h"
#import "AIAccountController.h"
#import <Adium/AIModularPaneCategoryView.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>

//Preferences
#define KEY_PREFERENCE_SELECTED_CATEGORY		@"Preference Selected Category Name"
#define KEY_ADVANCED_PREFERENCE_SELECTED_ROW    @"Preference Advanced Selected Row"

//Other
#define PREFERENCE_WINDOW_NIB					@"PreferenceWindow"	//Filename of the preference window nib
#define PREFERENCE_ICON_FORMAT					@"pref-%@"			//Format of the preference icon filenames
#define ADVANCED_PANE_HEIGHT					333+4				//Fixed advanced pane height
#define ADVANCED_PANE_IDENTIFIER				@"advanced"			//Identifier of advanced tab

//Localized strings
#define PREFERENCE_WINDOW_TITLE					AILocalizedString(@"Preferences",nil)

@interface AIPreferenceWindowController (PRIVATE)
+ (AIPreferenceWindowController *)_preferenceWindowController;
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;
- (void)_saveControlChanges;
- (void)_configureAdvancedPreferencesTable;
- (void)_configreTabViewItemLabels;
- (NSString *)tabView:(NSTabView *)tabView labelForTabViewItem:(NSTabViewItem *)tabViewItem;
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

/*!
 * @brief Open the preference window
 */
+ (void)openPreferenceWindow
{
	[[self _preferenceWindowController] showWindow:nil];
}

/*!
 * @brief Open the preference window to a specific category
 */
+ (void)openPreferenceWindowToCategoryWithIdentifier:(NSString *)identifier
{
	//Load the window first
	[[self _preferenceWindowController] window];
	
	[[self _preferenceWindowController] selectCategoryWithIdentifier:identifier];
	[[self _preferenceWindowController] showWindow:nil];
}

/*!
 * @brief Open the preference window to a specific advanced category
 */
+ (void)openPreferenceWindowToAdvancedPane:(NSString *)advancedPane
{
	[[self _preferenceWindowController] selectAdvancedPane:advancedPane];
	[[self _preferenceWindowController] showWindow:nil];
}

/*!
 * @brief Close the preference window (if it is open)
 */
+ (void)closePreferenceWindow
{
	if (sharedPreferenceInstance) [sharedPreferenceInstance closeWindow:nil];
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
    if (!sharedPreferenceInstance) {
        sharedPreferenceInstance = [[self alloc] initWithWindowNibName:PREFERENCE_WINDOW_NIB];
    }
    
    return sharedPreferenceInstance;
}

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		loadedPanes = [[NSMutableArray alloc] init];
		loadedAdvancedPanes = nil;
		_advancedCategoryArray = nil;
		shouldRestorePreviousSelectedPane = YES;
	}
	return self;    
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
	[[self window] setTitle:PREFERENCE_WINDOW_TITLE];
	[[[self window] standardWindowButton:NSWindowToolbarButton] setFrame:NSMakeRect(0,0,0,0)];
	[self _configureAdvancedPreferencesTable];
	[[self window] betterCenter];

	//Prepare our array of preference views.  We place these in an array to cut down on a ton of duplicate code.
	viewArray = [[NSArray alloc] initWithObjects:
		view_General,
		view_Accounts,
		view_Personal,
		view_Appearance,
		view_Messages,
		view_Status,
		view_Events,
		view_FileTransfer,
		view_Advanced,
		nil];
}

/*!
 * @brief Invoked before the window opens
 */
- (IBAction)showWindow:(id)sender
{
	//Ensure the window is loaded
	[self window];
	
	//Make the previously selected category active if it is valid
	if (shouldRestorePreviousSelectedPane) {
		NSString *previouslySelectedCategory = [[adium preferenceController] preferenceForKey:KEY_PREFERENCE_SELECTED_CATEGORY
																						group:PREF_GROUP_WINDOW_POSITIONS];
		if (!previouslySelectedCategory || [previouslySelectedCategory isEqualToString:@"loading"])
			previouslySelectedCategory = @"accounts";
		[self selectCategoryWithIdentifier:previouslySelectedCategory];
	}
	
	[super showWindow:sender];
}

/*!
 * @brief Invoked before the window closes
 *
 * We always allow closing of the preference window, so always return YES from this method.  We take this
 * opportunity to save the state of our window and clean up before the window closes.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
		
	//Save changes
	[self _saveControlChanges];
	
    //Save the selected category and advanced category
    [[adium preferenceController] setPreference:[[tabView_category selectedTabViewItem] identifier]
										 forKey:KEY_PREFERENCE_SELECTED_CATEGORY
										  group:PREF_GROUP_WINDOW_POSITIONS];
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[tableView_advanced selectedRow]]
										 forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
										  group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Close all panes and our shared instance
	[loadedPanes makeObjectsPerformSelector:@selector(closeView)];
    [sharedPreferenceInstance autorelease]; sharedPreferenceInstance = nil;
}


//Panes ---------------------------------------------------------------------------------------------------------------
#pragma mark Panes 
/*!
 * @brief Select a preference category
 */
- (void)selectCategoryWithIdentifier:(NSString *)identifier
{
	NSTabViewItem	*tabViewItem;
	int				index;

	//Load the window first
	[self window];
	
	index = [tabView_category indexOfTabViewItemWithIdentifier:identifier];
	if (index != NSNotFound) {
		tabViewItem = [tabView_category tabViewItemAtIndex:index];
		[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
		[tabView_category selectTabViewItem:tabViewItem];    
	}

	shouldRestorePreviousSelectedPane = NO;
}

/*!
 * @brief Select an advanced preference category
 */
- (void)selectAdvancedPane:(NSString *)advancedPane
{
	NSEnumerator		*enumerator = [[self advancedCategoryArray] objectEnumerator];
	AIPreferencePane	*pane;

	shouldRestorePreviousSelectedPane = NO;
	
	//Load the window first
	[self window];

    //First, select the advanced category
    [self selectCategoryWithIdentifier:@"advanced"];

	//Search for the advanded pane
	while ((pane = [enumerator nextObject])) {
		if ([advancedPane caseInsensitiveCompare:[pane label]] == NSOrderedSame) break;
	}

	//If it exists, make it active
	if (pane) {
		int row = [[self advancedCategoryArray] indexOfObject:pane];
		if ([self tableView:tableView_advanced shouldSelectRow:row]) {
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
    while ((pane = [enumerator nextObject])) {
        if ([pane category] == inCategory) {
            [paneArray addObject:pane];
            [loadedPanes addObject:pane];
        }
    }

    //Alphabetize them
    [paneArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return paneArray;
}

/*!
 * @brief Save any preference changes
 *
 * This takes focus away from any controls to ensure that any changes in the current pane are saved.
 * This isn't a problem for most controls, but can cause issues with text fields if the user switches panes
 * with a text field focused.
 */
- (void)_saveControlChanges
{
	[[self window] makeFirstResponder:tabView_category];
}

- (NSDictionary *)identifierToLabelDict
{
	static NSDictionary	*_identifierToLabelDict = nil;
	if (!_identifierToLabelDict) {
		_identifierToLabelDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			ACCOUNTS_TITLE,@"accounts",
			AILocalizedString(@"General",nil),@"general",
			AILocalizedString(@"Personal",nil),@"personal",
			AILocalizedString(@"Appearance",nil),@"appearance",
			AILocalizedString(@"Messages",nil),@"messages",
			AILocalizedString(@"Status",nil),@"status",
			AILocalizedString(@"Events",nil),@"events",
			AILocalizedString(@"File Transfer",nil),@"ft",
			AILocalizedString(@"Advanced",nil),@"advanced",
			AILocalizedString(@"Loading",nil),@"loading",
			nil];
	}

	return _identifierToLabelDict;
}

//Toolbar tab view -----------------------------------------------------------------------------------------------------
#pragma mark Toolbar tab view
/*!
 * @brief Tabview will select a new pane; load the views for that pane.
 */
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if (tabView == tabView_category && 
	   ![[tabViewItem identifier] isEqualToString:@"loading"]) {
		
		int selectedIndex = [tabView indexOfTabViewItem:tabViewItem];

		//Save changes
		[self _saveControlChanges];
		
		//Load the pane if it isn't already loaded
		if (![[tabViewItem identifier] isEqualToString:ADVANCED_PANE_IDENTIFIER]) {
			AIModularPaneCategoryView *view = [viewArray objectAtIndex:selectedIndex];
			if ([view isEmpty]) [view setPanes:[self _panesInCategory:selectedIndex]];
		}
		
		//Update the window title, using only the currently selected pane, per the Mac OS X standard
		[[self window] setTitle:[NSString stringWithFormat:@"%@",
									[self tabView:tabView labelForTabViewItem:tabViewItem]]];
   }
}

/*!
 * @brief Tabview will select a new pane; should it immediately show the loading indicator?
 *
 * We only immediately show the loading inidicator if the view is empty.
 */
- (BOOL)immediatelyShowLoadingIndicatorForTabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabView == tabView_category) {
		AIModularPaneCategoryView *view = [viewArray objectAtIndex:[tabView indexOfTabViewItem:tabViewItem]];
		if ([view isEmpty]) return YES;
	}

	return NO;
}

/*!
 * @brief Returns the preference image associated with the tab view item
 */
- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	return [NSImage imageNamed:[NSString stringWithFormat:PREFERENCE_ICON_FORMAT, [tabViewItem identifier]] forClass:[self class]];
}

/*!
 * @brief Returns the localized label for the tab view item
 */
- (NSString *)tabView:(NSTabView *)tabView labelForTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabView == tabView_category) {
		NSString	*identifier;
		if ((identifier = [tabViewItem identifier])) {
			return [[self identifierToLabelDict] objectForKey:identifier];
		}
	}
	
	return nil;
}

/*!
 * @brief Returns the desired height for the tab view item
 */
- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (![[tabViewItem identifier] isEqualToString:ADVANCED_PANE_IDENTIFIER]) {
		return [[viewArray objectAtIndex:[tabView indexOfTabViewItem:tabViewItem]] desiredHeight];
	} else {
		return ADVANCED_PANE_HEIGHT;
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
	while ((pane = [enumerator nextObject])) {
		[pane closeView];
	}
	[view_Advanced removeAllSubviews];
	[loadedAdvancedPanes release]; loadedAdvancedPanes = nil;
	
	//Load new panes
	if (preferencePane) {
		loadedAdvancedPanes = [[NSArray arrayWithObject:preferencePane] retain];
		[view_Advanced setPanes:loadedAdvancedPanes];
	}
}

/*!
 * @brief Returns an array containing all the available advanced preference views
 */
- (NSArray *)advancedCategoryArray
{
    if (!_advancedCategoryArray) {
        _advancedCategoryArray = [[self _panesInCategory:AIPref_Advanced] retain];
    }
    
    return _advancedCategoryArray;
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
	
    [scrollView_advanced setAutohidesScrollers:YES];
	
	//Select the previously selected row
	int row = [[[adium preferenceController] preferenceForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
														group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	if (row < 0 || row >= [tableView_advanced numberOfRows]) row = 1;
	
	if ([self tableView:tableView_advanced shouldSelectRow:row]) {
		[tableView_advanced selectRow:row byExtendingSelection:NO];
	}
}

/*!
 * @brief Return the number of accounts
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self advancedCategoryArray] count];
}

/*!
 * @brief Return the account description or image
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [[[self advancedCategoryArray] objectAtIndex:row] label];
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
	if (row >= 0 && row < [[self advancedCategoryArray] count]) {		
		[self configureAdvancedPreferencesForPane:[[self advancedCategoryArray] objectAtIndex:row]];
		return YES;
    } else {
		return NO;
	}
}

@end
