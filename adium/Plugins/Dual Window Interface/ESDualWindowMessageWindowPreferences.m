//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

#import "ESDualWindowMessageWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"


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

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == createMessages_inTabs){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([createMessages_inTabs state]==NSOffState)]
                                             forKey:KEY_ALWAYS_CREATE_NEW_WINDOWS
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		[self configureControlDimming];
	} else if(sender == createTabs_inLastWindow){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([createTabs_inLastWindow state]==NSOnState)]
                                             forKey:KEY_USE_LAST_WINDOW
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }
}

//Dim controls as needed
- (void)configureControlDimming
{
	if( [createMessages_inTabs state] == NSOnState ) {
		[createTabs_inLastWindow setEnabled:YES];
	} else {
		[createTabs_inLastWindow setEnabled:NO];
	}
}
//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    [createMessages_inTabs setState:![[preferenceDict objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS] boolValue]];
	[createTabs_inLastWindow setState:[[preferenceDict objectForKey:KEY_USE_LAST_WINDOW] boolValue]];

	[self configureControlDimming];
}

@end



