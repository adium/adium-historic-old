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

@class AIMiniToolbar, AIContactHandle, AIAdium, AIAccount, AISendingTextView;
@protocol AIContainerInterface, AIAccountSelectionViewDelegate;

@interface AIMessageViewController : NSObject <AIAccountSelectionViewDelegate> {
    IBOutlet	NSView			*view_contents;
    IBOutlet	NSScrollView		*scrollView_outgoingView;
    IBOutlet	AISendingTextView	*textView_outgoing;
    IBOutlet	NSScrollView		*scrollView_messages;
    IBOutlet	AIMiniToolbar		*toolbar_bottom;

    NSView				*view_messages;
    NSView				*view_accountSelection;

    //Variables
    AIAdium			*owner;
    id <AIContainerInterface> 	interface;
    AIContactHandle		*handle;
    AIAccount			*account;
}

+ (AIMessageViewController *)messageViewControllerWithHandle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent owner:(id)inOwner interface:(id <AIContainerInterface>)inInterface;
- (IBAction)sendMessage:(id)sender;
- (NSView *)view;
- (AIContactHandle *)handle;
- (void)setAccountSelectionMenuVisible:(BOOL)visible;

@end
