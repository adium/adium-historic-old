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
#import "SS_PrefsController.h"

#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIWindowControllerAdditions.h>

//Preferences
#define KEY_PREFERENCE_SELECTED_CATEGORY		@"Preference Selected Category Name"

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
- (NSArray *)_panesInCategory:(AIPreferenceCategory)inCategory;
- (void)_saveControlChanges;
- (void)_configureAdvancedPreferencesTable;
- (void)_configreTabViewItemLabels;
- (NSString *)tabView:(NSTabView *)tabView labelForTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)sizeWindowForToolbar;
@end

static SS_PrefsController			*prefsController = nil;

/*!
 * @class AIPreferenceWindowController
 * @brief Adium preference window controller
 *
 * Implements the main preference window.  This window pulls the preference panes registered with the preference
 * controller by plugins and places, organizing them by category.
 */
@implementation AIPreferenceWindowController

+ (SS_PrefsController *)sharedPrefsController
{
	if (!prefsController) {
		prefsController = [[SS_PrefsController preferencesWithPanes:[[[AIObject sharedAdiumInstance] preferenceController] paneArray]] retain];

		// Set which panes are included, and their order.
		[prefsController setPanesOrder:[NSArray arrayWithObjects:
			@"Accounts",
			NSToolbarSeparatorItemIdentifier,
			@"General", @"Personal", @"Appearance", @"Messages", @"Status", @"Events", @"File Transfer", @"Advanced", nil]];
		[prefsController setDebug:YES];
	}
	
	return prefsController;
}

/*!
 * @brief Open the preference window
 */
+ (void)openPreferenceWindow
{
	// Show the preferences window.
	[[self sharedPrefsController] showPreferencesWindow];
}

/*!
 * @brief Open the preference window to a specific category
 */
+ (void)openPreferenceWindowToCategoryWithIdentifier:(NSString *)identifier
{	
	[[self sharedPrefsController] createPreferencesWindowAndDisplay:NO];
	[[self sharedPrefsController] loadPreferencePaneNamed:identifier];
	[[self sharedPrefsController] showPreferencesWindow];
}

/*!
 * @brief Close the preference window (if it is open)
 */
+ (void)closePreferenceWindow
{
	[prefsController destroyPreferencesWindow];
	[prefsController release]; prefsController = nil;
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
		    
    //Close all panes and our shared instance
#warning XXX
//	[loadedPanes makeObjectsPerformSelector:@selector(closeView)];
}

//Panes ---------------------------------------------------------------------------------------------------------------
#pragma mark Panes 
/*!
 * @brief Select a preference category
 */
- (void)selectCategoryWithIdentifier:(NSString *)identifier
{
#if 0
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
#endif
}

/*!
 * @brief Tabview will select a new pane; should it immediately show the loading indicator?
 *
 * We only immediately show the loading inidicator if the view is empty.
 */
- (BOOL)immediatelyShowLoadingIndicatorForTabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
#if 0
	if (tabView == tabView_category) {
		AIModularPaneCategoryView *view = [viewArray objectAtIndex:[tabView indexOfTabViewItem:tabViewItem]];
		if ([view isEmpty]) return YES;
	}
#endif
	return NO;
}

@end
