//
//  AIDualWindowPreferences.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDualWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define AIDUAL_PREF_NIB			@"DualWindowPrefs"
#define AIDUAL_PREF_TITLE_RESIZE	@"Auto-Resizing"

@interface AIDualWindowPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIDualWindowPreferences
+ (AIDualWindowPreferences *)dualWindowInterfacePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*prefController;

    //Init
    [super init];
    owner = [inOwner retain];

    //Install our preference views
    [NSBundle loadNibNamed:AIDUAL_PREF_NIB owner:self];

    //Resizing
    prefController = [AIPreferenceViewController controllerWithName:AIDUAL_PREF_TITLE_RESIZE categoryName:PREFERENCE_CATEGORY_CONTACTLIST view:view_resizing];
    [[owner preferenceController] addPreferenceView:prefController];

    //Load the prefs and configure our view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE] retain];
    [self configureView];

    return(self);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_autoResize){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DUAL_RESIZE_VERTICAL
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    }else if(sender == checkBox_horizontalResize){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DUAL_RESIZE_HORIZONTAL
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }
    
    [self configureControlDimming];
}

//Configures our view for the current preferences
- (void)configureView
{
    [checkBox_autoResize setState:[[preferenceDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue]];
    [checkBox_horizontalResize setState:[[preferenceDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue]];

    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [checkBox_horizontalResize setEnabled:[checkBox_autoResize state]];
}

@end






