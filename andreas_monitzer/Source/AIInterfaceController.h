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

#define Interface_ContactSelectionChanged			@"Interface_ContactSelectionChanged"
#define Interface_SendEnteredMessage				@"Interface_SendEnteredMessage"
#define Interface_WillSendEnteredMessage 			@"Interface_WillSendEnteredMessage"
#define Interface_DidSendEnteredMessage				@"Interface_DidSendEnteredMessage"
#define Interface_ShouldDisplayErrorMessage			@"Interface_ShouldDisplayErrorMessage"
#define Interface_ShouldDisplayQuestion				@"Interface_ShouldDisplayQuestion"
#define Interface_ContactListDidBecomeMain			@"Interface_ContactListDidBecomeMain"
#define Interface_ContactListDidResignMain			@"Interface_contactListDidResignMain"
#define Interface_ContactListDidClose				@"Interface_contactListDidClose"
#define Interface_TabArrangingPreferenceChanged		@"Interface_TabArrangingPreferenceChanged"
#define AIViewDesiredSizeDidChangeNotification		@"AIViewDesiredSizeDidChangeNotification"

#define PREF_GROUP_INTERFACE			@"Interface"
#define KEY_TABBED_CHATTING				@"Tabbed Chatting"
#define KEY_GROUP_CHATS_BY_GROUP		@"Group Chats By Group"

#define PREF_GROUP_CONTACT_LIST				@"Contact List"
#define KEY_CL_WINDOW_LEVEL					@"Window Level"
#define KEY_CL_HIDE							@"Hide While in Background"
#define KEY_CL_EDGE_SLIDE					@"Hide On Screen Edges"
#define KEY_CL_FLASH_UNVIEWED_CONTENT		@"Flash Unviewed Content"
#define KEY_CL_SHOW_TRANSITIONS				@"Show Transitions"
#define KEY_CL_SHOW_TOOLTIPS				@"Show Tooltips"
#define KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND	@"Show Tooltips in Background"
#define KEY_CL_WINDOW_HAS_SHADOW			@"Window Has Shadow"

#define CONTACT_LIST_TITLE					AILocalizedString(@"Contact List","Name of the window which lists contacts")

@class AIMenuController , AIChat, AIListObject;

@protocol AIController;

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
- (void)setAttributedString:(NSAttributedString *)inAttributedString;
- (void)setTypingAttributes:(NSDictionary *)attrs;
- (BOOL)availableForSending;
- (AIChat *)chat;
@end

@protocol AIInterfaceController <NSObject>
- (void)openInterface;
- (void)closeInterface;
- (id)openChat:(AIChat *)chat inContainerWithID:(NSString *)containerName atIndex:(int)index;
//- (AIChat *)activeChat;
- (void)setActiveChat:(AIChat *)inChat;
- (void)moveChat:(AIChat *)chat toContainerWithID:(NSString *)containerID index:(int)index;
- (void)closeChat:(AIChat *)chat;
- (NSArray *)openContainersAndChats;
- (NSArray *)openContainers;
- (NSArray *)openChats;
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID;
- (NSString *)containerIDForChat:(AIChat *)chat;
- (NSWindow *)windowForChat:(AIChat *)chat;
- (AIChat *)activeChatInWindow:(NSWindow *)window;
@end

@protocol AIContactListController <NSObject>
- (void)showContactListAndBringToFront:(BOOL)bringToFront;
- (BOOL)contactListIsVisibleAndMain;
- (void)closeContactList;
@end

typedef enum {
	AINormalWindowLevel = 0,
	AIFloatingWindowLevel = 1,
	AIDesktopWindowLevel = 2
} AIWindowLevel;

//Identifiers for the various message views
typedef enum {
	DCStandardMessageView = 1,	//webkit is not available
	DCWebkitMessageView			//Preferred message view
} DCMessageViewType;

@interface AIInterfaceController : NSObject <AIController> {
	IBOutlet	AIMenuController	*menuController;
    IBOutlet	AIAdium			*adium;
	
    IBOutlet	NSMenuItem		*menuItem_close;
    IBOutlet	NSMenuItem		*menuItem_closeChat;
	IBOutlet	NSMenuItem		*menuItem_closeAllChats;

    IBOutlet	NSMenuItem		*menuItem_paste;
    IBOutlet	NSMenuItem		*menuItem_pasteAndMatchStyle;
    
    IBOutlet    NSMenuItem      *menuItem_bold;
    IBOutlet    NSMenuItem      *menuItem_italic;

	IBOutlet    NSMenuItem      *menuItem_showToolbar;
	IBOutlet    NSMenuItem      *menuItem_customizeToolbar;

	IBOutlet	NSMenuItem		*menuItem_print;
	
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
	
	BOOL						closeMenuConfiguredForChat;
	
	NSArray						*_cachedOpenChats;
	
	NSMutableArray				*windowMenuArray;
	
	AIChat						*activeChat;
	AIChat						*mostRecentActiveChat;
	
	BOOL						tabbedChatting;
	
	id <AIInterfaceController>	interfacePlugin;
	id <AIContactListController> contactListPlugin;
		
	BOOL						groupChatsByContactGroup;
	
	IBOutlet NSView				*fontPanelAccessoryView;
	IBOutlet NSButton			*button_fontPanelSetAsDefault;
}

- (void)registerInterfaceController:(id <AIInterfaceController>)inController;
- (void)registerContactListController:(id <AIContactListController>)inController;
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows;

//Contact List
- (IBAction)toggleContactList:(id)sender;
- (IBAction)showContactList:(id)sender;
- (IBAction)showContactListAndBringToFront:(id)sender;
- (IBAction)closeContactList:(id)sender;

//Messaging
- (void)openChat:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (void)consolidateChats;
- (void)setActiveChat:(AIChat *)inChat;
- (AIChat *)activeChat;
- (NSArray *)openChats;
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID;

//Interface plugin callbacks
- (void)chatDidOpen:(AIChat *)inChat;
- (void)chatDidBecomeActive:(AIChat *)inChat;
- (void)chatDidBecomeVisible:(AIChat *)inChat inWindow:(NSWindow *)inWindow;
- (void)chatDidClose:(AIChat *)inChat;
- (void)chatOrderDidChange;
- (NSWindow *)windowForChat:(AIChat *)inChat;
- (AIChat *)activeChatInWindow:(NSWindow *)window;

//Chat close menus
- (IBAction)closeMenu:(id)sender;
- (IBAction)closeChatMenu:(id)sender;
- (IBAction)closeAllChats:(id)sender;
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

//Question Display
- (void)displayQuestion:(NSString *)inTitle withAttributedDescription:(NSAttributedString *)inDesc withWindowTitle:(NSString *)inWindowTitle
		  defaultButton:(NSString *)inDefaultButton alternateButton:(NSString *)inAlternateButton otherButton:(NSString *)inOtherButton
				 target:(id)inTarget selector:(SEL)inSelector userInfo:(id)inUserInfo;
- (void)displayQuestion:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle
		  defaultButton:(NSString *)inDefaultButton alternateButton:(NSString *)inAlternateButton otherButton:(NSString *)inOtherButton
				 target:(id)inTarget selector:(SEL)inSelector userInfo:(id)inUserInfo;

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
- (IBAction)pasteAndMatchStyle:(id)sender;
- (IBAction)pasteWithImagesAndColors:(id)sender;

//Custom printing
- (IBAction)adiumPrint:(id)sender;

//Font panel
- (IBAction)showFontPanel:(id)sender;
- (IBAction)setFontPanelSettingsAsDefaultFont:(id)sender;

//Custom Dimming menu items
- (IBAction)toggleFontTrait:(id)sender;
- (void)toggleToolbarShown:(id)sender;
- (void)runToolbarCustomizationPalette:(id)sender;

//Window levels menu
- (NSMenu *)menuForWindowLevelsNotifyingTarget:(id)target;

- (IBAction)showPreferenceWindow:(id)sender;

@end

//Custom printing informal protocol
@interface NSObject (AdiumPrinting)
- (void)adiumPrint:(id)sender;
- (BOOL)validatePrintMenuItem:(id <NSMenuItem>)menuItem;
@end
