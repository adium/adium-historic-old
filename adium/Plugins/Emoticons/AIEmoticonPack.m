//
//  AIEmoticonPack.m
//  Adium
//
//  Created by Ian Krieg on Tue Jul 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEmoticonPack.h"
#import "AIEmoticonsPlugin.h"


@interface AIEmoticonPack (PRIVATE)
- (NSMutableDictionary *)_preferencesDictionary;
- (BOOL)_allEmoticonsEnabled;
- (NSString *)_emoticonPrefKey:(NSString *)emoticonID forProperty:(NSString *)prop;
- (NSString *)_emoticonPrefKey:(NSString *)emoticonID forSmileyText:(NSString *)prop;
- (void)_savePreferences;
@end

@implementation AIEmoticonPack
- (AIEmoticonPack *)initWithOwner:(AIAdium *)setOwner title:(NSString *)setTitle path:(NSString *)setPath sourceID:(NSString *)setSource emoticons:(NSMutableArray *)setEmoticons about:(NSAttributedString *)setAbout
{
    owner = [setOwner retain];
    title = [setTitle retain];
    path = [setPath retain];
    sourceID = [setSource copy];
    
    about = [setAbout retain];
    
    // Re-store emoticon references in dictionary
    emoticonRefs =	[[NSMutableDictionary alloc] init];
    NSEnumerator	*enumerator = [setEmoticons objectEnumerator];
    NSString		*curEmoticonPath = nil,
                    *curEmoticonName = nil;
    
    while (curEmoticonPath = [enumerator nextObject]){
        curEmoticonName = [[curEmoticonPath lastPathComponent] stringByDeletingPathExtension];
        [emoticonRefs setObject:curEmoticonPath	forKey:curEmoticonName];
    }
    
    // Load preferences dictionary
    prefDict = nil;
    [self loadPreferences];
    return self;
}

- (void)dealloc
{
    [owner release];
    [title release];
    [path release];
    [sourceID release];
    [about release];
    [emoticonRefs release];
    
    [super dealloc];
}

- (NSString *)title
{
    return(title);
}

- (NSString *)path
{
    return(path);
}

- (NSString *)sourceID
{
    return(sourceID);
}

- (NSAttributedString	*)about
{
    return(about);
}

// Emoticon Access	//
// Removes any emoticon references that are no longer valid
- (void)verifyEmoticons
{
    NSEnumerator	*enumerator = [self emoticonEnumerator];
    NSString		*curPath = nil;
    id				emoID = nil;
    NSMutableArray			*deadBeats = [NSMutableArray array];
    
    // Find deadbeats
    while (emoID = [enumerator nextObject]){
        BOOL	valid = TRUE;
        curPath = [self emoticonPath:emoID];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[curPath stringByAppendingPathComponent:@"TextEquivalents.txt"]])
            valid = FALSE;

        if (![[NSFileManager defaultManager] fileExistsAtPath:[curPath stringByAppendingPathComponent:@"Emoticon.tiff"]])
            valid = FALSE;
            
        if (!valid)
            [deadBeats addObject:emoID];
    }
    
    // Remove deadbeats
    enumerator = [deadBeats objectEnumerator];
    while (emoID = [enumerator nextObject]){
        [emoticonRefs removeObjectForKey:emoID];
    }
}

- (NSEnumerator *)emoticonEnumerator
{
    return([emoticonRefs	keyEnumerator]);
}

- (BOOL)emoticonEnabled:(NSString *)emoticonID
{
    BOOL	enabled = TRUE;

    if ([self isEnabled] == NSOffState){
        enabled = FALSE;
    }else if ([self isEnabled] == NSMixedState) {
        NSString	*key = [self _emoticonPrefKey:emoticonID forProperty:@"enabled"];
        NSNumber	*nsEnabled = [[self _preferencesDictionary] objectForKey:key];

        if (nsEnabled) {
            enabled = [nsEnabled intValue];
        }
    }
    
    return(enabled);
}

- (void)setEmoticon:(NSString *)emoticonID enabled:(BOOL)enabled
{
    // Set emoticon appropriately
    NSString	*key = [self _emoticonPrefKey:emoticonID forProperty:@"enabled"];
    [[self _preferencesDictionary] setObject:[NSNumber numberWithInt:enabled] forKey:key];
    [self _savePreferences];
    
    // Reset pack enabled state
    switch ([self isEnabled]){
    case NSOffState:
        // No state change
        break;

    case NSOnState:
    case NSMixedState:
        [self setEnabled:true];	// This method will check to see how many emoticons are enabled, and set
                                // state accordingly
        break;
    }
}

- (NSString *)emoticonName:(NSString *)emoticonID
{
    return([NSString stringWithString:emoticonID]);
}

- (NSString *)emoticonPath:(NSString *)emoticonID
{
    return([emoticonRefs objectForKey:emoticonID]);
}

- (NSString *)emoticonImagePath:(NSString *)emoticonID
{
    return([[self emoticonPath:emoticonID] stringByAppendingPathComponent:@"Emoticon.tiff"]);
}

- (NSImage *)emoticonImage:(NSString *)emoticonID
{
    return([[[NSImage alloc] initWithContentsOfFile:[self emoticonImagePath:emoticonID]] autorelease]);
}

- (NSString *)emoticonBuiltinTextRepresentationsReturnDelimited:(NSString *)emoticonID
{
    NSString	*curPath = [self emoticonPath:emoticonID];
    if (curPath){
        if ([[NSFileManager defaultManager] fileExistsAtPath:[curPath stringByAppendingPathComponent:@"TextEquivalents.txt"]]){
            NSMutableString	*emoText = [NSMutableString stringWithContentsOfFile:[curPath stringByAppendingPathComponent:@"TextEquivalents.txt"]];
            
            // Check string for UNIX or Windows line end encoding, repairing if needed.
            NSCharacterSet	*newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
            NSRange	charRange = [emoText rangeOfCharacterFromSet:newlineSet];

            while (charRange.length != 0){
                [emoText replaceCharactersInRange:charRange withString:@"\r"];
                charRange = [emoText rangeOfCharacterFromSet:newlineSet];
            }
            
            return [NSString stringWithString:emoText];
        } else {
            return @"";
        }
    } else {
        return @"";
    }
}

- (NSString *)emoticonEnabledTextRepresentationsReturnDelimited:(NSString *)emoticonID
{
    NSMutableArray	*emoTexts = [[self emoticonAllTextRepresentationsAsArray:emoticonID] mutableCopy];
    
    NSNumber	*enablement = nil;
    long 		index;

    for (index = 0; index < [emoTexts count]; index++) {
        if (enablement = [[self _preferencesDictionary]
                           objectForKey:[self _emoticonPrefKey:emoticonID
                                              forSmileyText:[emoTexts objectAtIndex:index]]]) {
            if ([enablement boolValue] == FALSE) {
                // Remove this string from array
                [emoTexts removeObjectAtIndex:index--];
            }
        }	// If the NSNumber isn't there, then the smiley defaults to enabled.
    }
    
    NSString		*outString = [emoTexts componentsJoinedByString:@"\r"];
    [emoTexts release];
    
    return (outString);
}

- (NSArray *)emoticonAllTextRepresentationsAsArray:(NSString *)emoticonID
{
    NSString	*key = [self _emoticonPrefKey:emoticonID forProperty:@"customStrings"];
    NSArray		*customText = [[self _preferencesDictionary] objectForKey:key];
    NSArray		*texts = [[self emoticonBuiltinTextRepresentationsReturnDelimited:emoticonID] componentsSeparatedByString:@"\r"];
    texts = [texts arrayByAddingObjectsFromArray:customText];
    
    return(texts);
}

// This function will also add the specified text if it is not there, whether enabling or disabling
- (void)setEmoticon:(NSString *)emoticonID text:(NSString *)text enabled:(BOOL)enabled
{
    NSArray		*texts = [self emoticonAllTextRepresentationsAsArray:emoticonID];
    long		ind = [texts indexOfObjectIdenticalTo:text];
    NSString	*key = nil;

    if (ind == NSNotFound){
    
        // Add this string to the end of the list
        key = [self _emoticonPrefKey:emoticonID forProperty:@"customStrings"];
        NSMutableArray	*newTexts = [[[self _preferencesDictionary] objectForKey:key] mutableCopy];
        [newTexts addObject:[text copy]];
        [[self _preferencesDictionary] setObject:[newTexts copy] forKey:key];
        [newTexts release];
        newTexts = nil;
    }
    
    // Set enablement for string
    key = [self _emoticonPrefKey:emoticonID forSmileyText:text];
    [[self _preferencesDictionary] setObject:[NSNumber numberWithBool:enabled] forKey:key];
    
    // Save everything we've done
    [self _savePreferences];
}

- (BOOL)isEmoticon:(NSString *)emoticonID textEnabled:(NSString *)text
{
    BOOL		isOn = TRUE;
    NSNumber	*numOb = [[self _preferencesDictionary] objectForKey:[self _emoticonPrefKey:emoticonID forSmileyText:text]];
    
    if (numOb)
        isOn = [numOb boolValue];
    
    return isOn;
}

// Returns success/failure.  Cannot remove strings that come w/ the pack, only user-added ones.
- (BOOL)removeEmoticon:(NSString *)emoticonID text:(NSString *)text
{
    // Remove text from list
    BOOL		success = FALSE;
    NSString	*key = [self _emoticonPrefKey:emoticonID forProperty:@"customStrings"];
    NSMutableArray	*texts = [[[self _preferencesDictionary] objectForKey:key] mutableCopy];
    long		index = [texts indexOfObjectIdenticalTo:text];

    if (index != NSNotFound) {
        success = TRUE;
        [texts removeObjectAtIndex:index];
        [[self _preferencesDictionary] setObject:[texts copy] forKey:key];
    }
    [texts release];
    
    // Remove enablement preferences
    if (success){
        key = [self _emoticonPrefKey:emoticonID forSmileyText:text];
        [[self _preferencesDictionary] removeObjectForKey:key];
        [[self _preferencesDictionary] removeObjectForKey:key];//TEST does doing it twice kill anything?
        [self _savePreferences];
    }

    return(success);
}

- (BOOL)_allEmoticonsEnabled
{
    //NSArray	*emoTexts = [self emoticonAllTextRepresentationsAsArray:emoticonID];

    NSNumber		*enablement = nil;
    BOOL			smileysEnabled = TRUE;
    NSEnumerator	*enumerator = [self emoticonEnumerator];
    id				curEmo = nil;

    while ((curEmo = [enumerator nextObject]) && smileysEnabled) {
        if (enablement = [[self _preferencesDictionary]
                           objectForKey:[self _emoticonPrefKey:curEmo
                                                   forProperty:@"enabled"]]) {
            if ([enablement boolValue] == FALSE) {
                smileysEnabled = FALSE;
            }
        }	// If the NSNumber isn't there, then the smiley will default to enabled.
    }

    return (smileysEnabled);
}

- (NSString *)_emoticonPrefKey:(NSString *)emoticonID forProperty:(NSString *)prop
{
    return([NSString stringWithFormat:@"emoticon_%@_%@", [self emoticonName:emoticonID], prop]);
}

// Used for keys concerning individual text strings for smileys
- (NSString *)_emoticonPrefKey:(NSString *)emoticonID forSmileyText:(NSString *)prop
{
    return([NSString stringWithFormat:@"emoticon_%@_@%@", [self emoticonName:emoticonID], prop]);
}

// Prefs
- (NSString *)preferencesKey
{
    return [NSString stringWithFormat:@"%@_pack_%@", [self sourceID], [self title]];
}

- (void)loadPreferences
{
    if (prefDict)
    {
        [prefDict release];
        prefDict = nil;
    }
    prefDict =	[[owner preferenceController] preferenceForKey:[self preferencesKey] group:PREF_GROUP_EMOTICONS object:nil];
    if (prefDict) {
        prefDict = [prefDict mutableCopy];
    }  else {
        prefDict = [[NSMutableDictionary alloc] init];

        [self _savePreferences];
        [self loadPreferences];
    }
}

- (NSMutableDictionary *)_preferencesDictionary
{
    return prefDict;
}

- (void)_savePreferences
{
    [[owner preferenceController] setPreference:[self _preferencesDictionary] forKey:[self preferencesKey] group:PREF_GROUP_EMOTICONS];
}

- (int)isEnabled
{
    return [[[self _preferencesDictionary] objectForKey:@"inUse"] intValue];
}

- (void)setEnabled:(BOOL)enabled
{
    //int	curState = [self isEnabled];
    
    if (enabled == TRUE)
    {
        /*switch (curState)
        {
        case	NSOffState:
            //[[owner preferenceController] setPreference:[self _preferencesDictionary] forKey:[self preferencesKey] group:PREF_GROUP_EMOTICONS];	//Save
            break;
        case	NSMixedState:
        case	NSOnState:
            break;
        }*/
        if ([self _allEmoticonsEnabled]) {
            [[self _preferencesDictionary] setObject:[NSNumber numberWithInt:NSOnState] forKey:@"inUse"];
        } else {
            [[self _preferencesDictionary] setObject:[NSNumber numberWithInt:NSMixedState] forKey:@"inUse"];
        }
        [self _savePreferences];
    }
    else
    {
        [[self _preferencesDictionary] setObject:[NSNumber numberWithInt:NSOffState] forKey:@"inUse"];
        [self _savePreferences];
    }
}
@end
