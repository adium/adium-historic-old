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

#define PREF_GROUP_EMOTICONS			@"Emoticons"
#define KEY_EMOTICON_ACTIVE_PACKS       @"Active Emoticon Packs"
#define KEY_EMOTICON_DISABLED           @"Disabled Emoticons"
#define KEY_EMOTICON_PACK_ORDERING		@"Emoticon Pack Ordering"

@protocol AIContentFilter;
@class AIEmoticonPreferences, AIEmoticonPack, AIEmoticon;

@interface AIEmoticonsPlugin : AIPlugin <AIContentFilter> {
    AIEmoticonPreferences	*prefs;
    BOOL                        observingContent;

    NSMutableArray              *_availableEmoticonPacks;
    NSMutableArray              *_activeEmoticons;
    NSMutableArray              *_activeEmoticonPacks;
    NSMutableCharacterSet       *_emoticonHintCharacterSet;
    NSMutableCharacterSet       *_emoticonStartCharacterSet;
    NSMutableDictionary         *_emoticonIndexDict;
}

- (NSArray *)availableEmoticonPacks;
- (AIEmoticonPack *)emoticonPackWithName:(NSString *)inName;
- (NSArray *)activeEmoticons;
- (NSArray *)activeEmoticonPacks;
- (void)moveEmoticonPacks:(NSArray *)inPacks toIndex:(int)index;
- (void)setEmoticonPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled;
- (void)setEmoticon:(AIEmoticon *)inEmoticon inPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled;
- (void)flushEmoticonImageCache;

@end
