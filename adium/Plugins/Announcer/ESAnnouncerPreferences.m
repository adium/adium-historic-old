//
//  ESAnnouncerPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESAnnouncerPreferences.h"
#import "ESAnnouncerPlugin.h"

@implementation ESAnnouncerPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Speak Messages");
}
- (NSString *)nibName{
    return(@"AnnouncerPrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_ANNOUNCER];
    
    [checkBox_outgoing setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue]];
    [checkBox_incoming setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue]];
    [checkBox_status setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_STATUS] boolValue]];
    [checkBox_time setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_TIME] boolValue]];
    [checkBox_sender setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_SENDER] boolValue]];
    [checkBox_messageText setState:[[dict objectForKey:KEY_ANNOUNCER_MESSAGETEXT] boolValue]];
    [self configureControlDimming];
}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_outgoing){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_OUTGOING
									group:PREF_GROUP_ANNOUNCER];
    } else if(sender == checkBox_incoming){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_INCOMING
									group:PREF_GROUP_ANNOUNCER];
    } else if(sender == checkBox_status){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_STATUS
									group:PREF_GROUP_ANNOUNCER];
    } else if(sender == checkBox_time){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_TIME
									group:PREF_GROUP_ANNOUNCER];
    } else if(sender == checkBox_sender){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_SENDER
									group:PREF_GROUP_ANNOUNCER];
    } else if (sender == checkBox_messageText){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_ANNOUNCER_MESSAGETEXT
                                              group:PREF_GROUP_ANNOUNCER];
    }

    [self configureControlDimming];
}

//Dim unavailable controls
- (void)configureControlDimming
{
    BOOL messages = ([checkBox_outgoing state] || [checkBox_incoming state]);
    
    [checkBox_messageText setEnabled:(messages)];
    [checkBox_sender setEnabled:(messages)];
    [checkBox_time setEnabled:(messages || [checkBox_status state])];
    
}

@end
