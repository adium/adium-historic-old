//
//  AIStatusOverlayPreferences.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 23 2003.
//

#import "AIStatusOverlayPreferences.h"
#import "AIContactStatusDockOverlaysPlugin.h"

@implementation AIStatusOverlayPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Dock);
}
- (NSString *)label{
    return(@"Contact Status Overlays");
}
- (NSString *)nibName{
    return(@"DockStatusOverlaysPrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DOCK_OVERLAYS];

    [checkBox_showStatusOverlays setState:[[preferenceDict objectForKey:KEY_DOCK_SHOW_STATUS] boolValue]];
    [checkBox_showContentOverlays setState:[[preferenceDict objectForKey:KEY_DOCK_SHOW_CONTENT] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_showStatusOverlays){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DOCK_SHOW_STATUS
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        
    }else if(sender == checkBox_showContentOverlays){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DOCK_SHOW_CONTENT
                                              group:PREF_GROUP_DOCK_OVERLAYS];

    }
}

@end
