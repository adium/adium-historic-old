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

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

#define PREF_GROUP_EMOTICONS		@"Emoticons"
#define	KEY_EMOTICON_PACK_PATH		@"EmoticonPackPath"
#define KEY_EMOTICON_PACK_CONTENTS	@"EmoticonPackContents"
#define KEY_EMOTICON_PACK_TITLE		@"EmoticonPackTitle"
#define KEY_EMOTICON_PACK_SOURCE	@"EmoticonPackSource"
#define KEY_EMOTICON_PACK_PREFS		@"EmoticonPackPrefsDict"
#define KEY_EMOTICON_PACK_ABOUT		@"EmoticonPackAbout"

@protocol AIContentFilter;
@class AIEmoticonPreferences;

@interface AIEmoticonsPlugin : AIPlugin <AIContentFilter> {
    BOOL			replaceEmoticons;
    
    NSMutableArray		*emoticons;
    
    NSMutableArray		*quickScanList;
    NSMutableString		*quickScanString;
	
    AIEmoticonPreferences	*prefs;
    NSMutableArray		*cachedPacks;
}

- (void)preferencesChanged:(NSNotification *)notification;
- (void)allEmoticonPacks:(NSMutableArray *)emoticonPackArray;
- (void)allEmoticonPacks:(NSMutableArray *)emoticonPackArray forceReload:(BOOL)reload;
- (BOOL)loadEmoticonsFromPacks;

@end
