/* 
Adium, Copyright 2001-2004, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

//Preference groups
#define PREF_GROUP_GENERAL              @"General"
#define PREF_GROUP_ACCOUNTS             @"Accounts"
#define PREF_GROUP_TOOLBARS 			@"Toolbars"
#define PREF_GROUP_WINDOW_POSITIONS     @"Window Positions"
#define PREF_GROUP_SPELLING 			@"Spelling"
#define OBJECT_PREFS_PATH               @"ByObject"				//Path to object specific preference folder
#define ACCOUNT_PREFS_PATH              @"Accounts"				//Path to account specific preference folder

//Preference Categories
typedef enum {
    AIPref_Accounts = 0, 
    AIPref_ContactList,
    AIPref_Messages,
    AIPref_Status_Away,
    AIPref_Status_Idle,
    AIPref_Dock,
    AIPref_Sound,
    AIPref_Emoticons,    
    AIPref_Keys,
    AIPref_Advanced_ContactList,
    AIPref_Advanced_Messages,
    AIPref_Advanced_Status,
    AIPref_Advanced_Service,
    AIPref_Advanced_Other,
} PREFERENCE_CATEGORY;

@class AIPreferencePane, AIAdium;

@interface AIPreferenceController : NSObject {
    IBOutlet	AIAdium		*adium;
	NSString				*userDirectory;
	
    NSMutableArray			*paneArray;						//Loaded preference panes
	NSMutableDictionary		*observers;						//Preference change observers

    NSMutableDictionary		*prefCache;						//Preference cache
    NSMutableDictionary		*objectPrefCache;				//Object specific preferences cache

    int						preferenceChangeDelays;			//Number of active delays (0 = not delayed)
    NSMutableSet			*delayedNotificationGroups;  	//Groups with delayed changes
}

- (void)initController;
- (void)willFinishIniting;
- (void)beginClosing;
- (void)closeController;

- (void)movePreferenceFolderFromAdium2ToAdium;

//Preference Window
- (IBAction)showPreferenceWindow:(id)sender;
- (void)openPreferencesToCategory:(PREFERENCE_CATEGORY)category;
- (void)openPreferencesToAdvancedPane:(NSString *)paneName inCategory:(PREFERENCE_CATEGORY)category;
- (void)addPreferencePane:(AIPreferencePane *)inPane;
- (NSArray *)paneArray;

//Observing
- (void)registerPreferenceObserver:(id)observer forGroup:(NSString *)group;
- (void)unregisterPreferenceObserver:(id)observer;
- (void)informObserversOfChangedKey:(NSString *)key inGroup:(NSString *)group object:(AIListObject *)object;
- (void)delayPreferenceChangedNotifications:(BOOL)inDelay;

//Setting Preferences
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)group object:(AIListObject *)object;

//Retrieving Preferences
- (id)preferenceForKey:(NSString *)key group:(NSString *)group;
- (id)preferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object;
- (id)preferenceForKey:(NSString *)key group:(NSString *)group objectIgnoringInheritance:(AIListObject *)object;
- (NSDictionary *)preferencesForGroup:(NSString *)group;

//Defaults
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group;
- (void)resetPreferencesInPane:(AIPreferencePane *)preferencePane;

//Preference Cache
- (NSMutableDictionary *)cachedPreferencesForGroup:(NSString *)group object:(AIListObject *)object;
- (void)updateCachedPreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)group object:(AIListObject *)object;

@end

@interface NSObject (AIPreferenceObserver)
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict;
@end

