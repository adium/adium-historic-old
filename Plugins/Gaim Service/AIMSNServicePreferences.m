//
//  AIMSNServicePreferences.m
//  Adium
//
//  Created by Adam Iser on 10/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIMSNServicePreferences.h"
#import "ESMSNService.h"

@implementation AIMSNServicePreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category
{
    return(AIPref_Advanced_Service);
}
- (NSString *)label
{
    return(AILocalizedString(@"MSN",nil));
}
- (NSString *)nibName
{
    return(@"MSNServicePrefs");
}

//- (NSDictionary *)restorablePreferences
//{
//	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS forClass:[self class]];
//	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_STATUS_MENU_ITEM];
//	return(defaultsDict);
//}

- (void)viewDidLoad
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_MSN_SERVICE];
	
	[checkBox_treatDisplayNamesAsStatus setState:[[prefDict objectForKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS] boolValue]];
	[checkBox_conversationClosed setState:[[prefDict objectForKey:KEY_MSN_CONVERSATION_CLOSED] boolValue]];
	[checkBox_conversationTimedOut setState:[[prefDict objectForKey:KEY_MSN_CONVERSATION_TIMED_OUT] boolValue]];
}

- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_treatDisplayNamesAsStatus){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS
											  group:PREF_GROUP_MSN_SERVICE];
		
	}else if(sender == checkBox_conversationClosed){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_CONVERSATION_CLOSED
											  group:PREF_GROUP_MSN_SERVICE];
		
	}else if(sender == checkBox_conversationTimedOut){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_CONVERSATION_TIMED_OUT
											  group:PREF_GROUP_MSN_SERVICE];
		
	}		
}

@end
