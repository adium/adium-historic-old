//
//  CBStatusMenuItemPlugin.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemPlugin.h"
#import "CBStatusMenuItemPreferences.h"

@interface CBStatusMenuItemPlugin(PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation CBStatusMenuItemPlugin

- (void)installPlugin
{
    //We're Panther only
    if([NSApp isOnPantherOrBetter]){
    
        //Just in case
        itemController = nil;
        
        //Register our defaults
        [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS 
                                              forClass:[self class]]
                                              forGroup:PREF_GROUP_STATUS_MENU_ITEM];
        //Create the preferences
        preferences = [[CBStatusMenuItemPreferences preferencePane] retain];

        //Observe
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_STATUS_MENU_ITEM];
    }
}

- (void)uninstallPlugin
{
    if([NSApp isOnPantherOrBetter]){
		[[adium preferenceController] unregisterPreferenceObserver:self];
        [itemController release]; itemController = nil;
        [preferences release];
    }
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict 
{
	if([[prefDict objectForKey:KEY_STATUS_MENU_ITEM_ENABLED] boolValue]){
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
