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
#import "AIEmoticonPreferences.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

#define EMOTICON_DEFAULT_PREFS	@"EmoticonDefaults"
#define PATH_EMOTICONS		@"/Emoticons"
#define PATH_INTERNAL_EMOTICONS		@"/Contents/Resources/Emoticons/"
#define EMOTICON_PACK_PATH_EXTENSION	@"emoticonPack"
#define EMOTICON_PATH_EXTENSION		@"emoticon"
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"	//Path to Adium's application support preferences
// The above is originally from AIAdium.m, but due to code structure, could not be accessed properly

@interface AIEmoticonsPlugin (PRIVATE)
- (void)filterContentObject:(AIContentObject *)inObject;
- (NSMutableAttributedString *)convertSmiliesInMessage:(NSAttributedString *)inMessage;
- (void)setupForTesting;
- (BOOL)_scanEmoticonPacksFromPath:(NSString *)emoticonFolderPath intoArray:(NSMutableArray *)emoticonPackArray tagKey:(NSString *)source;
- (void)_scanEmoticonsFromPath:(NSString *)emoticonPackPath intoArray:(NSMutableArray *)emoticonPackArray;
- (void)updateQuickScanList;
@end

@implementation AIEmoticonsPlugin

- (void)installPlugin
{
    //init
    quickScanList = [[NSMutableArray alloc] init];
    emoticons = [[NSMutableArray alloc] init];
	cachedPacks = [[NSMutableArray alloc] init];

	//Preferences
	 //Defaults
	[[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:@"EmoticonDefaults" forClass:[self class]] forGroup:PREF_GROUP_EMOTICONS];
	
	 //View
	prefs = [[AIEmoticonPreferences emoticonPreferencesWithOwner:owner plugin:self] retain];
	
	 //Keep up-to-date
	[self preferencesChanged:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Creata custom emoticons directory 
		// ~/Library/Application Support/Adium 2.0/Emoticons
		// Note: we should call AIAdium..., but that doesn't work, so I'm getting the info
		// "directly" FIX
    [AIFileUtilities createDirectory:[[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]/*[AIAdium applicationSupportDirectory]*/ stringByAppendingPathComponent:PATH_EMOTICONS]];
	
    //replaceEmoticons = YES;
	[self loadEmoticonsFromPacks];

    //Register our content filter
    [[owner contentController] registerDisplayingContentFilter:self];
    //[[owner contentController] registerIncomingContentFilter:self];
 
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_EMOTICONS] == 0){
	
		replaceEmoticons = [[[owner preferenceController] preferenceForKey:@"Enable" group:PREF_GROUP_EMOTICONS object:nil] intValue] == NSOnState;
		
		// Update pack prefs in cached list
		NSEnumerator	*numer = [cachedPacks objectEnumerator];
		NSMutableDictionary	*packDict = nil;
		NSString	*changedKey = [[notification userInfo] objectForKey:@"Key"];

		while (packDict = [numer nextObject])
		{
			NSString*		packKey = [NSString stringWithFormat:@"%@_pack_%@", [packDict objectForKey:KEY_EMOTICON_PACK_SOURCE], [packDict objectForKey:KEY_EMOTICON_PACK_TITLE]];
			
			if ([packKey compare:changedKey] == 0)
			{
				NSMutableDictionary	*prefDict =	[[owner preferenceController] preferenceForKey:packKey group:PREF_GROUP_EMOTICONS object:nil];
				
				[packDict	setObject:prefDict forKey:KEY_EMOTICON_PACK_PREFS];
			}
		}
    }
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if(replaceEmoticons){
	if([[inObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
	    BOOL			mayContainEmoticons = NO;
	    AIContentMessage		*contentMessage = (AIContentMessage *)inObject;
	    NSString			*messageString = [[contentMessage message] string];
	    NSMutableAttributedString	*replacementMessage = nil;

	    NSEnumerator		*enumerator = [quickScanList objectEnumerator];
	    NSString 			*currentChar = nil;

	    //First, we do a quick scan of the message for any substrings that might end up being emoticons
	    //This avoids having to do the slower, more complicated scan for the majority of messages.
	    while(currentChar = [enumerator nextObject]){
		if([messageString rangeOfString:currentChar].location != NSNotFound){
		    mayContainEmoticons = YES;
		    break;
		}
	    }

	    if (mayContainEmoticons){
		replacementMessage = [self convertSmiliesInMessage:[contentMessage message]];

		if(replacementMessage){
		    [contentMessage setMessage:replacementMessage];
		}
	    }
	}
    }
}

//most of this is ripped right from 1.x, YAY!
- (NSMutableAttributedString *)convertSmiliesInMessage:(NSAttributedString *)inMessage
{

    NSRange 		emoticonRange;
    NSRange		attributeRange;
    int			currentLocation = 0;

    NSEnumerator	*emoEnumerator = [emoticons objectEnumerator];
    NSEnumerator	*textEnumerator = nil;
    AIEmoticon		*currentEmo = nil;
    NSString		*currentEmoText = nil;

    NSMutableAttributedString	*tempMessage = [inMessage mutableCopy];
    BOOL			messageChanged = NO;

    while(currentEmo = [emoEnumerator nextObject]){
	textEnumerator = [currentEmo representedTextEnumerator];

	while(currentEmoText = [textEnumerator nextObject]){

	    //start at the beginning of the string
	    currentLocation = 0;

	    //--find emoticon--
	    emoticonRange = [[tempMessage string] rangeOfString:currentEmoText options:0 range:NSMakeRange(currentLocation,[tempMessage length] - currentLocation)];

	    while(emoticonRange.length != 0){ //if we found a emoticon
				       //--make sure this emoticon's not inside a link--
		if([tempMessage attribute:NSLinkAttributeName atIndex:emoticonRange.location effectiveRange:&attributeRange] == nil){

		    NSMutableAttributedString *replacement = [[[currentEmo attributedEmoticon] mutableCopy] autorelease];

		    [replacement addAttributes:[tempMessage attributesAtIndex:emoticonRange.location effectiveRange:nil] range:NSMakeRange(0,1)];

		    //--insert the emoticon--
                    [tempMessage replaceCharactersInRange:emoticonRange withAttributedString:replacement];

		    //shrink the emoticon range to 1 character (the multicharacter chunk has been replaced with a single character/emoticon)
		    emoticonRange.length = 1;

		    messageChanged = YES;
		}

		//--move our location--
		currentLocation = emoticonRange.location + emoticonRange.length;

		//--find the next emoticon--
		emoticonRange = [[tempMessage string] rangeOfString:currentEmoText options:0 range:NSMakeRange(currentLocation,[[tempMessage string] length] - currentLocation)];
	    }
        }
    }

    if(!messageChanged){
	tempMessage = nil;
    }

    return tempMessage;
}

- (void)updateQuickScanList
{
    int			loop = 0;
    NSEnumerator	*emoEnumerator = [emoticons objectEnumerator];
    NSEnumerator	*textEnumerator = nil;
    AIEmoticon		*currentEmo = nil;
    NSString		*currentEmoText = nil;
    NSString		*currentChar = nil;

    while(currentEmo = [emoEnumerator nextObject]){
	textEnumerator = [currentEmo representedTextEnumerator];

	while(currentEmoText = [textEnumerator nextObject]){
	    for(loop = 0; loop < [currentEmoText length]; loop++){
		currentChar = [NSString stringWithFormat:@"%C",[currentEmoText characterAtIndex:loop]];

		if(![quickScanList containsObject:currentChar]){
		    [quickScanList addObject:currentChar];
		}
	    }
	}
    }
}

- (void)allEmoticonPacks:(NSMutableArray *)emoticonPackArray
{
	[self allEmoticonPacks:emoticonPackArray	forceReload:FALSE];
}

- (void)allEmoticonPacks:(NSMutableArray *)emoticonPackArray forceReload:(BOOL)reload
{
	NSString			*path;
	
	// Empty input array
	[emoticonPackArray	removeAllObjects];
	
	if ([cachedPacks count] == 0 || reload)
	{
		[cachedPacks removeAllObjects];
	
		//Scan internal packs
		path = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_EMOTICONS] stringByExpandingTildeInPath];
		[self _scanEmoticonPacksFromPath:path intoArray:cachedPacks tagKey:@"bundle"];
	
		//Scan user packs
			// Note: we should call AIAdium..., but that doesn't work, so I'm getting the info
			// "directly" FIX
		path = [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]/*[AIAdium applicationSupportDirectory]*/ stringByAppendingPathComponent:PATH_EMOTICONS];
		[self _scanEmoticonPacksFromPath:path intoArray:cachedPacks tagKey:@"addons"];
	}
	else
	{
		// Make sure prefs are up-to-date
		/*NSEnumerator	*numer = [cachedPacks objectEnumerator];
		NSMutableDictionary	*packDict = nil;

		while (packDict = [numer nextObject])
		{
			NSString*		packKey = [NSString stringWithFormat:@"%@_pack_%@", [packDict objectForKey:KEY_EMOTICON_PACK_SOURCE], [packDict objectForKey:KEY_EMOTICON_PACK_TITLE]];
			NSMutableDictionary	*prefDict =	[[owner preferenceController] preferenceForKey:packKey group:PREF_GROUP_EMOTICONS object:nil];
			
			[packDict	setObject:prefDict forKey:KEY_EMOTICON_PACK_PREFS];
		}*/
	}
	
	[emoticonPackArray addObjectsFromArray:cachedPacks];
}

- (BOOL)loadEmoticonsFromPacks
{
	BOOL				foundGoodPack = TRUE;
	NSString*			path = nil;
	NSMutableArray		*emoticonPackArray;
	
	//Setup
	[emoticons	removeAllObjects];
	emoticonPackArray = [[NSMutableArray alloc] init];
	
	[self allEmoticonPacks:emoticonPackArray];
	
	//Load the appropriate emoticons from the appropriate paths
	//(Right now, just load everything from the first pack)
	if ([emoticonPackArray count] < 1)
		foundGoodPack = FALSE;
	
	if (foundGoodPack) {
		int o;
		for (o = 0; o < [emoticonPackArray count]; o++) {
			NSDictionary*	smileyPack = [emoticonPackArray objectAtIndex:o];
			NSArray*		smileyList = [smileyPack objectForKey:KEY_EMOTICON_PACK_CONTENTS];
			
			//NSString*		packKey = [NSString stringWithFormat:@"%@_pack_%@", [smileyPack objectForKey:KEY_EMOTICON_PACK_SOURCE], [smileyPack objectForKey:KEY_EMOTICON_PACK_TITLE]];
			NSDictionary*	prefDict = [smileyPack objectForKey:KEY_EMOTICON_PACK_PREFS];//[[owner preferenceController] preferenceForKey:packKey group:PREF_GROUP_EMOTICONS object:nil];
			
			if (/*o == 0*/[[prefDict	objectForKey:@"inUse"] intValue] && prefDict) {
				int				i;
				AIEmoticon		*emo = nil;
				NSMutableString*	emoText = nil;
				NSRange			charRange;
				NSCharacterSet*	newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
				//NSArray*		fakeSeparation = nil;
				
						
				for (i = 0;	i < [smileyList count]; i++)
				{
					path = [smileyList objectAtIndex:i];
					
					emoText = [NSMutableString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"TextEquivalents.txt"]];
					
					// Check string for UNIX or Windows line end encoding, repairing if needed.
					charRange = [emoText rangeOfCharacterFromSet:newlineSet];
					while (charRange.length != 0)	{
						[emoText replaceCharactersInRange:charRange withString:@"\r"];
						charRange = [emoText rangeOfCharacterFromSet:newlineSet];
					}
					
					// Make the emoticon object, add it to the master list
					emo = [[AIEmoticon alloc] initWithPath:[path stringByAppendingPathComponent:@"Emoticon.tiff"] andText:emoText];
					[emoticons addObject:emo];
				}
			}
		}
	}
	
	[emoticonPackArray release];
	
	if (!foundGoodPack)
		[self setupForTesting];	// use the bundled graphics if not emoticon pack could be found

	
    [self updateQuickScanList];
	
	return foundGoodPack;
}

- (BOOL)_scanEmoticonPacksFromPath:(NSString *)emoticonFolderPath intoArray:(NSMutableArray *)emoticonPackArray tagKey:(NSString *)source
{
    NSDirectoryEnumerator	*enumerator;			//Emoticon folder directory enumerator
    NSString			*file;				//Current Path (relative to Emoticon folder)
    NSString			*emoticonSetPath;			//Name of the set
    //NSMutableArray		*soundSetContents;		//Array of sounds in the set
	BOOL				foundGoodPack = FALSE;

    //Start things off with a valid set path and contents, incase any sounds aren't in subfolders
    emoticonSetPath = emoticonFolderPath;
    //soundSetContents = [[[NSMutableArray alloc] init] autorelease];

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:emoticonFolderPath];
    while((file = [enumerator nextObject])){
        BOOL			isDirectory;
        NSString		*fullPath = nil,	*title = nil;

        if([[file lastPathComponent] characterAtIndex:0] != '.' &&
           [[file pathExtension] caseInsensitiveCompare:EMOTICON_PACK_PATH_EXTENSION] == 0 /*&&
           ![[file pathComponents] containsObject:@"CVS"]*/){ //Ignore certain files

            //Determine if this is a file or a directory
            fullPath = [emoticonFolderPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];

            if(isDirectory){
				// Load the emoticonPack	//
				NSMutableArray	*heldEmoticons = [[[NSMutableArray alloc] init] autorelease];
				NSMutableDictionary	*prefDict = nil;
				
				title = [file stringByDeletingPathExtension];
			
				[self _scanEmoticonsFromPath:fullPath intoArray:heldEmoticons];
				
				// Get pref dictionary
				NSString*		packKey = [NSString stringWithFormat:@"%@_pack_%@", source, title];
				prefDict =	[[owner preferenceController] preferenceForKey:packKey group:PREF_GROUP_EMOTICONS object:nil];
				
				if (prefDict == nil)
				{	// Make pref dictionary
					prefDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:NSOffState], @"inUse", nil];
					[[owner preferenceController] setPreference:prefDict forKey:packKey group:PREF_GROUP_EMOTICONS];
				}

				[emoticonPackArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:title,  KEY_EMOTICON_PACK_TITLE, fullPath, KEY_EMOTICON_PACK_PATH, [NSArray arrayWithArray:heldEmoticons], KEY_EMOTICON_PACK_CONTENTS, source, KEY_EMOTICON_PACK_SOURCE, prefDict, KEY_EMOTICON_PACK_PREFS, nil]];
				
				if ([heldEmoticons count] > 0)	foundGoodPack = TRUE;
				
            }else{
                NSLog (@"File \"EmoticonPack\" found.  Valid EmoticonPacks are directories.");
            }
        }
    }

    //Close the last soundset, adding it to our sound set array
    //[self _addSet:soundSetPath withSounds:soundSetContents toArray:soundSetArray];   
	
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

- (void)setupForTesting
{
    AIEmoticon	*emo = nil;
    NSString	*defaultPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingFormat:@"/Contents/Resources%@",PATH_EMOTICONS];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley00.png"] andText:@"O:-)\rO:)\rO=)\ro:-)\ro:)\ro=)"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley01.png"] andText:@":-)\r:)\r=)\r:o)"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley02.png"] andText:@":-(\r:(\r=(("];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley03.png"] andText:@";-)\r;)"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley04.png"] andText:@":-P\r:P\r=P\r:-p\r:p\r=p"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley07.png"] andText:@">:o\r>=o"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley05.png"] andText:@"=-o\r=-O\r:-o\r:o\r=o"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley06.png"] andText:@":-*\r:*\r=*"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley08.png"] andText:@":-D\r:D\r=D"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley09.png"] andText:@":-$\r:$"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley10.png"] andText:@":-!\r:!"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley11.png"] andText:@":-[\r:[\r=["];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley12.png"] andText:@":-\\\r:\\\r=\\\r:-/\r=/\r:/"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley13.png"] andText:@":'(\r='("];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley14.png"] andText:@":-x\r:x\r=x\r:-X\r:X\r=X"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley15.png"] andText:@"8-)\r8)"];
    [emoticons addObject:emo];
}

@end
