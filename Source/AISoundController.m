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
#import <AIUtilities/SUSpeaker.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/QTSoundFilePlayer.h>
#import <AIUtilities/AIDictionaryAdditions.h>

#define	PATH_SOUNDS					@"/Sounds"
#define PATH_INTERNAL_SOUNDS		@"/Contents/Resources/Sounds/"
#define SOUND_SET_PATH_EXTENSION	@"txt"
#define SOUND_DEFAULT_PREFS			@"SoundPrefs"
#define MAX_CACHED_SOUNDS			4					//Max cached sounds

#define TEXT_TO_SPEAK				@"Text"
#define VOICE						@"Voice"
#define PITCH						@"Pitch"
#define RATE						@"Rate"

#define	SOUND_CACHE_CLEANUP_INTERVAL	60.0

@interface AISoundController (PRIVATE)
- (void)_removeSystemAlertIDs;
- (void)_coreAudioPlaySound:(NSString *)inPath;
- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray;
- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray;
- (void)preferencesChanged:(NSNotification *)notification;

- (void)loadVoiceArray;
- (SUSpeaker *)_speakerForVoice:(NSString *)voiceString index:(int *)voiceIndex;
- (void)speakNext;
- (void)initDefaultVoiceIfNecessary;
- (void)_stopSpeakingNow;

- (void)uncacheLastPlayer;
@end

@implementation AISoundController

- (void)initController
{
    soundCacheDict = [[NSMutableDictionary alloc] init];
    soundCacheArray = [[NSMutableArray alloc] init];
	soundCacheCleanupTimer = nil;

    speechArray = [[NSMutableArray alloc] init];
    resetNextTime = NO;
    speaking = NO;

	[self loadVoiceArray];

    //Create a custom sounds directory ~/Library/Application Support/Adium 2.0/Sounds
    [[AIObject sharedAdiumInstance] createResourcePathForName:PATH_SOUNDS];
    
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_SOUNDS];
    
    //Ensure the temporary mute is off
    [[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                         forKey:KEY_SOUND_TEMPORARY_MUTE
                                          group:PREF_GROUP_SOUNDS];   
    
    //observe pref changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
}

//close
- (void)closeController
{
	//Stop speaking
	[self _stopSpeakingNow];

	//Stop all sounds from playing
	NSEnumerator		*enumerator = [soundCacheDict objectEnumerator];
	QTSoundFilePlayer   *soundFilePlayer;
	while (soundFilePlayer = [enumerator nextObject]){
		[soundFilePlayer stop];
	}
}

- (void)dealloc
{
	[super dealloc];
	
	[voiceArray release]; voiceArray = nil;
	[speechArray release]; speechArray = nil;
	[soundCacheDict release]; soundCacheDict = nil;
	[soundCacheArray release]; soundCacheArray = nil;
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	NSEnumerator		*enumerator;
	QTSoundFilePlayer   *soundFilePlayer;
	SoundDeviceType		oldSoundDeviceType;
	
	useCustomVolume = YES;
	customVolume = ([[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]);
				
	muteSounds = ([[prefDict objectForKey:KEY_SOUND_MUTE] intValue] ||
				  [[prefDict objectForKey:KEY_SOUND_TEMPORARY_MUTE] intValue]);
	
	oldSoundDeviceType = soundDeviceType;
	soundDeviceType = [[prefDict objectForKey:KEY_SOUND_SOUND_DEVICE_TYPE] intValue];
	
	
	//Clear out our cached sounds and our speech aray if either
	// -We're probably not going to be using them for a while
	// -We've changed output device types so will want to recreate our sound output objects
	//
	//If neither of these things happened, we need to update our currently playing songs
	//to the new volume setting.
	
	BOOL needToStopAndRelease = (muteSounds || (soundDeviceType != oldSoundDeviceType));
	
	enumerator = [soundCacheDict objectEnumerator];
	while (soundFilePlayer = [enumerator nextObject]){
		if (needToStopAndRelease){
			[soundFilePlayer stop];
		}else{
			[soundFilePlayer setVolume:customVolume];
		}
	}
	
	if (needToStopAndRelease){
		[speechArray removeAllObjects];
		[soundCacheDict removeAllObjects];
		[soundCacheArray removeAllObjects];
	}
	
	muteWhileAway = [[prefDict objectForKey:KEY_EVENT_MUTE_WHILE_AWAY] boolValue];
}


//Sound Playing --------------------------------------------------------------------------------------------------------
#pragma mark Sound Playing
//Play a sound by name
- (void)playSoundNamed:(NSString *)inName
{
    NSString      *path;
    NSArray       *soundsFolders = [adium resourcePathsForName:PATH_SOUNDS];
    NSEnumerator  *folderEnum    = [soundsFolders objectEnumerator];
    NSFileManager *mgr           = [NSFileManager defaultManager];
    BOOL           isDir         = NO;

    while(path = [folderEnum nextObject]) {
        path = [path stringByAppendingPathComponent:inName];
        if([mgr fileExistsAtPath:path isDirectory:&isDir]) {
            if(!isDir) {
                break;
            }
        }
    }

    if(path) {
        [self playSoundAtPath:path];
    }else{
		//They wanted a sound.  We can't find the one they wanted.  At least give 'em something.
		NSBeep();
	}
}

//Play a sound by path
- (void)playSoundAtPath:(NSString *)inPath
{
    if(!muteSounds && (!muteWhileAway || ![[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS])){
		if (inPath){
			[self _coreAudioPlaySound:inPath];
		}
	}

}


//Quicktime ------------------------------------------------------------------------------------------------------------
#pragma mark CoreAudio
// - Sound loading routine is not incredibly cheap (though not bad), so we should cache manually
// + CoreAudio offers volume control, including in real time as the sound plays
// + CoreAudio offers control over the output device (system events versus default audio, for example)
// + CoreAudio is present and functional on OS X 10.2.7 and above
// + QTSoundFilePlayer utilizes Quicktime for conversion so can play basically anything
//Play a sound using CoreAudio via QTSoundFilePlayer.
- (void)_coreAudioPlaySound:(NSString *)inPath
{
    QTSoundFilePlayer	*justCrushAlot;

    //Search for this sound in our cache
    justCrushAlot = [soundCacheDict objectForKey:inPath];
	
    //If the sound is not cached, load it
    if(!justCrushAlot){
		//If the cache is full, remove the least recently used cached sound
		if([soundCacheDict count] >= MAX_CACHED_SOUNDS){
			[self uncacheLastPlayer];
		}
		
		//Load and cache the sound
		justCrushAlot = [[[QTSoundFilePlayer alloc] initWithContentsOfFile:inPath
											 usingSystemAlertDevice:(soundDeviceType == SOUND_SYTEM_ALERT_DEVICE)] autorelease];
		if(justCrushAlot){
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
			[soundCacheDict setObject:justCrushAlot forKey:inPath];
			[soundCacheArray insertObject:inPath atIndex:0];
		}
		
    }else{

		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
    }
	
    //Set the volume and play sound
    if(justCrushAlot){
		//Reset the cached sound back to the beginning and set its volume; if it is currently playing,
		//this will make it restart.
		[justCrushAlot setVolume:customVolume];
		[justCrushAlot setPlaybackPosition:0];
		
		//QTSoundFilePlayer won't play if the sound is already playing, but that's fine since we
		//reset the playback position and it will start playing there in the next run loop.
		[justCrushAlot play];
    }
	
	if (!soundCacheCleanupTimer){
		soundCacheCleanupTimer = [[NSTimer scheduledTimerWithTimeInterval:SOUND_CACHE_CLEANUP_INTERVAL
																   target:self
																 selector:@selector(soundCacheCleanup:)
																 userInfo:nil
																  repeats:YES] retain];
	}else{
		[soundCacheCleanupTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:SOUND_CACHE_CLEANUP_INTERVAL]];
	}
}

//If sounds are cached when this fires, dealloc the one used least recently;
//If none are cached, stop the timer that got us here.
- (void)soundCacheCleanup:(NSTimer *)inTimer
{
	if ([soundCacheArray count]){
		[self uncacheLastPlayer];
	}else{
		[soundCacheCleanupTimer invalidate]; [soundCacheCleanupTimer release]; soundCacheCleanupTimer = nil;
	}
}

- (void)uncacheLastPlayer
{
	NSString			*lastCachedPath = [soundCacheArray lastObject];
	QTSoundFilePlayer   *gangstaPlaya = [soundCacheDict objectForKey:lastCachedPath];
	
	if (![gangstaPlaya isPlaying]){
		[gangstaPlaya stop];
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];	
	}
}

//Sound Sets -----------------------------------------------------------------------------------------------------------
#pragma mark Sound Sets
//Returns an array of dictionaries, each representing a soundset with the following keys:
// (NString *)"Set" - The path of the soundset (name is the last component)
// (NSArray *)"Sounds" - An array of sound paths (name is the last component) (NSString *'s)
- (NSArray *)soundSetArray
{
    NSString		*path;
    NSMutableArray	*soundSetArray;
	NSEnumerator	*enumerator;
	
    //Setup
    soundSetArray = [[NSMutableArray alloc] init];
    
    //Scan sounds
	enumerator = [[adium resourcePathsForName:@"Sounds"] objectEnumerator];
	while (path = [enumerator nextObject]){
		[self _scanSoundSetsFromPath:path intoArray:soundSetArray];
	}
    
    return([soundSetArray autorelease]);
}

- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray
{
    NSDirectoryEnumerator	*enumerator;		//Sound folder directory enumerator
    NSString				*file;				//Current Path (relative to sound folder)
    NSString				*soundSetPath;		//Name of the set
    NSMutableArray			*soundSetContents;  //Array of sounds in the set

    //Start things off with a valid set path and contents, incase any sounds aren't in subfolders
    soundSetPath = soundFolderPath;
    soundSetContents = [[[NSMutableArray alloc] init] autorelease];

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:soundFolderPath];
    while((file = [enumerator nextObject])){
        BOOL			isDirectory;
        NSString		*fullPath;

        if([[file lastPathComponent] characterAtIndex:0] != '.' &&
           [[file pathExtension] caseInsensitiveCompare:SOUND_SET_PATH_EXTENSION] != 0 &&
           ![[file pathComponents] containsObject:@".svn"]){ //Ignore certain files

            //Determine if this is a file or a directory
            fullPath = [soundFolderPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
            if(isDirectory){
                if([soundSetContents count] != 0){
                    //Close the current soundset, adding it to our sound set array
                    [self _addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];
                }

                //Open a new soundset for this directory
                soundSetPath = fullPath;
                soundSetContents = [[[NSMutableArray alloc] init] autorelease];

            }else{
                //Add the sound
                [soundSetContents addObject:fullPath];

            }
        }
    }

    //Close the last soundset, adding it to our sound set array
    [self _addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];    
}

- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray
{
	if(inSet && inSounds && inArray){
		[inArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:inSet, KEY_SOUND_SET, inSounds, KEY_SOUND_SET_CONTENTS, nil]];
	}
}


//Text to Speech -------------------------------------------------------------------------------------------------------
#pragma mark Text to Speech
/* Text to Speech
 * We use SUSpeaker to provide maximum flexibility over speech.  NSSpeechSynthesizer does not gives us pitch/rate controls,
 * and is not compatible with 10.2, as well.
 * The only significant bug in SUSpeaker is that it does not reset to the system default voice when it is asked to. We
 * therefore use 2 instances of SUSpeaker: one for default settings, and one for custom settings.
 */

//Convenience method: speak the given text with default values
- (void)speakText:(NSString *)text
{
    [self speakText:text withVoice:nil andPitch:0 andRate:0];
}

//Speak a voice-specific sample text at the passed settings
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(int)rate
{		
	NSString	*demoText;	
	int			voiceIndex;
	SUSpeaker	*theSpeaker;

	[self _stopSpeakingNow];
	theSpeaker = [self _speakerForVoice:voiceString index:&voiceIndex];
	demoText = [theSpeaker demoTextForVoiceAtIndex:((voiceIndex != NSNotFound) ? voiceIndex : -1)];

	[self speakText:demoText
		  withVoice:voiceString
		   andPitch:pitch
			andRate:rate];
}

//Return an array of voices in the same order as expected by SUSpeaker
- (NSArray *)voices
{
    return voiceArray;
}

//The systemwide default rate. This is cached when first used; it does not update if the systemwide default updates.
- (int)defaultRate
{
    [self initDefaultVoiceIfNecessary];
    return defaultRate;
}

//The systemwide default pitch. This is cached when first used; it does not update if the systemwide default updates.
- (int)defaultPitch
{ 
    [self initDefaultVoiceIfNecessary];
    return defaultPitch;
}

//add text & voiceString to the speech queue and attempt to speak text now
//pass voice as nil to use default voice
//pass pitch as 0 to use default pitch
//pass rate as 0 to use default rate
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString andPitch:(float)pitch andRate:(int)rate
{
    if(text && [text length]){
		if(!muteSounds && (!muteWhileAway || ![[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS])){
			NSMutableDictionary *dict;
			
			dict = [[NSMutableDictionary alloc] init];
			
			if(text){
				[dict setObject:text forKey:TEXT_TO_SPEAK];
			}
			
			if(voiceString) [dict setObject:voiceString forKey:VOICE];			
			if(pitch) [dict setObject:[NSNumber numberWithFloat:pitch] forKey:PITCH];
			if(rate) [dict setObject:[NSNumber numberWithInt:rate] forKey:RATE];

			[speechArray addObject:dict];
			[dict release];
			
			[self speakNext];
		}
    }
}

//attempt to speak the next item in the queue
- (void)speakNext
{
    //we have items left to speak and aren't already speaking
    if([speechArray count] && !speaking){
		//If we are on Panther and can easily check, don't speak on top of other apps; instead, wait 1 second and try again
		if([NSApp isOnPantherOrBetter]){
			if([NSClassFromString(@"NSSpeechSynthesizer") isAnyApplicationSpeaking]){
				[self performSelector:@selector(speakNext)
						   withObject:nil
						   afterDelay:1.0];
				return;
			}
		}

		speaking = YES;
		NSMutableDictionary *dict = [speechArray objectAtIndex:0];
		NSString 			*text = [dict objectForKey:TEXT_TO_SPEAK];
		NSNumber 			*pitchNumber = [dict objectForKey:PITCH];
		NSNumber 			*rateNumber = [dict objectForKey:RATE];
		SUSpeaker 			*theSpeaker = [self _speakerForVoice:[dict objectForKey:VOICE] index:NULL];

		[theSpeaker setPitch:(pitchNumber ? [pitchNumber floatValue] : defaultPitch)];
		[theSpeaker setRate:(rateNumber ? [rateNumber intValue] : defaultRate)];

		[theSpeaker speakText:text];
		[speechArray removeObjectAtIndex:0];
    }
}

- (IBAction)didFinishSpeaking:(SUSpeaker *)theSpeaker
{
    speaking = NO;
    [self speakNext];
}

//Immediately stop speaking
- (void)_stopSpeakingNow
{
	[speaker_defaultVoice stopSpeaking];
	[speaker_variableVoice stopSpeaking];
}

//INitialize the default voice if it has not yet been done
- (void)initDefaultVoiceIfNecessary
{
    if(!speaker_defaultVoice){
		speaker_defaultVoice = [[SUSpeaker alloc] init];
		[speaker_defaultVoice setDelegate:self];
		defaultRate = [speaker_defaultVoice rate];
		defaultPitch = [speaker_defaultVoice pitch];
    }
}

//Return the SUSpeaker which should be used for a given voice name, configured for that voice. Optionally, return
//the index of that voice in our array by reference.
- (SUSpeaker *)_speakerForVoice:(NSString *)voiceString index:(int *)voiceIndex;
{
	int theIndex = (voiceIndex ? *voiceIndex : 0);
	SUSpeaker	*theSpeaker;

	if(voiceString){
		theIndex = [voiceArray indexOfObject:voiceString];
	}else{
		theIndex = NSNotFound;
	}

	if(theIndex != NSNotFound){
		if(!speaker_variableVoice){ //initVariableVoiceifNecessary
			speaker_variableVoice = [[SUSpeaker alloc] init];
			[speaker_variableVoice setDelegate:self];
		}
		theSpeaker = speaker_variableVoice;
		[theSpeaker setVoice:theIndex];

	}else{
		[self initDefaultVoiceIfNecessary];
		theSpeaker = speaker_defaultVoice;
	}

	if (voiceIndex) *voiceIndex = theIndex;
		
	return theSpeaker;
}

- (void)loadVoiceArray
{
	NSArray			*originalVoiceArray = [SUSpeaker voiceNames];
	NSMutableArray	*ourVoiceArray = [originalVoiceArray mutableCopy];
	int messedUpIndex;

	//Vicki, a new voice in 10.3, returns an invalid name to SUSpeaker, Vicki3Smallurrent. If we see that name,
	//replace it with just Vicki.  If this gets fixed in a future release of OS X, this code will simply do nothing.
	messedUpIndex = [ourVoiceArray indexOfObject:@"Vicki3Smallurrent"];
	if(messedUpIndex != NSNotFound){
		[ourVoiceArray replaceObjectAtIndex:messedUpIndex
								 withObject:@"Vicki"];
	}

	//ourVoiceArray is retained, so just assign it
    voiceArray = ourVoiceArray;  //voiceArray will be in the same order that SUSpeaker expects
}

@end
