//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDualWindowMessageWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>


@implementation ESDualWindowMessageWindowPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages_Sending);
}
- (NSString *)label{
    return(@"E");
}
- (NSString *)nibName{
    return(@"DualWindowMessageWindowPrefs");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == createMessages_inTabs){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:([createMessages_inTabs state]==NSOffState)]
                                             forKey:KEY_ALWAYS_CREATE_NEW_WINDOWS
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    }
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    [createMessages_inTabs setState:![[preferenceDict objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS] boolValue]];
}

@end



