/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIVolumeControlPreferences.h"
#import "AIVolumeControlPlugin.h"

#define VOLUME_CONTROL_PREF_NIB		@"VolumeControlPrefs"	//Name of preference nib
#define VOLUME_CONTROL_PREF_TITLE	@"Adium Volume"		//Title of the preference view

@interface AIVolumeControlPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
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
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Sound withDelegate:self label:VOLUME_CONTROL_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:VOLUME_CONTROL_PREF_NIB owner:self];

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
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    
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
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
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
