//
//  CBStatusMenuItemPlugin.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemPlugin.h"

@interface CBStatusMenuItemPlugin(PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation CBStatusMenuItemPlugin

- (void)installPlugin
{
    //Just in case
    itemController = nil;
    
    //Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS 
                                          forClass:[self class]]
                                          forGroup:PREF_GROUP_STATUS_MENU_ITEM];
    //Create the preferences
    preferences = [[CBStatusMenuItemPreferences preferencePane] retain];

    //Observe
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(preferencesChanged:)
                                       name:Preference_GroupChanged
                                     object:nil];
    //Initial setup
    [self preferencesChanged:nil];

}

- (void)uninstallPlugin
{
    if(itemController){
        [itemController release];
        itemController = nil;
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if([[[adium preferenceController] preferenceForKey:KEY_STATUS_MENU_ITEM_ENABLED group:PREF_GROUP_STATUS_MENU_ITEM] boolValue]){
        //If it hasn't been created yet, create it. Otherwise, tell it to show itself.
        if(!itemController){
            itemController = [CBStatusMenuItemController statusMenuItemController];
        }else{
            [itemController showStatusItem];
        }
    }else{
        //if it exists, tell it to hide itself
        if(itemController){
            [itemController hideStatusItem];
        }
    }
}

@end
