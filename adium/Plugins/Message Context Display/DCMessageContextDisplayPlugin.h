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
#define KEY_DISPLAY_LINES			@"Lines to Display"
#define KEY_DISPLAY_MODE			@"Display Mode"
#define KEY_HAVE_TALKED_DAYS		@"Have Talked Days"
#define KEY_HAVE_NOT_TALKED_DAYS	@"Have Not Talked Days"

#define CONTEXT_DISPLAY_DEFAULTS	@"MessageContextDisplayDefaults"

// Possible Display Modes
#define MODE_ALWAYS					0
#define MODE_HAVE_TALKED			1
#define MODE_HAVE_NOT_TALKED		2

@class DCMessageContextDisplayPreferences;

@interface DCMessageContextDisplayPlugin : AIPlugin {
	
	BOOL								isObserving;
	BOOL								shouldDisplay;
	int									linesToDisplay;
	
	int									displayMode;
	int									haveTalkedDays;
	int									haveNotTalkedDays;
	
	DCMessageContextDisplayPreferences  *preferences;
}

- (NSDictionary *)savableContentObject:(AIContentObject *)content;

@end
