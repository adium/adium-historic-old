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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    
	[checkbox_useCustomVolume setState:[[preferenceDict objectForKey:KEY_SOUND_USE_CUSTOM_VOLUME] boolValue]];
    if([[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] == YES){
        [slider_volume setFloatValue:0.0];
    }else{
        [slider_volume setFloatValue:[[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]];
    }

    [self configureControlDimming];
}

//New value selected on the volume slider
- (IBAction)selectVolume:(id)sender
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    float			value = [slider_volume floatValue];
    BOOL			mute = (value == 0.0);
    BOOL			playSample = NO;
    
    //Volume
    if(value != [[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:value]
                                             forKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
                                              group:PREF_GROUP_GENERAL];
        playSample = YES;
    }

    //Muted
    if(mute != [[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue]){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:mute]
                                             forKey:KEY_SOUND_MUTE
                                              group:PREF_GROUP_GENERAL];
        playSample = NO;
    }

    //Play a sample sound
    if(playSample){
        [[adium soundController] playSoundAtPath:@"/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/volume.aiff"];
    }
}

//Apply a changed controls
- (IBAction)changePreference:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkbox_useCustomVolume state]]
										 forKey:KEY_SOUND_USE_CUSTOM_VOLUME
										  group:PREF_GROUP_GENERAL];
	[super changePreference:sender];
}

//Configure control dimming
- (void)configureControlDimming
{
    [slider_volume setEnabled:[checkbox_useCustomVolume state]];
}

@end
