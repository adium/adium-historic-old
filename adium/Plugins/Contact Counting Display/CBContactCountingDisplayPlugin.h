//
//  CBContactCountingDisplayPlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Jan 11 2004.
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
