//
//  AITypingNotificationPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#define PREF_GROUP_TYPING_NOTIFICATIONS			@"Typing Notifications"
#define KEY_DISABLE_TYPING_NOTIFICATIONS		@"Disable Typing Notifications"

@class AITypingNotificationPreferences;

@interface AITypingNotificationPlugin : AIPlugin {
	AITypingNotificationPreferences		*preferences;
	BOOL								disableTypingNotifications;
}

@end
