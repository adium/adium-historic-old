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

#import "AIVolumeControlPreferences.h"
#import "AIVolumeControlPlugin.h"

#define DEFAULT_VOLUME 0.5

@implementation AIVolumeControlPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Sound);
}
- (NSString *)label{
    return(@"X");
}
- (NSString *)nibName{
    return(@"VolumeControlPrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    
    if([[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] == YES){
        [slider_volume setFloatValue:0.0];

    }else if([[preferenceDict objectForKey:KEY_SOUND_USE_CUSTOM_VOLUME] intValue] == NO){
        [slider_volume setFloatValue:DEFAULT_VOLUME];

    }else{
        float	volume = [[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];
        [slider_volume setFloatValue:volume];

    }
}

//Reset to the default value
- (IBAction)resetVolume:(id)sender
{
    [slider_volume setFloatValue:DEFAULT_VOLUME];
    [self selectVolume:nil]; 
}

//New value selected on the volume slider
- (IBAction)selectVolume:(id)sender
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    float		value = [slider_volume floatValue];
    BOOL		mute, custom;
    BOOL		playSample = NO;
    
    //Save the pref
    if(value == 0.0){ //Muted
        mute = YES;
        custom = NO;        
    }else if(value == DEFAULT_VOLUME){ //Default Volume
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
        playSample = NO;
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
