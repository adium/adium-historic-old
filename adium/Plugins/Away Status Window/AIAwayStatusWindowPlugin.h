//
//  AIAwayStatusWindowPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue May 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

#define AWAY_STATUS_DEFAULT_PREFS			@"AwayStatusPrefs"
#define PREF_GROUP_AWAY_STATUS_WINDOW			@"Away Status Window"
#define KEY_SHOW_AWAY_STATUS_WINDOW			@"Show Away Status Window"
#define KEY_FLOAT_AWAY_STATUS_WINDOW			@"Float Away Status Window"
#define KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW	@"Hide Away Status Window in Background"

@class AIAwayStatusWindowPreferences;

@interface AIAwayStatusWindowPlugin : AIPlugin {
    AIAwayStatusWindowPreferences	*preferences;

}

- (void)installPlugin;

@end
