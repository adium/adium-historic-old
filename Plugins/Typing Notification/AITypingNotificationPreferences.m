//
//  AITypingNotificationPreferences.m
//  Adium
//
//  Created by Adam Iser on 12/28/04.
//  Copyright (c) 2004 The Adium Team. All rights reserved.
//

#import "AITypingNotificationPreferences.h"
#import "AITypingNotificationPlugin.h"

@implementation AITypingNotificationPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Typing Notification");
}
- (NSString *)nibName{
    return(@"TypingPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_TYPING_NOTIFICATIONS];

    [checkBox_disableTyping setState:[[preferenceDict objectForKey:KEY_DISABLE_TYPING_NOTIFICATIONS] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_disableTyping){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DISABLE_TYPING_NOTIFICATIONS
                                              group:PREF_GROUP_TYPING_NOTIFICATIONS];
    }
}

@end
