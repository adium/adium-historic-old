//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDualWindowMessageAdvancedPreferences.h"
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>


@implementation ESDualWindowMessageAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Message Window Preferences");
}
- (NSString *)nibName{
    return(@"DualWindowMessageAdvanced");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == createMessages_inTabs){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:([createMessages_inTabs state]==NSOffState)]
                                             forKey:KEY_ALWAYS_CREATE_NEW_WINDOWS
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    }else if(sender == createTabs_inLastWindow){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:([createTabs_inLastWindow state]==NSOnState)]
                                             forKey:KEY_USE_LAST_WINDOW
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }else if (sender == autohide_tabBar){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:([autohide_tabBar state]==NSOffState)]
				      forKey:KEY_AUTOHIDE_TABBAR
				       group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }

    [self configureControlDimming];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    [createMessages_inTabs setState:![[preferenceDict objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS] boolValue]];
    [createTabs_inLastWindow setState:[[preferenceDict objectForKey:KEY_USE_LAST_WINDOW] boolValue]];
    [autohide_tabBar setState:![[preferenceDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue]];
    
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [createTabs_inLastWindow setEnabled:([createMessages_inTabs state] == NSOnState)];
}

@end



