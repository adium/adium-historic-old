//
//  CBStatusMenuItemPlugin.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemController.h"

#define STATUS_MENU_ITEM_DEFAULT_PREFS  @"StatusMenuItemDefaultPrefs"
#define PREF_GROUP_STATUS_MENU_ITEM     @"Status Menu Item"
#define KEY_STATUS_MENU_ITEM_ENABLED    @"Status Menu Item Enabled"

@class CBStatusMenuItemPreferences;

@interface CBStatusMenuItemPlugin : AIPlugin 
{
    CBStatusMenuItemController  *itemController;
    CBStatusMenuItemPreferences *preferences;
}

@end
