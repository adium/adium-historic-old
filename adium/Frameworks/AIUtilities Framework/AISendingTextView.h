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

#define PREF_GROUP_PUSH_PREFS   @"Push Message"
#define KEY_AUTOPOP				@"Autopop"

@class AIListObject, AIAdium, AIAccount, AIChat;
@protocol AITextEntryView;

@interface AISendingTextView : NSTextView <AITextEntryView> {
    AIAdium			*adium;
    AIChat			*chat;
    
    BOOL			sendOnEnter;
    BOOL			sendOnReturn;
	BOOL			pushPop;
    NSMutableArray	*returnArray;
    BOOL			insertingText;
    
    id				target;
    SEL				selector;
    BOOL			availableForSending;

    NSMutableArray	*historyArray;
    int				currentHistoryLocation;

    NSMutableArray	*pushArray;
    BOOL			pushIndicatorVisible;
	NSDictionary	*prefDict;
    NSButton		*indicator;
	NSMenu			*pushMenu;
        
    NSSize			lastPostedSize;
	NSSize			_desiredSizeCached;
    
    IBOutlet		NSScrollView	*messageScrollView;
}

- (id)initWithFrame:(NSRect)frameRect;
- (NSSize)desiredSize;

- (void)setSendOnReturn:(BOOL)inBool;
- (void)setSendOnEnter:(BOOL)inBool;
- (void)setPushPop:(BOOL)inBool

- (void)setTarget:(id)inTarget action:(SEL)inSelector;

- (void)insertText:(id)aString;

- (void)interpretKeyEvents:(NSArray *)eventArray;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;

- (void)setAvailableForSending:(BOOL)inBool;
- (BOOL)availableForSending;

- (void)setChat:(AIChat *)inChat;
- (AIChat *)chat;

@end
