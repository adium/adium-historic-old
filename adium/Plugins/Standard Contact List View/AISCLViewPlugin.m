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

#import "AISCLViewPlugin.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AICLPreferences.h"
#import "ESCLViewAdvancedPreferences.h"
#import "ESCLViewLabelsAdvancedPrefs.h"
#import "AISCLViewController.h"

@interface AISCLViewPlugin (PRIVATE)
@end

@implementation AISCLViewPlugin

#define LABELS_THEMABLE_PREFS   @"Labels Themable Prefs"
#define SCL_THEMABLE_PREFS      @"SCL Themable Prefs"

- (void)installPlugin
{
    //Register ourself as a contact list view plugin
    [[adium interfaceController] registerContactListViewPlugin:self];

    //Register our default preferences and install our preference views
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:LABELS_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:SCL_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    
    preferences = [[AICLPreferences preferencePane] retain];
    preferencesGroup = [[AICLGroupPreferences preferencePane] retain];
    preferencesAdvanced = [[ESCLViewAdvancedPreferences preferencePane] retain];
    preferencesLabelsAdvanced = [[ESCLViewLabelsAdvancedPrefs preferencePane] retain];
}

//Return a new contact list view controller
- (id <AIContactListViewController>)contactListViewController
{
    return([AISCLViewController contactListViewController]);
}

@end



