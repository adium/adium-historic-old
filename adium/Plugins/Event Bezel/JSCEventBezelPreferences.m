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
    [checkBox_online setEnabled: [checkBox_showBezel state]];
    [checkBox_offline setEnabled: [checkBox_showBezel state]];
    [checkBox_available setEnabled: [checkBox_showBezel state]];
    [checkBox_away setEnabled: [checkBox_showBezel state]];
    [checkBox_noIdle setEnabled: [checkBox_showBezel state]];
    [checkBox_idle setEnabled: [checkBox_showBezel state]];
    [checkBox_firstMessage setEnabled: [checkBox_showBezel state]];
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

- (IBAction)toggleOnline:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_ONLINE
                                          group:PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)toggleOffline:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_OFFLINE
                                          group:PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)toggleAvailable:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_AVAILABLE
                                          group:PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)toggleAway:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_AWAY
                                          group:PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)toggleNoIdle:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_NO_IDLE
                                          group:PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)toggleIdle:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_IDLE
                                          group:PREF_GROUP_EVENT_BEZEL];
}

- (IBAction)toggleFirstMessage:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_BEZEL_FIRST_MESSAGE
                                          group:PREF_GROUP_EVENT_BEZEL];
}


//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
    
    // Set the values of the checkboxes
    [checkBox_showBezel setState:[[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue]];
    
    [popUp_position selectItemAtIndex: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue]];
    [popUp_buddyNameFormat selectItemAtIndex: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT] intValue]];
    
    [checkBox_online setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_ONLINE] boolValue]];
    [checkBox_offline setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_OFFLINE] boolValue]];
    [checkBox_available setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_AVAILABLE] boolValue]];
    [checkBox_away setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_AWAY] boolValue]];
    [checkBox_noIdle setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_NO_IDLE] boolValue]];
    [checkBox_idle setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IDLE] boolValue]];
    [checkBox_firstMessage setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FIRST_MESSAGE] boolValue]];
    
    // Enable or disable checkboxes based on the "show bezel" checkbox
    [popUp_position setEnabled: [checkBox_showBezel state]];
    [popUp_buddyNameFormat setEnabled: [checkBox_showBezel state]];
    [checkBox_online setEnabled: [checkBox_showBezel state]];
    [checkBox_offline setEnabled: [checkBox_showBezel state]];
    [checkBox_available setEnabled: [checkBox_showBezel state]];
    [checkBox_away setEnabled: [checkBox_showBezel state]];
    [checkBox_noIdle setEnabled: [checkBox_showBezel state]];
    [checkBox_idle setEnabled: [checkBox_showBezel state]];
    [checkBox_firstMessage setEnabled: [checkBox_showBezel state]];
}

@end
