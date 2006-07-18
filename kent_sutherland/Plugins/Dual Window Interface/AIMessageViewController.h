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

#import "ESChatUserListController.h"

@class AIAccount, AIListContact, AIListObject, AIAccountSelectionView, AISplitView, AIMessageEntryTextView;
@protocol AIMessageViewController;

@interface AIMessageViewController : AIObject <AIListControllerDelegate> {
    IBOutlet	NSView					*view_contents;
	
	//Split views
	IBOutlet	AISplitView				*splitView_textEntryHorizontal;
	IBOutlet	AISplitView				*splitView_messages;

	//Message Display
	NSView								*controllerView_messages;
	IBOutlet	NSScrollView			*scrollView_messages;
	IBOutlet	NSView					*customView_messages;
	
	//User List
	IBOutlet	AIAutoScrollView		*scrollView_userList;
	BOOL								retainingScrollViewUserList;
    IBOutlet	AIListOutlineView		*userListView;
	ESChatUserListController			*userListController;

	//Text entry
	IBOutlet	NSScrollView			*scrollView_outgoing;
	IBOutlet	AIMessageEntryTextView	*textView_outgoing;
	
	//
    NSObject<AIMessageViewController>	*messageViewController;
	AIAccountSelectionView				*view_accountSelection;

    AIChat					*chat;
	BOOL					suppressSendLaterPrompt;
	int						entryMinHeight;
	int						userListMinWidth;
}

+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat;
- (void)messageViewWillLeaveWindow:(NSWindow *)inWindow;
- (void)messageViewAddedToWindow:(NSWindow *)inWindow;
- (AIChat *)chat;

- (AIListContact *)listObject;
- (AIListObject *)preferredListObject;

//Message Display
- (NSView *)view;
- (void)adiumPrint:(id)sender;

//Message Entry
- (IBAction)sendMessage:(id)sender;
- (IBAction)didSendMessage:(id)sender;
- (IBAction)sendMessageLater:(id)sender;

//Account Selection
- (void)redisplaySourceAndDestinationSelector:(NSNotification *)notification;
- (void)setAccountSelectionMenuVisibleIfNeeded:(BOOL)makeVisible;

//Text Entry
- (void)makeTextEntryViewFirstResponder;
- (void)clearTextEntryView;
- (void)addToTextEntryView:(NSAttributedString *)inString;

//User List
- (void)setUserListVisible:(BOOL)inVisible;
- (BOOL)userListVisible;


@end

