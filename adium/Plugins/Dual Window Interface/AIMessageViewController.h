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

@class AIMiniToolbar, AIListObject, AIAccount, AISendingTextView, AIAutoScrollView, AIChat, AIPlasticButton, AIAccountSelectionView;
@protocol AIAccountSelectionViewDelegate, AIMessageViewController;

@interface AIMessageViewController : AIObject <AIAccountSelectionViewDelegate> {
    IBOutlet	NSView					*view_contents;
    IBOutlet	NSScrollView			*scrollView_outgoingView;
    IBOutlet	AIMessageEntryTextView	*textView_outgoing;
				NSView					*controllerView_messages;
    IBOutlet	NSView					*scrollView_messages;
    IBOutlet	AIMiniToolbar			*toolbar_bottom;

    IBOutlet	NSTableView				*tableView_userList;
    IBOutlet	AIAutoScrollView		*scrollView_userList;

    IBOutlet	AIPlasticButton			*button_send;

    id <AIMessageViewController>		messageViewController;
    AIAccountSelectionView				*view_accountSelection;

    //Variables
    id				delegate;
    AIChat			*chat;
    BOOL			showUserList;
	BOOL			sendMessagesToOfflineContact;
}

+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat;
- (IBAction)sendMessage:(id)sender;
- (NSView *)view;
- (void)setAccountSelectionMenuVisible:(BOOL)visible;
- (void)makeTextEntryViewFirstResponder;
- (void)setAccount:(AIAccount *)inAccount;
- (AIChat *)chat;
- (AIListObject *)listObject;
- (AIAccount *)account;
- (void)setDelegate:(id)inDelegate;
- (void)addToTextEntryView:(NSAttributedString *)inString;
- (void)setShouldSendMessagesToOfflineContacts:(BOOL)should;
- (IBAction)sendMessageLater:(id)sender;

@end


