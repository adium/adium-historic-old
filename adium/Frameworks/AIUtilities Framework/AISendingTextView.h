/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@class AIContactHandle;
@protocol AITextEntryView;

@interface AISendingTextView : NSTextView <AITextEntryView> {
    BOOL		sendOnEnter;
    BOOL		sendOnReturn;

    id			target;
    SEL			selector;

    NSMutableArray	*returnArray;
}

- (id)initWithFrame:(NSRect)frameRect;
- (void)setSendOnReturn:(BOOL)inBool;
- (void)setSendOnEnter:(BOOL)inBool;
- (void)setTarget:(id)inTarget action:(SEL)inSelector;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)insertText:(NSString *)aString;
- (void)interpretKeyEvents:(NSArray *)eventArray;

@end
