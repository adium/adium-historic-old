//
//  AIStatusOverlayAdvancedPreferences.m
//  Adium XCode
//
//  Created by Adam Iser on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIStatusOverlayAdvancedPreferences.h"
#import "AIContactStatusDockOverlaysPlugin.h"

@implementation AIStatusOverlayAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Other);
}
- (NSString *)label{
    return(@"Contact Status Overlays");
}
- (NSString *)nibName{
    return(@"DockOverlayAdvancedPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:DOCK_OVERLAY_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_DOCK_OVERLAYS];
	return(defaultsDict);
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DOCK_OVERLAYS];
    
    [radioButton_topOfIcon setState:[[preferenceDict objectForKey:KEY_DOCK_OVERLAY_POSITION] boolValue]];
    [radioButton_bottomOfIcon setState:![[preferenceDict objectForKey:KEY_DOCK_OVERLAY_POSITION] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == radioButton_topOfIcon){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                             forKey:KEY_DOCK_OVERLAY_POSITION
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        [radioButton_bottomOfIcon setState:NSOffState];
        
    }else if(sender == radioButton_bottomOfIcon){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                             forKey:KEY_DOCK_OVERLAY_POSITION
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        [radioButton_topOfIcon setState:NSOffState];
        
    }
}

@end
