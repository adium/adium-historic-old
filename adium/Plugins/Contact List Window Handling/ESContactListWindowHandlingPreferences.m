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

/*
+ (ESContactListWindowHandlingPreferences *)contactListWindowHandlingPreferences
{
    return([[[self alloc] init] autorelease]);
}
*/
//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_alwaysOnTop){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)] forKey:KEY_CLWH_ALWAYS_ON_TOP group:PREF_GROUP_CONTACT_LIST];
    } else if(sender == checkBox_hide){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)] forKey:KEY_CLWH_HIDE group:PREF_GROUP_CONTACT_LIST];
    }
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_CONTACT_LIST];	
	return(defaultsDict);
}

//Private ---------------------------------------------------------------------------
//init
/*
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_General withDelegate:self label:CLWH_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:CLWH_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;
}


//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];

    [checkBox_alwaysOnTop setState:[[preferenceDict objectForKey:KEY_CLWH_ALWAYS_ON_TOP] boolValue]];
    [checkBox_hide setState:[[preferenceDict objectForKey:KEY_CLWH_HIDE] boolValue]];
}
*/

- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
	
    [checkBox_alwaysOnTop setState:[[preferenceDict objectForKey:KEY_CLWH_ALWAYS_ON_TOP] boolValue]];
    [checkBox_hide setState:[[preferenceDict objectForKey:KEY_CLWH_HIDE] boolValue]];
}
@end
