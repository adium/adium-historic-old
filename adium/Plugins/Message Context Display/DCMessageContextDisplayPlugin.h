//
//  DCMessageContextDisplayPlugin.h
//  Adium
//
//  Created by David Clark on Tuesday, March 23, 2004.


#define PREF_GROUP_CONTEXT_DISPLAY  @"Message Context Display"
#define KEY_MESSAGE_CONTEXT			@"Message Context"
#define KEY_DISPLAY_CONTEXT			@"Display Message Context"
#define KEY_DISPLAY_LINES			@"Lines to Display"

#define CONTEXT_DISPLAY_DEFAULTS	@"MessageContextDisplayDefaults"

@class DCMessageContextDisplayPreferences;

@interface DCMessageContextDisplayPlugin : AIPlugin {
	
	BOOL								isObserving;
	BOOL								shouldDisplay;
	int									linesToDisplay;
	DCMessageContextDisplayPreferences  *preferences;
}

- (NSDictionary *)savableContentObject:(AIContentObject *)content;

@end
