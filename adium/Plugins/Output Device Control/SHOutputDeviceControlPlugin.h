//
//  SHOutputDeviceControlPlugin.h
//  Adium
//
//  Created by Stephen Holt on Mon Apr 12 2004.

//#define PREF_GROUP_SOUND_OUTPUT_DEVICE          @"Sound Output"

@class SHOutputDeviceControlPreferences;

@interface SHOutputDeviceControlPlugin : AIPlugin {
    SHOutputDeviceControlPreferences *preferences;
}

@end
