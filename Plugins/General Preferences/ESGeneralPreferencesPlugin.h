//
//  ESGeneralPreferencesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESGeneralPreferences;

typedef enum {
	AISwitchArrows = 0,
	AISwitchShiftArrows,
	AIBrackets
} AITabKeys;

#define PREF_GROUP_CHAT_CYCLING			@"Chat Cycling"
#define KEY_TAB_SWITCH_KEYS				@"Tab Switching Keys"

#define	SEND_ON_RETURN					@"Send On Return"
#define	SEND_ON_ENTER					@"Send On Enter"

#define PREF_GROUP_LOGGING              @"Logging"
#define KEY_LOGGER_ENABLE               @"Enable Logging"
#define	KEY_LOGGER_HTML                 @"Enable HTML Logging"

#define	KEY_STATUS_ICON_PACK			@"Status Icon Pack"
#define	KEY_SERVICE_ICON_PACK			@"Service Icon Pack"

@interface ESGeneralPreferencesPlugin : AIPlugin {
	ESGeneralPreferences	*preferences;
}

@end
