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

#import "AIEmoticonsPlugin.h"
#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPreferences.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

#define EMOTICON_DEFAULT_PREFS			@"EmoticonDefaults"
#define PATH_EMOTICONS				@"/Emoticons"
#define PATH_INTERNAL_EMOTICONS			@"/Contents/Resources/Emoticons/"
#define EMOTICON_PACK_PATH_EXTENSION		@"emoticonPack"
#define EMOTICON_PATH_EXTENSION			@"emoticon"
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
// Path to Adium's application support preferences
// The above is originally from AIAdium.m, but due to code structure, could not be accessed properly

@interface AIEmoticonsPlugin (PRIVATE)
- (void)filterContentObject:(AIContentObject *)inObject;
- (NSMutableAttributedString *)convertSmiliesInMessage:(NSAttributedString *)inMessage;
- (void)installDefaultEmoticons;
- (BOOL)_scanEmoticonPacksFromPath:(NSString *)emoticonFolderPath intoArray:(NSMutableArray *)emoticonPackArray tagKey:(NSString *)source;
- (void)_scanEmoticonsFromPath:(NSString *)emoticonPackPath intoArray:(NSMutableArray *)emoticonPackArray;
- (void)addEmoticonsWithPath:(NSString *)inPath andReturnDelimitedString:(NSString *)returnDelimitedString;
- (NSArray *)emoticonsStartingWithCharacter:(unichar)firstCharacter;
- (void)updateQuickScanList;
- (void)orderEmoticonArray;

int sortByTextRepresentationLength(id objectA, id objectB, void *context);

@end

@implementation AIEmoticonsPlugin

- (void)installPlugin
{
    //init
//    quickScanSet = [[NSCharacterSet alloc] init];
    
//    emoticons = [[NSMutableArray alloc] init];
//    indexedEmoticons = [[NSMutableDictionary alloc] init];
    
//   cachedPacks = [[NSMutableArray alloc] init];
     //Creata custom emoticons directory
    // ~/Library/Application Support/Adium 2.0/Emoticons
    // Note: we should call AIAdium..., but that doesn't work, so I'm getting the info
    // "directly" FIX
    [AIFileUtilities createDirectory:[[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]/*[AIAdium applicationSupportDirectory]*/ stringByAppendingPathComponent:PATH_EMOTICONS]];

    //replaceEmoticons = YES;
//    [self loadEmoticonsFromPacks];

    //Preferences
    //Defaults
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:@"EmoticonDefaults" forClass:[self class]] forGroup:PREF_GROUP_EMOTICONS];
    //View
    prefs = [[AIEmoticonPreferences emoticonPreferencesWithOwner:owner plugin:self] retain];
    //Keep up-to-date
    
    emoticonsEnabled = NO;
    [self preferencesChanged:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

}

- (void)uninstallPlugin
{
    [quickScanSet release]; quickScanSet = nil;
    [emoticons release]; emoticons = nil;
    [cachedPacks release]; cachedPacks = nil;
    [indexedEmoticons release]; indexedEmoticons = nil;
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_EMOTICONS] == 0){
        
        replaceEmoticons = [[[owner preferenceController] preferenceForKey:@"Enable" group:PREF_GROUP_EMOTICONS object:nil] intValue] == NSOnState;
        
        if (replaceEmoticons) { //if emoticons are now enabled according to the prefs
            if (!emoticonsEnabled) //if emoticons are currently unloaded
            {
                [self loadEmoticonsIfNecessary:YES];  //emoticons not enabled going in, so we will load what we need
                emoticonsEnabled = YES; //now we know they are
                //Register our content filter
                [[owner contentController] registerDisplayingContentFilter:self];
                
            }
            // Update pack prefs in cached list
            NSEnumerator		*enumerator = [cachedPacks objectEnumerator];
            //NSMutableDictionary	*packDict = nil;
            AIEmoticonPack		*pack = nil;
            NSString                *changedKey = [[notification userInfo] objectForKey:@"Key"];
            
            while (pack = [enumerator nextObject]){
                if ([[pack preferencesKey] isEqualToString:changedKey]){
                    [pack loadPreferences];
                    [self loadEmoticonsFromPacks];
                }
            }
        } else { //if emoticons are now not enabled according to the prefs
            if (emoticonsEnabled) { //if emoticons are currently loaded
                emoticonsEnabled = NO;  //emoticons are now disabled
                [self loadEmoticonsIfNecessary:NO];   //emoticons not enabled going in, so will unload what we no longer need
                
                //Unregister our content filter
                [[owner contentController] unregisterDisplayingContentFilter:self];

            }
        }
    }
}

-(void)loadEmoticonsIfNecessary:(BOOL)load
{
    if (load) {
        if (!emoticonsEnabled) {
            quickScanSet = [[NSCharacterSet alloc] init];
            emoticons = [[NSMutableArray alloc] init];
            indexedEmoticons = [[NSMutableDictionary alloc] init];
            cachedPacks = [[NSMutableArray alloc] init];
            [self loadEmoticonsFromPacks];
        }
    } else {
        if (!emoticonsEnabled) {
            [quickScanSet release]; quickScanSet = nil;
            [emoticons release]; emoticons = nil;
            [cachedPacks release]; cachedPacks = nil;
            [indexedEmoticons release]; indexedEmoticons = nil;
        }
    }
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        BOOL			mayContainEmoticons = NO;
        AIContentMessage		*contentMessage = (AIContentMessage *)inObject;
        NSString			*messageString = [[[contentMessage message] safeString] string];
        NSMutableAttributedString	*replacementMessage = nil;
        
        //First, we do a quick scan of the message for any substrings that might end up being emoticons
        //This avoids having to do the slower, more complicated scan for the majority of messages.
        if ([messageString rangeOfCharacterFromSet:quickScanSet].location != NSNotFound){
            mayContainEmoticons = YES;
        }
        
        if (mayContainEmoticons){
            replacementMessage = [self convertSmiliesInMessage:[contentMessage message]];
            
            if(replacementMessage){
                [contentMessage setMessage:replacementMessage];
            }
        }
    }
    
}

//most of this is ripped right from 1.x, YAY!
// well...not so much anymore...but the conversion code is based on it...yippee :)
- (NSMutableAttributedString *)convertSmiliesInMessage:(NSAttributedString *)inMessage
{
    NSRange 		emoticonRange;
    NSRange		attributeRange;
    
    int			currentLocation = 0;
    int			nextOccurence = 0;
    int			replacementCount = 0;

    NSEnumerator	*emoEnumerator = nil;
    AIEmoticon		*currentEmo = nil;
    NSString		*currentEmoText = nil;

    NSMutableAttributedString	*tempMessage = [inMessage mutableCopy];
    BOOL			messageChanged = NO;

    currentLocation = [[[inMessage safeString] string] rangeOfCharacterFromSet:quickScanSet].location;

    while(currentLocation < [inMessage length]){
	
        emoEnumerator = [[self emoticonsStartingWithCharacter:[[[inMessage safeString] string] characterAtIndex:currentLocation]] objectEnumerator];
        while(currentEmo = [emoEnumerator nextObject]){
        
            currentEmoText = [currentEmo representedText];
    
            //nifty info about the current search
            //NSLog(@"%d %d %@ %@ %@", currentLocation, [inMessage length], [[inMessage safeString] string], [[[inMessage safeString] string] substringWithRange:NSMakeRange(currentLocation,[inMessage length]-currentLocation)], currentEmoText);
    
            if(currentLocation+[currentEmoText length] <= [inMessage length]){
            
                //look for the range of the emoticon
                //emoticonRange = [[[inMessage safeString] string] rangeOfString:currentEmoText options:0 range:NSMakeRange(currentLocation,[currentEmoText length])];
        
                //did we find one?
                if([[[inMessage safeString] string] compare:currentEmoText options:0 range:(emoticonRange = NSMakeRange(currentLocation,[currentEmoText length]))] == NSOrderedSame){
                //if(emoticonRange.location != NSNotFound){
            
                    //make sure this emoticon is not inside a link
                    if([inMessage attribute:NSLinkAttributeName atIndex:currentLocation effectiveRange:&attributeRange] == nil){
            
                    NSMutableAttributedString *replacement = [[[currentEmo attributedEmoticon] mutableCopy] autorelease];
        
                    //grab the original attributes
                    //ensures that the background is not lost in a message consisting only of an emoticon
                    [replacement addAttributes:[inMessage attributesAtIndex:currentLocation effectiveRange:nil] range:NSMakeRange(0,1)];
            
                    //insert the emoticon
                    [tempMessage replaceCharactersInRange:NSMakeRange(currentLocation-replacementCount,emoticonRange.length) withAttributedString:replacement];
        
                    //nifty info about where we found the emoticon and stopped looking
                    //NSLog(@"break at %d for %@",currentLocation,currentEmoText);
        
                    //essential info about where we are in the original and replacement messages
                    replacementCount += emoticonRange.length-1;
                    currentLocation += emoticonRange.length-1;
                    messageChanged = YES;
                    
                    break;
                    }
                }
            }
        }
    
        // find the next possible location of an emoticon
        currentLocation ++;
    
        //only continue parsing if we aren't at the end the message, or if no other emoticons may exist
        if(currentLocation < [inMessage length]){
            //nextOccurence = [[[[inMessage safeString] string] substringWithRange:NSMakeRange(currentLocation,[inMessage length]-currentLocation)] rangeOfCharacterFromSet:quickScanSet].location;
            nextOccurence = [[[inMessage safeString] string] rangeOfCharacterFromSet:quickScanSet options:0 range:NSMakeRange(currentLocation,[inMessage length]-currentLocation)].location;
        }else{
            nextOccurence = NSNotFound;
        }
    
        if(nextOccurence != NSNotFound){
            currentLocation = nextOccurence;
        }else{
            break;
        }
    }
    
    if(!messageChanged){
        tempMessage = nil;
    }

    return tempMessage;
}

- (void)updateQuickScanList
{
    NSEnumerator		*emoEnumerator = [emoticons objectEnumerator];
    AIEmoticon			*currentEmo = nil;
    unichar			currentChar;
    NSMutableCharacterSet	*tempSet = [[NSMutableCharacterSet alloc] init];

    while(currentEmo = [emoEnumerator nextObject]){
	//we only need to add the first character of each emoticon to the quickscan list
	//a somewhat obvious timesaver...that I never thought of
	currentChar = [[currentEmo representedText] characterAtIndex:0];

	if(![tempSet characterIsMember:currentChar]){
	    [tempSet addCharactersInString:[NSString stringWithFormat:@"%C",currentChar]];
	}
    }
    
    quickScanSet = [tempSet copy];
    [tempSet release];
}

- (void)addEmoticonsWithPath:(NSString *)inPath andReturnDelimitedString:(NSString *)returnDelimitedString
{
    NSArray		*textStrings = [returnDelimitedString componentsSeparatedByString:@"\r"];
    NSEnumerator	*enumerator = [textStrings objectEnumerator];
    NSString		*currentString = nil;
    AIEmoticon		*emo = nil;
    NSMutableArray	*subEmoticons = nil;

    while(currentString = [enumerator nextObject]){
        [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //don't add anything with path or string with length = 0
        if([inPath length] && [currentString length]){
            emo = [[AIEmoticon alloc] initWithPath:inPath andText:currentString];
            [emoticons addObject:emo];
            
            if (!(subEmoticons = [indexedEmoticons objectForKey:[NSString stringWithFormat:@"%C", [currentString characterAtIndex:0]]]))
            {
                subEmoticons = [[NSMutableArray alloc] init];
                [indexedEmoticons setObject:subEmoticons forKey:[NSString stringWithFormat:@"%C", [currentString characterAtIndex:0]]];
                [subEmoticons release];	// Adding it to the dictionary will have retained it once
            }
            
            [subEmoticons addObject:emo];
        }
    }
}

- (NSArray *)emoticonsStartingWithCharacter:(unichar)firstCharacter
{
    /*
    NSMutableArray	*limitedEmoticons = [[NSMutableArray alloc] init];
    NSEnumerator	*enumerator = [emoticons objectEnumerator];
    AIEmoticon		*emo = nil;

    while(emo = [enumerator nextObject]){
	if([[emo representedText] characterAtIndex:0] == firstCharacter){
	    [limitedEmoticons addObject:emo];
	}
    }

    return [limitedEmoticons copy];
    */
    NSMutableArray	*limitedEmoticons = [indexedEmoticons objectForKey:[NSString stringWithFormat:@"%C", firstCharacter]];
    
    if (limitedEmoticons == nil) {
        limitedEmoticons = [[[NSMutableArray alloc] init] autorelease];
    }
    
    return limitedEmoticons;
}

- (void)orderEmoticonArray
{
    // Sort master list
    //[emoticons sortUsingFunction:sortByTextRepresentationLength context:nil];
        // Only the dictionary lists need to be ordered.  This array is not used for actual conversions anymore.
    
    // Sort indexed sublists
    NSEnumerator	*enumerator = [indexedEmoticons objectEnumerator];
    NSMutableArray	*emoticonsSubset = nil;
    
    while (emoticonsSubset = [enumerator nextObject]) {
        [emoticonsSubset sortUsingFunction:sortByTextRepresentationLength context:nil];
    }
}

int sortByTextRepresentationLength(id objectA, id objectB, void *context)
{
    BOOL	emoticonA = [objectA isKindOfClass:[AIEmoticon class]];
    BOOL	emoticonB = [objectB isKindOfClass:[AIEmoticon class]];
    int		returnVal = NSOrderedSame;

    if(emoticonA && emoticonB){
        int lengthA = [[objectA representedText] length];
        int lengthB = [[objectB representedText] length];

        if (lengthA < lengthB){
            returnVal = NSOrderedDescending;
        }else if (lengthA > lengthB){
            returnVal = NSOrderedAscending;
        }
    }

    return returnVal;
}

- (void)allEmoticonPacks:(NSMutableArray *)emoticonPackArray
{
    [self allEmoticonPacks:emoticonPackArray forceReload:FALSE];
}

- (void)allEmoticonPacks:(NSMutableArray *)emoticonPackArray forceReload:(BOOL)reload
{
    NSString	*path;

    // Empty input array
    [emoticonPackArray removeAllObjects];

    // Check that all emoticon-packs are still there
    if (!reload){
	
        NSEnumerator	*enumerator = [cachedPacks objectEnumerator];
        AIEmoticonPack	*pack = nil;
        BOOL		isFolder = NO;

        while (pack = [enumerator nextObject]){
	    
            if ([[NSFileManager defaultManager] fileExistsAtPath:[pack path] isDirectory:&isFolder]){

                if (!isFolder){
                    reload = TRUE;
                }
            }else{
                reload = TRUE;
            }
        }
    }

    // Reload if requested
    if ([cachedPacks count] == 0 || reload){
        [cachedPacks removeAllObjects];
    
        //Scan internal packs
        path = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_EMOTICONS] stringByExpandingTildeInPath];
        [self _scanEmoticonPacksFromPath:path intoArray:cachedPacks tagKey:@"bundle"];
    
        //Scan user packs
        // Note: we should call AIAdium..., but that doesn't work, so I'm getting the info "directly" FIX
        path = [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]/*[AIAdium applicationSupportDirectory]*/ stringByAppendingPathComponent:PATH_EMOTICONS];
        [self _scanEmoticonPacksFromPath:path intoArray:cachedPacks tagKey:@"addons"];
    }

    [emoticonPackArray addObjectsFromArray:cachedPacks];
}

- (BOOL)loadEmoticonsFromPacks
{
    BOOL		foundGoodPack = TRUE;
    NSMutableArray	*emoticonPackArray;

    //Setup
    [emoticons	removeAllObjects];
    [indexedEmoticons	removeAllObjects];
    emoticonPackArray = [[NSMutableArray alloc] init];

    [self allEmoticonPacks:emoticonPackArray];

    //Load the appropriate emoticons from the appropriate paths
    //(Right now, just load everything from the first pack)
    if ([emoticonPackArray count] < 1)
        foundGoodPack = FALSE;

    if (foundGoodPack){
        //int o;
        NSEnumerator	*enumerator = [emoticonPackArray objectEnumerator];
        AIEmoticonPack	*smileyPack = nil;
        
        //for (o = 0; o < [emoticonPackArray count]; o++) {
        while(smileyPack = [enumerator nextObject]) {
            int	packState = [smileyPack isEnabled];
            if (packState != NSOffState) {
                [smileyPack verifyEmoticons];
                NSEnumerator	*emoEnumerator = [smileyPack emoticonEnumerator];
                id				emoID = nil;
                
                while (emoID = [emoEnumerator nextObject]) {
                    BOOL	useEmo = TRUE;
                    
                    if (packState == NSMixedState) 
                        useEmo = [smileyPack emoticonEnabled:emoID];
                    
                    if (useEmo)
                        [self addEmoticonsWithPath:[smileyPack emoticonImagePath:emoID] andReturnDelimitedString:[smileyPack emoticonEnabledTextRepresentationsReturnDelimited:emoID]];
                }
            }
            /*NSArray			*smileyList = [smileyPack objectForKey:KEY_EMOTICON_PACK_CONTENTS];
    
            //NSString		*packKey = [NSString stringWithFormat:@"%@_pack_%@", [smileyPack objectForKey:KEY_EMOTICON_PACK_SOURCE], [smileyPack objectForKey:KEY_EMOTICON_PACK_TITLE]];
            NSDictionary	*prefDict = [smileyPack objectForKey:KEY_EMOTICON_PACK_PREFS];//[[owner preferenceController] preferenceForKey:packKey group:PREF_GROUP_EMOTICONS object:nil];
    
            if ([[prefDict objectForKey:@"inUse"] intValue] && prefDict){
                int		i;
                BOOL		smileyGood;
                NSMutableString	*emoText = nil;
                NSRange		charRange;
                NSCharacterSet	*newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
                //NSArray	*fakeSeparation = nil;
        
                for (i = 0; i < [smileyList count]; i++){
                    path = [smileyList objectAtIndex:i];
        
                    // Check that files are present
                    smileyGood = TRUE;
                    
                    if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"TextEquivalents.txt"]])
                        smileyGood = FALSE;
        
                    if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"Emoticon.tiff"]])
                        smileyGood = FALSE;
        
                    if (smileyGood){
                    // Load text
                    emoText = [NSMutableString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"TextEquivalents.txt"]];
        
                    // Check string for UNIX or Windows line end encoding, repairing if needed.
                    charRange = [emoText rangeOfCharacterFromSet:newlineSet];
        
                    while (charRange.length != 0){
                        [emoText replaceCharactersInRange:charRange withString:@"\r"];
                        charRange = [emoText rangeOfCharacterFromSet:newlineSet];
                    }
        
                    // Make the emoticon object, add it to the master list
                    [self addEmoticonsWithPath:[path stringByAppendingPathComponent:@"Emoticon.tiff"] andReturnDelimitedString:emoText];
                    }else{
                    NSLog (@"Incomplete emoticon, lacking files: %@", path);
                    }
                }
            }*/
        }
    }

    [emoticonPackArray release];

    if (!foundGoodPack){
        [self installDefaultEmoticons];	// use the bundled graphics if no emoticon pack could be found
    }
    
    [self orderEmoticonArray];
    [self updateQuickScanList];

    return foundGoodPack;
}

- (BOOL)_scanEmoticonPacksFromPath:(NSString *)emoticonFolderPath intoArray:(NSMutableArray *)emoticonPackArray tagKey:(NSString *)source
{
    NSDirectoryEnumerator	*enumerator;			//Emoticon folder directory enumerator
    NSString			*file;				//Current Path (relative to Emoticon folder)
    NSString			*emoticonSetPath;		//Name of the set
    BOOL			foundGoodPack = FALSE;

    //Start things off with a valid set path and contents, incase any emoticons aren't in subfolders
    emoticonSetPath = emoticonFolderPath;

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:emoticonFolderPath];
    while((file = [enumerator nextObject])){
        BOOL			isDirectory;
        NSString		*fullPath = nil,	*title = nil;

	//Ignore certain files
        if([[file lastPathComponent] characterAtIndex:0] != '.' &&
           [[file pathExtension] caseInsensitiveCompare:EMOTICON_PACK_PATH_EXTENSION] == 0 /*&&
           ![[file pathComponents] containsObject:@"CVS"]*/){

            //Determine if this is a file or a directory
            fullPath = [emoticonFolderPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];

            if(isDirectory){
                // Load the emoticonPack	//
                NSMutableArray	*heldEmoticons = [[[NSMutableArray alloc] init] autorelease];
        
                title = [file stringByDeletingPathExtension];
        
                [self _scanEmoticonsFromPath:fullPath intoArray:heldEmoticons];

                // Get ReadMe, if available
                NSAttributedString* about = nil;

                if ([[NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByAppendingPathComponent:@"ReadMe.rtf"]]){
                    if ([NSURL fileURLWithPath:[fullPath stringByAppendingPathComponent:@"ReadMe.rtf"]]){
                        about = [[[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:[fullPath stringByAppendingPathComponent:@"ReadMe.rtf"]] documentAttributes:nil] retain];
                    }
		    
                }else if ([[NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByAppendingPathComponent:@"ReadMe.html"]]){
                    if ([NSURL fileURLWithPath:[fullPath stringByAppendingPathComponent:@"ReadMe.html"]]){
                        about = [[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:[fullPath stringByAppendingPathComponent:@"ReadMe.html"]] documentAttributes:nil];
                }
		    
                }else if ([[NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByAppendingPathComponent:@"ReadMe.txt"]]){
                    if ([NSURL fileURLWithPath:[fullPath stringByAppendingPathComponent:@"ReadMe.txt"]])
                        about = [[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:[fullPath stringByAppendingPathComponent:@"ReadMe.txt"]] documentAttributes:nil];
                }


                //[emoticonPackArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:title,  KEY_EMOTICON_PACK_TITLE, fullPath, KEY_EMOTICON_PACK_PATH, [NSArray arrayWithArray:heldEmoticons], KEY_EMOTICON_PACK_CONTENTS, source, KEY_EMOTICON_PACK_SOURCE, prefDict, KEY_EMOTICON_PACK_PREFS, about, KEY_EMOTICON_PACK_ABOUT, nil]];
                [emoticonPackArray addObject:[[[AIEmoticonPack alloc] initWithOwner:owner title:title path:fullPath sourceID:source emoticons:heldEmoticons about:about] autorelease]];
        
                if ([heldEmoticons count] > 0){
                    foundGoodPack = TRUE;
                }

            }else{
                NSLog (@"File \"EmoticonPack\" found.  Valid EmoticonPacks are directories.");
            }
        }
    }

    return foundGoodPack;	// Should return success in finding at least one pack
}

- (void)_scanEmoticonsFromPath:(NSString *)emoticonPackPath intoArray:(NSMutableArray *)emoticonPackArray
{
    NSDirectoryEnumerator	*enumerator;			//Sound folder directory enumerator
    NSString			*file;				//Current Path (relative to sound folder)

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:emoticonPackPath];
    while((file = [enumerator nextObject])){
        BOOL			isDirectory;
        NSString		*fullPath;

        if([[file lastPathComponent] characterAtIndex:0] != '.' &&
           [[file pathExtension] caseInsensitiveCompare:EMOTICON_PATH_EXTENSION] == 0 /*&&
           ![[file pathComponents] containsObject:@"CVS"]*/){ //Ignore certain files, only take emoticons

            //Determine if this is a file or a directory
            fullPath = [emoticonPackPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];

            if(isDirectory){
                [emoticonPackArray addObject:fullPath];

            }else{
                NSLog (@"File \"Emoticon\" found.  Valid Emoticons are directories.");
            }
        }
    }
}

- (void)installDefaultEmoticons
{
    NSString	*defaultPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingFormat:@"/Contents/Resources%@",PATH_EMOTICONS];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley00.png"] andReturnDelimitedString:@"O:-)\rO:)\rO=)\ro:-)\ro:)\ro=)"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley00.png"] andReturnDelimitedString:@"O:-)\rO:)\rO=)\ro:-)\ro:)\ro=)"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley01.png"] andReturnDelimitedString:@":-)\r:)\r=)\r:o)"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley02.png"] andReturnDelimitedString:@":-(\r:(\r=(("];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley03.png"] andReturnDelimitedString:@";-)\r;)"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley04.png"] andReturnDelimitedString:@":-P\r:P\r=P\r:-p\r:p\r=p"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley07.png"] andReturnDelimitedString:@">:o\r>=o"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley05.png"] andReturnDelimitedString:@"=-o\r=-O\r:-o\r:o\r=o"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley06.png"] andReturnDelimitedString:@":-*\r:*\r=*"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley08.png"] andReturnDelimitedString:@":-D\r:D\r=D"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley09.png"] andReturnDelimitedString:@":-$\r:$"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley10.png"] andReturnDelimitedString:@":-!\r:!"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley11.png"] andReturnDelimitedString:@":-[\r:[\r=["];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley12.png"] andReturnDelimitedString:@":-\\\r:\\\r=\\\r:-/\r=/\r:/"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley13.png"] andReturnDelimitedString:@":'(\r='("];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley14.png"] andReturnDelimitedString:@":-x\r:x\r=x\r:-X\r:X\r=X"];

    [self addEmoticonsWithPath:[defaultPath stringByAppendingString:@"/Smiley15.png"] andReturnDelimitedString:@"8-)\r8)"];
}

- (NSArray *)getEmoticons
{
    return [NSMutableArray arrayWithArray:emoticons];
}

@end
