//
//  JSCEventBezelPreferences.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelPreferences.h"
#import "JSCEventBezelPlugin.h"

@interface JSCEventBezelPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

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

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:EVENT_BEZEL_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_EVENT_BEZEL];
	return(defaultsDict);
}

//

- (IBAction)changePreference:(id)sender
{
    if (sender == popUp_position) {
        [[adium preferenceController] setPreference: [NSNumber numberWithInt: [popUp_position indexOfSelectedItem]]
                                         forKey: KEY_EVENT_BEZEL_POSITION
                                          group: PREF_GROUP_EVENT_BEZEL];
    } else if (sender == slider_duration) {
        [[adium preferenceController] setPreference: [NSNumber numberWithInt: [slider_duration intValue]]
                                             forKey: KEY_EVENT_BEZEL_DURATION
                                              group:PREF_GROUP_EVENT_BEZEL];
    } else if (sender == popUp_size) {
        [[adium preferenceController] setPreference: [NSNumber numberWithInt: [popUp_size indexOfSelectedItem]]
                                             forKey: KEY_EVENT_BEZEL_SIZE
                                              group: PREF_GROUP_EVENT_BEZEL];
    } else if (sender == popUp_background) {
        [[adium preferenceController] setPreference: [NSNumber numberWithInt: [popUp_background indexOfSelectedItem]]
                                             forKey: KEY_EVENT_BEZEL_BACKGROUND
                                              group: PREF_GROUP_EVENT_BEZEL];
    } else { //handle the check boxes
        NSString *key = nil;
        
        if (sender == checkBox_showBezel) {
            key = KEY_SHOW_EVENT_BEZEL;
        } if (sender == checkBox_online) {
            key = KEY_EVENT_BEZEL_ONLINE;
        } else if (sender == checkBox_offline) {
            key = KEY_EVENT_BEZEL_OFFLINE;
        } else if (sender == checkBox_available) {
            key = KEY_EVENT_BEZEL_AVAILABLE;
        } else if (sender == checkBox_away) {
            key = KEY_EVENT_BEZEL_AWAY;
        } else if (sender == checkBox_noIdle) {
            key = KEY_EVENT_BEZEL_NO_IDLE;
        } else if (sender == checkBox_idle) {
            key = KEY_EVENT_BEZEL_IDLE;
        } else if (sender == checkBox_firstMessage) {
            key = KEY_EVENT_BEZEL_FIRST_MESSAGE;
        } else if (sender == checkBox_imageBadges) {
            key = KEY_EVENT_BEZEL_IMAGE_BADGES;
        } else if (sender == checkBox_colorLabels) {
            key = KEY_EVENT_BEZEL_COLOR_LABELS;
        } else if (sender == checkBox_nameLabels) {
            key = KEY_EVENT_BEZEL_NAME_LABELS;
        } else if (sender == checkBox_fadeIn) {
            key = KEY_EVENT_BEZEL_FADE_IN;
        } else if (sender == checkBox_fadeOut) {
            key = KEY_EVENT_BEZEL_FADE_OUT;
        } else if (sender == checkBox_showHidden) {
            key = KEY_EVENT_BEZEL_SHOW_HIDDEN;
        } else if (sender == checkBox_showAway) {
            key = KEY_EVENT_BEZEL_SHOW_AWAY;
        } else if (sender == checkBox_includeText) {
            key = KEY_EVENT_BEZEL_INCLUDE_TEXT;
        }
        
        if (key) {
            [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                                 forKey:key
                                                  group:PREF_GROUP_EVENT_BEZEL];
        }
    }
}

- (void)viewDidLoad
{
    //Observer preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
}

//Configure the preference view
- (void)preferencesChanged:(NSNotification *)notification
{
    if (notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_EVENT_BEZEL] == 0) {
		NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
		
		// Set the values of the checkboxes
		[checkBox_showBezel setState:[[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue]];
		
		[popUp_position selectItemAtIndex: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue]];
		
		[slider_duration setIntValue: [[preferenceDict objectForKey: KEY_EVENT_BEZEL_DURATION] intValue]];
		
		[checkBox_online setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_ONLINE] boolValue]];
		[checkBox_offline setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_OFFLINE] boolValue]];
		[checkBox_available setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_AVAILABLE] boolValue]];
		[checkBox_away setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_AWAY] boolValue]];
		[checkBox_noIdle setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_NO_IDLE] boolValue]];
		[checkBox_idle setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IDLE] boolValue]];
		[checkBox_firstMessage setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FIRST_MESSAGE] boolValue]];
		[checkBox_includeText setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_INCLUDE_TEXT] boolValue]];
		[checkBox_imageBadges setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IMAGE_BADGES] boolValue]];
		[checkBox_colorLabels setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_COLOR_LABELS] boolValue]];
		[checkBox_nameLabels setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_NAME_LABELS] boolValue]];
		
		[popUp_size selectItemAtIndex: [[preferenceDict objectForKey: KEY_EVENT_BEZEL_SIZE] intValue]];
		
		[popUp_background selectItemAtIndex: [[preferenceDict objectForKey: KEY_EVENT_BEZEL_BACKGROUND] intValue]];
		
		[checkBox_fadeIn setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FADE_IN] boolValue]];
		[checkBox_fadeOut setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FADE_OUT] boolValue]];
		[checkBox_showHidden setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_SHOW_HIDDEN] boolValue]];
		[checkBox_showAway setState: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_SHOW_AWAY] boolValue]];
		
		// Enable or disable checkboxes based on the "show bezel" checkbox
		BOOL showBezel = [checkBox_showBezel state];
		[checkBox_online setEnabled:showBezel];
		[checkBox_offline setEnabled:showBezel];
		[checkBox_available setEnabled:showBezel];
		[checkBox_away setEnabled:showBezel];
		[checkBox_noIdle setEnabled:showBezel];
		[checkBox_idle setEnabled:showBezel];
		[checkBox_firstMessage setEnabled:showBezel];
		[checkBox_includeText setEnabled:(showBezel && [checkBox_firstMessage state])];
	}
}

@end
