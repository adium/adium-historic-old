//
//  DCMessageContextDisplayPlugin.h
//  Adium
//
//  Created by David Clark on Tuesday, March 23, 2004.

// Object pref keys
#define PREF_GROUP_CONTEXT_DISPLAY  @"Message Context Display"
#define KEY_MESSAGE_CONTEXT			@"Message Context"

// Pref keys
#define KEY_DISPLAY_CONTEXT			@"Display Message Context"
#define	KEY_DIM_RECENT_CONTEXT		@"Dim Recent Context"
#define KEY_DISPLAY_LINES			@"Lines to Display"
#define KEY_DISPLAY_MODE			@"Display Mode"
#define KEY_HAVE_TALKED_DAYS		@"Have Talked Days"
#define KEY_HAVE_NOT_TALKED_DAYS	@"Have Not Talked Days"
#define KEY_HAVE_TALKED_UNITS		@"Have Talked Units"
#define KEY_HAVE_NOT_TALKED_UNITS   @"Have Not Talked Units"

#define CONTEXT_DISPLAY_DEFAULTS	@"MessageContextDisplayDefaults"

// Possible Display Modes
#define MODE_ALWAYS					0
#define MODE_HAVE_TALKED			1
#define MODE_HAVE_NOT_TALKED		2

// Possible Units
#define UNIT_DAYS					0
#define UNIT_HOURS					1

@class DCMessageContextDisplayPreferences;

@interface DCMessageContextDisplayPlugin : AIPlugin {
	
	BOOL							isObserving;
	BOOL							shouldDisplay;
	BOOL							dimRecentContext;
	int								linesToDisplay;
	
	int								displayMode;
	int								haveTalkedDays;
	int								haveNotTalkedDays;
	
	int								haveTalkedUnits;
	int								haveNotTalkedUnits;
	
	DCMessageContextDisplayPreferences  *preferences;
}

- (NSDictionary *)savableContentObject:(AIContentObject *)content;

@end
