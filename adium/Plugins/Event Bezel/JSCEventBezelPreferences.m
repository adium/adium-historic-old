//
//  JSCEventBezelPreferences.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelPreferences.h"
#import "JSCEventBezelPlugin.h"

@implementation JSCEventBezelPreferences

// Preference pane properties
- (PREFERENCE_CATEGORY)category
{
    return(AIPref_Advanced_Other);
}

- (NSString *)label
{
    return(PREF_GROUP_EVENT_BEZEL);
}

- (NSString *)nibName
{
    return(@"EventBezelPrefs");
}
//

- (IBAction)toggleShowBezel:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_SHOW_EVENT_BEZEL
                                          group:PREF_GROUP_EVENT_BEZEL];
    
    //Enable others checkboxes if this one is checked
    [popUp_position setEnabled: [checkBox_showBezel state]];
    [popUp_buddyNameFormat setEnabled: [checkBox_showBezel state]];
}

- (IBAction)changePosition:(id)sender
{
    //NSLog(@"%d", [popUp_position indexOfSelectedItem]);
    [[owner preferenceController] setPreference: [NSNumber numberWithInt: [popUp_position indexOfSelectedItem]]
                                         forKey: KEY_EVENT_BEZEL_POSITION
                                          group: PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)changeBuddyNameFormat:(id)sender
{
    [[owner preferenceController] setPreference: [NSNumber numberWithInt: [popUp_buddyNameFormat indexOfSelectedItem]]
                                         forKey: KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT
                                          group: PREF_GROUP_EVENT_BEZEL];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
    
    // Set the values of the checkboxes
    [checkBox_showBezel setState:[[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue]];
    
    [popUp_position selectItemAtIndex: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue]];
    [popUp_buddyNameFormat selectItemAtIndex: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT] intValue]];
    
    // Enable or disable checkboxes based on the "show bezel" checkbox
    [popUp_position setEnabled: [checkBox_showBezel state]];
    [popUp_buddyNameFormat setEnabled: [checkBox_showBezel state]];
}

@end
