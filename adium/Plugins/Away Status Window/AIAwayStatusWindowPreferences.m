//
//  AIAwayStatusWindowPreferences.m
//  Adium
//
//  Created by Adam Iser on Tue May 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIAwayStatusWindowPreferences.h"
#import "AIAwayStatusWindowController.h"
#import "AIAwayStatusWindowPlugin.h"

#define AWAY_MESSAGE_WINDOW_PREF_TITLE	@"Away Status Window" 		//Title of preference view
#define AWAY_MESSAGE_WINDOW_PREF_NIB	@"AwayStatusWindowPrefs"	//Name of preference nib

@interface AIAwayStatusWindowPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AIAwayStatusWindowPreferences

+ (AIAwayStatusWindowPreferences *)awayStatusWindowPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

- (IBAction)toggleShowAway:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_SHOW_AWAY_STATUS_WINDOW
                                          group:PREF_GROUP_AWAY_STATUS_WINDOW];

    //Enable the "float away" and "hide on deactivate" checkboxes if this one is checked
    [checkBox_floatAway setEnabled:[checkBox_showAway state]];
    [checkBox_hideInBackground setEnabled:[checkBox_showAway state]];

    // Force a live update of the window status
    [AIAwayStatusWindowController updateAwayStatusWindow];

}

- (IBAction)toggleFloatAway:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_FLOAT_AWAY_STATUS_WINDOW
                                          group:PREF_GROUP_AWAY_STATUS_WINDOW];

    // Force a live update of the window status
    [AIAwayStatusWindowController updateAwayStatusWindow];

}

- (IBAction)toggleHideInBackground:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW
                                          group:PREF_GROUP_AWAY_STATUS_WINDOW];

    // Force a live update of the window status
    [AIAwayStatusWindowController updateAwayStatusWindow];
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    //Init
    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:AWAY_MESSAGE_WINDOW_PREF_NIB owner:self];

    //Install Away Status Window preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:AWAY_MESSAGE_WINDOW_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Configure our view
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    // Set the values of the checkboxes
    [checkBox_showAway setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_SHOW_AWAY_STATUS_WINDOW] boolValue]];

    [checkBox_floatAway setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_FLOAT_AWAY_STATUS_WINDOW] boolValue]];

    [checkBox_hideInBackground setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW] boolValue]];

    // Enable or disable checkboxes based on the "show away" checkbox
    [checkBox_floatAway setEnabled:[checkBox_showAway state]];
    [checkBox_hideInBackground setEnabled:[checkBox_showAway state]];
}

@end



