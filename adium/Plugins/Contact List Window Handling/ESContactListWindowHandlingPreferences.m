//
//  ESContactListWindowHandlingPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "ESContactListWindowHandlingPreferences.h"
#import "ESContactListWindowHandlingPlugin.h"

#define CLWH_PREF_TITLE	@"Window Handling"
#define CLWH_PREF_NIB	@"ContactListWindowHandlingPrefs"

@interface ESContactListWindowHandlingPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation ESContactListWindowHandlingPreferences
+ (ESContactListWindowHandlingPreferences *)contactListWindowHandlingPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_alwaysOnTop){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] forKey:KEY_CLWH_ALWAYS_ON_TOP group:PREF_GROUP_CONTACT_LIST];
    } else if(sender == checkBox_hide){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] forKey:KEY_CLWH_HIDE group:PREF_GROUP_CONTACT_LIST];
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_General withDelegate:self label:CLWH_PREF_TITLE]];

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
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];

    [checkBox_alwaysOnTop setState:[[preferenceDict objectForKey:KEY_CLWH_ALWAYS_ON_TOP] boolValue]];
    [checkBox_hide setState:[[preferenceDict objectForKey:KEY_CLWH_HIDE] boolValue]];
}
@end
