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

@interface CBContactCountingDisplayPlugin : AIPlugin <AIListObjectObserver>
{
    BOOL                                allCount;
    BOOL                                visibleCount;
    
    NSMenuItem                          *visibleCountingMenuItem;
    NSMenuItem                          *allCountingMenuItem;
    
    CBContactCountingDisplayPreferences *prefs;
}
- (void)installPlugin;
- (void)uninstallPlugin;

- (void)preferencesChanged:(NSNotification *)notification;
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
@end
