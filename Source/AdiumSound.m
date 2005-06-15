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

#import "AdiumSound.h"

#define	SOUND_CACHE_CLEANUP_INTERVAL	60.0		//One minute

@interface AdiumSound (PRIVATE)

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

		AIPreferenceController *preferenceController = [adium preferenceController];
		
		//Register our default preferences
		[preferenceController registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]]
									  forGroup:PREF_GROUP_SOUNDS];
		
		//Ensure the temporary mute is off
		if ([[preferenceController preferenceForKey:KEY_SOUND_TEMPORARY_MUTE
											  group:PREF_GROUP_SOUNDS] boolValue]) {
			[preferenceController setPreference:nil
										 forKey:KEY_SOUND_TEMPORARY_MUTE
										  group:PREF_GROUP_SOUNDS];
		}
		
		//observe pref changes
		[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];	
	}
	
	return(self);
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	//Stop all sounds from playing
	NSEnumerator		*enumerator = [soundCacheDict objectEnumerator];
	QTSoundFilePlayer   *soundFilePlayer;
	while ((soundFilePlayer = [enumerator nextObject])) {
		[soundFilePlayer stop];
	}

	//Cleanup
	[preferenceController unregisterPreferenceObserver:self];	

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
    if (inPath && !muteSounds) {
		[self _coreAudioPlaySound:inPath];
	}
}

/*!
 * @brief Play a sound using CoreAudio via QTSoundFilePlayer
 * 
 * @param inPath path to the sound file
 */
- (void)_coreAudioPlaySound:(NSString *)inPath
{
    QTSoundFilePlayer	*existingPlayer = [soundCacheDict objectForKey:inPath];
	
	//Load the sound if necessary
    if (!existingPlayer) {
		//If the cache is full, remove the least recently used cached sound
		if ([soundCacheDict count] >= MAX_CACHED_SOUNDS) {
			[self uncacheLastPlayer];
		}
		
		//Load and cache the sound
		existingPlayer = [[QTSoundFilePlayer alloc] initWithContentsOfFile:inPath
													usingSystemAlertDevice:(soundDeviceType == SOUND_SYTEM_ALERT_DEVICE)];
		if (existingPlayer) {
			/*
			 It's important that we are caching, not so much because of the overhead but because:
			 1) we don't want to leak QTSoundFilePlayer objects but
			 2) we don't want to release them immediately as then they would crash while playing and
			 3) we don't want to wait here until they finish playing as then Adium would beachball during each sound
			 So we cache them and release them at some point in the future.  We could accomplish the same using a
			 non-autoreleasing QTSoundFilePlayer and the provided delegate methods, however:
			 4) we don't want to play the same sound more than once at a time - we would rather reset to the beginning.
			 this implies having one QTSoundFilePlayer per path, which requires caching into a lookup dict.
			 */
			[soundCacheDict setObject:existingPlayer forKey:inPath];
			[existingPlayer release];
			
			[soundCacheArray insertObject:inPath atIndex:0];
		}
		
    } else {
		
		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
    }
	
    //Set the volume and play sound
    if (existingPlayer) {
		//Reset the cached sound back to the beginning and set its volume; if it is currently playing,
		//this will make it restart.
		[existingPlayer setVolume:customVolume];
		[existingPlayer setPlaybackPosition:0];
		
		//QTSoundFilePlayer won't play if the sound is already playing, but that's fine since we
		//reset the playback position and it will start playing there in the next run loop.
		[existingPlayer play];
    }
	
	if (!soundCacheCleanupTimer) {
		soundCacheCleanupTimer = [[NSTimer scheduledTimerWithTimeInterval:SOUND_CACHE_CLEANUP_INTERVAL
																   target:self
																 selector:@selector(soundCacheCleanup:)
																 userInfo:nil
																  repeats:YES] retain];
	} else {
		[soundCacheCleanupTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:SOUND_CACHE_CLEANUP_INTERVAL]];
	}
}

//If sounds are cached when this fires, dealloc the one used least recently;
//If none are cached, stop the timer that got us here.
- (void)soundCacheCleanup:(NSTimer *)inTimer
{
	if ([soundCacheArray count]) {
		[self uncacheLastPlayer];
	} else {
		[soundCacheCleanupTimer invalidate]; [soundCacheCleanupTimer release]; soundCacheCleanupTimer = nil;
	}
}

/*!
 *
 */
- (void)uncacheLastPlayer
{
	NSString			*lastCachedPath = [soundCacheArray lastObject];
	QTSoundFilePlayer   *existingPlayer = [soundCacheDict objectForKey:lastCachedPath];
	
	if (![existingPlayer isPlaying]) {
		[existingPlayer stop];
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];	
	}
}

@end
