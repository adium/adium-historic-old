/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id$

#import "AISoundController.h"

#define	PATH_SOUNDS					@"/Sounds"
#define PATH_INTERNAL_SOUNDS		@"/Contents/Resources/Sounds/"
#define SOUND_SET_PATH_EXTENSION	@"txt"
#define SOUND_DEFAULT_PREFS			@"SoundPrefs"
#define MAX_CACHED_SOUNDS			4					//Max cached sounds

#define TEXT_TO_SPEAK				@"Text"
#define VOICE_INDEX					@"Voice"
#define PITCH						@"Pitch"
#define RATE						@"Rate"

@interface AISoundController (PRIVATE)
- (void)_removeSystemAlertIDs;
- (void)_coreAudioPlaySound:(NSString *)inPath;
- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray;
- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)speakNext;
- (void)initDefaultVoiceIfNecessary;
- (void)_stopSpeakingNow;
@end

@implementation AISoundController

- (void)initController
{
    soundCacheDict = [[NSMutableDictionary alloc] init];
    soundCacheArray = [[NSMutableArray alloc] init];
    activeSoundThreads = 0;
    soundLock = [[NSLock alloc] init];
    soundThreadActive = NO;
    systemSoundIDDict = [[NSMutableDictionary alloc] init];

    voiceArray = [[SUSpeaker voiceNames] retain];  //voiceArray will be in the same order that speaker expects
    speechArray = [[NSMutableArray alloc] init];
    resetNextTime = NO;
    speaking = NO;
    
    //Create a custom sounds directory ~/Library/Application Support/Adium 2.0/Sounds
    [[AIObject sharedAdiumInstance] createResourcePathForName:PATH_SOUNDS];
    
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_SOUNDS];
    
    //Ensure the temporary mute is off
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                         forKey:KEY_SOUND_TEMPORARY_MUTE
                                          group:PREF_GROUP_SOUNDS];   
    
    //observe pref changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
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
	
	//If using CFAlertSound, remove system alert IDs
	//    [self _removeSystemAlertIDs];
}

- (void)dealloc
{
	[voiceArray release]; voiceArray = nil;
	[speechArray release]; speechArray = nil;
	[soundCacheDict release]; soundCacheDict = nil;
	[soundCacheArray release]; soundCacheArray = nil;
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_SOUNDS]){    
        NSDictionary		*preferenceDict;
		NSEnumerator		*enumerator;
		QTSoundFilePlayer   *soundFilePlayer;
        SoundDeviceType		oldSoundDeviceType;
		
		preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
		useCustomVolume = YES;
		customVolume = ([[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]);
				
        muteSounds = ([[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] ||
					  [[preferenceDict objectForKey:KEY_SOUND_TEMPORARY_MUTE] intValue]);
  
		oldSoundDeviceType = soundDeviceType;
		soundDeviceType = [[preferenceDict objectForKey:KEY_SOUND_SOUND_DEVICE_TYPE] intValue];
		
		
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
		
		muteWhileAway = [[preferenceDict objectForKey:KEY_EVENT_MUTE_WHILE_AWAY] boolValue];
	}
}


//Sound Playing --------------------------------------------------------------------------------------------------------
#pragma mark Sound Playing
//Play a sound by name
- (void)playSoundNamed:(NSString *)inName
{
    NSString      *path;
    NSArray       *soundsFolders = [[AIObject sharedAdiumInstance] resourcePathsForName:PATH_SOUNDS];
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
    if(!muteSounds && (!muteWhileAway || ![[owner preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS])){
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
		//If the cache is full, remove the less recently used cached sound
		if([soundCacheDict count] >= MAX_CACHED_SOUNDS){
			NSString			*lastCachedPath = [soundCacheArray lastObject];
			QTSoundFilePlayer   *gangstaPlaya = [soundCacheDict objectForKey:lastCachedPath];
			
			[gangstaPlaya stop];
			[soundCacheDict removeObjectForKey:lastCachedPath];
			[soundCacheArray removeLastObject];
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
}


//NSSound - Not used --------------------------------------------------------------------------------------------------------------
/*
#pragma mark NSSound
 + NSSound can be threaded to avoid blocking Adium while the sound hardware wakes up
 + NSSound is fast
 - NSSound does not offer volume control
 - NSSound only plays a few formats
 + Cached by the system
Play a sound using NSSound.  Meant to be detached as a new thread.
- (void)_threadPlaySound:(NSString *)inPath
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];
    NSSound		*sound;

    //Lock to avoid trying to play two sounds at once from two different threads.
    soundThreadActive = YES;
    [soundLock lock];

    //Load the sound (The system apparently caches these)
    sound = [[NSSound alloc] initWithContentsOfFile:inPath byReference:YES];
    [sound setDelegate:self];

    //Play the sound
    [sound play];

    //When run on a laptop using battery power, the play method may block while the audio
    //hardware warms up.  If it blocks, the sound WILL NOT PLAY after the block ends.
    //To get around this, we check to make sure the sound is playing, and if it isn't
    //we call the play method again.
    if(![sound isPlaying]){
        [sound play];
    }

    //Unlock and cleanup
    [soundLock unlock];
    soundThreadActive = NO;
	
    [pool release];
}

NSSound finished playing callback
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
    //Clean up the sound
    [sound release];
}
*/

/*
//CF Alert Sound - Not used -------------------------------------------------------------------------------------------------------
//#pragma mark CF Alert Sound
// Play a sound using the CF sound API's available in 10.2+ (or so says apple)
// It's slightly more flexable than NSSound, but higher level than CoreAudio.  Good compromise?
// ? threadable (works in 10.3, crashes in 10.2 regardless of running in thread or not)
// + faster then QuickTime
// + respects system settings for Alerts (including volume and output device)
// - plays a few formats
// ? system will interrupt sounds when a new event triggers
// Ref: http://developer.apple.com/technotes/tn2002/tn2102.html
- (void)_threadPlaySoundAsAlert:(NSString *)inPath
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];
    SystemSoundActionID  soundID = 0;
    FSRef                soundRef;
    OSStatus             err;
    
    
    soundThreadActive = YES;
    [soundLock lock];
    
    // to use this API, we have to work with carbon - so need to use CF's File Manager
    // to get a refrence to the file and then use that to register the event sound with the system
    // BUT, first, we see if the system sound ID we need has already been generated.
    soundID = (SystemSoundActionID)[[systemSoundIDDict objectForKey:inPath] unsignedLongValue];
    
    //if not, then we have to generate it and save it for later (for graceful removal)
    if(!soundID){
        err = FSPathMakeRef ([inPath fileSystemRepresentation], &soundRef, NULL);
        if(noErr == err)
            err = SystemSoundGetActionID(&soundRef, &soundID);
        if(noErr == err){
            [systemSoundIDDict setObject:[NSNumber numberWithUnsignedLong:soundID] forKey:inPath];
        }
    }
    
    //play the sound (system takes care of queueing and waking audio hardware)
    SystemSoundPlay(soundID);
    
    [soundLock unlock];
    soundThreadActive = NO;
    
    [pool release];
}

// the SystemSoundGetActionID's generated in the above method need to be gracefully
// removed from the system.  We do that here.
// called from closeController:
- (void)_removeSystemAlertIDs
{
    NSEnumerator            *enumerator = [systemSoundIDDict objectEnumerator];
    SystemSoundActionID      soundID = 0;
    
    while((soundID = (SystemSoundActionID)[[enumerator nextObject] intValue])){
        SystemSoundRemoveActionID(soundID);
    }
}
*/

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
	enumerator = [[owner resourcePathsForName:@"Sounds"] objectEnumerator];
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
           ![[file pathComponents] containsObject:@"CVS"]){ //Ignore certain files

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
- (void)speakText:(NSString *)text
{
    [self speakText:text withVoice:nil andPitch:0 andRate:0];
}

- (NSArray *)voices
{
    return voiceArray;
}

- (int)defaultRate
{
    [self initDefaultVoiceIfNecessary];
    return defaultRate;
}

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
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		if(text){
			[dict setObject:text forKey:TEXT_TO_SPEAK];
		}
		
		if(voiceString){
			int voiceIndex = [voiceArray indexOfObject:voiceString];
			if(voiceIndex != NSNotFound){
				[dict setObject:[NSNumber numberWithInt:voiceIndex] forKey:VOICE_INDEX];
			}
		}
		
		if(pitch) [dict setObject:[NSNumber numberWithFloat:pitch] forKey:PITCH];
		if(rate) [dict setObject:[NSNumber numberWithInt:rate] forKey:RATE];
		
		[speechArray addObject:dict];
		[dict release];
		
		if(!muteSounds && (!muteWhileAway || ![[owner preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS])){
			[self speakNext];
		}
    }
}

//attempt to speak the next item in the queue
- (void)speakNext
{
    //we have items left to speak and aren't already speaking
    if([speechArray count] && !speaking){
		speaking = YES;
		NSMutableDictionary *dict = [speechArray objectAtIndex:0];
		NSString 			*text = [dict objectForKey:TEXT_TO_SPEAK];
		NSNumber 			*voiceNumber = [dict objectForKey:VOICE_INDEX];
		NSNumber 			*pitchNumber = [dict objectForKey:PITCH];
		NSNumber 			*rateNumber = [dict objectForKey:RATE];
		SUSpeaker 			*theSpeaker;
		
		if(voiceNumber){
			if(!speaker_variableVoice){ //initVariableVoiceifNecessary
				speaker_variableVoice = [[SUSpeaker alloc] init];
				[speaker_variableVoice setDelegate:self];
			}
			theSpeaker = speaker_variableVoice;
			[theSpeaker setVoice:[voiceNumber intValue]];
		}else{
			[self initDefaultVoiceIfNecessary];
			theSpeaker = speaker_defaultVoice;
		}
		
		if(pitchNumber){
			[theSpeaker setPitch:[pitchNumber floatValue]];
		}else{
			[theSpeaker setPitch:defaultPitch];
		}
		if(rateNumber){
			[theSpeaker setRate:[rateNumber intValue]];
		}else{
			[theSpeaker setRate:defaultRate];
		}
		
		[theSpeaker speakText:text];
		[speechArray removeObjectAtIndex:0];
    }
}

- (IBAction)didFinishSpeaking:(SUSpeaker *)theSpeaker
{
    speaking = NO;
    [self speakNext];
}

- (void)_stopSpeakingNow
{
	[speaker_defaultVoice stopSpeaking];
	[speaker_variableVoice stopSpeaking];
}

- (void)initDefaultVoiceIfNecessary
{
    if(!speaker_defaultVoice){
		speaker_defaultVoice = [[SUSpeaker alloc] init];
		[speaker_defaultVoice setDelegate:self];
		defaultRate = [speaker_defaultVoice rate];
		defaultPitch = [speaker_defaultVoice pitch];
    }
}

@end
