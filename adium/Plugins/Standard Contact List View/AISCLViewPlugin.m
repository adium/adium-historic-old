/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AISCLViewPlugin.h"
#import "AICLPreferences.h"
#import "AIStandardListWindowController.h"
#import "AIBorderlessListWindowController.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"

@interface AISCLViewPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AISCLViewPlugin

- (void)installPlugin
{
    [[adium interfaceController] registerContactListController:self];

	[adium createResourcePathForName:LIST_LAYOUT_FOLDER];
	[adium createResourcePathForName:LIST_THEME_FOLDER];

    //Register our default preferences and install our preference views
//    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    preferences = [[AICLPreferences preferencePane] retain];

	//Observe list closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListDidClose)
									   name:Interface_ContactListDidClose
									 object:nil];
	
    //Observe window style changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    [self preferencesChanged:nil];
}


//Refresh the contact list window when the window style changes
- (void)preferencesChanged:(NSNotification *)notification
{
	NSString	*group = [[notification userInfo] objectForKey:@"Group"];
    if(notification == nil || [group isEqualToString:PREF_GROUP_LIST_LAYOUT]){
		NSString	*key = [[notification userInfo] objectForKey:@"Key"];

		if(notification == nil || !key || [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE]){
			windowStyle = [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE
																	group:PREF_GROUP_LIST_LAYOUT] intValue];
			if(contactListWindowController){
				[self closeContactList];
				[self showContactListAndBringToFront:NO];
			}
		}
	}
}


//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//Show contact list
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
    if(!contactListWindowController){ //Load the window
		if(windowStyle == WINDOW_STYLE_STANDARD){
			contactListWindowController = [[AIStandardListWindowController listWindowController] retain];
		}else{
			contactListWindowController = [[AIBorderlessListWindowController listWindowController] retain];
		}
    }

	[contactListWindowController showWindowInFront:bringToFront];
}

//Returns YES if the contact list is visible and in front
- (BOOL)contactListIsVisibleAndMain
{
	return(contactListWindowController && [[contactListWindowController window] isMainWindow]);
}

//Close contact list
- (void)closeContactList
{
    if(contactListWindowController){
        [[contactListWindowController window] performClose:nil];
		[self contactListDidClose];
    }
}

//Callback when the contact list closes, clear our reference to it
- (void)contactListDidClose
{
	[contactListWindowController release];
	contactListWindowController = nil;
}

@end

