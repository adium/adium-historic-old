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

#define AIMessageWindow_ControllersChanged 		@"AIMessageWindow_ControllersChanged"
#define AIMessageWindow_ControllerOrderChanged 		@"AIMessageWindow_ControllerOrderChanged"
#define AIMessageWindow_SelectedControllerChanged 	@"AIMessageWindow_SelectedControllerChanged"

@class AIAdium, AIContactHandle, AIMessageSendingTextView, AIMiniToolbar, AIMessageViewController;

@protocol AIMessageView
- (AIContactHandle *)handle;	//Return the handle associated with this tab
- (NSAttributedString *)title;	//Return an alternate title (if handle is nil)
- (NSView *)view;		//Return a view, the tab contents
@end

@protocol AITabHoldingInterface <NSObject>
- (void)closeMessageViewController:(id <AIMessageView>)controller;
@end


@interface AIMessageWindowController : NSWindowController {
    IBOutlet	NSTabView	*tabView_messages;

    NSMutableArray		*messageViewArray;

    AIAdium			*owner;
    id <AITabHoldingInterface> 	interface;
    
}

+ (AIMessageWindowController *)messageWindowControllerWithOwner:(id)inOwner interface:(id <AITabHoldingInterface>)inInterface;
- (void)selectMessageViewController:(id <AIMessageView>)inController;
- (void)addMessageViewController:(id <AIMessageView>)inController;
- (BOOL)removeMessageViewController:(id <AIMessageView>)inController;
- (int)count;
- (NSArray *)messageViewArray;
- (IBAction)closeWindow:(id)sender;
- (id <AIMessageView>)selectedMessageView;
- (BOOL)selectNextController;
- (BOOL)selectPreviousController;
- (void)selectFirstController;
- (void)selectLastController;

@end
