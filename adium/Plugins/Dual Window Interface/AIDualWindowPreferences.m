//
//  AIDualWindowPreferences.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDualWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"

@interface AIDualWindowPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIDualWindowPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_ContactList_General);
}
- (NSString *)label{
    return(@"General Appearance");
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
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DUAL_RESIZE_HORIZONTAL
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }
}

//Configure the preference view
- (void)viewDidLoad
{
    [checkBox_autoResize setAllowsMixedState:YES];
    
    [self preferencesChanged:nil];
    
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

//Keep the preferences current
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the Behavior set changed
        if(notification == nil || ([key compare:KEY_DUAL_RESIZE_VERTICAL] == 0) || ([key compare:KEY_DUAL_RESIZE_HORIZONTAL] == 0) ){
            NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
            
            BOOL vertical = [[preferenceDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
            BOOL horizontal = [[preferenceDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
            if (vertical && horizontal) {
                [checkBox_autoResize setState:NSOnState];
            } else if (vertical || horizontal) {
                [checkBox_autoResize setState:NSMixedState];
            } else 
                [checkBox_autoResize setState:NSOffState];
        }
    }
}

@end



