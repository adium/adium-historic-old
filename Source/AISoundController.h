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

//Sound Controller
#define	KEY_SOUND_SET						@"Set"
#define	KEY_SOUND_SET_CONTENTS				@"Sounds"
#define KEY_SOUND_MUTE						@"Mute Sounds"
#define KEY_SOUND_TEMPORARY_MUTE			@"Mute Sounds Temporarily"
#define	KEY_SOUND_STATUS_MUTE				@"Mute Sounds based on Status"
#define KEY_SOUND_USE_CUSTOM_VOLUME			@"Use Custom Volume"
#define KEY_SOUND_CUSTOM_VOLUME_LEVEL		@"Custom Volume Level"
#define KEY_USE_SYSTEM_SOUND_OUTPUT			@"Use System Sound Output"
#define KEY_SOUND_SOUND_DEVICE_TYPE			@"Sound Device Type"

#define PREF_GROUP_SOUNDS					@"Sounds"
#define KEY_EVENT_MUTE_WHILE_AWAY			@"Mute While Away"

@class SUSpeaker;

@protocol AIController;

typedef enum{
	SOUND_SYTEM_OUTPUT_DEVICE = 0,
	SOUND_SYTEM_ALERT_DEVICE
} SoundDeviceType;

@interface AISoundController : AIObject <AIController> {
    NSMutableDictionary	*soundCacheDict;
    NSMutableArray		*soundCacheArray;
	NSTimer				*soundCacheCleanupTimer;
    BOOL				useCustomVolume;
    BOOL				muteSounds;
	BOOL				muteWhileAway;
	SoundDeviceType		soundDeviceType;
    float				customVolume;
	
    int					activeSoundThreads;
    BOOL				soundThreadActive;
    
    NSMutableDictionary	*systemSoundIDDict;
	
    NSMutableArray 		*speechArray;
    NSArray				*voiceArray;
    BOOL				resetNextTime;
    BOOL				speaking;
    int                 defaultRate;
    int                 defaultPitch;

    SUSpeaker			*speaker_variableVoice;
    SUSpeaker			*speaker_defaultVoice;    
}

//Sound
- (void)playSoundAtPath:(NSString *)inPath;

//Speech
- (NSArray *)voices;
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(int)rate;
- (int)defaultRate;
- (int)defaultPitch;
- (void)speakText:(NSString *)text;
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(float)pitch rate:(float)rate;

//Soundsets
- (NSArray *)soundSetArray;
- (NSDictionary *)soundsDictionaryFromDictionary:(NSDictionary *)infoDict usingLocation:(NSString **)outSoundLocation;

@end

