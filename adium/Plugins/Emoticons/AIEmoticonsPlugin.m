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

#define EMOTICON_DEFAULT_PREFS			@"EmoticonDefaults"
#define PATH_EMOTICONS				@"/Emoticons"
#define PATH_INTERNAL_EMOTICONS			@"/Contents/Resources/Emoticons/"
#define EMOTICON_PACK_PATH_EXTENSION		@"emoticonPack"
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"

@interface AIEmoticonsPlugin (PRIVATE)
- (NSDictionary *)emoticonIndex;
- (NSCharacterSet *)emoticonHintCharacterSet;
- (NSCharacterSet *)emoticonStartCharacterSet;
- (void)resetActiveEmoticons;
- (void)resetAvailableEmoticons;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSArray *)_emoticonsPacksAvailableAtPath:(NSString *)inPath;
- (NSMutableAttributedString *)_convertEmoticonsInMessage:(NSAttributedString *)inMessage;
- (void)_buildCharacterSetsAndIndexEmoticons;
- (void)_saveActiveEmoticonPacks;
@end

@implementation AIEmoticonsPlugin

//
- (void)installPlugin
{
    //Init    
    observingContent = NO;
    _availableEmoticonPacks = nil;
    _activeEmoticonPacks = nil;
    _activeEmoticons = nil;
    _emoticonHintCharacterSet = nil;
    _emoticonStartCharacterSet = nil;
    _emoticonIndexDict = nil;

    //Create the custom emoticons directory
    [AIFileUtilities createDirectory:[[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:PATH_EMOTICONS]];
    
    //Setup Preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:@"EmoticonDefaults" forClass:[self class]] forGroup:PREF_GROUP_EMOTICONS];
    prefs = [[AIEmoticonPreferences preferencePaneForPlugin:self] retain];

    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_EMOTICONS] == 0){
        //Flush our cached active emoticons
        [self resetActiveEmoticons];
        
        //Enable/Disable logging
        BOOL    emoticonsEnabled = ([[self activeEmoticons] count] != 0);
        if(observingContent != emoticonsEnabled){
            if(emoticonsEnabled){
                [[adium contentController] registerDisplayingContentFilter:self];
            }else{
                [[adium contentController] unregisterDisplayingContentFilter:self];
            }
            observingContent = emoticonsEnabled;
        }
    }
}

//Returns all active emoticons, categoriezed by starting character, using a dictionary, with each value containing an array of characters
- (NSDictionary *)emoticonIndex
{
    if(!_emoticonIndexDict) [self _buildCharacterSetsAndIndexEmoticons];
    return(_emoticonIndexDict);
}

//Returns a characterset containing characters that hint at the presence of an emoticon
- (NSCharacterSet *)emoticonHintCharacterSet
{
    if(!_emoticonHintCharacterSet) [self _buildCharacterSetsAndIndexEmoticons];
    return(_emoticonHintCharacterSet);
}

//Returns a characterset containing all the characters that may start an emoticon
- (NSCharacterSet *)emoticonStartCharacterSet
{
    if(!_emoticonStartCharacterSet) [self _buildCharacterSetsAndIndexEmoticons];
    return(_emoticonStartCharacterSet);
}

//For optimization, we build a list of characters that could possibly be an emoticon and will require additional scanning.
//We also build a dictionary categorizing the emoticons by their first character to quicken lookups.
- (void)_buildCharacterSetsAndIndexEmoticons
{
    NSEnumerator        *emoticonEnumerator;
    AIEmoticon          *emoticon;
    
    //Start with a fresh character set, and a fresh index
    [_emoticonHintCharacterSet release]; _emoticonHintCharacterSet = [[NSMutableCharacterSet alloc] init];
    [_emoticonStartCharacterSet release]; _emoticonStartCharacterSet = [[NSMutableCharacterSet alloc] init];
    [_emoticonIndexDict release]; _emoticonIndexDict = [[NSMutableDictionary alloc] init];
    
    //Process all the text equivalents of each active emoticon
    emoticonEnumerator = [[self activeEmoticons] objectEnumerator];
    while(emoticon = [emoticonEnumerator nextObject]){
        if([emoticon isEnabled]){
            NSEnumerator        *textEnumerator;
            NSString            *text;

            textEnumerator = [[emoticon textEquivalents] objectEnumerator];
            while(text = [textEnumerator nextObject]){
                NSMutableArray  *subIndex;
                unichar         firstCharacter;
                NSString        *firstCharacterString;
                
                if([text length] != 0){ //Invalid emoticon files may let empty text equivalents sneak in
                    firstCharacter = [text characterAtIndex:0];
                    firstCharacterString = [NSString stringWithFormat:@"%C",firstCharacter];
                    
                    // -- Emoticon Hint Character Set --
                    //If any letter in this text equivalent already exists in the quick scan character set, we can skip it
                    if([text rangeOfCharacterFromSet:_emoticonHintCharacterSet].location == NSNotFound){
                        //Potential for optimization!: Favor punctuation characters ( :();- ) over letters (especially vowels).                
                        [_emoticonHintCharacterSet addCharactersInString:firstCharacterString];
                    }
                    
                    // -- Emoticon Start Character Set --
                    //First letter of this emoticon goes in the start set
                    if(![_emoticonStartCharacterSet characterIsMember:firstCharacter]){
                        [_emoticonStartCharacterSet addCharactersInString:firstCharacterString];
                    }
                    
                    // -- Index --
                    //Get the index according to this emoticon's first character
                    if(!(subIndex = [_emoticonIndexDict objectForKey:firstCharacterString])){
                        subIndex = [[NSMutableArray alloc] init];
                        [_emoticonIndexDict setObject:subIndex forKey:firstCharacterString];
                        [subIndex release];
                    }
                    
                    //Place the emoticon into that index (If it isn't already in there)
                    if(![subIndex containsObject:emoticon]){
                        [subIndex addObject:emoticon];
                    }
                }
            }
            
        }
    }
}

//Filter a content object before display, inserting graphical emoticons
- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIContentMessage    *contentMessage = (AIContentMessage *)inObject;
        NSString            *messageString = [[[contentMessage message] safeString] string];

        //First, we do a quick scan of the message for any characters that might end up being emoticons
        //This avoids having to do the slower, more complicated scan for the majority of messages.
        if([messageString rangeOfCharacterFromSet:[self emoticonHintCharacterSet]].location != NSNotFound){
            NSAttributedString      *replacementMessage; 
            
            //If an emoticon character was found, we do a more thorough scan
            if(replacementMessage = [self _convertEmoticonsInMessage:[contentMessage message]]){
                [contentMessage setMessage:replacementMessage];
            }
            
        }
    }
}

//Insert graphical emoticons into a string
- (NSMutableAttributedString *)_convertEmoticonsInMessage:(NSAttributedString *)inMessage
{
    NSCharacterSet              *emoticonStartCharacterSet = [self emoticonStartCharacterSet];
    NSDictionary                *emoticonIndex = [self emoticonIndex];
    NSString                    *messageString = [inMessage string];   
    NSMutableAttributedString   *newMessage = nil; //We avoid creating a new string unless necessary
    int                         currentLocation = 0;
    int                         replacementCount = 0; //Number of characters we've replaced so far (used to calcluate placement in the destination string)

    while(currentLocation != NSNotFound && currentLocation < [messageString length]){
        //Find the next occurence of a suspected emoticon
        currentLocation = [messageString rangeOfCharacterFromSet:emoticonStartCharacterSet options:0 range:NSMakeRange(currentLocation, [messageString length] - currentLocation)].location;
        if(currentLocation != NSNotFound){
            unichar         currentCharacter = [messageString characterAtIndex:currentLocation];
            NSString        *currentCharacterString = [NSString stringWithFormat:@"%C", currentCharacter];
            NSEnumerator    *emoticonEnumerator;
            AIEmoticon      *emoticon;        

            //Check for the presence of all emoticons starting with this character
            emoticonEnumerator = [[emoticonIndex objectForKey:currentCharacterString] objectEnumerator];
            while(emoticon = [emoticonEnumerator nextObject]){
                NSEnumerator        *textEnumerator;
                NSString            *text;
                
                textEnumerator = [[emoticon textEquivalents] objectEnumerator];
                while(text = [textEnumerator nextObject]){
                    int     textLength = [text length];

                    if(textLength != 0){ //Invalid emoticon files may let empty text equivalents sneak in
                        //If there is not enough room in the string for this text, we can skip it
                        if(currentLocation + [text length] <= [messageString length]){
                            if([messageString compare:text options:0 range:NSMakeRange(currentLocation, textLength)] == 0){
                                //Ignore emoticons within links
                                if([inMessage attribute:NSLinkAttributeName atIndex:currentLocation effectiveRange:nil] == nil){
                                    NSMutableAttributedString   *replacement = [emoticon attributedStringWithTextEquivalent:text];
                                    
                                    //grab the original attributes, to ensure that the background is not lost in a message consisting only of an emoticon
                                    [replacement addAttributes:[inMessage attributesAtIndex:currentLocation effectiveRange:nil] range:NSMakeRange(0,1)];
                                    
                                    //insert the emoticon
                                    if(!newMessage) newMessage = [[inMessage mutableCopy] autorelease];
                                    [newMessage replaceCharactersInRange:NSMakeRange(currentLocation - replacementCount, textLength) withAttributedString:replacement];
                                    
                                    //Update where we are in the original and replacement messages
                                    replacementCount += textLength-1;
                                    currentLocation += textLength-1;
        
                                    //Invalidate the enumerators to stop scanning prematurely
                                    textEnumerator = nil; emoticonEnumerator = nil;
                                }
                            }
                        }
                    }
                    
                }
            }
            
        }
        
        //Move to the next possible location of an emoticon
        currentLocation++;
    }
    
    return(newMessage ? newMessage : inMessage);
}

//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    
    //Flag our emoticons as enabled/disabled
    enumerator = [[self availableEmoticonPacks] objectEnumerator];
    while(pack = [enumerator nextObject]){
        [pack flushEmoticonImageCache];
    }
}

//Reset the active emoticons cache
- (void)resetActiveEmoticons
{
    [_activeEmoticonPacks release]; _activeEmoticonPacks = nil;
    
    //Let the contentController know about the lack of active emoticons
    [[adium contentController] setEmoticonsArray:nil];
    [_activeEmoticons release]; _activeEmoticons = nil;
    
    [_emoticonHintCharacterSet release]; _emoticonHintCharacterSet = nil;
    [_emoticonStartCharacterSet release]; _emoticonStartCharacterSet = nil;
    [_emoticonIndexDict release]; _emoticonIndexDict = nil;
}

//Reset the available emoticons cache
- (void)resetAvailableEmoticons
{
    [_availableEmoticonPacks release]; _availableEmoticonPacks = nil;
    [self resetActiveEmoticons];
}

//Returns an array of the currently active emoticons
- (NSArray *)activeEmoticons
{
    if(!_activeEmoticons){
        NSEnumerator    *enumerator;
        AIEmoticonPack  *emoticonPack;
        
        //
        _activeEmoticons = [[NSMutableArray alloc] init];

        //Grap the emoticons from each active pack
        enumerator = [[self activeEmoticonPacks] objectEnumerator];
        while(emoticonPack = [enumerator nextObject]){
            [_activeEmoticons addObjectsFromArray:[emoticonPack emoticons]];
        }
        
        //Let the contentController know about the active emoticons
        [[adium contentController] setEmoticonsArray:_activeEmoticons];
    }

    //
    return(_activeEmoticons);
}

//Re-arrange an emoticon pack
- (void)moveActiveEmoticonPacks:(NSArray *)inPacks toIndex:(int)index
{    
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    
    //Remove each pack
    enumerator = [inPacks objectEnumerator];
    while(pack = [enumerator nextObject]){
        if([_activeEmoticonPacks indexOfObject:pack] < index) index--;
        [_activeEmoticonPacks removeObject:pack];
    }

    //Add back the packs in their new location
    [self addActiveEmoticonPacks:inPacks toIndex:index];
}

//Remove a set of emoticon packs
- (void)removeActiveEmoticonPacks:(NSArray *)inPacks
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    
    //Remove all the packs
    enumerator = [inPacks objectEnumerator];
    while(pack = [enumerator nextObject]){
        [_activeEmoticonPacks removeObject:pack];
    }

    //Save
    [self _saveActiveEmoticonPacks];
}

//
- (void)addActiveEmoticonPacks:(NSArray *)inPacks toIndex:(int)index
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;

    //Add back the packs in their new location
    enumerator = [inPacks objectEnumerator];
    while(pack = [enumerator nextObject]){
        [_activeEmoticonPacks insertObject:pack atIndex:index];
        index++;
    }

    //Save
    [self _saveActiveEmoticonPacks];
}

//Save the active emoticon packs to preferences
- (void)_saveActiveEmoticonPacks
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    NSMutableArray  *nameArray = [NSMutableArray array];
    
    enumerator = [[self activeEmoticonPacks] objectEnumerator];
    while(pack = [enumerator nextObject]){
        [nameArray addObject:[pack name]];
    }
    
    [[adium preferenceController] setPreference:nameArray forKey:KEY_EMOTICON_ACTIVE_PACKS group:PREF_GROUP_EMOTICONS];
}

//Enabled or disable a specific emoticon
- (void)setEmoticon:(AIEmoticon *)inEmoticon inPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled
{
    NSDictionary            *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_EMOTICONS];
    NSString                *packKey = [NSString stringWithFormat:@"Pack:%@",[inPack name]];
    NSMutableDictionary     *packDict = [[[preferenceDict objectForKey:packKey] mutableCopy] autorelease];
    NSMutableArray          *disabledArray = [[[packDict objectForKey:KEY_EMOTICON_DISABLED] mutableCopy] autorelease];

    if(!packDict) packDict = [NSMutableDictionary dictionary];
    if(!disabledArray) disabledArray = [NSMutableArray array];
    
    //Enable/Disable the emoticon
    if(enabled){
        [disabledArray removeObject:[inEmoticon name]];
    }else{
        [disabledArray addObject:[inEmoticon name]];
    }
    
    //Update the pack (This should really be done from the prefs changed method, but it works here as well)
    [inPack setDisabledEmoticons:disabledArray];
    
    //Save changes
    [packDict setObject:disabledArray forKey:KEY_EMOTICON_DISABLED];
    [[adium preferenceController] setPreference:packDict forKey:packKey group:PREF_GROUP_EMOTICONS];
}

//Returns the disabled emoticons in a pack
- (NSArray *)disabledEmoticonsInPack:(AIEmoticonPack *)inPack
{
    NSDictionary    *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_EMOTICONS];
    NSDictionary    *packDict = [preferenceDict objectForKey:[NSString stringWithFormat:@"Pack:%@",[inPack name]]];
    
    return([packDict objectForKey:KEY_EMOTICON_DISABLED]);
}

//Returns an array of the currently active emoticon packs
- (NSArray *)activeEmoticonPacks
{
    if(!_activeEmoticonPacks){
        NSArray         *activePackNames;
        NSEnumerator    *enumerator;
        NSString        *packName;
        
        //
        _activeEmoticonPacks = [[NSMutableArray alloc] init];
        
        //Get the names of our active packs
        activePackNames = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_EMOTICONS] objectForKey:KEY_EMOTICON_ACTIVE_PACKS];
        
        //Use the names to build an array of the desired emoticon packs
        enumerator = [activePackNames objectEnumerator];
        while(packName = [enumerator nextObject]){
            AIEmoticonPack  *emoticonPack = [self emoticonPackWithName:packName];
            
            if(emoticonPack){
                [_activeEmoticonPacks addObject:emoticonPack];
            }
        }
    }

    //
    return(_activeEmoticonPacks);
}

//Returns the emoticon pack by name
- (AIEmoticonPack *)emoticonPackWithName:(NSString *)inName
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *emoticonPack;

    enumerator = [[self availableEmoticonPacks] objectEnumerator];
    while(emoticonPack = [enumerator nextObject]){
        if([[emoticonPack name] compare:inName] == 0) return(emoticonPack);
    }

    return(nil);
}

//Returns an array of the available emoticon packs
- (NSArray *)availableEmoticonPacks
{
    if(!_availableEmoticonPacks){
        NSString	*path;

        _availableEmoticonPacks = [[NSMutableArray alloc] init];
        
        //Load internal packs
        path = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_EMOTICONS] stringByExpandingTildeInPath];
        [_availableEmoticonPacks addObjectsFromArray:[self _emoticonsPacksAvailableAtPath:path]];
        
        //Load user packs
        path = [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:PATH_EMOTICONS] stringByExpandingTildeInPath];
        [_availableEmoticonPacks addObjectsFromArray:[self _emoticonsPacksAvailableAtPath:path]];

    }
    
    return(_availableEmoticonPacks);
}

//Returns an array of the emoticon packs at the specified path
- (NSArray *)_emoticonsPacksAvailableAtPath:(NSString *)inPath
{
    NSMutableArray          *emoticonPackArray = [NSMutableArray array];
    NSDirectoryEnumerator   *enumerator;
    NSString                *file;

    //Scan the directory
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:inPath];
    while((file = [enumerator nextObject])){        
        if([[file lastPathComponent] characterAtIndex:0] != '.' &&                              //Ignore invisible files
           [[file pathExtension] caseInsensitiveCompare:EMOTICON_PACK_PATH_EXTENSION] == 0){    //Only accept emoticon packs
            NSString        *fullPath = [inPath stringByAppendingPathComponent:file];
            BOOL            isDirectory;
            
            //Ensure that this is a folder
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
            if(isDirectory){
                AIEmoticonPack  *pack = [AIEmoticonPack emoticonPackFromPath:fullPath];
                
                [emoticonPackArray addObject:pack];
                [pack setDisabledEmoticons:[self disabledEmoticonsInPack:pack]];
            }
        }
    }
    
    return(emoticonPackArray);
}

@end
