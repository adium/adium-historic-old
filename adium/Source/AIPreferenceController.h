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

// $Id: AIPreferenceController.h,v 1.11 2004/02/03 05:23:45 dchoby98 Exp $ 

//Preference groups
#define PREF_GROUP_GENERAL              @"General"
#define PREF_GROUP_ACCOUNTS             @"Accounts"
#define PREF_GROUP_TOOLBARS 		@"Toolbars"
#define PREF_GROUP_WINDOW_POSITIONS     @"Window Positions"
#define PREF_GROUP_SPELLING 		@"Spelling"
#define OBJECT_PREFS_PATH               @"ByObject"		//Path to object specific preference folder
#define ACCOUNT_PREFS_PATH              @"Accounts"		//Path to account specific preference folder
#define Preference_GroupChanged		@"Preference_GroupChanged"
#define Preference_WindowWillOpen       @"Preference_WindowWillOpen"
#define Preference_WindowDidClose       @"Preference_WindowDidClose"
#define Themes_Changed                  @"Themes_Changed"

//Preference Categories
typedef enum {
    //Temporary, for transition only
    AIPref_Accounts = 0, 
    AIPref_ContactList_General,
    AIPref_ContactList_Groups,
    AIPref_ContactList_Contacts,
    AIPref_Messages_Display,
    AIPref_Messages_Sending,
    //AIPref_Messages_Receiving,
    AIPref_Status_Away,
    AIPref_Status_Idle,
    AIPref_Dock,
    AIPref_Sound,
    AIPref_Emoticons,
    AIPref_Alerts,
    
	/*    AIPref_Accounts = 0,
    AIPref_ContactList,
    AIPref_Messages,
    AIPref_Sound,
    AIPref_Alerts,*/
    AIPref_Advanced_ContactList,
    AIPref_Advanced_Messages,
    AIPref_Advanced_Status,
    AIPref_Advanced_Other
	
} PREFERENCE_CATEGORY;

@class AIPreferencePane;

@interface AIPreferenceController : NSObject {
    IBOutlet	AIAdium		*owner;
	
    NSMutableArray			*paneArray;		//An array of preference panes
    NSMutableDictionary		*groupDict;		//A dictionary of pref dictionaries
	NSMutableDictionary		*defaultPrefs;  //A dictionary of default preferences
    NSMutableDictionary		*themablePreferences;
    
    BOOL					shouldDelay;
    NSMutableSet			*delayedNotificationGroups;  //Group names for delayed notifications
}

//Preference window
- (IBAction)showPreferenceWindow:(id)sender;
- (void)openPreferencesToPane:(AIPreferencePane *)inPane;

//Preference views
- (void)addPreferencePane:(AIPreferencePane *)inPane;

//Defaults and access to preferences
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)groupName;
- (NSDictionary *)preferencesForGroup:(NSString *)groupName;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;

//Themable preferences
- (void)registerThemableKeys:(NSArray *)keysArray forGroup:(NSString *)groupName;
- (NSDictionary *)themablePreferences;

- (BOOL)tempImportOldPreferenceForKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (void)delayPreferenceChangedNotifications:(BOOL)inDelay;

//Private
- (void)initController;
- (void)finishIniting;
- (void)closeController;
- (NSArray *)paneArray;

@end
