//
//  ESGlobalEventsPreferencesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 12/18/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SOUND_ALERT_IDENTIFIER					@"PlaySound"
#define KEY_EVENT_SOUND_SET						@"Event Sound Set"

#define PREF_GROUP_DOCK_BEHAVIOR				@"DockBehavior"
#define DOCK_BEHAVIOR_ALERT_IDENTIFIER			@"BounceDockIcon"
#define KEY_DOCK_ACTIVE_BEHAVIOR_SET			@"Active Behavior Set"

#define PREF_GROUP_ANNOUNCER					@"Announcer"
#define KEY_SPEECH_ACTIVE_PRESET				@"Active Speech Preset"
#define SPEAK_EVENT_ALERT_IDENTIFIER	@"SpeakEvent"

@class ESGlobalEventsPreferences;

@interface ESGlobalEventsPreferencesPlugin : AIPlugin {
	ESGlobalEventsPreferences	*preferences;
	
	NSArray		*dockBehaviorPresetsArray;
	NSArray		*speechPresetsArray;
}

- (NSArray *)availableDockBehaviorPresets;
- (void)updateActiveDockBehaviorSet;

- (NSArray *)availableSpeechPresets;
- (void)updateActiveSpeechPreset;

@end
