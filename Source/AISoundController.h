/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

//Sound Controller
#define	KEY_SOUND_SET						@"Set"
#define	KEY_SOUND_SET_CONTENTS				@"Sounds"
#define KEY_SOUND_MUTE						@"Mute Sounds"
#define KEY_SOUND_TEMPORARY_MUTE			@"Mute Sounds Temporarily"
#define KEY_SOUND_USE_CUSTOM_VOLUME			@"Use Custom Volume"
#define KEY_SOUND_CUSTOM_VOLUME_LEVEL		@"Custom Volume Level"
#define KEY_USE_SYSTEM_SOUND_OUTPUT			@"Use System Sound Output"
#define KEY_SOUND_SOUND_DEVICE_TYPE			@"Sound Device Type"

#define PREF_GROUP_SOUNDS					@"Sounds"
#define KEY_EVENT_MUTE_WHILE_AWAY			@"Mute While Away"

@class SUSpeaker;

typedef enum{
	SOUND_SYTEM_OUTPUT_DEVICE = 0,
	SOUND_SYTEM_ALERT_DEVICE
} SoundDeviceType;

@interface AISoundController : NSObject {
    IBOutlet	AIAdium		*adium;
	
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
	
    NSLock				*soundLock;
    
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

//Sounds
- (void)playSoundNamed:(NSString *)inName;
- (void)playSoundAtPath:(NSString *)inPath;
- (NSArray *)soundSetArray;
- (void)speakText:(NSString *)text;
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString andPitch:(float)pitch andRate:(int)rate;

- (NSArray *)voices;
- (void)speakSampleTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(int)rate;

- (int)defaultRate;
- (int)defaultPitch;

//Private
- (void)initController;
- (void)closeController;

@end

