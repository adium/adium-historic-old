//
//  SHOutputDeviceControlPlugin.m
//  Adium
//
//  Created by Stephen Holt on Mon Apr 12 2004.

#import "SHOutputDeviceControlPlugin.h"
#import "SHOutputDeviceControlPreferences.h"

#define KEY_SYS_SOUND_PATHER_FIRST_RUN          @"System Sound Asserted on Panther"

@interface SHOutputDeviceControlPlugin (PRIVATE)

@end

@implementation SHOutputDeviceControlPlugin

- (void)installPlugin
{
//    BOOL assertSoundOnPather = ![[[adium preferenceController] preferenceForKey:KEY_SYS_SOUND_PATHER_FIRST_RUN
//                                                                          group:PREF_GROUP_GENERAL]
//                                                                          boolValue];
    //Install our preference view
    if([NSApp isOnPantherOrBetter]){
        preferences = [[SHOutputDeviceControlPreferences preferencePane] retain];
        
//        if(assertSoundOnPather){
//            [[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
//                                                 forKey:KEY_USE_SYSTEM_SOUND_OUTPUT
//                                                  group:PREF_GROUP_GENERAL];
//                                                  
//            [[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
//                                                 forKey:KEY_SYS_SOUND_PATHER_FIRST_RUN
//                                                  group:PREF_GROUP_GENERAL];
//        }
    }
}

- (void)uninstallPlugin
{

}

@end
