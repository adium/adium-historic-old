//
//  AIChatCyclingPlugin.h
//  Adium
//
//  Created by Adam Iser on Thu Jul 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define PREF_GROUP_CHAT_CYCLING			@"Chat Cycling"
#define KEY_TAB_SWITCH_KEYS				@"Tab Switching Keys"

typedef enum {
	AISwitchArrows = 0,
	AISwitchShiftArrows,
	AIBrackets
} AITabKeys;

@class AIChatCyclingPreferences;

@interface AIChatCyclingPlugin : AIPlugin {
	AIChatCyclingPreferences	*preferences;
	
	NSMenuItem					*previousChatMenuItem;
	NSMenuItem					*nextChatMenuItem;
}

@end
