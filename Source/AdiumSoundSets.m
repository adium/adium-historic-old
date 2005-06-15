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

#import "AdiumSoundSets.h"
#import "AISoundController.h"

#define	PATH_SOUNDS						@"/Sounds"

#define SOUND_LOCATION					@"Location"
#define SOUND_LOCATION_SEPARATOR		@"////"
#define	SOUND_PACK_PATHNAME				@"AdiumSetPathname_Private"
#define	SOUND_PACK_VERSION				@"AdiumSetVersion"
#define SOUND_NAMES						@"Sounds"
#define SOUND_SET_PATH_EXTENSION		@"txt"

@interface AdiumSoundSets (PRIVATE)
- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray;
- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray;
- (void)addSoundsIndicatedByDictionary:(NSDictionary *)infoDict toArray:(NSMutableArray *)soundSetContents;

@end

@implementation AdiumSoundSets

/*!
 * @brief Init
 */
- (id)init {
	if ((self = [super init])) {
		//Create a custom sounds directory ~/Library/Application Support/Adium 2.0/Sounds
		[adium createResourcePathForName:PATH_SOUNDS];
	}
	
	return(self);
}

/*!
 * @brief Close
 */
- (void)dealloc {
	
	[super dealloc];
}


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
	while ((path = [enumerator nextObject])) {
		[self _scanSoundSetsFromPath:path intoArray:soundSetArray];
	}
    
    return [soundSetArray autorelease];
}

- (void)_scanSoundSetsFromPath:(NSString *)soundFolderPath intoArray:(NSMutableArray *)soundSetArray
{
    NSDirectoryEnumerator	*enumerator;		//Sound folder directory enumerator
    NSString				*file;				//Current Path (relative to sound folder)
    NSString				*soundSetPath;		//Name of the set
    NSMutableArray			*soundSetContents;  //Array of sounds in the set
	
    //Start things off with a valid set path and contents, incase any sounds aren't in subfolders
    soundSetPath = soundFolderPath;
    soundSetContents = [[NSMutableArray alloc] init];
	
    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:soundFolderPath];
    while ((file = [enumerator nextObject])) {
        BOOL			isDirectory;
        NSString		*fullPath;
		NSString		*fileName = [file lastPathComponent];
		
		//Skip .*, *.txt, and .svn
        if ([fileName characterAtIndex:0] != '.' &&
			[[file pathExtension] caseInsensitiveCompare:SOUND_SET_PATH_EXTENSION] != NSOrderedSame &&
			![[file pathComponents] containsObject:@".svn"]) { //Ignore certain files
			
            //Determine if this is a file or a directory
            fullPath = [soundFolderPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
            if (isDirectory) {
				//Only add the soundset if it contains sounds
                if ([soundSetContents count] != 0) {
                    //Close the current soundset, adding it to our sound set array
                    [self _addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];
                }
				
                //Open a new soundset for this directory
                soundSetPath = fullPath;
				
				[soundSetContents release];
                soundSetContents = [[NSMutableArray alloc] init];
				
            } else {
				if ([fileName isEqualToString:@"Info.plist"]) {
					NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
					[infoDict setObject:soundSetPath forKey:SOUND_PACK_PATHNAME];
					[self addSoundsIndicatedByDictionary:infoDict
												 toArray:soundSetContents];
					
				} else {
					//Add the sound
					[soundSetContents addObject:fullPath];
				}
            }
        }
    }
	
    //Close the last soundset, adding it to our sound set array
    [self _addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];
	[soundSetContents release];
}

- (void)_addSet:(NSString *)inSet withSounds:(NSArray *)inSounds toArray:(NSMutableArray *)inArray
{
	if (inSet && inSounds && inArray) {
		[inArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:inSet, KEY_SOUND_SET, inSounds, KEY_SOUND_SET_CONTENTS, nil]];
	}
}

/*!
* @brief Add sounds indicated dynamically by a dictionary to an array
 *
 * Handle optional location key, which allows emoticons to be loaded from arbitrary directories.
 * This is currently only used by the iChat sound pack.
 */
- (void)addSoundsIndicatedByDictionary:(NSDictionary *)infoDict toArray:(NSMutableArray *)soundSetContents
{
	int version = [[infoDict objectForKey:SOUND_PACK_VERSION] intValue];
	
	switch (version) {
		case 1:
		{
			NSDictionary	*sounds;
			NSEnumerator	*enumerator;
			NSString		*soundName, *soundLocation = nil;
			
			sounds = [self soundsDictionaryFromDictionary:infoDict usingLocation:&soundLocation];
			
			//If we don't have a sound location, return
			if (!sounds || !soundLocation) return;
			
			enumerator = [sounds objectEnumerator];
			while ((soundName = [enumerator nextObject])) {
				[soundSetContents addObject:[soundLocation stringByAppendingPathComponent:soundName]];
			}
			
			break;	
		}
			
		default:
			NSRunAlertPanel(AILocalizedString(@"Cannot open sound set", nil),
			                AILocalizedString(@"The sound set at %@ is version %i, and this version of Adium does not know how to handle that; perhaps try a later version of Adium.", nil),
			                /*defaultButton*/ nil, /*alternateButton*/ nil, /*otherButton*/ nil,
			                [infoDict objectForKey:SOUND_PACK_PATHNAME], version);
			break;
	}	
}

- (NSDictionary *)soundsDictionaryFromDictionary:(NSDictionary *)infoDict usingLocation:(NSString **)outSoundLocation
{
	NSString		*soundLocation = nil, *fullSoundLocation = nil;
	NSDictionary	*sounds;
	
	id			possiblePaths = [infoDict objectForKey:SOUND_LOCATION];
	
	if (possiblePaths) {
		if ([possiblePaths isKindOfClass:[NSString class]]) {
			possiblePaths = [NSArray arrayWithObjects:possiblePaths, nil];
		}
		
		NSEnumerator	*pathEnumerator = [possiblePaths objectEnumerator];
		NSString		*aPath;
		
		while ((aPath = [pathEnumerator nextObject])) {
			NSString	*possiblePath;
			NSArray		*splitPath = [aPath componentsSeparatedByString:SOUND_LOCATION_SEPARATOR];
			
			/* Two possible formats:
				*
				* <string>/absolute/path/to/directory</string>
				* <string>CFBundleIdentifier////relative/path/from/bundle/to/directory</string>
				*
				* The separator in the latter is ////, defined as SOUND_LOCATION_SEPARATOR.
				*/
			if ([splitPath count] == 1) {
				possiblePath = [splitPath objectAtIndex:0];
			} else {
				NSArray *components = [NSArray arrayWithObjects:
					[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[splitPath objectAtIndex:0]],
					[splitPath objectAtIndex:1],
					nil];
				possiblePath = [NSString pathWithComponents:components];
			}
			
			/* If the directory exists, then we've found the location. If we
				* make it all the way through the list without finding a valid
				* directory, then the standard location will be used.
				*/
			BOOL isDir;
			if ([[NSFileManager defaultManager] fileExistsAtPath:possiblePath isDirectory:&isDir] && isDir) {
				soundLocation = possiblePath;
				
				/* Keep the 'full sound location', which is what was indicated in the dictionary, for generation of
				* the SOUND_NAMES key on a by-location basis later on.
				*/
				fullSoundLocation = aPath;
				break;
			}
		}
	}
	
	sounds = [infoDict objectForKey:[NSString stringWithFormat:@"%@:%@",SOUND_NAMES,fullSoundLocation]];
	if (!sounds) sounds = [infoDict objectForKey:SOUND_NAMES];
	
	if (outSoundLocation) *outSoundLocation = soundLocation;
	
	return sounds;
}


@end
