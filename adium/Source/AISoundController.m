/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id: AISoundController.m,v 1.43 2004/05/20 12:57:06 adamiser Exp $

#import "AISoundController.h"
#import <QuickTime/QuickTime.h>

#define	PATH_SOUNDS					@"/Sounds"
#define PATH_INTERNAL_SOUNDS		@"/Contents/Resources/Sounds/"
#define SOUND_SET_PATH_EXTENSION	@"txt"
#define SOUND_DEFAULT_PREFS			@"SoundPrefs"
#define MAX_THREAD_SOUNDS			3					//Max concurrent sounds
#define SOUND_SLEEP_INTERVAL		0.5					//Seconds to sleep between sound activity checks
#define MAX_QT_CACHED_SOUNDS		5					//Max sounds cached for QT play

#define KEY_SOUND_WARNED_ABOUT_CUSTOM_VOLUME	@"Warned About Custom Volume"

#define TEXT_TO_SPEAK				@"Text"
#define VOICE_INDEX					@"Voice"
#define PITCH						@"Pitch"
#define RATE						@"Rate"

@interface AISoundController (PRIVATE)
- (void)_removeSystemAlertIDs;
- (void)_quicktimePlaySound:(NSString *)inPath;
- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray;
- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)speakNext;
-(void)initDefaultVoiceIfNecessary;
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
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];

    
    //Ensure the temporary mute is off
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                         forKey:KEY_SOUND_TEMPORARY_MUTE
                                          group:PREF_GROUP_GENERAL];   
    
    //observe pref changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //
    EnterMovies();
}

//close
- (void)closeController
{
    [self _removeSystemAlertIDs];
    [voiceArray release];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){    
        NSDictionary 	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
		NSNumber		*customVolumeNumber = [preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL];
        
		//On Panther, we only use the QuickTime sound playing code if a customvolume is set,
		//but on Jaguar we must always use QuickTime code since our threaded sound code will crash
		if([NSApp isOnPantherOrBetter]){
			useCustomVolume = [[preferenceDict objectForKey:KEY_SOUND_USE_CUSTOM_VOLUME] intValue];
		}else{
			useCustomVolume = YES;
		}
		customVolume = ([customVolumeNumber floatValue] * 512.0);
		
        muteSounds = ([[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] ||
					  [[preferenceDict objectForKey:KEY_SOUND_TEMPORARY_MUTE] intValue]);
        
        //If we should be muted now, clear out the speech array.
        if(muteSounds) [speechArray removeAllObjects];
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
    }
    //should create some sort of feedback if the sound was not found.
}

//Play a sound by path
- (void)playSoundAtPath:(NSString *)inPath
{
    if(!muteSounds){
        if(useCustomVolume && customVolume != 0){
			//If the user is specifying a custom volume, we must use quicktime to play our sounds.
			[self _quicktimePlaySound:inPath];

        }else if(!useCustomVolume){ 
			if(!soundThreadActive){
				[NSThread detachNewThreadSelector:@selector(_threadPlaySoundAsAlert:)
										 toTarget:self
									   withObject:inPath];
			}
		}    
	}
}


//Quicktime ------------------------------------------------------------------------------------------------------------
#pragma mark Quicktime
// - Quicktime cannot be threaded to avoid blocking while sound hardware wakes up
// - Quicktime is slow
// + Quicktime offers volume contorl
// + Quicktime can play almost anything
// - Must cache manually
//Play a sound using quicktime.
- (void)_quicktimePlaySound:(NSString *)inPath
{
    NSMovie	*movie;
	
    //Search for this sound in our cache
    movie = [soundCacheDict objectForKey:inPath];
	
    //If the sound is not cached, load it
    if(!movie){
		//If the cache is full, remove the less recently used cached sound
		if([soundCacheDict count] >= MAX_QT_CACHED_SOUNDS){
			[soundCacheDict removeObjectForKey:[soundCacheArray lastObject]];
			[soundCacheArray removeLastObject];
		}
		
		//Load and cache the sound
		movie = [[[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:inPath] byReference:YES] autorelease];
		if(movie){
			[soundCacheDict setObject:movie forKey:inPath];
			[soundCacheArray insertObject:inPath atIndex:0];
		}
		
    }else{
		//Reset the cached sound back to the beginning
		StopMovie([movie QTMovie]);
		GoToBeginningOfMovie([movie QTMovie]);
		
		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
    }
	
    //Set the volume and play sound
    if(movie){
		SetMovieVolume([movie QTMovie], customVolume);
		StartMovie([movie QTMovie]);
    }
}


//NSSound --------------------------------------------------------------------------------------------------------------
//#pragma mark NSSound
// + NSSound can be threaded to avoid blocking Adium while the sound hardware wakes up
// + NSSound is fast
// - NSSound does not offer volume control
// - NSSound only plays a few formats
// + Cached by the system
//Play a sound using NSSound.  Meant to be detached as a new thread.
//- (void)_threadPlaySound:(NSString *)inPath
//{
//    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];
//    NSSound		*sound;
//
//    //Lock to avoid trying to play two sounds at once from two different threads.
//    soundThreadActive = YES;
//    [soundLock lock];
//
//    //Load the sound (The system apparently caches these)
//    sound = [[NSSound alloc] initWithContentsOfFile:inPath byReference:YES];
//    [sound setDelegate:self];
//
//    //Play the sound
//    [sound play];
//
//    //When run on a laptop using battery power, the play method may block while the audio
//    //hardware warms up.  If it blocks, the sound WILL NOT PLAY after the block ends.
//    //To get around this, we check to make sure the sound is playing, and if it isn't
//    //we call the play method again.
//    if(![sound isPlaying]){
//        [sound play];
//    }
//
//    //Unlock and cleanup
//    [soundLock unlock];
//    soundThreadActive = NO;
//	
//    [pool release];
//}
//
//NSSound finished playing callback
//- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
//{
//    //Clean up the sound
//    [sound release];
//}
	

//CF Alert Sound -------------------------------------------------------------------------------------------------------
#pragma mark CF Alert Sound
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
    
    //play the sound (system takes care of cueueing and waking audio hardware)
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
        if(!muteSounds) [self speakNext];
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
