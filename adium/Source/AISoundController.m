/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface AISoundController (PRIVATE)
- (void)addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray;
@end

@implementation AISoundController

- (void)initController
{
    sharedMovie = nil;
}

//close
- (void)closeController
{

}

//Returns an array of dictionaries, each representing a soundset with the following keys:
// (NString *)"Set" - The path of the soundset (name is the last component)
// (NSArray *)"Sounds" - An array of sound paths (name is the last component) (NSString *'s)
- (NSArray *)soundSetArray
{
    NSString 			*soundFolderPath;		//Path to Adium's sound folder
    NSDirectoryEnumerator	*enumerator;			//Sound folder directory enumerator
    NSString			*file;				//Current Path (relative to sound folder)
    NSMutableArray		*soundSetArray;			//Array of available soundsets
    NSString			*soundSetPath;			//Name of the set
    NSMutableArray		*soundSetContents = nil;	//Array of sounds in the set

    //Setup
    soundFolderPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_SOUNDS] stringByExpandingTildeInPath];
    soundSetArray = [[NSMutableArray alloc] init];

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:soundFolderPath];
    while((file = [enumerator nextObject])){
        BOOL			isDirectory;
        NSString		*fullPath;

        if([[file lastPathComponent] characterAtIndex:0] != '.' &&
           [[file pathExtension] compare:SOUND_SET_PATH_EXTENSION] != 0){//Ignore certain files

            //Determine if this is a file or a directory
            fullPath = [soundFolderPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
    
            if(isDirectory){
                //Close the current soundset, adding it to our sound set array
                [self addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];
    
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
    [self addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];

    return([soundSetArray autorelease]);
}

- (void)addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray
{
    if(inSet && inSounds && inArray){
        [inArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:inSet, KEY_SOUND_SET, inSounds, KEY_SOUND_SET_CONTENTS, nil]];
    }
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
    if(sharedMovie){
        //Stop any currently playing sound
        StopMovie([sharedMovie QTMovie]);
        [sharedMovie release]; sharedMovie = nil;
    }

    //Play the new sound
    sharedMovie = [[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:inPath] byReference:YES];
    if(sharedMovie != nil){
        StartMovie([sharedMovie QTMovie]);
    }
}




//        SetMovieVolume([sharedMovie QTMovie],soundVolume);
// returns the shared instance of AISound
/*static AISound	*sharedInstance;
+ (AISound *)sharedInstance
{
    if(sharedInstance == nil){
        sharedInstance = [[self alloc] init];
    }

    return(sharedInstance);
}*/



// Releases sound files if they are done playing - call periodically
/*- (void)soundIdle:(NSTimer *)timer
{
    NSParameterAssert(timer != nil);

    if(sharedMovie != nil && IsMovieDone([sharedMovie QTMovie])){
        [sharedMovie release];
        sharedMovie = nil;
    }
}*/

// plays the specified sound - using the volume and soundset specified by settings
/*- (void)playSound:(SoundType)soundID
{
    if([[AISettings sharedInstance] boolForKey:[NSString stringWithFormat:@"%@:%i",KEY_SOUND_ENABLED,soundID]]){

        if([[AIAway sharedInstance] away] == NO || [[AISettings sharedInstance] boolForKey:KEY_AWAY_MUTE_SOUNDS] == NO){
            NSString *soundName;
            BOOL	 customSound;
            float	 appVolume;
            float 	 volume;
    
            soundName = [[AISettings sharedInstance] stringForKey:[NSString stringWithFormat:@"%@:%i",KEY_SOUND_FILENAME,soundID]];
            if(soundName != nil && [soundName length] != 0){    
                customSound = [[AISettings sharedInstance] boolForKey:[NSString stringWithFormat:@"%@:%i",KEY_SOUND_CUSTOM,soundID]];
                appVolume = [[AISettings sharedInstance] intForKey:KEY_SOUND_APP_VOLUME];
                volume = [[AISettings sharedInstance] intForKey:[NSString stringWithFormat:@"%@:%i",KEY_SOUND_VOLUME,soundID]];
        
                [self playSound:soundName custom:customSound volume:(appVolume * (volume / 50.0) )];
            }else{
                NSLog(@"invalid sound name");
            }
        }
    }
}*/

//  plays the specified sound - using the supplied volume and soundset
/*- (void)playSound:(NSString *)fileName custom:(BOOL)custom volume:(int)soundVolume
{
    NSString 	*soundPath;

    //---release the old sound---
    if(sharedMovie != nil){
        StopMovie([sharedMovie QTMovie]);
        [sharedMovie release];
        sharedMovie = nil;        
    }

    if(fileName != nil && [fileName length] != 0){
        //---load the new sound---
        if(custom){
            soundPath = [[PATH_CUSTOM_SOUNDS
                            stringByAppendingPathComponent:fileName] stringByExpandingTildeInPath];
        }else{
            soundPath = [[[[[NSBundle mainBundle] bundlePath]
                            stringByAppendingPathComponent:PATH_INTERNAL_SOUNDS] 
                            stringByAppendingPathComponent:fileName]
                            stringByExpandingTildeInPath];
        }
    
        
        sharedMovie = [[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:soundPath] byReference:YES];
    
        //---set the volume & play---
        if(sharedMovie != nil){
            SetMovieVolume([sharedMovie QTMovie],soundVolume);
            StartMovie([sharedMovie QTMovie]);
        }
    }
}*/

// init AISound
/*- (id)init
{
    NSTimer	*soundCleanUpTimer;

    [super init];

    EnterMovies();
    sharedMovie = nil;
    
    soundCleanUpTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) // (1.0 / X ) = X times per second
                        target: self
                        selector: @selector(soundIdle:)
                        userInfo: nil
                        repeats: true];
    [[NSRunLoop currentRunLoop] addTimer:soundCleanUpTimer forMode:NSModalPanelRunLoopMode];

    //There is a large delay when quicktime first loads - which causes an annoying pause during sign on.  
    //Here Adium loads and plays a sound (stopping it quick enough that it isn't really played).  This
    //causes the delay to happen during or immedientally after loading - which is much less noticable and
    //not as annoying
    {
        NSString	*soundPath;
        NSMovie		*tempMovie;
        
        soundPath = [[[[[NSBundle mainBundle] bundlePath]
                        stringByAppendingPathComponent:PATH_INTERNAL_SOUNDS] 
                        stringByAppendingPathComponent:@"(Adium)Buddy_SignedOn.aif"]
                        stringByExpandingTildeInPath];

        tempMovie = [[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:soundPath] byReference:YES];
    
        //---play & stop---
        if(tempMovie != nil){
            StartMovie([tempMovie QTMovie]);
            StopMovie([tempMovie QTMovie]);
        }

        [tempMovie release]; //clean up
    }

    return(self);
}*/

@end
