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

@class AIMessageSendingTextView, AIMiniToolbar, AIContactHandle, AIAdium, AIColoredBoxView, AIAccount, AICompletingTextField, AISendingTextView;
@protocol AITextEntryView, AIMessageView, AITabHoldingInterface;

@interface AIMessageViewController : NSObject <AIMessageView> {
    IBOutlet	NSView			*view_contents;

    //Present in nib
    IBOutlet	NSScrollView		*scrollView_outgoingView;
    IBOutlet	AIColoredBoxView	*view_account;
    IBOutlet	NSPopUpButton		*popUp_accounts;
    
    //Disposable
    IBOutlet	AISendingTextView	*textView_outgoing;
    IBOutlet	AIColoredBoxView	*view_handle;
    IBOutlet	AICompletingTextField	*textField_handle;
    IBOutlet	AIColoredBoxView	*view_buttons;

    //Manually created
    NSScrollView			*scrollView_messages;
    NSView				*view_messages;
    AIMiniToolbar			*toolbar_bottom;

    //Variables
    AIAdium			*owner;
    id <AITabHoldingInterface> 	interface;
    AIContactHandle		*handle;
    AIAccount			*account;
    BOOL			accountMenuVisible;
}

+ (AIMessageViewController *)messageViewControllerWithHandle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent owner:(id)inOwner interface:(id <AITabHoldingInterface>)inInterface;
- (IBAction)sendMessage:(id)sender;
- (AIContactHandle *)handle;
- (NSAttributedString *)title;
- (NSView *)view;
- (IBAction)setFocusOnEnterView:(id)sender;
- (IBAction)selectNewAccount:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)setAccountMenuVisible:(BOOL)visible;

@end
