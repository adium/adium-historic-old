/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIPlugin.h>

#define SOUND_ALERT_IDENTIFIER					@"PlaySound"
#define KEY_EVENT_SOUND_SET						@"Event Sound Set"

#define PREF_GROUP_DOCK_BEHAVIOR				@"DockBehavior"
#define DOCK_BEHAVIOR_ALERT_IDENTIFIER			@"BounceDockIcon"
#define KEY_DOCK_ACTIVE_BEHAVIOR_SET			@"Active Behavior Set"

#define PREF_GROUP_ANNOUNCER					@"Announcer"
#define KEY_SPEECH_ACTIVE_PRESET				@"Active Speech Preset"
#define SPEAK_EVENT_ALERT_IDENTIFIER			@"SpeakEvent"

#define PREF_GROUP_GROWL						@"Growl"
#define KEY_GROWL_ACTIVE_PRESET					@"Active Growl Preset"

#define GROWL_EVENT_ALERT_IDENTIFIER			@"Growl"

#define PREF_GROUP_EVENT_PRESETS				@"Event Presets"

@class ESGlobalEventsPreferences;

@interface ESGlobalEventsPreferencesPlugin : AIPlugin {
	ESGlobalEventsPreferences	*preferences;

	NSDictionary		*builtInEventPresets;
	NSMutableDictionary	*storedEventPresets;
}

- (void)setEventPreset:(NSDictionary *)preset;
- (void)saveEventPreset:(NSDictionary *)eventPreset;
- (NSDictionary *)builtInEventPresets;
- (NSDictionary *)storedEventPresets;

- (void)applySoundSetWithPath:(NSString *)soundSetPath;

@end
