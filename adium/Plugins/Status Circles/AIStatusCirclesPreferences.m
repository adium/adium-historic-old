//
//  AIStatusCirclesPreferences.m
//  Adium
//
//  Created by Arno Hautala on Thu May 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIStatusCirclesPreferences.h"
#import "AIStatusCirclesPlugin.h"

#define	STATUS_CIRCLES_PREF_NIB		@"StatusCirclesPrefs"
#define STATUS_CIRCLES_PREF_TITLE	@"Status - Contact Status Circles"

@interface AIStatusCirclesPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIStatusCirclesPreferences

+ (AIStatusCirclesPreferences *)statusCirclesPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == colorWell_signedOff){
        [[owner preferenceController] setPreference:[[colorWell_signedOff color] stringRepresentation]
                                             forKey:KEY_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_signedOn){
        [[owner preferenceController] setPreference:[[colorWell_signedOn color] stringRepresentation]
                                             forKey:KEY_SIGNED_ON_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_online){
        [[owner preferenceController] setPreference:[[colorWell_online color] stringRepresentation]
                                             forKey:KEY_ONLINE_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_away){
        [[owner preferenceController] setPreference:[[colorWell_away color] stringRepresentation]
                                             forKey:KEY_AWAY_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_idle){
        [[owner preferenceController] setPreference:[[colorWell_idle color] stringRepresentation]
                                             forKey:KEY_IDLE_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_idleAway){
        [[owner preferenceController] setPreference:[[colorWell_idleAway color] stringRepresentation]
                                             forKey:KEY_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_openTab){
        [[owner preferenceController] setPreference:[[colorWell_openTab color] stringRepresentation]
                                             forKey:KEY_OPEN_TAB_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_unviewedContent){
        [[owner preferenceController] setPreference:[[colorWell_unviewedContent color] stringRepresentation]
                                             forKey:KEY_UNVIEWED_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == colorWell_warning){
        [[owner preferenceController] setPreference:[[colorWell_warning color] stringRepresentation]
                                             forKey:KEY_WARNING_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];

    }else if(sender == checkBox_displayIdle){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DISPLAY_IDLE_TIME
                                              group:PREF_GROUP_STATUS_CIRCLES];
    }

    [self configureControlDimming];
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:STATUS_CIRCLES_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:STATUS_CIRCLES_PREF_TITLE categoryName:PREFERENCE_CATEGORY_CONTACTLIST view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_STATUS_CIRCLES] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{

    [checkBox_displayIdle setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue]];
    
    [colorWell_signedOff setColor:[[preferenceDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[preferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
    [colorWell_online setColor:[[preferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
    [colorWell_away setColor:[[preferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[preferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
    [colorWell_idleAway setColor:[[preferenceDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_openTab setColor:[[preferenceDict objectForKey:KEY_OPEN_TAB_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[preferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
    [colorWell_warning setColor:[[preferenceDict objectForKey:KEY_WARNING_COLOR] representedColor]];

    [self configureControlDimming]; //disable the unavailable controls
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
/*
    //Font
    [button_setFont setEnabled:[checkBox_forceFont state]];
    [textField_desiredFont setEnabled:[checkBox_forceFont state]];

    //Text
    [colorWell_textColor setEnabled:[checkBox_forceTextColor state]];

    //Background
    [colorWell_backgroundColor setEnabled:[checkBox_forceBackgroundColor state]];
*/
}

@end
