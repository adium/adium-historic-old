/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#define Interface_ShouldClearTextEntryView			@"Interface_ShouldClearTextEntryView"
#define Interface_ShouldDisplayErrorMessage			@"Interface_ShouldDisplayErrorMessage"
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
- (id)openChat:(AIChat *)chat inContainerNamed:(NSString *)containerName atIndex:(int)index;
- (void)closeChat:(AIChat *)chat;
- (void)setActiveChat:(AIChat *)inChat;
- (void)moveChat:(AIChat *)chat toContainerNamed:(NSString *)containerName index:(int)index;

- (NSArray *)openContainersAndChats;
- (NSArray *)openContainerNames;
- (NSArray *)openChats;
- (NSArray *)openChatsInContainerNamed:(NSString *)containerName;

- (NSString *)containerNameForChat:(AIChat *)chat;



@end

@class AIContactListWindowController, AIMenuController;

@interface AIInterfaceController : NSObject {
	IBOutlet	AIMenuController	*menuController;
    IBOutlet	AIAdium			*owner;
	
    IBOutlet	NSMenuItem		*menuItem_close;
    IBOutlet	NSMenuItem		*menuItem_closeChat;

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
	
    AIContactListWindowController 	*contactListWindowController;
	
	BOOL			closeMenuConfiguredForChat;
	
	NSArray		*_cachedOpenChats;
	
	NSMutableArray	*windowMenuArray;
	
	AIChat	*activeChat;
	
	
	
	id <AIInterfaceController> interface;
	
	
	BOOL	groupChatsByContactGroup;
	BOOL	arrangeChats;
	
	
}

- (void)registerInterfaceController:(id <AIInterfaceController>)inController;
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows;

//Contact List
- (void)registerContactListViewPlugin:(id <AIContactListViewPlugin>)inPlugin;
- (id <AIContactListViewController>)contactListViewController;
- (IBAction)toggleContactList:(id)sender;
- (IBAction)showContactList:(id)sender;
- (IBAction)showContactListAndBringToFront:(id)sender;
- (IBAction)closeContactList:(id)sender;
- (void)contactListDidClose;

//Messaging
- (void)openChat:(AIChat *)inChat;
- (void)setActiveChat:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (AIChat *)activeChat;
- (NSArray *)openChats;
- (NSArray *)openChatsInContainerNamed:(NSString *)containerName;
- (BOOL)allowChatOrdering;
- (BOOL)allowChatGrouping;
- (int)indexForInsertingChat:(AIChat *)chat intoContainerNamed:(NSString *)containerName;

//Interface plugin callbacks
- (void)chatDidOpen:(AIChat *)inChat;
- (void)chatDidBecomeActive:(AIChat *)inChat;
- (void)chatDidClose:(AIChat *)inChat;
- (void)chatOrderDidChange;
- (void)clearUnviewedContentOfChat:(AIChat *)inChat;

//Chat close menus
- (IBAction)closeMenu:(id)sender;
- (IBAction)closeChatMenu:(id)sender;
- (void)updateCloseMenuKeys;

//Window Menu
- (IBAction)showChatWindow:(id)sender;
- (void)updateActiveWindowMenuItem;
- (void)buildWindowMenu;

//Chat Cycling
- (IBAction)nextMessage:(id)sender;
- (IBAction)previousMessage:(id)sender;

//Message View
- (void)registerMessageViewPlugin:(id <AIMessageViewPlugin>)inPlugin;
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat;

//Error Display
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc;
- (void)handleMessage:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle;

//Synchronized Flashing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver;
- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver;
- (void)flashTimer:(NSTimer *)inTimer;
- (int)flashState;

//Tooltips
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary;
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow;

//Custom pasting
- (IBAction)paste:(id)sender;
- (IBAction)pasteFormatted:(id)sender;

//Custom Dimming menu items
- (IBAction)toggleFontTrait:(id)sender;
- (void)toggleToolbarShown:(id)sender;
- (void)runToolbarCustomizationPalette:(id)sender;

//Private
- (void)initController;
- (void)finishIniting;
- (void)closeController;

@end

