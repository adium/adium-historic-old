//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDualWindowMessageWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define ESDUAL_MESSAGE_PREF_NIB			@"DualWindowMessageWindowPrefs"
#define ESDUAL_PREF_TITLE_WINDOW		@"Message Window Handling"

@interface ESDualWindowMessageWindowPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)configureControlDimming;
@end


@implementation ESDualWindowMessageWindowPreferences
//
+ (ESDualWindowMessageWindowPreferences *)dualWindowMessageWindowInterfacePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Display withDelegate:self label:ESDUAL_PREF_TITLE_WINDOW]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_pref){
        [NSBundle loadNibNamed:ESDUAL_MESSAGE_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_pref);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_pref release]; view_pref = nil;

}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == matrix_windowMode){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:([matrix_windowMode selectedCell] == modeWindow)]
                                             forKey:KEY_ALWAYS_CREATE_NEW_WINDOWS
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    }else if(sender == matrix_tabPref){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:([matrix_tabPref selectedCell] == lastUsedWindow)]
                                             forKey:KEY_USE_LAST_WINDOW
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }else if (sender == autohide_tabBar){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:([autohide_tabBar state]==NSOnState)]
				      forKey:KEY_AUTOHIDE_TABBAR
				       group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }

    [self configureControlDimming];
}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    BOOL newWindows = [[preferenceDict objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS] boolValue];
    if (newWindows)
    {
	[matrix_windowMode selectCell:modeWindow];
    }
    else
	[matrix_windowMode selectCell:modeTab];


    BOOL lastUsedWindowPref = [[preferenceDict objectForKey:KEY_USE_LAST_WINDOW] boolValue];
    if (lastUsedWindowPref)
	[matrix_tabPref selectCell:lastUsedWindow];
    else
	[matrix_tabPref selectCell:primaryWindow];

    [autohide_tabBar setState:[[preferenceDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue]];
    
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [matrix_tabPref setEnabled:([matrix_windowMode selectedCell] == modeTab)];
}

@end



