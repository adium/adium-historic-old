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

#import <Adium/AIObject.h>

#define PREF_GROUP_SOUNDS					@"Sounds"

//Sound Controller
#define	KEY_SOUND_SET						@"Set"
#define	KEY_SOUND_SET_CONTENTS				@"Sounds"
#define KEY_SOUND_CUSTOM_VOLUME_LEVEL		@"Custom Volume Level"
#define KEY_SOUND_SOUND_DEVICE_TYPE			@"Sound Device Type"

@class AdiumSound, AdiumSpeech, AdiumSoundSets;

@protocol AIController;

typedef enum{
	SOUND_SYTEM_OUTPUT_DEVICE = 0,
	SOUND_SYTEM_ALERT_DEVICE
} SoundDeviceType;


@interface AISoundController : AIObject <AIController> {
	AdiumSound			*adiumSound;
	AdiumSpeech 		*adiumSpeech;
	AdiumSoundSets 		*adiumSoundSets;
}

//Sound
- (void)playSoundAtPath:(NSString *)inPath;

//Speech
- (NSArray *)voices;
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(int)rate;
- (float)defaultRate;
- (float)defaultPitch;
- (void)speakText:(NSString *)text;
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(float)pitch rate:(float)rate;

//Soundsets
- (NSArray *)soundSets;

@end

