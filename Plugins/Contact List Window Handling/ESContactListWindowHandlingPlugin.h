//
//  ESContactListWindowHandlingPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

#import "ESContactListWindowHandlingPreferences.h"

#define CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS @"ContactListWindowHandlingDefaults"

#define PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_CLWH_WINDOW_POSITION		@"Contact Window Position"
#define KEY_CLWH_HIDE					@"Hide While in Background"

typedef enum {
    RegularBehaviour,
    AlwaysOnTop,
    AlwaysOnBottom,
} WindowPosition;


@interface ESContactListWindowHandlingPlugin : AIPlugin {
    ESContactListWindowHandlingPreferences	* preferences;
}

- (void)installPlugin;
- (void)uninstallPlugin;

@end
