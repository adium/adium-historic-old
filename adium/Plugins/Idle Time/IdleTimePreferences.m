//
//  IdleTimePreferences.m
//  Adium
//
//  Created by Adam Iser on Tue Jan 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "IdleTimePreferences.h"
#import "IdleTimePlugin.h"

#define IDLE_TIME_PREF_NIB		@"IdleTimePrefs"	//Name of preference nib
#define IDLE_TIME_PREF_TITLE		@"Idle"			//Title of the preference view

@interface IdleTimePreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation IdleTimePreferences

+ (IdleTimePreferences *)idleTimePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableIdle){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_TIME_ENABLED
                                              group:PREF_GROUP_IDLE_TIME];

    }else if(sender == textField_idleMinutes){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_IDLE_TIME_IDLE_MINUTES
                                              group:PREF_GROUP_IDLE_TIME];

    }
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:IDLE_TIME_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:IDLE_TIME_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    //Idle
    [checkBox_enableIdle setState:[[preferenceDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue]];
    [textField_idleMinutes setIntValue:[[preferenceDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue]];
}

@end
