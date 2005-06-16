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

#import <AIUtilities/AISendingTextView.h>

#define	AIContinuousSpellCheckingWasToggledNotification	@"AIContinuousSpellCheckingWasToggledNotification"

@class AIListContact, AIAdium, AIAccount, AIChat;
@protocol AITextEntryView;

@interface AIMessageEntryTextView : AISendingTextView <AITextEntryView> {
    AIAdium             *adium;
    AIChat              *chat;
    
    BOOL                 clearOnEscape;
    BOOL                 pushPopEnabled;
	BOOL				 homeToStartOfLine;

    NSMutableArray		*historyArray;
    int                  currentHistoryLocation;

    NSMutableArray		*pushArray;
    BOOL                 pushIndicatorVisible;
    NSButton			*indicator;
    NSMenu              *pushMenu;
    NSDictionary		*defaultTypingAttributes;
	
    NSSize               lastPostedSize;
    NSSize               _desiredSizeCached;
	BOOL				resizing;
    
    NSView              *associatedView;
}

- (id)initWithFrame:(NSRect)frameRect;

//Configure
- (void)setClearOnEscape:(BOOL)inBool;
- (void)setHomeToStartOfLine:(BOOL)inBool;
- (void)setAssociatedView:(NSView *)inView;
- (NSView *)associatedView;

//Adium Text Entry
- (void)setAttributedString:(NSAttributedString *)inAttributedString;
- (void)setString:(NSString *)string;
- (void)setTypingAttributes:(NSDictionary *)attrs;
- (void)pasteAsRichText:(id)sender;
- (void)insertText:(id)aString;
- (NSSize)desiredSize;

//Context
- (void)setChat:(AIChat *)inChat;
- (AIChat *)chat;
- (AIListContact *)listObject;

//Paging
- (void)scrollPageUp:(id)sender;
- (void)scrollPageDown:(id)sender;

//History
- (void)historyUp;
- (void)historyDown;

//Push and Pop
- (void)setPushPopEnabled:(BOOL)inBool;
- (void)pushContent;
- (void)popContent;
- (void)swapContent;

@end
