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
- (NSMutableDictionary *)preferencesDictionary;
- (BOOL)_allEmoticonsEnabled;
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
    return(TRUE);	//FIX
}

- (void)setEmoticon:(NSString *)emoticonID enabled:(BOOL)enabled
{
    //FIX
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

- (NSString *)emoticonEnabledTextRepresentationsReturnDelimited:(NSString *)emoticonID
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
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)emoticonAllTextRepresentationsAsArray:(NSString *)emoticonID
{
    return([NSArray array]);//FIX
}

// This function will also add the specified text if it is not there, whether enabling or disabling
- (void)setEmoticon:(NSString *)emoticonID text:(NSString *)text enabled:(BOOL)enabled
{//FIX
}

// Returns success/failure.  Cannot remove strings that come w/ the pack, only user-added ones.
- (BOOL)removeEmoticon:(NSString *)emoticonID text:(NSString *)text
{
    return(FALSE);//FIX
}

- (BOOL)_allEmoticonsEnabled
{
    return YES;	//FIX
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
    prefDict =	[[[owner preferenceController] preferenceForKey:[self preferencesKey] group:PREF_GROUP_EMOTICONS object:nil] mutableCopy];
}

- (NSMutableDictionary *)preferencesDictionary
{
    return prefDict;
}

- (int)isEnabled
{
    return [[[self preferencesDictionary] objectForKey:@"inUse"] intValue];
}

- (void)setEnabled:(BOOL)enabled
{
    int	curState = [self isEnabled];
    
    if (enabled == TRUE)
    {
        switch (curState)
        {
        case	NSOffState:
            if ([self _allEmoticonsEnabled]) {
                [[self preferencesDictionary] setObject:[NSNumber numberWithInt:NSOnState] forKey:@"inUse"];
            } else {
                [[self preferencesDictionary] setObject:[NSNumber numberWithInt:NSMixedState] forKey:@"inUse"];
            }
            [[owner preferenceController] setPreference:[self preferencesDictionary] forKey:[self preferencesKey] group:PREF_GROUP_EMOTICONS];	//Save
            break;
        case	NSMixedState:
        case	NSOnState:
            // Do nothing
            NSLog (@"Attempt to enable an enabled pack");
            break;
        }
    }
    else
    {
        [[self preferencesDictionary] setObject:[NSNumber numberWithInt:NSOffState] forKey:@"inUse"];
        [[owner preferenceController] setPreference:[self preferencesDictionary] forKey:[self preferencesKey] group:PREF_GROUP_EMOTICONS];	//Save
    }
}
@end
