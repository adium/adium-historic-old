//
//  AIDualWindowPreferences.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDualWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@implementation AIDualWindowPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_ContactList_General);
}
- (NSString *)label{
    return(@"V");
}
- (NSString *)nibName{
    return(@"DualWindowPrefs");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_autoResize){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DUAL_RESIZE_VERTICAL
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    }
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    [checkBox_autoResize setState:[[preferenceDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue]];

    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:PREF_GROUP_DUAL_WINDOW_INTERFACE object:nil];
}

//Keep the preferences current
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the Behavior set changed
        if(notification == nil || [key compare:KEY_DUAL_RESIZE_VERTICAL] == 0){
            [checkBox_autoResize setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE] objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue]];
        }
    }
}

@end



