//
//  ESDualWindowMessageWindowAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESDualWindowMessageAdvancedPreferences.h"
#import "AIDualWindowInterfacePlugin.h"

@class AIPreferenceWindowController;

@implementation ESDualWindowMessageAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(AILocalizedString(@"Messages",nil));
}
- (NSString *)nibName{
    return(@"DualWindowMessageAdvanced");
}
- (NSImage *)image{
	return([NSImage imageNamed:@"pref-messages" forClass:[AIPreferenceWindowController class]]);
}

- (NSDictionary *)restorablePreferences
{
#warning Evan: Need to fix these defaults
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:DUAL_INTERFACE_WINDOW_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsTemp = [NSDictionary dictionaryWithObjectsAndKeys:
		[defaultPrefs objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS],KEY_ALWAYS_CREATE_NEW_WINDOWS,
		[defaultPrefs objectForKey:KEY_AUTOHIDE_TABBAR],KEY_AUTOHIDE_TABBAR,
		[defaultPrefs objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE],KEY_ENABLE_INACTIVE_TAB_CLOSE,
		nil];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultsTemp forKey:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	return(defaultsDict);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == autohide_tabBar){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:![sender state]]
											 forKey:KEY_AUTOHIDE_TABBAR
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
    }else if(sender == checkBox_allowInactiveClosing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_ENABLE_INACTIVE_TAB_CLOSE
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
	}else if (sender == checkBox_combineConsecutive){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_COMBINE_CONSECUTIVE
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	}else if(sender == checkBox_customNameFormatting){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_USE_NAME_FORMAT
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}else if(sender == popUp_nameFormat){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_WEBKIT_NAME_FORMAT
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}else if(sender == checkBox_backgroundColorFormatting){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_USE_BACKGROUND
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}
	
	[self configureControlDimming];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*prefDict;
	
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    [autohide_tabBar setState:![[prefDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue]];
    [checkBox_allowInactiveClosing setState:[[prefDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];

	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	[popUp_nameFormat compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue]];
	[checkBox_customNameFormatting setState:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
	[checkBox_combineConsecutive setState:[[prefDict objectForKey:KEY_WEBKIT_COMBINE_CONSECUTIVE] boolValue]];
	[checkBox_backgroundColorFormatting setState:[[prefDict objectForKey:KEY_WEBKIT_USE_BACKGROUND] boolValue]];
	
    [self configureControlDimming];
}

- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	
	[popUp_nameFormat setEnabled:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
}
@end



