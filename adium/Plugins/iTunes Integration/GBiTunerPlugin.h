//
//  GBiTunerPlugin.h
//  Adium
//
//  Created by Gregory Barchard on Wed Dec 10 2003.

#define ITUNER_DEFAULT_PREFS           @"iTunesIntegrationPrefs"
#define PREF_GROUP_ITUNER              @"iTunes Integration"

@protocol AIContentFilter;

@interface GBiTunerPlugin : AIPlugin <AIContentFilter, AIStringFilter> {    
    NSMutableDictionary		*scriptDict;		//Lookup dict for script usage
	NSMutableArray			*scriptArray;		//Ordered array for script menu
	NSMenuItem				*scriptMenuItem;
	BOOL					hasGeneratedScriptMenu;
}

@end
