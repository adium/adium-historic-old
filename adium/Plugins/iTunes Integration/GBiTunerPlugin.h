//
//  GBiTunerPlugin.h
//  Adium XCode
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#define PREF_GROUP_ITUNER   @"iTuner"

@class GBiTunerPreferences;

@interface GBiTunerPlugin : AIPlugin <AIContentFilter> {
    //the hash table of the %'s 
    NSDictionary                    *hash;
}

@end
