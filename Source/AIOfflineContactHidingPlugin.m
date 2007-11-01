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

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import "AIOfflineContactHidingPlugin.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import "AIContactController.h"

#define HIDE_CONTACTS_MENU_TITLE			AILocalizedString(@"Hide Certain Contacts",nil)
#define HIDE_OFFLINE_MENU_TITLE				AILocalizedString(@"Hide Offline Contacts",nil)
#define HIDE_IDLE_MENU_TITLE				AILocalizedString(@"Hide Idle Contacts",nil)
#define	USE_OFFLINE_GROUP_MENU_TITLE		AILocalizedString(@"Show Offline Group",nil)

#define OFFLINE_CONTACTS_IDENTIFER			@"OfflineContacts"

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
	
	//"Hide Contacts" menu item
	menuItem_hideContacts = [[NSMenuItem alloc] initWithTitle:HIDE_CONTACTS_MENU_TITLE
													  target:self
													  action:@selector(toggleHideContacts:)
											   keyEquivalent:@"H"];
	[[adium menuController] addMenuItem:menuItem_hideContacts toLocation:LOC_View_Toggles];		
	
	
	//Show offline contacts menu item
    menuItem_hideOffline = [[NSMenuItem alloc] initWithTitle:HIDE_OFFLINE_MENU_TITLE
													 target:self
													 action:@selector(toggleOfflineContactsMenu:)
											  keyEquivalent:@""];
	[menuItem_hideOffline setIndentationLevel:1];
	[[adium menuController] addMenuItem:menuItem_hideOffline toLocation:LOC_View_Toggles];		
	
    menuItem_hideIdle = [[NSMenuItem alloc] initWithTitle:HIDE_IDLE_MENU_TITLE
												   target:self
												   action:@selector(toggleIdleContactsMenu:)
											keyEquivalent:@""];
	[menuItem_hideIdle setIndentationLevel:1];
	[[adium menuController] addMenuItem:menuItem_hideIdle toLocation:LOC_View_Toggles];	

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
	[menuItem_hideOffline release]; menuItem_hideOffline = nil;
	[menuItem_hideIdle release]; menuItem_hideIdle = nil;
	[menuItem_useOfflineGroup release]; menuItem_useOfflineGroup = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	hideContacts = [[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue];
	showOfflineContacts = [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue];
	showIdleContacts = [[prefDict objectForKey:KEY_SHOW_IDLE_CONTACTS] boolValue];

	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = (useContactListGroups && [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);

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
	[menuItem_hideContacts setState:hideContacts];
	[menuItem_hideOffline setState:!showOfflineContacts];
	[menuItem_hideIdle setState:!showIdleContacts];
	[menuItem_useOfflineGroup setState:useOfflineGroup];
}

/*!
 * @brief Toggle contact hiding
 */
- (IBAction)toggleHideContacts:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!hideContacts]
										 forKey:KEY_HIDE_CONTACTS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
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

- (IBAction)toggleIdleContactsMenu:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!showIdleContacts]
										 forKey:KEY_SHOW_IDLE_CONTACTS
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
		[inModifiedKeys containsObject:@"IdleSince"] ||
		[inModifiedKeys containsObject:@"Signed Off"] ||
		[inModifiedKeys containsObject:@"New Object"] ||
		[inModifiedKeys containsObject:@"VisibleObjectCount"]) {

		if ([inObject isKindOfClass:[AIListContact class]]) {
			BOOL visible = YES;
			
			// If we're hiding contacts, and these meet a criteria for hiding
			if (hideContacts && (([inObject statusObjectForKey:@"IdleSince"] &&
								  !showIdleContacts) ||
								 (!showOfflineContacts &&
								  ![inObject online] &&
								  ![inObject integerStatusObjectForKey:@"Signed Off"] &&
								  ![inObject integerStatusObjectForKey:@"New Object"]))) {
				visible = NO;
			}

			if ([inObject conformsToProtocol:@protocol(AIContainingObject)]) {
				//A metaContact must meet the criteria for a contact to be visible and also have at least 1 contained contact
				[inObject setVisible:(visible &&
									  ([(AIListContact<AIContainingObject> *)inObject visibleCount] > 0))];
				
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_useOfflineGroup) {
		return useContactListGroups;
	} else if (menuItem == menuItem_hideOffline || menuItem == menuItem_hideIdle) {
		return hideContacts;
	}
	
	return YES;
}
@end
