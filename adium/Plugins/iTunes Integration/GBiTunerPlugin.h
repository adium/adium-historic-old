//
//  GBiTunerPlugin.h
//  Adium
//
//  Created by Gregory Barchard on Wed Dec 10 2003.

#define ITUNER_DEFAULT_PREFS           @"iTunesIntegrationPrefs"
#define PREF_GROUP_ITUNER              @"iTunes Integration"

@protocol AIContentFilter;

@interface GBiTunerPlugin : AIPlugin <AIContentFilter, AIStringFilter> {    
	NSMenuItem				*scriptMenuItem;		//Script menu parent
	NSMenu 					*scriptMenu;			//Submenu of scripts

	NSMutableArray			*flatScriptArray;		//Flat array of scripts
	NSMutableArray			*scriptArray;			//Ordered array for script menu
	
	BOOL					buildingScriptMenu;
}

@end
