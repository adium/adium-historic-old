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

#import "AISoundController.h"
#import <QuickTime/QuickTime.h>

#define	PATH_SOUNDS			@"/Sounds"
#define PATH_INTERNAL_SOUNDS		@"/Contents/Resources/Sounds/"
#define SOUND_SET_PATH_EXTENSION	@"txt"
#define SOUND_DEFAULT_PREFS		@"SoundPrefs"
#define MAX_THREAD_SOUNDS		3		//Max concurrent sounds
#define SOUND_SLEEP_INTERVAL		0.5		//Seconds to sleep between sound activity checks
#define MAX_QT_CACHED_SOUNDS		5		//Max sounds cached for QT play

#define KEY_SOUND_WARNED_ABOUT_CUSTOM_VOLUME	@"Warned About Custom Volume"

#define TEXT_TO_SPEAK			@"Text"
#define VOICE_INDEX			@"Voice"
#define PITCH				@"Pitch"
#define RATE				@"Rate"

@interface AISoundController (PRIVATE)
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
    activeSoundThreads = 0;
    soundLock = [[NSLock alloc] init];

#ifdef MAC_OS_X_VERSION_10_0
    voiceArray = [[SUSpeaker voiceNames] retain];  //voiceArray will be in the same order that speaker expects
#endif
    
    speechArray = [[NSMutableArray alloc] init];
    resetNextTime = NO;
    speaking = NO;
    
    //Create a custom sounds directory ~/Library/Application Support/Adium 2.0/Sounds
    [AIFileUtilities createDirectory:[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_SOUNDS]];
    
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];

    
    //Ensure the temporary mute is off
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                         forKey:KEY_SOUND_TEMPORARY_MUTE
                                          group:PREF_GROUP_GENERAL];   
    
    //observe pref changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

}

//close
- (void)closeController
{
    [voiceArray release];
}

//Returns an array of dictionaries, each representing a soundset with the following keys:
// (NString *)"Set" - The path of the soundset (name is the last component)
// (NSArray *)"Sounds" - An array of sound paths (name is the last component) (NSString *'s)
- (NSArray *)soundSetArray
{
    NSString		*path;
    NSMutableArray	*soundSetArray;

    //Setup
    soundSetArray = [[NSMutableArray alloc] init];
    
    //Scan internal sounds
    path = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_SOUNDS] stringByExpandingTildeInPath];
    [self _scanSoundSetsFromPath:path intoArray:soundSetArray];

    //Scan user sounds
    path = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_SOUNDS];
    [self _scanSoundSetsFromPath:path intoArray:soundSetArray];

    
    return([soundSetArray autorelease]);
}


//Private ------------------------------------------------------------------------
- (void)playSoundNamed:(NSString *)inName
{
    NSString	*path;
    
    //Sounds stored in ~/Library/Application Support/Adium 2.0/Sounds
    path = [[[AIAdium applicationSupportDirectory]
			stringByAppendingPathComponent:PATH_SOUNDS]
			stringByAppendingPathComponent:inName];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //Sounds stored within the Adium application
        path = [[[[[NSBundle mainBundle] bundlePath]
    			stringByAppendingPathComponent:PATH_INTERNAL_SOUNDS]
        		stringByAppendingPathComponent:inName]
        		stringByExpandingTildeInPath];
    }

    [self playSoundAtPath:path];
}

- (void)playSoundAtPath:(NSString *)inPath
{
    if(!muteSounds){
        //If the user is specifying a custom volume, we must use quicktime to play our sounds.
        if(useCustomVolume && customVolume != 0){
            NSMovie	*movie;
            
            //Search for this sound in our cache
            movie = [soundCacheDict objectForKey:inPath];
            if(!movie){ //If the sound is not cached, load it
                //If the cache is full, empty it
                if([soundCacheDict count] >= MAX_QT_CACHED_SOUNDS){
                    [soundCacheDict removeAllObjects];
                }
                
                movie = [[[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:inPath] byReference:YES] autorelease];
                [soundCacheDict setObject:movie forKey:inPath];
            }else{
                StopMovie([movie QTMovie]);
                GoToBeginningOfMovie([movie QTMovie]); //Reset to the begining of the sound
            }
    
            //Set the volume & play sound
            SetMovieVolume([movie QTMovie], customVolume);
            StartMovie([movie QTMovie]);
            
        }else if(!useCustomVolume){ //Otherwise, we can use NSSound
    //     if(activeSoundThreads < MAX_THREAD_SOUNDS){
                //Detach a thead to play the sound
                [NSThread detachNewThreadSelector:@selector(_threadPlaySound:) toTarget:self withObject:inPath];
                activeSoundThreads++;
    //     }else{
    //         NSLog(@"Too many sounds playing, skipping %@",[inPath lastPathComponent]);
    //     }
        }
    }    
}

//Play a sound using NSSound.  Meant to be detached as a new thread.
- (void)_threadPlaySound:(NSString *)inPath
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];
    NSSound		*sound;

    //Load the sound (The system apparently caches these)
    sound = [[NSSound alloc] initWithContentsOfFile:inPath byReference:YES];


    //Play the sound
//I'm getting crashes within [sound play], and I believe they're caused by more than one of these threads calling play simultaneously.  I'm not sure if this lock will have any effect on the crash, but it's worth a try.  Unfortunately it's very difficult to reproduce.
[soundLock lock];
    [sound play];

    //When run on a laptop using battery power, the play method may block while the audio hardware warms up.  If it blocks, the sound WILL NOT PLAY after the block ends.  To get around this, we check to make sure the sound is playing, and if it isn't - we call the play method again.
    if(![sound isPlaying]){
        [sound play];
    }
[soundLock unlock];

    //We keep this thread active until the sound finishes playing, so we can accurately update the activeSoundThread count when it is complete
    while([sound isPlaying]){ //Check every second for sound completion
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:SOUND_SLEEP_INTERVAL]];
    }
    activeSoundThreads--;    

    //Release the sound
    [sound release];
    
    //Release the autorelease pool
    [pool release];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){    
        NSDictionary *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    
        //Remember the values of some preferences
        useCustomVolume = [[preferenceDict objectForKey:KEY_SOUND_USE_CUSTOM_VOLUME] intValue];
        customVolume = ([[preferenceDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue] * 512.0);
        muteSounds = ( [[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] || [[preferenceDict objectForKey:KEY_SOUND_TEMPORARY_MUTE] intValue] );
        
        //If we should be muted now, clear out the speech array.
        if (muteSounds)
            [speechArray removeAllObjects];
        
        //Display the custom volume performance warning
        if(useCustomVolume && ![[preferenceDict objectForKey:KEY_SOUND_WARNED_ABOUT_CUSTOM_VOLUME] intValue]){
            int result;
    
            result = NSRunInformationalAlertPanel(@"Notice", @"Setting a custom volume may cause delays when Adium plays a sound.\r\rThese delays are most noticeable to users:\r � using a laptop (on battery power) or \r � using an older computer\r\rIf you experience delays, please set volume back to 'Normal'.", nil, @"Cancel", nil);
    
            if(result == NSAlertAlternateReturn){
                //If the user canceled, we turn the custom volume preference back off
                [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                                    forKey:KEY_SOUND_USE_CUSTOM_VOLUME
                                                    group:PREF_GROUP_GENERAL];
    
            }else{
                //Otherwise we leave it on, and suppress the warning message
                [[owner preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                                    forKey:KEY_SOUND_WARNED_ABOUT_CUSTOM_VOLUME
                                                    group:PREF_GROUP_GENERAL];
            }
        }
    }
}

- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray
{
    NSDirectoryEnumerator	*enumerator;			//Sound folder directory enumerator
    NSString			*file;				//Current Path (relative to sound folder)
    NSString			*soundSetPath;			//Name of the set
    NSMutableArray		*soundSetContents;		//Array of sounds in the set

    //Start things off with a valid set path and contents, incase any sounds aren't in subfolders
    soundSetPath = soundFolderPath;
    soundSetContents = [[[NSMutableArray alloc] init] autorelease];

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:soundFolderPath];
    while((file = [enumerator nextObject])){
        BOOL			isDirectory;
        NSString		*fullPath;

        if([[file lastPathComponent] characterAtIndex:0] != '.' &&
           [[file pathExtension] compare:SOUND_SET_PATH_EXTENSION] != 0 &&
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

- (void)speakText:(NSString *)text
{
    [self speakText:text withVoice:nil andPitch:0 andRate:0];
}

//add text & voiceString to the speech queue and attempt to speak text now
//pass voice as nil to use default voice
//pass pitch as 0 to use default pitch
//pass rate as 0 to use default rate
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString andPitch:(float)pitch andRate:(int)rate
{
    if (text && [text length]) {
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];

	if (text) {
	    [dict setObject:text forKey:TEXT_TO_SPEAK];
	}

	if (voiceString) {
	    int voiceIndex = [voiceArray indexOfObject:voiceString];
	    if (voiceIndex != NSNotFound) {
		[dict setObject:[NSNumber numberWithInt:voiceIndex] forKey:VOICE_INDEX];
	    }
	}

	if (pitch)
	    [dict setObject:[NSNumber numberWithFloat:pitch] forKey:PITCH];

	if (rate)
	    [dict setObject:[NSNumber numberWithInt:rate] forKey:RATE];
	
	[speechArray addObject:dict];
	[dict release];
        if (!muteSounds)
            [self speakNext];
    }
}

//attempt to speak the next item in the queue
- (void)speakNext
{
#ifdef MAC_OS_X_VERSION_10_0
    //we have items left to speak and aren't already speaking
    if ([speechArray count] && !speaking) {
	speaking = YES;
	NSMutableDictionary * dict = [speechArray objectAtIndex:0];
	NSString * text = [dict objectForKey:TEXT_TO_SPEAK];
	NSNumber * voiceNumber = [dict objectForKey:VOICE_INDEX];
	NSNumber * pitchNumber = [dict objectForKey:PITCH];
	NSNumber * rateNumber = [dict objectForKey:RATE];
	SUSpeaker * theSpeaker;

	if (voiceNumber) {
	    if (!speaker_variableVoice) { //initVariableVoiceifNecessary
		speaker_variableVoice = [[SUSpeaker alloc] init];
		[speaker_variableVoice setDelegate:self];
	    }
	    theSpeaker = speaker_variableVoice;
	    [theSpeaker setVoice:[voiceNumber intValue]];
	} else {
	    [self initDefaultVoiceIfNecessary];
	    theSpeaker = speaker_defaultVoice;
	}
	
	if (pitchNumber) {
	    [theSpeaker setPitch:[pitchNumber floatValue]];
	} else {
	    [theSpeaker setPitch:defaultPitch];
	}
	if (rateNumber) {
	    [theSpeaker setRate:[rateNumber intValue]];
	} else {
	    [theSpeaker setRate:defaultRate];
	}

	[theSpeaker speakText:text];
	[speechArray removeObjectAtIndex:0];
    }
#endif
}

- (IBAction)didFinishSpeaking:(SUSpeaker *)theSpeaker
{
    speaking = NO;
    [self speakNext];
}

- (void)initDefaultVoiceIfNecessary
{
#ifdef MAC_OS_X_VERSION_10_0
    if (!speaker_defaultVoice) {
	speaker_defaultVoice = [[SUSpeaker alloc] init];
	[speaker_defaultVoice setDelegate:self];
	defaultRate = [speaker_defaultVoice rate];
	defaultPitch = [speaker_defaultVoice pitch];
    }
#endif
}

@end
