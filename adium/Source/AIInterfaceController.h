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

#define Interface_ContactSelectionChanged			@"Interface_ContactSelectionChanged"
#define Interface_SendEnteredMessage				@"Interface_SendEnteredMessage"
#define Interface_WillSendEnteredMessage 			@"Interface_WillSendEnteredMessage"
#define Interface_DidSendEnteredMessage				@"Interface_DidSendEnteredMessage"
#define Interface_ErrorMessageReceived				@"Interface_ErrorMessageRecieved"
#define Interface_ContactListDidBecomeMain			@"Interface_ContactListDidBecomeMain"
#define Interface_ContactListDidResignMain			@"Interface_contactListDidResignMain"
#define AIViewDesiredSizeDidChangeNotification		@"AIViewDesiredSizeDidChangeNotification"

//Sends Interface_ViewDesiredSizeDidChange notifications
@protocol AIAutoSizingView 
- (NSSize)desiredSize;
@end

//Controls a contact list view
@protocol AIContactListViewController <NSObject>	
- (NSView *)contactListView;
@end

@protocol AIMessageViewController <NSObject>
- (NSView *)messageView;
- (NSView *)messageScrollView;
@end

//Manages contact list view controllers
@protocol AIContactListViewPlugin <NSObject>	
- (id <AIContactListViewController>)contactListViewController;
@end

//manages message view controllers
@protocol AIMessageViewPlugin <NSObject>	
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat;
@end



@protocol AIContactListTooltipEntry <NSObject>
- (NSString *)labelForObject:(AIListObject *)inObject;
- (NSAttributedString *)entryForObject:(AIListObject *)inObject;
@end

@protocol AIFlashObserver <NSObject>
- (void)flash:(int)value;
@end

//Handles any attributed text entry
@protocol AITextEntryView 
- (NSAttributedString *)attributedString;
- (void)setAttributedString:(NSAttributedString *)inAttributedString;
- (void)setTypingAttributes:(NSDictionary *)attrs;
- (BOOL)availableForSending;
- (AIChat *)chat;
@end

@protocol AIInterfaceController <NSObject>
- (void)openInterface;
- (void)closeInterface;
- (void)initiateNewMessage;
- (void)openChat:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (void)setActiveChat:(AIChat *)inChat;
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows;
@end

@interface AIInterfaceController : NSObject {
    IBOutlet	AIAdium			*owner;
	
    IBOutlet	NSMenuItem		*menuItem_paste;
    IBOutlet	NSMenuItem		*menuItem_pasteFormatted;
    
    IBOutlet    NSMenuItem      *menuItem_bold;
    IBOutlet    NSMenuItem      *menuItem_italic;

	IBOutlet    NSMenuItem      *menuItem_showToolbar;
	IBOutlet    NSMenuItem      *menuItem_customizeToolbar;

    NSMutableArray				*contactListViewArray;
    NSMutableArray				*messageViewArray;
    NSMutableArray				*interfaceArray;
    NSMutableArray				*contactListTooltipEntryArray;
    NSMutableArray              *contactListTooltipSecondaryEntryArray;
    float                       maxLabelWidth;
    
    NSMutableArray				*flashObserverArray;
    NSTimer						*flashTimer;
    int							flashState;
    AIListObject				*tooltipListObject;
    NSMutableAttributedString   *tooltipBody;
    NSMutableAttributedString   *tooltipTitle;
    NSImage                     *tooltipImage;
	
    NSString					*errorTitle;
    NSString					*errorDesc;
	
}

//Interface controllers
- (void)registerInterfaceController:(id <AIInterfaceController>)inController;

//Contact list views
- (void)registerContactListViewPlugin:(id <AIContactListViewPlugin>)inPlugin;
- (id <AIContactListViewController>)contactListViewController;

//Message views
- (void)registerMessageViewPlugin:(id <AIMessageViewPlugin>)inPlugin;
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat;

//Messaging
- (IBAction)initiateMessage:(id)sender;
- (void)openChat:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (void)setActiveChat:(AIChat *)inChat;

//Error messages
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc;
- (void)handleMessage:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle;

//Flash Syncing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver;
- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver;
- (int)flashState;

//Tooltips
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow;
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary;

//Custom pasting
- (IBAction)paste:(id)sender;
- (IBAction)pasteFormatted:(id)sender;

//Custom dimming menus
- (IBAction)toggleFontTrait:(id)sender;
- (void)toggleToolbarShown:(id)sender;
- (void)runToolbarCustomizationPalette:(id)sender;

//Activation
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows;

//Private
- (void)initController;
- (void)closeController;
- (void)finishIniting;

@end

