/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "ESChatUserListController.h"

@class AIMiniToolbar, AIListObject, AIAccount, AISendingTextView, AIAutoScrollView, AIChat;
@class AIPlasticButton, AIAccountSelectionView, AITabStatusIconsPlugin;

@protocol AIAccountSelectionViewDelegate, AIMessageViewController;

@interface AIMessageViewController : AIObject <AIAccountSelectionViewDelegate, AIListControllerDelegate> {
    IBOutlet	NSView					*view_contents;

    IBOutlet	NSScrollView			*scrollView_outgoing;
    IBOutlet	AIMessageEntryTextView	*textView_outgoing;
	float								entryMinHeight;
		
				NSView					*controllerView_messages;
	IBOutlet	NSView					*scrollView_messages;
	IBOutlet	NSView					*customView_messages;

	IBOutlet	NSSplitView				*splitView_messages;
	IBOutlet	NSSplitView				*splitView_textEntryHorizontal;

	IBOutlet	NSButton				*button_inviteUser;
	
    IBOutlet	AIMiniToolbar			*toolbar_bottom;

	IBOutlet	AIAutoScrollView		*scrollView_userList;
    IBOutlet	AIListOutlineView		*userListView;
	ESChatUserListController			*userListController;

    IBOutlet	AIPlasticButton			*button_send;

    NSObject<AIMessageViewController>	*messageViewController;
	AIAccountSelectionView				*view_accountSelection;

    //Variables
    id				delegate;
    AIChat			*chat;
    BOOL			showUserList;
	BOOL			sendMessagesToOfflineContact;
	
	BOOL inSizeAndArrange;
}

+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat;

- (void)setDelegate:(id)inDelegate;

- (NSView *)view;
- (AIChat *)chat;
- (AIListContact *)listObject;
- (AIAccount *)account;
- (NSObject<AIMessageViewController> *)messageViewController;

- (void)setAccountSelectionMenuVisible:(BOOL)visible;
- (void)setShouldSendMessagesToOfflineContacts:(BOOL)should;

- (void)setAccount:(AIAccount *)inAccount;
- (void)makeTextEntryViewFirstResponder;
- (void)addToTextEntryView:(NSAttributedString *)inString;

- (IBAction)sendMessageLater:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)inviteUser:(id)sender;

- (BOOL)userListVisible;
- (void)tabViewItemWillClose;

@end
