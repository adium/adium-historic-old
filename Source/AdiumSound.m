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

#import "AISoundController.h"
#import "AIPreferenceController.h"
#import "AdiumSound.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/QTSoundFilePlayer.h>

#define SOUND_DEFAULT_PREFS				@"SoundPrefs"
#define MAX_CACHED_SOUNDS				4			//Max cached sounds

@interface AdiumSound (PRIVATE)
- (void)_stopAndReleaseAllSounds;
- (void)_setVolumeOfAllSoundsTo:(float)inVolume;
- (void)coreAudioPlaySound:(NSString *)inPath;
- (void)_uncacheLeastRecentlyUsedSound;
@end

@implementation AdiumSound

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		soundCacheDict = [[NSMutableDictionary alloc] init];
		soundCacheArray = [[NSMutableArray alloc] init];
		soundCacheCleanupTimer = nil;
		soundsAreMuted = NO;

		//Observe workspace activity changes so we can mute sounds as necessary
		NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];

		[workspaceCenter addObserver:self
							selector:@selector(workspaceSessionDidBecomeActive:)
								name:NSWorkspaceSessionDidBecomeActiveNotification
							  object:nil];

		[workspaceCenter addObserver:self
							selector:@selector(workspaceSessionDidResignActive:)
								name:NSWorkspaceSessionDidResignActiveNotification
							  object:nil];
	}

	return self;
}

/*!
 * @brief Finish Initing
 *
 * Requires:
 * 1) Preference controller is ready
 */
- (void)controllerDidLoad
{
	//Register our default preferences and observe changes
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_SOUNDS];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[self _stopAndReleaseAllSounds];

	[soundCacheDict release]; soundCacheDict = nil;
	[soundCacheArray release]; soundCacheArray = nil;
	[soundCacheCleanupTimer invalidate]; [soundCacheCleanupTimer release]; soundCacheCleanupTimer = nil;

	[super dealloc];
}

/*!
 * @brief Play a sound
 * 
 * @param inPath path to the sound file
 */
- (void)playSoundAtPath:(NSString *)inPath
{
	if (inPath && customVolume != 0.0 && !soundsAreMuted) {
		[self coreAudioPlaySound:inPath];
	}
}

/*!
 * @brief Preferences changed, adjust to the new values
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	float newVolume = [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];

	//If sound volume has changed, we must update all existing sounds to the new volume
	if (customVolume != newVolume) {
		[self _setVolumeOfAllSoundsTo:newVolume];
	}

	//Load the new preferences
	customVolume = newVolume;
}

/*!
 * @brief Stop and release all cached sounds
 */
- (void)_stopAndReleaseAllSounds
{
	[[soundCacheDict allValues] makeObjectsPerformSelector:@selector(stop)];
	[soundCacheDict removeAllObjects];
	[soundCacheArray removeAllObjects];
}

/*!
 * @brief Update the volume of all cached sounds
 */
- (void)_setVolumeOfAllSoundsTo:(float)inVolume
{
	NSEnumerator 		*enumerator = [soundCacheDict objectEnumerator];
	QTSoundFilePlayer	*player;

	while((player = [enumerator nextObject])){
		[player setVolume:inVolume];
	}
}

/*!
 * @brief Play a sound using CoreAudio via QTSoundFilePlayer
 * 
 * @param inPath path to the sound file
 */
- (void)coreAudioPlaySound:(NSString *)inPath
{
    QTSoundFilePlayer	*existingPlayer = [soundCacheDict objectForKey:inPath];

	//Load the sound if necessary
    if (!existingPlayer) {
		//If the cache is full, remove the least recently used cached sound
		if ([soundCacheDict count] >= MAX_CACHED_SOUNDS) {
			[self _uncacheLeastRecentlyUsedSound];
		}

		//Load and cache the sound
		existingPlayer = [[QTSoundFilePlayer alloc] initWithContentsOfFile:inPath
													usingSystemAlertDevice:YES];
		if (existingPlayer) {
			//Insert the player at the front of our cache
			[soundCacheArray insertObject:inPath atIndex:0];
			[soundCacheDict setObject:existingPlayer forKey:inPath];
			[existingPlayer release];

			//Set the volume (otherwise #2283 happens)
			[existingPlayer setVolume:[[[adium preferenceController] preferenceForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL group:PREF_GROUP_SOUNDS] floatValue]];
		}

    } else {
		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
    }

    //Engage!
    if (existingPlayer) {
		//Ensure the sound is starting from the beginning; necessary for cached sounds that have already been played
		[existingPlayer setPlaybackPosition:0];

		//QTSoundFilePlayer won't play if the sound is already playing, but that's fine since we
		//reset the playback position and it will start playing there in the next run loop.
		[existingPlayer play];
    }
}

/*!
 * @brief Remove the least recently used sound from the cache
 */
- (void)_uncacheLeastRecentlyUsedSound
{
	NSString			*lastCachedPath = [soundCacheArray lastObject];
	QTSoundFilePlayer   *existingPlayer = [soundCacheDict objectForKey:lastCachedPath];

	if (![existingPlayer isPlaying]) {
		[existingPlayer stop];
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];
	}
}

/*!
 * @brief Workspace activated (Computer switched to our user)
 */
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification
{
	[self setSoundsAreMuted:YES];
}

/*!
 * @brief Workspace resigned (Computer switched to another user)
 */
- (void)workspaceSessionDidResignActive:(NSNotification *)notification
{
	[self setSoundsAreMuted:YES];
}

- (void)setSoundsAreMuted:(BOOL)mute
{
	soundsAreMuted = mute;
	if (soundsAreMuted)
		[self _stopAndReleaseAllSounds];
}

@end
