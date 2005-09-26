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

#import "AIEmoticonController.h"
#warning crosslinking, move emoticon stuff to framework i guess
#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPreferences.h"
#import "AIContentObject.h"
#import "AIContentMessage.h"
#import "AIAccountController.h"
#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "AIAccount.h"
#import "AIListObject.h"
#import "AIListContact.h"
#import "AIService.h"
#import <AIUtilities/AIDictionaryAdditions.h>

#define EMOTICON_DEFAULT_PREFS				@"EmoticonDefaults"
#define PATH_EMOTICONS						@"/Emoticons"
#define PATH_INTERNAL_EMOTICONS				@"/Contents/Resources/Emoticons/"
#define EMOTICONS_PATH_NAME					@"Emoticons"

#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"

//We support loading .AdiumEmoticonset, .emoticonPack, and .emoticons
#define ADIUM_EMOTICON_SET_PATH_EXTENSION   @"AdiumEmoticonset"
#define EMOTICON_PACK_PATH_EXTENSION		@"emoticonPack"
#define PROTEUS_EMOTICON_SET_PATH_EXTENSION @"emoticons"

@interface AIEmoticonController (PRIVATE)
- (NSDictionary *)emoticonIndex;
- (NSCharacterSet *)emoticonHintCharacterSet;
- (NSCharacterSet *)emoticonStartCharacterSet;
- (void)resetActiveEmoticons;
- (void)resetAvailableEmoticons;
- (NSArray *)_emoticonsPacksAvailableAtPath:(NSString *)inPath;
- (NSMutableAttributedString *)_convertEmoticonsInMessage:(NSAttributedString *)inMessage context:(id)context;
- (AIEmoticon *) _bestReplacementFromEmoticons:(NSArray *)candidateEmoticons
							   withEquivalents:(NSArray *)candidateEmoticonTextEquivalents
									   context:(NSString *)serviceClassContext
									equivalent:(NSString **)replacementString
							  equivalentLength:(int *)textLength;
- (void)_buildCharacterSetsAndIndexEmoticons;
- (void)_saveActiveEmoticonPacks;
- (void)_saveEmoticonPackOrdering;
- (NSString *)_keyForPack:(AIEmoticonPack *)inPack;
- (void)_sortArrayOfEmoticonPacks:(NSMutableArray *)packArray;
@end

int packSortFunction(id packA, id packB, void *packOrderingArray);

@implementation AIEmoticonController

#define EMOTICONS_THEMABLE_PREFS      @"Emoticon Themable Prefs"

//init
- (id)init
{
	if ((self = [super init])) {
		observingContent = NO;
		_availableEmoticonPacks = nil;
		_activeEmoticonPacks = nil;
		_activeEmoticons = nil;
		_emoticonHintCharacterSet = nil;
		_emoticonStartCharacterSet = nil;
		_emoticonIndexDict = nil;
	}
	
	return self;
}

- (void)controllerDidLoad
{
    //Create the custom emoticons directory
    [adium createResourcePathForName:EMOTICONS_PATH_NAME];
    
    //Setup Preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:@"EmoticonDefaults" 
																		forClass:[self class]]
										  forGroup:PREF_GROUP_EMOTICONS];
    
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
	
	//Observe for installation of new emoticon sets
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
}

- (void)controllerWillClose
{
//	[[adium contentController] unregisterOutgoingContentFilter:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Flush our cached active emoticons
	[self resetActiveEmoticons];
	
	//Enable/Disable logging
	BOOL    emoticonsEnabled = ([[self activeEmoticons] count] != 0);
	if (observingContent != emoticonsEnabled) {
		if (emoticonsEnabled) {
			[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
			[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterOutgoing];
			[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
			[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
		} else {
			[[adium contentController] unregisterContentFilter:self];
		}
		observingContent = emoticonsEnabled;
	}
}


//Content filter -------------------------------------------------------------------------------------------------------
#pragma mark Content filter
//Filter a content object before display, inserting graphical emoticons
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *replacementMessage = nil;
    if (inAttributedString) {
        //First, we do a quick scan of the message for any characters that might end up being emoticons
        //This avoids having to do the slower, more complicated scan for the majority of messages.
        if ([[inAttributedString string] rangeOfCharacterFromSet:[self emoticonHintCharacterSet]].location != NSNotFound) {
            //If an emoticon character was found, we do a more thorough scan
            replacementMessage = [self _convertEmoticonsInMessage:inAttributedString context:context];
        }
    }
    return (replacementMessage ? replacementMessage : inAttributedString);
}

//Do emoticons after the default filters
- (float)filterPriority
{
	return LOW_FILTER_PRIORITY;
}

//Insert graphical emoticons into a string
- (NSMutableAttributedString *)_convertEmoticonsInMessage:(NSAttributedString *)inMessage context:(id)context
{
    NSCharacterSet              *emoticonStartCharacterSet = [self emoticonStartCharacterSet];
    NSDictionary                *emoticonIndex = [self emoticonIndex];
    NSString                    *messageString = [inMessage string];
    NSMutableAttributedString   *newMessage = nil; //We avoid creating a new string unless necessary
	NSString					*serviceClassContext = nil;
    unsigned					currentLocation = 0, messageStringLength;
	
	//Determine our service class context
	if ([context isKindOfClass:[AIContentObject class]]) {
		serviceClassContext = [[[(AIContentObject *)context destination] service] serviceClass];
		//If there's no destination, try to use the source for context
		if (!serviceClassContext) {
			serviceClassContext = [[[(AIContentObject *)context source] service] serviceClass];
		}			
	} else if ([context isKindOfClass:[AIListContact class]]) {
		serviceClassContext = [[[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																					   toContact:(AIListContact *)context] service] serviceClass];
	} else if ([context isKindOfClass:[AIListObject class]] && [context respondsToSelector:@selector(service)]) {
		serviceClassContext = [[(AIListObject *)context service] serviceClass];
	}
	
    //Number of characters we've replaced so far (used to calcluate placement in the destination string)
	int                         replacementCount = 0; 

	messageStringLength = [messageString length];
    while (currentLocation != NSNotFound && currentLocation < messageStringLength) {
        //Find the next occurence of a suspected emoticon
        currentLocation = [messageString rangeOfCharacterFromSet:emoticonStartCharacterSet
                                                         options:0 
                                                           range:NSMakeRange(currentLocation, 
																			 messageStringLength - currentLocation)].location;
		
		//Use paired arrays so multiple emoticons can qualify for the same text equivalent
        NSMutableArray  *candidateEmoticons = nil;
		NSMutableArray  *candidateEmoticonTextEquivalents = nil;
		
        if (currentLocation != NSNotFound) {
            unichar         currentCharacter = [messageString characterAtIndex:currentLocation];
            NSString        *currentCharacterString = [NSString stringWithFormat:@"%C", currentCharacter];
            NSEnumerator    *emoticonEnumerator;
            AIEmoticon      *emoticon;     

            //Check for the presence of all emoticons starting with this character
            emoticonEnumerator = [[emoticonIndex objectForKey:currentCharacterString] objectEnumerator];
            while ((emoticon = [emoticonEnumerator nextObject])) {
                NSEnumerator        *textEnumerator;
                NSString            *text;
                
                textEnumerator = [[emoticon textEquivalents] objectEnumerator];
                while ((text = [textEnumerator nextObject])) {
                    int     textLength = [text length];

                    if (textLength != 0) { //Invalid emoticon files may let empty text equivalents sneak in
                        //If there is not enough room in the string for this text, we can skip it
                        if (currentLocation + textLength <= messageStringLength) {
                            if ([messageString compare:text options:0 range:NSMakeRange(currentLocation, textLength)] == NSOrderedSame) {
                                //Ignore emoticons within links
                                if ([inMessage attribute:NSLinkAttributeName atIndex:currentLocation effectiveRange:nil] == nil) {
									if (!candidateEmoticons) {
										candidateEmoticons = [[NSMutableArray alloc] init];
										candidateEmoticonTextEquivalents = [[NSMutableArray alloc] init];
									}
									
									[candidateEmoticons addObject:emoticon];
									[candidateEmoticonTextEquivalents addObject:text];
                                }
                            }
                        }
                    }
                }
            }
			
            if ([candidateEmoticons count]) {
                NSString					*replacementString;
                AIEmoticon					*emoticon;
                NSMutableAttributedString   *replacement;
                int							textLength;
				
				//Use the most appropriate, longest string of those which could be used for the emoticon text we found here
				emoticon = [self _bestReplacementFromEmoticons:candidateEmoticons
											   withEquivalents:candidateEmoticonTextEquivalents
													   context:serviceClassContext
													equivalent:&replacementString
											  equivalentLength:&textLength];
				replacement = [emoticon attributedStringWithTextEquivalent:replacementString];
                                    
                //grab the original attributes, to ensure that the background is not lost in a message consisting only of an emoticon
                [replacement addAttributes:[inMessage attributesAtIndex:currentLocation 
                                                         effectiveRange:nil] 
                                                                  range:NSMakeRange(0,1)];
                                    
                //insert the emoticon
                if (!newMessage) newMessage = [inMessage mutableCopy];
				[newMessage replaceCharactersInRange:NSMakeRange(currentLocation - replacementCount, textLength)
                                withAttributedString:replacement];
                //Update where we are in the original and replacement messages
                replacementCount += textLength-1;
                currentLocation += textLength-1;
        
                //Invalidate the enumerators to stop scanning prematurely
                //textEnumerator = nil; emoticonEnumerator = nil;
            }
        
			//Move to the next possible location of an emoticon
			currentLocation++;
        }

		[candidateEmoticons release];
		[candidateEmoticonTextEquivalents release];
    }

    return newMessage ? [newMessage autorelease] : inMessage;
}

- (AIEmoticon *) _bestReplacementFromEmoticons:(NSArray *)candidateEmoticons
							   withEquivalents:(NSArray *)candidateEmoticonTextEquivalents
									   context:(NSString *)serviceClassContext
									equivalent:(NSString **)replacementString
							  equivalentLength:(int *)textLength
{
	unsigned	i = 0;
	unsigned	bestIndex = 0, bestLength = 0;
	unsigned	bestServiceAppropriateIndex = 0, bestServiceAppropriateLength = 0;
	NSString	*serviceAppropriateReplacementString = nil;
	unsigned	count;
	
	count = [candidateEmoticonTextEquivalents count];
	while (i < count) {
		NSString	*thisString = [candidateEmoticonTextEquivalents objectAtIndex:i];
		unsigned thisLength = [thisString length];
		if (thisLength > bestLength) {
			bestLength = thisLength;
			bestIndex = i;
			*replacementString = thisString;
		}

		//If we are using service appropriate emoticons, check if this is on the right service and, if so, compare.
		if (thisLength > bestServiceAppropriateLength) {
			AIEmoticon	*thisEmoticon = [candidateEmoticons objectAtIndex:i];
			if ([thisEmoticon isAppropriateForServiceClass:serviceClassContext]) {
				bestServiceAppropriateLength = thisLength;
				bestServiceAppropriateIndex = i;
				serviceAppropriateReplacementString = thisString;
			}
		}
		
		i++;
	}

	/* Did we get a service appropriate replacement? If so, use that rather than the current replacementString if it
	 * differs. */
	if (serviceAppropriateReplacementString && (serviceAppropriateReplacementString != *replacementString)) {
		bestLength = bestServiceAppropriateLength;
		bestIndex = bestServiceAppropriateIndex;
		*replacementString = serviceAppropriateReplacementString;
	}

	//Return the length by reference
	*textLength = bestLength;

	//Return the AIEmoticon we found to be best
    return [candidateEmoticons objectAtIndex:bestIndex];
}

//Active emoticons -----------------------------------------------------------------------------------------------------
#pragma mark Active emoticons
//Returns an array of the currently active emoticons
- (NSArray *)activeEmoticons
{
    if (!_activeEmoticons) {
        NSEnumerator    *enumerator;
        AIEmoticonPack  *emoticonPack;
        
        //
        _activeEmoticons = [[NSMutableArray alloc] init];
		
        //Grap the emoticons from each active pack
        enumerator = [[self activeEmoticonPacks] objectEnumerator];
        while ((emoticonPack = [enumerator nextObject])) {
            [_activeEmoticons addObjectsFromArray:[emoticonPack emoticons]];
        }
    }
	
    //
    return _activeEmoticons;
}

//Returns all active emoticons, categoriezed by starting character, using a dictionary, with each value containing an array of characters
- (NSDictionary *)emoticonIndex
{
    if (!_emoticonIndexDict) [self _buildCharacterSetsAndIndexEmoticons];
    return _emoticonIndexDict;
}


//Disabled emoticons ---------------------------------------------------------------------------------------------------
#pragma mark Disabled emoticons
//Enabled or disable a specific emoticon
- (void)setEmoticon:(AIEmoticon *)inEmoticon inPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled
{
    NSString                *packKey = [self _keyForPack:inPack];
    NSMutableDictionary     *packDict = [[[adium preferenceController] preferenceForKey:packKey
																				  group:PREF_GROUP_EMOTICONS] mutableCopy];
    NSMutableArray          *disabledArray = [[packDict objectForKey:KEY_EMOTICON_DISABLED] mutableCopy];
	
    if (!packDict) packDict = [[NSMutableDictionary alloc] init];
    if (!disabledArray) disabledArray = [[NSMutableArray alloc] init];
    
    //Enable/Disable the emoticon
    if (enabled) {
        [disabledArray removeObject:[inEmoticon name]];
    } else {
        [disabledArray addObject:[inEmoticon name]];
    }
    
    //Update the pack (This should really be done from the prefs changed method, but it works here as well)
    [inPack setDisabledEmoticons:disabledArray];
    
    //Save changes
    [packDict setObject:disabledArray forKey:KEY_EMOTICON_DISABLED];
	[disabledArray release];

    [[adium preferenceController] setPreference:packDict forKey:packKey group:PREF_GROUP_EMOTICONS];
	[packDict release];
}

//Returns the disabled emoticons in a pack
- (NSArray *)disabledEmoticonsInPack:(AIEmoticonPack *)inPack
{
    NSDictionary    *packDict = [[adium preferenceController] preferenceForKey:[self _keyForPack:inPack]
																		 group:PREF_GROUP_EMOTICONS];
    
    return [packDict objectForKey:KEY_EMOTICON_DISABLED];
}


//Active emoticon packs ------------------------------------------------------------------------------------------------
#pragma mark Active emoticon packs
//Returns an array of the currently active emoticon packs
- (NSArray *)activeEmoticonPacks
{
    if (!_activeEmoticonPacks) {
        NSArray         *activePackNames;
        NSEnumerator    *enumerator;
        NSString        *packName;
        
        //
        _activeEmoticonPacks = [[NSMutableArray alloc] init];
        
        //Get the names of our active packs
        activePackNames = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_EMOTICONS] objectForKey:KEY_EMOTICON_ACTIVE_PACKS];
        //Use the names to build an array of the desired emoticon packs
        enumerator = [activePackNames objectEnumerator];
        while ((packName = [enumerator nextObject])) {
            AIEmoticonPack  *emoticonPack = [self emoticonPackWithName:packName];
            
            if (emoticonPack) {
                [_activeEmoticonPacks addObject:emoticonPack];
				[emoticonPack setIsEnabled:YES];
            }
        }
		
		//Sort as per the saved ordering
		[self _sortArrayOfEmoticonPacks:_activeEmoticonPacks];
    }

    return _activeEmoticonPacks;
}

- (void)setEmoticonPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled
{
	if (enabled) {
		[_activeEmoticonPacks addObject:inPack];	
		[inPack setIsEnabled:YES];
		
		//Sort the active emoticon packs as per the saved ordering
		[self _sortArrayOfEmoticonPacks:_activeEmoticonPacks];
	} else {
		[_activeEmoticonPacks removeObject:inPack];
		[inPack setIsEnabled:NO];
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
    while ((pack = [enumerator nextObject])) {
        [nameArray addObject:[pack name]];
    }
    
    [[adium preferenceController] setPreference:nameArray forKey:KEY_EMOTICON_ACTIVE_PACKS group:PREF_GROUP_EMOTICONS];
}


//Available emoticon packs ---------------------------------------------------------------------------------------------
#pragma mark Available emoticon packs
//Returns an array of the available emoticon packs
- (NSArray *)availableEmoticonPacks
{
    if (!_availableEmoticonPacks) {
		NSEnumerator	*enumerator;
        NSString		*path;
		
        _availableEmoticonPacks = [[NSMutableArray alloc] init];
        
		//Load emoticon packs
		enumerator = [[adium allResourcesForName:EMOTICONS_PATH_NAME withExtensions:[NSArray arrayWithObjects:EMOTICON_PACK_PATH_EXTENSION,ADIUM_EMOTICON_SET_PATH_EXTENSION,PROTEUS_EMOTICON_SET_PATH_EXTENSION,nil]] objectEnumerator];
		
		while ((path = [enumerator nextObject])) {
			AIEmoticonPack  *pack = [AIEmoticonPack emoticonPackFromPath:path];
			
			if ([[pack emoticons] count]) {
				[_availableEmoticonPacks addObject:pack];
				[pack setDisabledEmoticons:[self disabledEmoticonsInPack:pack]];
			}
		}
		
		//Sort as per the saved ordering
		[self _sortArrayOfEmoticonPacks:_availableEmoticonPacks];

		//Build the list of active packs
		[self activeEmoticonPacks];
    }
    
    return _availableEmoticonPacks;
}

//Returns the emoticon pack by name
- (AIEmoticonPack *)emoticonPackWithName:(NSString *)inName
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *emoticonPack;
	
    enumerator = [[self availableEmoticonPacks] objectEnumerator];
    while ((emoticonPack = [enumerator nextObject])) {
        if ([[emoticonPack name] isEqualToString:inName]) return emoticonPack;
    }
	
    return nil;
}

- (void)xtrasChanged:(NSNotification *)notification
{
	if (notification == nil || [[notification object] caseInsensitiveCompare:@"AdiumEmoticonset"] == 0) {
		[self resetAvailableEmoticons];
		[prefs emoticonXtrasDidChange];
	}
}


//Pack ordering --------------------------------------------------------------------------------------------------------
#pragma mark Pack ordering
//Re-arrange an emoticon pack
- (void)moveEmoticonPacks:(NSArray *)inPacks toIndex:(int)index
{    
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    
    //Remove each pack
    enumerator = [inPacks objectEnumerator];
    while ((pack = [enumerator nextObject])) {
        if ([_availableEmoticonPacks indexOfObject:pack] < index) index--;
        [_availableEmoticonPacks removeObject:pack];
    }
	
    //Add back the packs in their new location
    enumerator = [inPacks objectEnumerator];
    while ((pack = [enumerator nextObject])) {
        [_availableEmoticonPacks insertObject:pack atIndex:index];
        index++;
    }
	
    //Save our new ordering
    [self _saveEmoticonPackOrdering];
}

- (void)_saveEmoticonPackOrdering
{
    NSEnumerator		*enumerator;
    AIEmoticonPack		*pack;
    NSMutableArray		*nameArray = [NSMutableArray array];
    
    enumerator = [[self availableEmoticonPacks] objectEnumerator];
    while ((pack = [enumerator nextObject])) {
        [nameArray addObject:[pack name]];
    }
    
	//Changing a preference will clear out our premade _activeEmoticonPacks array
    [[adium preferenceController] setPreference:nameArray forKey:KEY_EMOTICON_PACK_ORDERING group:PREF_GROUP_EMOTICONS];	
}

- (void)_sortArrayOfEmoticonPacks:(NSMutableArray *)packArray
{
	//Load the saved ordering and sort the active array based on it
	NSArray *packOrderingArray = [[adium preferenceController] preferenceForKey:KEY_EMOTICON_PACK_ORDERING 
																		  group:PREF_GROUP_EMOTICONS];
	//It's most likely quicker to create an empty array here than to do nil checks each time through the sort function
	if (!packOrderingArray)
		packOrderingArray = [NSArray array];
	[packArray sortUsingFunction:packSortFunction context:packOrderingArray];
}

int packSortFunction(id packA, id packB, void *packOrderingArray)
{
	int packAIndex = [(NSArray *)packOrderingArray indexOfObject:[packA name]];
	int packBIndex = [(NSArray *)packOrderingArray indexOfObject:[packB name]];
	
	BOOL notFoundA = (packAIndex == NSNotFound);
	BOOL notFoundB = (packBIndex == NSNotFound);
	
	//Packs which aren't in the ordering index sort to the bottom
	if (notFoundA && notFoundB) {
		return ([[packA name] compare:[packB name]]);
		
	} else if (notFoundA) {
		return (NSOrderedDescending);
		
	} else if (notFoundB) {
		return (NSOrderedAscending);
		
	} else if (packAIndex > packBIndex) {
		return NSOrderedDescending;
		
	} else {
		return NSOrderedAscending;
		
	}
}


//Character hints for efficiency ---------------------------------------------------------------------------------------
#pragma mark Character hints for efficiency
//Returns a characterset containing characters that hint at the presence of an emoticon
- (NSCharacterSet *)emoticonHintCharacterSet
{
    if (!_emoticonHintCharacterSet) [self _buildCharacterSetsAndIndexEmoticons];
    return _emoticonHintCharacterSet;
}

//Returns a characterset containing all the characters that may start an emoticon
- (NSCharacterSet *)emoticonStartCharacterSet
{
    if (!_emoticonStartCharacterSet) [self _buildCharacterSetsAndIndexEmoticons];
    return _emoticonStartCharacterSet;
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
    while ((emoticon = [emoticonEnumerator nextObject])) {
        if ([emoticon isEnabled]) {
            NSEnumerator        *textEnumerator;
            NSString            *text;
			
            textEnumerator = [[emoticon textEquivalents] objectEnumerator];
            while ((text = [textEnumerator nextObject])) {
                NSMutableArray  *subIndex;
                unichar         firstCharacter;
                NSString        *firstCharacterString;
                
                if ([text length] != 0) { //Invalid emoticon files may let empty text equivalents sneak in
                    firstCharacter = [text characterAtIndex:0];
                    firstCharacterString = [NSString stringWithFormat:@"%C",firstCharacter];
                    
                    // -- Emoticon Hint Character Set --
                    //If any letter in this text equivalent already exists in the quick scan character set, we can skip it
                    if ([text rangeOfCharacterFromSet:_emoticonHintCharacterSet].location == NSNotFound) {
                        //Potential for optimization!: Favor punctuation characters ( :();- ) over letters (especially vowels).                
                        [_emoticonHintCharacterSet addCharactersInString:firstCharacterString];
                    }
                    
                    // -- Emoticon Start Character Set --
                    //First letter of this emoticon goes in the start set
                    if (![_emoticonStartCharacterSet characterIsMember:firstCharacter]) {
                        [_emoticonStartCharacterSet addCharactersInString:firstCharacterString];
                    }
                    
                    // -- Index --
                    //Get the index according to this emoticon's first character
                    if (!(subIndex = [_emoticonIndexDict objectForKey:firstCharacterString])) {
                        subIndex = [[NSMutableArray alloc] init];
                        [_emoticonIndexDict setObject:subIndex forKey:firstCharacterString];
                        [subIndex release];
                    }
                    
                    //Place the emoticon into that index (If it isn't already in there)
                    if (![subIndex containsObject:emoticon]) {
						//Keep emoticons in order from largest to smallest.  This prevents icons that contain other
						//icons from being masked by the smaller icons they contain.
						//This cannot work unless the emoticon equivelents are broken down.
						/*int i;
						for (i = 0;i < [subIndex count]; i++) {
							if ([subIndex objectAtIndex:i] equivelentLength] < ourLength]) break;
						}*/
                        
						//Instead of adding the emoticon, add all of its equivalents... ?
						
						[subIndex addObject:emoticon];
                    }
                }
            }
            
        }
    }
	
	
	//After building all the subIndexes, sort them by length here
}


//Cache flushing -------------------------------------------------------------------------------------------------------
#pragma mark Cache flushing
//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    
    //Flag our emoticons as enabled/disabled
    enumerator = [[self availableEmoticonPacks] objectEnumerator];
    while ((pack = [enumerator nextObject])) {
        [pack flushEmoticonImageCache];
    }
}

//Reset the active emoticons cache
- (void)resetActiveEmoticons
{
    [_activeEmoticonPacks release]; _activeEmoticonPacks = nil;
    
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


//Private --------------------------------------------------------------------------------------------------------------
#pragma mark Private
- (NSString *)_keyForPack:(AIEmoticonPack *)inPack
{
	return [NSString stringWithFormat:@"Pack:%@",[inPack name]];
}


@end
