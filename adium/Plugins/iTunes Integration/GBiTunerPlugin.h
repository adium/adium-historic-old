//
//  GBiTunerPlugin.h
//  Adium XCode
//
//  Created by Gregory Barchard on Wed Dec 10 2003.

#define ITUNER_DEFAULT_PREFS           @"iTunesIntegrationPrefs"
#define PREF_GROUP_ITUNER              @"iTunes Integration"

@protocol AIContentFilter;
@class GBiTunerPreferences;

@interface GBiTunerPlugin : AIPlugin <AIContentFilter> {    
    //dictionary of scripts
    NSDictionary            *scriptDict;
    
    GBiTunerPreferences     *preferences;
}

@end
