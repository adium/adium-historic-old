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

#import "AIOfflineContactHidingPlugin.h"

#define	PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define SHOW_OFFLINE_MENU_TITLE				AILocalizedString(@"Show Offline Contacts",nil)
#define HIDE_OFFLINE_MENU_TITLE				AILocalizedString(@"Hide Offline Contacts",nil)
#define KEY_SHOW_OFFLINE_CONTACTS			@"Show Offline Contacts"
#define OFFLINE_CONTACTS_IDENTIFER			@"OfflineContacts"

@interface AIOfflineContactHidingPlugin (PRIVATE)
- (void)configureOfflineContactHiding;
- (void)configurePreferences;
@end

@implementation AIOfflineContactHidingPlugin

//Install
- (void)installPlugin
{
	//Configure the preferences first to have correct values for the following calls
    [self configurePreferences];
	
	//Observe contact and preference changes
    [[adium contactController] registerListObjectObserver:self];
	
	//Show offline contacts menu item
    showOfflineMenuItem = [[NSMenuItem alloc] initWithTitle:(showOfflineContacts ?
															 HIDE_OFFLINE_MENU_TITLE : 
															 SHOW_OFFLINE_MENU_TITLE)
													 target:self
													 action:@selector(toggleOfflineContactsMenu:)
											  keyEquivalent:@"H"];
	[[adium menuController] addMenuItem:showOfflineMenuItem toLocation:LOC_View_Unnamed_B];		

	//Toolbar
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:OFFLINE_CONTACTS_IDENTIFER
														  label:AILocalizedString(@"Offline Contacts",nil)
												   paletteLabel:AILocalizedString(@"Toggle Offline Contacts",nil)
														toolTip:AILocalizedString(@"Toggle display of offline contacts",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"offlineContacts" forClass:[self class]]
														 action:@selector(toggleOfflineContactsMenu:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ContactList"];
}

//Uninstall
- (void)uninstallPlugin
{
	[showOfflineMenuItem release]; showOfflineMenuItem = nil;
    [[adium contactController] unregisterListObjectObserver:self];
}

//Set up preferences initially
- (void)configurePreferences
{
	showOfflineContacts = [[[adium preferenceController] preferenceForKey:KEY_SHOW_OFFLINE_CONTACTS
																	group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
}

//Toggle the display of offline contacts (call from menu)
- (IBAction)toggleOfflineContactsMenu:(id)sender
{
	showOfflineContacts = !showOfflineContacts;
	
	//Store the preference
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:showOfflineContacts]
										 forKey:KEY_SHOW_OFFLINE_CONTACTS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	//Update the menu item's title
	[self configureOfflineContactHiding];
}

//Set Show/Hide Text and update the contact list
- (void)configureOfflineContactHiding
{
	//The menu item shows the opposite of the current state, since that what happens if you toggle it
	[showOfflineMenuItem setTitle:(showOfflineContacts ? HIDE_OFFLINE_MENU_TITLE : SHOW_OFFLINE_MENU_TITLE)];

	//Refresh visibility of all contacts
	[[adium contactController] updateAllListObjectsForObserver:self];

	//Resort the entire list, since we know the whole thing changed
	[[adium contactController] sortContactList];	
}

//Update visibility of a list object
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Online"] ||
	   [inModifiedKeys containsObject:@"Signed Off"] ||
	   [inModifiedKeys containsObject:@"VisibleObjectCount"]){

		if([inObject isKindOfClass:[AIListContact class]]){
			int		online = [inObject online];
			int		justSignedOff = [inObject integerStatusObjectForKey:@"Signed Off"];
//			NSLog(@"%@ Visible? %i || %i || %i == %i",inObject,showOfflineContacts,online,justSignedOff,(showOfflineContacts || online || justSignedOff));
			[inObject setVisible:(showOfflineContacts || online || justSignedOff)];
			
		}else if([inObject isKindOfClass:[AIListGroup class]]){
			int visibleCount = [(AIListGroup *)inObject visibleCount];
			
			[inObject setVisible:(showOfflineContacts || visibleCount > 0)];
			
		}
	}
	
    return(nil);
}

@end
