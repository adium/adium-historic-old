//
//  CBStatusMenuItemPreferences.m
//  Adium
//
//  Created by Colin Barrett on Thu Jul 15 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBStatusMenuItemPreferences.h"
#import "CBStatusMenuItemPlugin.h"

@implementation CBStatusMenuItemPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category
{
    return(AIPref_Advanced_Other);
}
- (NSString *)label
{
    return(AILocalizedString(@"Status Menu Item",nil));
}
- (NSString *)nibName
{
    return(@"StatusMenuItemPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_STATUS_MENU_ITEM];
	return(defaultsDict);
}

- (void)viewDidLoad
{
    if([[[adium preferenceController] preferenceForKey:KEY_STATUS_MENU_ITEM_ENABLED group:PREF_GROUP_STATUS_MENU_ITEM] boolValue]){
        [checkBox_enableStatusMenuItem setState:NSOnState];
    }else{
        [checkBox_enableStatusMenuItem setState:NSOffState];
    }
}

- (IBAction)changePreference:(id)sender
{
    if([checkBox_enableStatusMenuItem state] == NSOnState){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:YES] 
                                             forKey:KEY_STATUS_MENU_ITEM_ENABLED
                                              group:PREF_GROUP_STATUS_MENU_ITEM];
    }else{
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:NO] 
                                     forKey:KEY_STATUS_MENU_ITEM_ENABLED
                                      group:PREF_GROUP_STATUS_MENU_ITEM];
    }
}

@end
