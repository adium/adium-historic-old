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

#import "AIBorderlessListWindowController.h"
#import "AIInterfaceController.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"
#import "AISCLViewPlugin.h"
#import "AIStandardListWindowController.h"
#import "ESContactListAdvancedPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>

#define PREF_GROUP_APPEARANCE		@"Appearance"

/*!
 * @class AISCLViewPlugin
 * @brief This component plugin is responsible for window and view of the contact list
 *
 * Either an AIStandardListWindowController or AIBorderlessListWindowController, each of which is a subclass of AIListWindowController,
 * is instantiated. This window controller, with the help of the plugin, will be responsible for display of an AIListOutlineView.
 * The borderless window controller uses an AIBorderlessListOutlineView.
 *
 * In either case, the outline view itself is controlled by an instance of AIListController.
 *
 * AISCLViewPlugin's class methods also manage ListLayout and ListTheme preference sets. ListLayout sets determine the contents and layout
 * of the contact list; ListTheme sets control the colors used in the contact list.
 */
@implementation AISCLViewPlugin

- (void)installPlugin
{
    [[adium interfaceController] registerContactListController:self];

    //Install our preference views
	advancedPreferences = [[ESContactListAdvancedPreferences preferencePane] retain];
	   
	//Observe list closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListDidClose)
									   name:Interface_ContactListDidClose
									 object:nil];

	AIPreferenceController *preferenceController = [adium preferenceController];
	
	//Now register our other defaults, which are 
    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTACT_LIST_DEFAULTS
																forClass:[self class]]
	                              forGroup:PREF_GROUP_CONTACT_LIST];
	
	//Observe window style changes
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller

/*
 * @brief Retrieve the AIListWindowController in use
 */
- (AIListWindowController *)contactListWindowController {
	return contactListWindowController;
}

//Show contact list
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
    if (!contactListWindowController) { //Load the window
		if (windowStyle == WINDOW_STYLE_STANDARD) {
			contactListWindowController = [[AIStandardListWindowController listWindowController] retain];
		} else {
			contactListWindowController = [[AIBorderlessListWindowController listWindowController] retain];
		}
    }
	
	[contactListWindowController showWindowInFront:bringToFront];
}

//Returns YES if the contact list is visible and in front
- (BOOL)contactListIsVisibleAndMain
{
	return (contactListWindowController &&
			[[contactListWindowController window] isVisible] &&
			[[contactListWindowController window] isMainWindow]);
}

//Close contact list
- (void)closeContactList
{
    if (contactListWindowController) {
        [[contactListWindowController window] performClose:nil];
    }
}

//Callback when the contact list closes, clear our reference to it
- (void)contactListDidClose
{
	[contactListWindowController release];
	contactListWindowController = nil;
}


//Themes and Layouts ---------------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//Apply any theme/layout changes
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime || !key || [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE]) {
		int	newWindowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		
		if (newWindowStyle != windowStyle) {
			windowStyle = newWindowStyle;
			
			//If a contact list is visible and the window style has changed, update for the new window style
			if (contactListWindowController) {
				//XXX - Evan: I really do not like this at all.  What to do?
				//We can't close and reopen the contact list from within a preferencesChanged call, as the
				//contact list itself is a preferences observer and will modify the array for its group as it
				//closes... and you can't modify an array while enuemrating it, which the preferencesController is
				//currently doing.  This isn't pretty, but it's the most efficient fix I could come up with.
				//It has the obnoxious side effect of the contact list changing its view prefs and THEN closing and
				//reopening with the right windowStyle.
				[self performSelector:@selector(closeAndReopencontactList)
						   withObject:nil
						   afterDelay:0.00001];
			}
		}
	}
}

- (void)closeAndReopencontactList
{
	[self closeContactList];
	[self showContactListAndBringToFront:NO];
}

@end

