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

#import "AIOfflineContactHidingPlugin.h"

#define	PREF_GROUP_CONTACT_LIST_DISPLAY @"Contact List Display"
#define SHOW_OFFLINE_MENU_TITLE 		@"Show Offline Contacts"
#define KEY_SHOW_OFFLINE_CONTACTS 		@"Show Offline Contacts"

@interface AIOfflineContactHidingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIOfflineContactHidingPlugin

//Install
- (void)installPlugin
{
	//Show offline contacts menu item
    showOfflineMenuItem = [[NSMenuItem alloc] initWithTitle:SHOW_OFFLINE_MENU_TITLE
													 target:self
													 action:@selector(toggleOfflineContactsMenu:)
											  keyEquivalent:@""];
	[[adium menuController] addMenuItem:(NSMenuItem *)[NSMenuItem separatorItem] toLocation:LOC_View_General];		
	[[adium menuController] addMenuItem:showOfflineMenuItem toLocation:LOC_View_General];		

	//Observe contact and preference changes
    [[adium contactController] registerListObjectObserver:self];
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//Uninstall
- (void)uninstallPlugin
{
	[showOfflineMenuItem release];
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
}

//Toggle the display of offline contacts (call from menu)
- (IBAction)toggleOfflineContactsMenu:(id)sender
{
	[sender setState:![sender state]];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
										 forKey:KEY_SHOW_OFFLINE_CONTACTS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

//Our preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST_DISPLAY] == 0){
		BOOL showOffline = [[[adium preferenceController] preferenceForKey:KEY_SHOW_OFFLINE_CONTACTS
																	 group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
		if(showOffline != [showOfflineMenuItem state]){
			[showOfflineMenuItem setState:showOffline];
		}
		
		//Refresh visibility of all contacts
		[[adium contactController] updateAllListObjectsForObserver:self];
		
		//Resort the entire list, since we know the whole thing changed
		[[adium contactController] sortContactList];
    }
}

//Update visibility of a list object
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Online"] ||
	   [inModifiedKeys containsObject:@"Signed Off"] ||
	   [inModifiedKeys containsObject:@"VisibleObjectCount"]){

		BOOL	showOffline = [[inObject preferenceForKey:KEY_SHOW_OFFLINE_CONTACTS
													group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
		
		if([inObject isKindOfClass:[AIListContact class]]){
			int		online = [inObject integerStatusObjectForKey:@"Online"];
			int		justSignedOff = [inObject integerStatusObjectForKey:@"Signed Off"];
			
			[inObject setVisible:(showOffline || online || justSignedOff)];
			
		}else if([inObject isKindOfClass:[AIListGroup class]]){
			int visibleCount = [(AIListGroup *)inObject visibleCount];
			
			[inObject setVisible:(showOffline || visibleCount > 0)];
			
		}
	}
	
    return(nil);
}

@end
