/*
 *  AIInterfaceControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>
#import <Adium/AIPlugin.h>

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
#define KEY_CL_ANIMATE_CHANGES				@"Animate Changes"
#define KEY_CL_SHOW_TOOLTIPS				@"Show Tooltips"
#define KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND	@"Show Tooltips in Background"
#define KEY_CL_WINDOW_HAS_SHADOW			@"Window Has Shadow"

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

@protocol AIInterfaceComponent, AIContactListComponent, AIMessageDisplayController, AIMessageDisplayPlugin;
@protocol AIContactListTooltipEntry, AIFlashObserver;

@class AIListWindowController;

@class AIChat, AIListObject, AIListGroup;

@protocol AIInterfaceController <AIController>
- (void)registerInterfaceController:(id <AIInterfaceComponent>)inController;
- (void)registerContactListController:(id <AIContactListComponent>)inController;

/*!	@brief	Implement handling of the reopen Apple Event.
 *
 *	@par	The reopen handler should respond by making sure that at least one of Adium's windows is visible.
 *
 *	@par	Adium.app's implementation handles this event this way:
 *
 *	@li	If there are no chat windows, shows the Contact List.
 *	@li	Else, if the foremost chat window and chat tab has unviewed content, make sure it stays foremost (bringing it forward of the Contact List, if necessary).
 *	@li	Else, if any chat window has unviewed content, bring foremost the chat window and chat tab with the most recent unviewed content.
 *	@li	Else, if all chat windows are minimized, unminimize one of them.
 *	@li	If the application is hidden, unhide it.
 *
 *	@return	A value suitable for returning from the \c NSApplication delegate method <code>applicationShouldHandleReopen:hasVisibleWindows:
</code>. Specifically: \c YES if AppKit should perform its usual response to the event; \c NO if AppKit should do nothing.
 */
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows;

//Contact List
/*! @name Contact List */
/* @{ */
- (IBAction)showContactList:(id)sender;
- (IBAction)closeContactList:(id)sender;
- (BOOL)contactListIsVisibleAndMain;
- (BOOL)contactListIsVisible;
/*! @} */

//Detachable Contact List
- (AIListWindowController *)detachContactList:(AIListGroup *)aContactList;

//Messaging
- (void)openChat:(AIChat *)inChat;
- (id)openChat:(AIChat *)inChat inContainerWithID:(NSString *)containerID atIndex:(int)index;
- (void)moveChatToNewContainer:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (void)consolidateChats;
- (void)setActiveChat:(AIChat *)inChat;
- (AIChat *)activeChat;
- (AIChat *)mostRecentActiveChat;
- (NSArray *)openChats;
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID;
- (NSArray *)openContainers;
- (id)openContainerWithID:(NSString *)containerID name:(NSString *)containerName;

//Chat cycling
- (void)nextChat:(id)sender;
- (void)previousChat:(id)sender;

//Interface plugin callbacks
- (void)chatDidOpen:(AIChat *)inChat;
- (void)chatDidBecomeActive:(AIChat *)inChat;
- (void)chatDidBecomeVisible:(AIChat *)inChat inWindow:(NSWindow *)inWindow;
- (void)chatDidClose:(AIChat *)inChat;
- (void)chatOrderDidChange;
- (NSWindow *)windowForChat:(AIChat *)inChat;
- (AIChat *)activeChatInWindow:(NSWindow *)window;

//Interface selection
- (AIListObject *)selectedListObject;
- (AIListObject *)selectedListObjectInContactList;
- (NSArray *)arrayOfSelectedListObjectsInContactList;

//Message View
- (void)registerMessageDisplayPlugin:(id <AIMessageDisplayPlugin>)inPlugin;
- (id <AIMessageDisplayController>)messageDisplayControllerForChat:(AIChat *)inChat;

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
- (int)flashState;

//Tooltips
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary;
- (void)unregisterContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary;
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow;

//Window levels menu
- (NSMenu *)menuForWindowLevelsNotifyingTarget:(id)target;

@end

//Controls a contact list view
@protocol AIContactListViewController <NSObject>	
- (NSView *)contactListView;
@end

//Manages contact list view controllers
@protocol AIContactListController <NSObject>	
- (id <AIContactListViewController>)contactListViewController;
@end

/*!
 * @protocol AIMessageDisplayController
 * @brief    The message display controller is responsible for, unsurprisingly, the actual display of messages.
 *
 * The display controller manages a view ("messageView") which will be inserted along with other UI elements such
 * as a text entry area into a window.  The Interface Plugin knows nothing about how the AIMessageDisplayController 
 * keeps its messageView up to date, nor should it, but knows that the view will show messages.
 *
 * The AIMessageDisplayController is informed when the message view which is using it is closing.
 */
@protocol AIMessageDisplayController <NSObject>
- (NSView *)messageView;
- (NSView *)messageScrollView;
- (void)messageViewIsClosing;
- (void)clearView;
@end

/*
 * @protocol AIMessageDisplayPlugin
 * @brief    A AIMessageDisplayPlugin provides AIMessageDisplayController objects on demand.
 *
 * The WebKit display plugin is one example.
 */
@protocol AIMessageDisplayPlugin <NSObject, AIPlugin>	
- (id <AIMessageDisplayController>)messageDisplayControllerForChat:(AIChat *)inChat;
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

@protocol AIInterfaceComponent <NSObject>
- (void)openInterface;
- (void)closeInterface;
- (id)openChat:(AIChat *)chat inContainerWithID:(NSString *)containerID withName:(NSString *)containerName atIndex:(int)index;
- (void)setActiveChat:(AIChat *)inChat;
- (void)moveChat:(AIChat *)chat toContainerWithID:(NSString *)containerID index:(int)index;
- (void)moveChatToNewContainer:(AIChat *)inChat;
- (void)closeChat:(AIChat *)chat;
- (id)openContainerWithID:(NSString *)containerID name:(NSString *)containerName;
- (NSArray *)openContainersAndChats;
- (NSArray *)openContainers;
- (NSArray *)openChats;
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID;
- (NSString *)containerIDForChat:(AIChat *)chat;
- (NSWindow *)windowForChat:(AIChat *)chat;
- (AIChat *)activeChatInWindow:(NSWindow *)window;
@end

/*!
 * @protocol AIInterfaceContainer
 * @brief This protocol is for a general interface element such as the contact list or the container of a chat
 */
@protocol AIInterfaceContainer <NSObject>
- (void)makeActive:(id)sender;	//Make the container active/front
- (void)close:(id)sender;	//Close the container
@end

/*!
 * @brief AIChatWindow defines the protocol for an object which contains one or more AIChatContainers
 */
@protocol AIChatWindowController <NSObject>
/*
 * @brief Get an array of all the chats within this window controller's window.
 */
- (NSArray *)containedChats;

/*
 * @brief The window
 */
- (NSWindow *)window;
@end

/*!
 * @protocol AIChatContainer
 * @brief This protocol is for an object which displays a single chat (e.g. a tab in a chat window)
 */
@protocol AIChatContainer <AIInterfaceContainer>
/*
 * @brief Get the window controller which holds this AIChatContainer
 */
- (id <AIChatWindowController>)windowController;
@end

@protocol AIContactListComponent <NSObject>
- (void)showContactListAndBringToFront:(BOOL)bringToFront;
- (BOOL)contactListIsVisibleAndMain;
- (BOOL)contactListIsVisible;
- (void)closeContactList;
@end

@protocol AIMultiContactListComponent <AIContactListComponent>
- (id)detachContactList:(AIListGroup *)contactList;
- (void)nextDetachedContactList;
- (void)previousDetachedContactList;
- (unsigned)detachedContactListCount;
@end

//Custom printing informal protocol
@interface NSObject (AdiumPrinting)
- (void)adiumPrint:(id)sender;
- (BOOL)validatePrintMenuItem:(NSMenuItem *)menuItem;
@end

@interface NSWindowController (AdiumBorderlessWindowClosing)
- (BOOL)windowPermitsClose;
@end
