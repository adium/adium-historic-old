//
//  CBContactCountingDisplayPlugin.h
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define PREF_GROUP_CONTACT_LIST     @"Contact List"
#define KEY_COUNT_ALL_CONTACTS      @"Count All Contacts"
#define KEY_COUNT_VISIBLE_CONTACTS  @"Count Visible Contacts"

@class CBContactCountingDisplayPreferences;

@interface CBContactCountingDisplayPlugin : AIPlugin 
{
    BOOL                                allCount;
    BOOL                                visibleCount;
    
    CBContactCountingDisplayPreferences *prefs;
}
- (void)installPlugin;
- (void)uninstallPlugin;

- (void)preferencesChanged:(NSNotification *)notification;
- (void)contactsChanged:(NSNotification *)notification;
@end
