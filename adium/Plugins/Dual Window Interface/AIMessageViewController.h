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

@class AIMiniToolbar, AIListObject, AIAdium, AIAccount, AISendingTextView, AIAutoScrollView, AIChat, AIPlasticButton, AIAccountSelectionView;
@protocol AIContainerInterface, AIAccountSelectionViewDelegate, AIMessageViewController;

@interface AIMessageViewController : NSObject <AIAccountSelectionViewDelegate> {
    IBOutlet	NSView			*view_contents;
    IBOutlet	NSScrollView		*scrollView_outgoingView;
    IBOutlet	AISendingTextView	*textView_outgoing;
    IBOutlet	AIAutoScrollView	*scrollView_messages;
    IBOutlet	AIMiniToolbar		*toolbar_bottom;

    IBOutlet	NSTableView		*tableView_userList;
    IBOutlet	AIAutoScrollView	*scrollView_userList;

    IBOutlet	AIPlasticButton		*button_send;

    id <AIMessageViewController>	messageViewController;
    AIAccountSelectionView		*view_accountSelection;

    //Variables
    id				delegate;
    AIAdium			*owner;
    id <AIContainerInterface> 	interface;
    AIAccount			*account;
    AIChat			*chat;
    float			currentTextEntryHeight;
    BOOL			showUserList;
    BOOL			availableForSending;
}

+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat owner:(id)inOwner;
- (IBAction)sendMessage:(id)sender;
- (NSView *)view;
- (void)setAccountSelectionMenuVisible:(BOOL)visible;
- (void)makeTextEntryViewFirstResponder;
- (void)setAccount:(AIAccount *)inAccount;
- (void)closeMessageView;
- (AIChat *)chat;
- (AIAccount *)account;
- (void)setDelegate:(id)inDelegate;
- (void)setChat:(AIChat *)inChat;

@end

@interface NSObject (AIMessageViewControllerDelegate)
- (void)messageViewController:(AIMessageViewController *)messageView chatChangedTo:(AIChat *)chat;
@end


