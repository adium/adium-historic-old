//
//  ESContactListWindowHandlingPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

#import "ESContactListWindowHandlingPreferences.h"
#import "ESContactListWindowHandlingPlugin.h"

#define CLWH_PREF_TITLE	AILocalizedString(@"Window Handling","Contact List Window Handling")
#define CLWH_PREF_NIB	@"ContactListWindowHandlingPrefs"

@interface ESContactListWindowHandlingPreferences (PRIVATE)
- (void)configureView;
@end

@implementation ESContactListWindowHandlingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_ContactList);
}
- (NSString *)label{
    return(CLWH_PREF_TITLE);
}
- (NSString *)nibName{
    return(CLWH_PREF_NIB);
}

//
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
	int 			menuIndex = [window_position_menu indexOfItemWithTag:[[preferenceDict objectForKey:KEY_CLWH_WINDOW_POSITION] intValue]];
	
	if(menuIndex >= 0 && menuIndex < [window_position_menu numberOfItems]){
		[window_position_menu selectItemAtIndex:menuIndex];
	}
    [checkBox_hide setState:[[preferenceDict objectForKey:KEY_CLWH_HIDE] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == window_position_menu){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_CLWH_WINDOW_POSITION
											  group:PREF_GROUP_CONTACT_LIST];
		
	}else if(sender == checkBox_hide){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CLWH_HIDE
											  group:PREF_GROUP_CONTACT_LIST];
		
    }
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_CONTACT_LIST];	
	return(defaultsDict);
}

@end
