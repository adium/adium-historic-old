//
//  ESSMAdvancedPreferences.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Nov 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESSMAdvancedPreferences.h"
#import "AISMViewPlugin.h"

@interface ESSMAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESSMAdvancedPreferences
//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Message Display Preferences");
}
- (NSString *)nibName{
    return(@"ESSMAdvancedPrefView");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == slider_consolidatedIndentation){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SMV_COMBINE_MESSAGES_INDENT
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
    }
}

//Configure the preference view
- (void)viewDidLoad
{
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//Close the preference view
- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STANDARD_MESSAGE_DISPLAY] == 0){
        
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        
        [slider_consolidatedIndentation setFloatValue:[[prefDict objectForKey:KEY_SMV_COMBINE_MESSAGES_INDENT] floatValue]];
        
        //Only enabled if an all-on-one-line incoming prefix is set with Combine Messages enabled
        [slider_consolidatedIndentation setEnabled:(([(NSString *)[prefDict objectForKey:KEY_SMV_PREFIX_INCOMING] rangeOfString:@"%m"].location != NSNotFound) && [[prefDict objectForKey:KEY_SMV_COMBINE_MESSAGES] boolValue])];
    }
}
@end
