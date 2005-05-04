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
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>

#define	PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define SHOW_OFFLINE_MENU_TITLE				AILocalizedString(@"Show Offline Contacts",nil)
#define KEY_SHOW_OFFLINE_CONTACTS			@"Show Offline Contacts"
#define OFFLINE_CONTACTS_IDENTIFER			@"OfflineContacts"
#define	KEY_HIDE_CONTACT_LIST_GROUPS		@"Hide Contact List Groups"

@interface AIOfflineContactHidingPlugin (PRIVATE)
- (void)configureOfflineContactHiding;
- (void)configurePreferences;
@end

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
	//Show offline contacts menu item
    showOfflineMenuItem = [[NSMenuItem alloc] initWithTitle:SHOW_OFFLINE_MENU_TITLE
													 target:self
													 action:@selector(toggleOfflineContactsMenu:)
											  keyEquivalent:@"H"];
	[[adium menuController] addMenuItem:showOfflineMenuItem toLocation:LOC_View_Toggles];		

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
	[showOfflineMenuItem release]; showOfflineMenuItem = nil;
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

	if(firstTime){
		//Observe contact and preference changes
		[[adium contactController] registerListObjectObserver:self];
	}else{
		//Refresh visibility of all contacts
		[[adium contactController] updateAllListObjectsForObserver:self];
		
		//Resort the entire list, forcing the visibility changes to hae an immediate effect (we return nil in the 
		//updateListObject: method call, so the contact controller doesn't know we changed anything)
		[[adium contactController] sortContactList];
	}

	//Update our menu to reflect the current preferences
	[showOfflineMenuItem setState:showOfflineContacts];
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
	
	if([[item itemIdentifier] isEqualToString:OFFLINE_CONTACTS_IDENTIFER]){
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
    if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Online"] ||
	   [inModifiedKeys containsObject:@"Signed Off"] ||
	   [inModifiedKeys containsObject:@"New Object"] ||
	   [inModifiedKeys containsObject:@"VisibleObjectCount"]){

		if([inObject isKindOfClass:[AIListContact class]]){
			BOOL	online = [inObject online];
			BOOL	justSignedOff = [inObject integerStatusObjectForKey:@"Signed Off"];
			BOOL	newObject = [inObject integerStatusObjectForKey:@"New Object"];

			if([inObject isKindOfClass:[AIMetaContact class]]){
				[inObject setVisible:((online) || 
									  (justSignedOff) || 
									  (newObject) ||
									  (showOfflineContacts && ([(AIMetaContact *)inObject visibleCount] > 0)))];
				
			}else{
				[inObject setVisible:(showOfflineContacts || online || justSignedOff || newObject)];
			}

		}else if([inObject isKindOfClass:[AIListGroup class]]){
			BOOL	newObject = [inObject integerStatusObjectForKey:@"New Object"];

			[inObject setVisible:((useContactListGroups) &&
								  ([(AIListGroup *)inObject visibleCount] > 0 || newObject))];
		}
	}
	
    return(nil);
}

@end
