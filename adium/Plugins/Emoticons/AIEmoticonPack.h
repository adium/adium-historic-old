//
//  AIEmoticonPack.h
//  Adium
//
//  Created by Ian Krieg on Tue Jul 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface AIEmoticonPack : NSObject {
    AIAdium				*owner;
    NSString			*title;
    NSString			*path;
    NSString			*sourceID;	// Bundle or Extras
    
    NSAttributedString	*about;
    
    NSMutableDictionary	*emoticonRefs;
    NSMutableDictionary *prefDict;
}

- (AIEmoticonPack *)initWithOwner:(AIAdium *)setOwner title:(NSString *)setTitle path:(NSString *)setPath sourceID:(NSString *)setSource emoticons:(NSMutableArray *)setEmoticons about:(NSAttributedString *)setAbout;
- (NSString *)title;
- (NSString *)path;
- (NSString *)sourceID;
- (NSAttributedString	*)about;

// Emoticon Access
- (void)verifyEmoticons;	// Removes invalid references
- (NSEnumerator *)emoticonEnumerator;

- (BOOL)emoticonEnabled:(NSString *)emoticonID;
- (void)setEmoticon:(NSString *)emoticonID enabled:(BOOL)enabled;

- (NSString *)emoticonName:(NSString *)emoticonID;
- (NSString *)emoticonPath:(NSString *)emoticonID;
- (NSString *)emoticonImagePath:(NSString *)emoticonID;
- (NSImage *)emoticonImage:(NSString *)emoticonID;

- (NSString *)emoticonBuiltinTextRepresentationsReturnDelimited:(NSString *)emoticonID;
- (NSString *)emoticonEnabledTextRepresentationsReturnDelimited:(NSString *)emoticonID;
- (NSArray *)emoticonAllTextRepresentationsAsArray:(NSString *)emoticonID;
- (void)setEmoticon:(NSString *)emoticonID text:(NSString *)text enabled:(BOOL)enabled;
    // This function will also add the specified text if it is not there, whether enabling or disabling
- (BOOL)isEmoticon:(NSString *)emoticonID textEnabled:(NSString *)text;
- (BOOL)removeEmoticon:(NSString *)emoticonID text:(NSString *)text;
    // Returns success/failure.  Cannot remove strings that come w/ the pack, only user-added ones.

// Prefs
- (NSString *)preferencesKey;
- (void)loadPreferences;
- (int)isEnabled;	// Returns NSOffState, NSOnState, or NSMixedState
- (void)setEnabled:(BOOL)enabled;


@end
