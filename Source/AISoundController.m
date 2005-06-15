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

// $Id$

#import "AIPreferenceController.h"
#import "AISoundController.h"
#import <Adium/AIObject.h>
#import <Adium/AIAccount.h>
#import <Adium/SUSpeaker.h>
#import <Adium/QTSoundFilePlayer.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#include <float.h>

#define	PATH_SOUNDS					@"/Sounds"
#define PATH_INTERNAL_SOUNDS		@"/Contents/Resources/Sounds/"
#define SOUND_SET_PATH_EXTENSION	@"txt"
#define SOUND_DEFAULT_PREFS			@"SoundPrefs"
#define MAX_CACHED_SOUNDS			4					//Max cached sounds

#define TEXT_TO_SPEAK				@"Text"
#define VOICE						@"Voice"
#define PITCH						@"Pitch"
#define RATE						@"Rate"


#define SOUND_LOCATION					@"Location"
#define SOUND_LOCATION_SEPARATOR		@"////"
#define	SOUND_PACK_PATHNAME				@"AdiumSetPathname_Private"
#define	SOUND_PACK_VERSION				@"AdiumSetVersion"
#define SOUND_NAMES						@"Sounds"

@interface AISoundController (PRIVATE)
- (void)_removeSystemAlertIDs;
- (void)_coreAudioPlaySound:(NSString *)inPath;
- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray;
- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray;
- (void)addSoundsIndicatedByDictionary:(NSDictionary *)infoDict toArray:(NSMutableArray *)soundSetContents;

- (void)loadVoiceArray;
- (SUSpeaker *)_speakerForVoice:(NSString *)voiceString index:(int *)voiceIndex;
- (void)speakNext;
- (void)initDefaultVoiceIfNecessary;
- (void)_stopSpeakingNow;

- (void)uncacheLastPlayer;
@end

@implementation AISoundController

- (id)init
{
	if ((self = [super init])) {
		adiumSound = [[AdiumSound alloc] init];
		adiumSpeech = [[AdiumSpeech alloc] init];
		adiumSoundSets = [[AdiumSoundSets alloc] init];
	}
	
	return self;
}

- (void)controllerDidLoad
{
	[adiumSound controllerDidLoad];
}

- (void)controllerWillClose
{
	[adiumSound dealloc]; adiumSound = nil;
	[adiumSpeech dealloc]; adiumSpeech = nil;
	[adiumSoundSets dealloc]; adiumSoundSets = nil;
}

- (void)dealloc
{
	[super dealloc];
}

//
//- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
//							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
//{
//	NSEnumerator		*enumerator;
//	QTSoundFilePlayer   *soundFilePlayer;
//	SoundDeviceType		oldSoundDeviceType;
//	
//	useCustomVolume = YES;
//	customVolume = ([[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]);
//				
//	muteSounds = ([[prefDict objectForKey:KEY_SOUND_MUTE] intValue] ||
//				  [[prefDict objectForKey:KEY_SOUND_TEMPORARY_MUTE] intValue] ||
//				  [[prefDict objectForKey:KEY_SOUND_STATUS_MUTE] intValue]);
//	
//	oldSoundDeviceType = soundDeviceType;
//	soundDeviceType = [[prefDict objectForKey:KEY_SOUND_SOUND_DEVICE_TYPE] intValue];
//	
//	
//	//Clear out our cached sounds and our speech aray if either
//	// -We're probably not going to be using them for a while
//	// -We've changed output device types so will want to recreate our sound output objects
//	//
//	//If neither of these things happened, we need to update our currently playing songs
//	//to the new volume setting.
//	
//	BOOL needToStopAndRelease = (muteSounds || (soundDeviceType != oldSoundDeviceType));
//	
//	enumerator = [soundCacheDict objectEnumerator];
//	while ((soundFilePlayer = [enumerator nextObject])) {
//		if (needToStopAndRelease) {
//			[soundFilePlayer stop];
//		} else {
//			[soundFilePlayer setVolume:customVolume];
//		}
//	}
//	
//	if (needToStopAndRelease) {
//		[speechArray removeAllObjects];
//		[soundCacheDict removeAllObjects];
//		[soundCacheArray removeAllObjects];
//	}
//}




@end
