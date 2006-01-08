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

#import "AIContactController.h"
#import "AIMenuController.h"
#import "AIOfflineContactHidingPlugin.h"
#import "AIPreferenceController.h"
#import "AIToolbarController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>

#define	PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define SHOW_OFFLINE_MENU_TITLE				AILocalizedString(@"Show Offline Contacts",nil)
#define KEY_SHOW_OFFLINE_CONTACTS			@"Show Offline Contacts"

#define	USE_OFFLINE_GROUP_MENU_TITLE		AILocalizedString(@"Show Offline Group",nil)
#define	KEY_USE_OFFLINE_GROUP				@"Use Offline Group"

#define OFFLINE_CONTACTS_IDENTIFER			@"OfflineContacts"
#define	KEY_HIDE_CONTACT_LIST_GROUPS		@"Hide Contact List Groups"

/*!
 * @class AIOfflineContactHidingPlugin
 * @brief Component to handle showing or hiding offline contacts and hiding empty groups
 */
@implementation AIOfflineContactHidingPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{	
	//Default preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:@"OfflineContactHidingDefaults" forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	//Show offline contacts menu item
    menuItem_showOffline = [[NSMenuItem alloc] initWithTitle:SHOW_OFFLINE_MENU_TITLE
													 target:self
													 action:@selector(toggleOfflineContactsMenu:)
											  keyEquivalent:@"H"];
	[[adium menuController] addMenuItem:menuItem_showOffline toLocation:LOC_View_Toggles];		

	menuItem_useOfflineGroup = [[NSMenuItem alloc] initWithTitle:USE_OFFLINE_GROUP_MENU_TITLE
														  target:self
														  action:@selector(toggleUseOfflineGroup:)
												   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_useOfflineGroup toLocation:LOC_View_Toggles];
	
	//Register preference observer first so values will be correct for the following calls
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	//Toolbar
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:OFFLINE_CONTACTS_IDENTIFER
														  label:AILocalizedString(@"Offline Contacts",nil)
												   paletteLabel:AILocalizedString(@"Toggle Offline Contacts",nil)
														toolTip:AILocalizedString(@"Toggle display of offline contacts",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"offlinecontacts"
																		   forClass:[self class]]
														 action:@selector(toggleOfflineContactsToolbar:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ContactList"];
	
	//Toolbar item registration
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
    [[adium    contactController] unregisterListObjectObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[menuItem_showOffline release]; menuItem_showOffline = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	showOfflineContacts = [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue];
	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue];

	if (firstTime) {
		//Observe contact and preference changes
		[[adium contactController] registerListObjectObserver:self];
	} else {
		//Refresh visibility of all contacts
		[[adium contactController] updateAllListObjectsForObserver:self];
		
		//Resort the entire list, forcing the visibility changes to hae an immediate effect (we return nil in the 
		//updateListObject: method call, so the contact controller doesn't know we changed anything)
		[[adium contactController] sortContactList];
	}

	//Update our menu to reflect the current preferences
	[menuItem_showOffline setState:showOfflineContacts];
	[menuItem_useOfflineGroup setState:useOfflineGroup];
}

/*!
 * @brief Toggle the display of offline contacts
 */
- (IBAction)toggleOfflineContactsMenu:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!showOfflineContacts]
										 forKey:KEY_SHOW_OFFLINE_CONTACTS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

- (IBAction)toggleOfflineContactsToolbar:(id)sender
{
	[self toggleOfflineContactsMenu:sender];
	
	[sender setImage:[NSImage imageNamed:(showOfflineContacts ?
										  @"offlinecontacts_transparent" :
										  @"offlinecontacts")
								forClass:[self class]]];
}

/*!
* @brief After the toolbar has added the item we can set up the submenus
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if ([[item itemIdentifier] isEqualToString:OFFLINE_CONTACTS_IDENTIFER]) {
		[item setImage:[NSImage imageNamed:(showOfflineContacts ?
											@"offlinecontacts_transparent" :
											@"offlinecontacts")
								  forClass:[self class]]];
	}
}

/*!
 * @brief Update visibility of a list object
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if (inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Online"] ||
	   [inModifiedKeys containsObject:@"Signed Off"] ||
	   [inModifiedKeys containsObject:@"New Object"] ||
	   [inModifiedKeys containsObject:@"VisibleObjectCount"]) {

		if ([inObject isKindOfClass:[AIListContact class]]) {
			BOOL	visible = (showOfflineContacts || 
							   [inObject online] ||
							   [inObject integerStatusObjectForKey:@"Signed Off"] ||
							   [inObject integerStatusObjectForKey:@"New Object"]);

			if ([inObject isKindOfClass:[AIMetaContact class]]) {
				//A metaContact must meet the criteria for a contact to be visible and also have at least 1 contained contact
				[inObject setVisible:(visible &&
									  ([(AIMetaContact *)inObject visibleCount] > 0))];
				
			} else {
				[inObject setVisible:visible];
			}

		} else if ([inObject isKindOfClass:[AIListGroup class]]) {
			BOOL	newObject = [inObject integerStatusObjectForKey:@"New Object"];

			[inObject setVisible:((useContactListGroups) &&
								  ([(AIListGroup *)inObject visibleCount] > 0 || newObject) &&
								  (useOfflineGroup || ((AIListGroup *)inObject != [[adium contactController] offlineGroup])))];
		}
	}
	
    return nil;
}

#pragma mark Offline group

- (IBAction)toggleUseOfflineGroup:(id)sender
{
	//Store the preference
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!useOfflineGroup]
										 forKey:KEY_USE_OFFLINE_GROUP
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if (menuItem == menuItem_useOfflineGroup) {
		return (useContactListGroups && showOfflineContacts);
	}
	
	return YES;
}
@end
