//
//  AIVolumeControlPreferences.m
//  Adium
//
//  Created by Adam Iser on Wed Apr 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIVolumeControlPreferences.h"
#import "AIVolumeControlPlugin.h"

#define VOLUME_CONTROL_PREF_NIB		@"VolumeControlPrefs"	//Name of preference nib
#define VOLUME_CONTROL_PREF_TITLE	@"Adium Volume"		//Title of the preference view

@interface AIVolumeControlPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)configureView;
@end

@implementation AIVolumeControlPreferences

//Return a new instance
+ (AIVolumeControlPreferences *)volumeControlPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];
    preferenceDict = nil;

    //Load the pref view nib
    [NSBundle loadNibNamed:VOLUME_CONTROL_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:VOLUME_CONTROL_PREF_TITLE categoryName:PREFERENCE_CATEGORY_OTHER view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    [self preferencesChanged:nil];

    //Observe preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    return(self);
}

//called when the prefs change
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){

        //Hold onto the pref dict
        [preferenceDict release];
        preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] retain];

        //Configure our view
        [self configureView];
    }
}

//Configures our view for the current preferences
- (void)configureView
{
    if([[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] == YES){
        [slider_volume setFloatValue:0.0];

    }else if([[preferenceDict objectForKey:KEY_SOUND_USE_CUSTOM_VOLUME] intValue] == NO){
        [slider_volume setFloatValue:0.5];

    }else{
        float	volume = [[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];
        [slider_volume setFloatValue:volume];

    }
}

//New value selected on the volume slider
- (IBAction)selectVolume:(id)sender
{
    float		value = [sender floatValue];
    BOOL		mute, custom;
    BOOL		playSample = NO;
    
    //Save the pref
    if(value == -1.0){ //Muted
        mute = YES;
        custom = NO;        
    }else if(value == 0.5){ //Default Volume
        mute = NO;
        custom = NO;        
    }else{ //Custom volume
        mute = NO;
        custom = YES;        
    }

    //Volume
    if(value != [[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]){
        [[owner preferenceController] setPreference:[NSNumber numberWithFloat:value]
                                             forKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
                                              group:PREF_GROUP_GENERAL];
        playSample = YES;
    }

    //Muted
    if(mute != [[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue]){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:mute]
                                             forKey:KEY_SOUND_MUTE
                                              group:PREF_GROUP_GENERAL];
        playSample = YES;
    }

    //Custom
    if(custom != [[preferenceDict objectForKey:KEY_SOUND_USE_CUSTOM_VOLUME] intValue]){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:custom]
                                             forKey:KEY_SOUND_USE_CUSTOM_VOLUME
                                              group:PREF_GROUP_GENERAL];
        playSample = YES;
    }

    //Play a sample sound
    if(playSample){
        [[owner soundController] playSoundAtPath:@"/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/volume.aiff"];
    }
}

@end
