//
//  ESStatusPreferencesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIPlugin.h>

@class ESStatusPreferences;

@interface ESStatusPreferencesPlugin : AIPlugin {
	ESStatusPreferences	*preferences;
}

@end
