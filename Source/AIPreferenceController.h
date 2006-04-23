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

#import <Adium/AIObject.h>

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
	AIPref_General,
	AIPref_Personal,
	AIPref_Appearance,
    AIPref_Messages,
	AIPref_Status,
	AIPref_Events,
	AIPref_FileTransfer,
    AIPref_Advanced
} PREFERENCE_CATEGORY;

@class AIPreferencePane, AIAdium, AIListObject;

@protocol AIController;

@interface AIPreferenceController : AIObject <AIController> {
	NSString				*userDirectory;
	
	NSMutableArray			*paneArray;						//Loaded preference panes
	NSMutableDictionary		*observers;						//Preference change observers

	NSMutableDictionary		*defaults;						//Preference defaults
	NSMutableDictionary		*prefCache;						//Preference cache
	NSMutableDictionary		*prefWithDefaultsCache;			//Preference cache with defaults included
	
	NSMutableDictionary		*objectDefaults;				//Object specific defaults
	NSMutableDictionary		*objectPrefCache;				//Object specific preferences cache
	NSMutableDictionary		*objectPrefWithDefaultsCache;	//Object specific preferences cache with defaults included

	int						preferenceChangeDelays;			//Number of active delays (0 = not delayed)
	NSMutableSet			*delayedNotificationGroups;  	//Groups with delayed changes
}

//Preference Window
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)closePreferenceWindow:(id)sender;
- (void)openPreferencesToCategoryWithIdentifier:(NSString *)identifier;
- (void)openPreferencesToAdvancedPane:(NSString *)paneName;
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
- (void)setPreferences:(NSDictionary *)inPrefDict inGroup:(NSString *)group;

//Retrieving Preferences
- (id)preferenceForKey:(NSString *)key group:(NSString *)group;
- (id)preferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object;
- (id)preferenceForKey:(NSString *)key group:(NSString *)group objectIgnoringInheritance:(AIListObject *)object;
- (NSDictionary *)preferencesForGroup:(NSString *)group;
- (id)defaultPreferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object;

//Defaults
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group;
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group object:(AIListObject *)object;

//Preference Cache
- (NSMutableDictionary *)cachedPreferencesForGroup:(NSString *)group object:(AIListObject *)object;

//Default download location
- (NSString *)userPreferredDownloadFolder;
- (void)setUserPreferredDownloadFolder:(NSString *)path;

@end

@interface NSObject (AIPreferenceObserver)
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
@end

