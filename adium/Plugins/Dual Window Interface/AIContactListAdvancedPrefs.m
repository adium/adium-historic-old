//
//  AIDualWindowPreferences.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//

#import "AIContactListAdvancedPrefs.h"
#import "AIContactListWindowController.h"
#import "AISCLViewPlugin.h"

@implementation AIContactListAdvancedPrefs

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_ContactList);
}
- (NSString *)label{
    return(AILocalizedString(@"Auto-resizing","Automatic size changes of the contact list"));
}
- (NSString *)nibName{
    return(@"ContactListAdvanced");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsTemp = [NSDictionary dictionaryWithObjectsAndKeys:
		[defaultPrefs objectForKey:KEY_DUAL_RESIZE_VERTICAL],KEY_DUAL_RESIZE_VERTICAL,
		[defaultPrefs objectForKey:KEY_DUAL_RESIZE_HORIZONTAL],KEY_DUAL_RESIZE_HORIZONTAL,
			nil];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultsTemp forKey:PREF_GROUP_CONTACT_LIST_DISPLAY];
	return(defaultsDict);
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];

    [checkBox_verticalResize setState:[[preferenceDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue]];
    [checkBox_horizontalResize setState:[[preferenceDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_verticalResize){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DUAL_RESIZE_VERTICAL
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];

    }else if(sender == checkBox_horizontalResize){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DUAL_RESIZE_HORIZONTAL
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }
}

@end



