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
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AdiumSound.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <QTKit/QTKit.h>

#define SOUND_DEFAULT_PREFS				@"SoundPrefs"
#define MAX_CACHED_SOUNDS				4			//Max cached sounds

@interface AdiumSound (PRIVATE)
- (void)_stopAndReleaseAllSounds;
- (void)_setVolumeOfAllSoundsTo:(float)inVolume;
- (void)cachedPlaySound:(NSString *)inPath;
- (void)_uncacheLeastRecentlyUsedSound;
- (QTAudioContextRef)createAudioContextWithSystemOutputDevice;
- (NSArray *)allSounds;
@end

static OSStatus systemOutputDeviceDidChange(AudioHardwarePropertyID property, void *refcon);

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

		//Sign up for notification when the user changes the system output device in the Sound pane of System Preferences.
		OSStatus err = AudioHardwareAddPropertyListener(kAudioHardwarePropertyDefaultSystemOutputDevice, systemOutputDeviceDidChange, /*refcon*/ self);
		NSAssert2(err == noErr, @"%s: Couldn't sign up for system-output-device-changed notification, because AudioHardwareAddPropertyListener returned %i", __PRETTY_FUNCTION__, err);
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
		[self cachedPlaySound:inPath];
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
	QTMovie *movie;

	while((movie = [enumerator nextObject])){
		[movie setVolume:inVolume];
	}
}

/*!
 * @brief Play a QTMovie, possibly cached
 * 
 * @param inPath path to the sound file
 */
- (void)cachedPlaySound:(NSString *)inPath
{
    QTMovie *movie = [soundCacheDict objectForKey:inPath];

	//Load the sound if necessary
    if (!movie) {
		//If the cache is full, remove the least recently used cached sound
		if ([soundCacheDict count] >= MAX_CACHED_SOUNDS) {
			[self _uncacheLeastRecentlyUsedSound];
		}

		//Load and cache the sound
		NSError *error = nil;
		movie = [[QTMovie alloc] initWithFile:inPath
		                                error:&error];
		if (movie) {
			//Insert the player at the front of our cache
			[soundCacheArray insertObject:inPath atIndex:0];
			[soundCacheDict setObject:movie forKey:inPath];
			[movie release];

			//Set the volume (otherwise #2283 happens)
			[movie setVolume:customVolume];

			//Create an audio context for the system output audio device.
			//We'd reuse one context for all the movies, but that doesn't work; movies can't share a context, apparently. (You get paramErr when you try to give the second movie a context already in use by the first.)
			QTAudioContextRef newAudioContext = [self createAudioContextWithSystemOutputDevice];

			OSStatus err = SetMovieAudioContext([movie quickTimeMovie], newAudioContext);
			NSAssert4(err == noErr, @"%s: Could not set audio context of movie %@ to %p: SetMovieAudioContext returned error %i", __PRETTY_FUNCTION__, movie, newAudioContext, err);

			//We created it, so we must release it.
			QTAudioContextRelease(newAudioContext);
		}

    } else {
		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
    }

    //Engage!
    if (movie) {
		//Ensure the sound is starting from the beginning; necessary for cached sounds that have already been played
		QTTime startOfMovie = {
			.timeValue = 0LL,
			.timeScale = [[movie attributeForKey:QTMovieTimeScaleAttribute] longValue],
			.flags = 0,
		};
		[movie setCurrentTime:startOfMovie];

		//This only has an effect if the movie is not already playing. It won't stop it, and it won't start it over (the latter is what setCurrentTime: is for).
		[movie play];
    }
}

/*!
 * @brief Remove the least recently used sound from the cache
 */
- (void)_uncacheLeastRecentlyUsedSound
{
	NSString			*lastCachedPath = [soundCacheArray lastObject];
	QTMovie *movie = [soundCacheDict objectForKey:lastCachedPath];

	//If a movie is stopped, then its rate is zero. Thus, this tests whether the movie is playing. We remove it from the cache only if it is not playing.
	if ([movie rate] == 0.0) {
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];
	}
}

- (QTAudioContextRef) createAudioContextWithSystemOutputDevice
{
	QTAudioContextRef newAudioContext = NULL;
	OSStatus err;
	UInt32 dataSize;

	//First, obtain the device itself.
	AudioDeviceID systemOutputDevice = 0;
	dataSize = sizeof(systemOutputDevice);
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultSystemOutputDevice, &dataSize, &systemOutputDevice);
	NSAssert2(err == noErr, @"%s: Could not get the system output device: AudioHardwareGetProperty returned error %i", __PRETTY_FUNCTION__, err);

	//Now get its UID. We'll need to release this.
	CFStringRef deviceUID = NULL;
	dataSize = sizeof(deviceUID);
	err = AudioDeviceGetProperty(systemOutputDevice, /*channel*/ 0, /*isInput*/ false, kAudioDevicePropertyDeviceUID, &dataSize, &deviceUID);
	NSAssert3(err == noErr, @"%s: Could not get the device UID for device %p: AudioDeviceGetProperty returned error %i", __PRETTY_FUNCTION__, systemOutputDevice, err);
	[(NSObject *)deviceUID autorelease];

	//Create an audio context for this device so that our movies can play into it.
	err = QTAudioContextCreateForAudioDevice(kCFAllocatorDefault, deviceUID, /*options*/ NULL, &newAudioContext);
	NSAssert3(err == noErr, @"%s: QTAudioContextCreateForAudioDevice with device UID %@ returned error %i", __PRETTY_FUNCTION__, deviceUID, err);

	return newAudioContext;
}

- (NSArray *)allSounds
{
	return [soundCacheDict allValues];
}

/*!
 * @brief Workspace activated (Computer switched to our user)
 */
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification
{
	[self setSoundsAreMuted:NO];
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
	AILog(@"setSoundsAreMuted: %i",mute);
	if (soundsAreMuted > 0 && !mute)
		soundsAreMuted--;
	else if (mute)
		soundsAreMuted++;

	if (soundsAreMuted == 1)
		[self _stopAndReleaseAllSounds];
}

@end

static OSStatus systemOutputDeviceDidChange(AudioHardwarePropertyID property, void *refcon)
{
#pragma unused(property)
	AdiumSound *self = (id)refcon;
	NSCAssert1(self, @"AudioHardware property listener function %s called with nil refcon, which we expected to be the AdiumSound instance", __PRETTY_FUNCTION__);

	NSEnumerator *soundsEnum = [[self allSounds] objectEnumerator];
	QTMovie *movie;
	while ((movie = [soundsEnum nextObject])) {
		//QTMovie gets confused if we're playing when we do this, so pause momentarily.
		float savedRate = [movie rate];
		[movie setRate:0.0];

		//Exchange the audio context for a new one with the new device.
		QTAudioContextRef newAudioContext = [self createAudioContextWithSystemOutputDevice];

		OSStatus err = SetMovieAudioContext([movie quickTimeMovie], newAudioContext);
		NSCAssert4(err == noErr, @"%s: Could not set audio context of movie %@ to %p: SetMovieAudioContext returned error %i", __PRETTY_FUNCTION__, movie, newAudioContext, err);

		//We created it, so we must release it.
		QTAudioContextRelease(newAudioContext);

		//Resume playback, now on the new device.
		[movie setRate:savedRate];
	}
	
	return noErr;
}
