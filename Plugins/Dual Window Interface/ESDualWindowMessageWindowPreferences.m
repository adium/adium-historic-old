//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

#import "ESDualWindowMessageWindowPreferences.h"

@implementation ESDualWindowMessageWindowPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages);
}
- (NSString *)label{
    return(@"z");
}
- (NSString *)nibName{
    return(@"DualWindowMessageWindowPrefs");
}

#warning move to a separate plugin, this is coreside now

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_messagesInTabs){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TABBED_CHATTING
                                              group:PREF_GROUP_INTERFACE];
		[self configureControlDimming];
		
	}else if(sender == checkBox_arrangeTabs){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_SORT_CHATS
											  group:PREF_GROUP_INTERFACE];
		
	}else if(sender == checkBox_arrangeByGroup){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_GROUP_CHATS_BY_GROUP
											  group:PREF_GROUP_INTERFACE];
		
	}
	
}

//Dim controls as needed
- (void)configureControlDimming
{
	[checkBox_arrangeTabs setEnabled:[checkBox_messagesInTabs state]];
	[checkBox_arrangeByGroup setEnabled:[checkBox_messagesInTabs state]];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_INTERFACE];

    [checkBox_messagesInTabs setState:[[preferenceDict objectForKey:KEY_TABBED_CHATTING] boolValue]];
    [checkBox_arrangeTabs setState:[[preferenceDict objectForKey:KEY_SORT_CHATS] boolValue]];
	[checkBox_arrangeByGroup setState:[[preferenceDict objectForKey:KEY_GROUP_CHATS_BY_GROUP] boolValue]];

	[self configureControlDimming];
}

@end



