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
#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AICLPreferences.h"
#import "ESCLViewAdvancedPreferences.h"
#import "ESCLViewLabelsAdvancedPrefs.h"
#import "AISCLViewController.h"
#import "AIStandardListWindowController.h"
#import "AIBorderlessListWindowController.h"
#import "AIContactListAdvancedPrefs.h"


#define BORDERLESS_CONTACT_LIST	YES

@interface AISCLViewPlugin (PRIVATE)
@end

@implementation AISCLViewPlugin

#define LABELS_THEMABLE_PREFS   @"Labels Themable Prefs"
#define SCL_THEMABLE_PREFS      @"SCL Themable Prefs"

- (void)installPlugin
{
    [[adium interfaceController] registerContactListController:self];

    //Register our default preferences and install our preference views
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:LABELS_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:SCL_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    
    preferences = [[AICLPreferences preferencePane] retain];
    preferencesGroup = [[AICLGroupPreferences preferencePane] retain];
    preferencesAdvanced = [[ESCLViewAdvancedPreferences preferencePane] retain];
    preferencesLabelsAdvanced = [[ESCLViewLabelsAdvancedPrefs preferencePane] retain];
	[[AIContactListAdvancedPrefs preferencePane] retain];
}



//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
    if(!contactListWindowController){ //Load the window
		if(BORDERLESS_CONTACT_LIST){
			contactListWindowController = [[AIBorderlessListWindowController listWindowController] retain];
		}else{
			contactListWindowController = [[AIStandardListWindowController listWindowController] retain];
		}
    }
    [contactListWindowController makeActive:nil];

    if(bringToFront) [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (BOOL)contactListIsVisibleAndMain
{
	return(contactListWindowController && [[contactListWindowController window] isMainWindow]);
}

- (void)closeContactList
{
    if(contactListWindowController){
        [[contactListWindowController window] performClose:nil];
    }
}

//Callback when the contact list closes, clear our reference to it
- (void)contactListDidClose
{
	[contactListWindowController release];
	contactListWindowController = nil;
}


@end



