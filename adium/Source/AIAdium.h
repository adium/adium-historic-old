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

@class AILoginController, AIAccountController, AIInterfaceController, AIContactController, AIPluginController, AIPreferenceController, AIPreferencePane, AIMenuController, AILoginWindowController, AIAccountWindowController, AIAccount, AIMessageObject, AIServiceType, AIPreferenceCategory, AIContactInfoView, AIMiniToolbar, AIAnimatedView, AIContentController, AIToolbarController, AIContactInfoViewController, AIPreferenceViewController, AISoundController, AIDockController, AIHandle, AIListContact, AIListGroup, AIListObject, AIIconState, AIContactListGeneration, AIChat, AIContentObject, ESFileTransferController, ESFileTransfer, ESContactAlertsController, ESContactAlert, AIMutableOwnerArray;
#ifdef MAC_OS_X_VERSION_10_0
@class SUSpeaker;
#endif

@interface AIAdium : NSObject {

    IBOutlet	AIMenuController            *menuController;
    IBOutlet	AILoginController           *loginController;
    IBOutlet	AIAccountController         *accountController;
    IBOutlet	AIInterfaceController       *interfaceController;
    IBOutlet	AIContactController         *contactController;
    IBOutlet	AIContentController         *contentController;
    IBOutlet	AIPluginController          *pluginController;
    IBOutlet	AIPreferenceController      *preferenceController;
    IBOutlet	AIToolbarController         *toolbarController;
    IBOutlet	AISoundController           *soundController;
    IBOutlet	AIDockController            *dockController;
    IBOutlet    ESFileTransferController    *fileTransferController;
    IBOutlet    ESContactAlertsController   *contactAlertsController;
    
    NSNotificationCenter                    *notificationCenter;
    NSMutableDictionary                     *eventNotifications;
}


+ (NSString *)applicationSupportDirectory;
- (AILoginController *)loginController;
- (AIAccountController *)accountController;
- (AIContactController *)contactController;
- (AIContentController *)contentController;
- (AISoundController *)soundController;
- (AIInterfaceController *)interfaceController;
- (AIPreferenceController *)preferenceController;
- (AIMenuController *)menuController;
- (AIDockController *)dockController;
- (ESFileTransferController *)fileTransferController;
- (ESContactAlertsController *)contactAlertsController;

- (NSNotificationCenter *)notificationCenter;
- (void)registerEventNotification:(NSString *)inNotification displayName:(NSString *)displayName;
- (NSDictionary *)eventNotifications;

- (IBAction)showAboutBox:(id)sender;
- (IBAction)confirmQuit:(id)sender;


@end

// Public core controller typedefs and defines --------------------------------------------------
typedef enum {
    LOC_Adium_About, LOC_Adium_Preferences,
    LOC_File_New, LOC_File_Close, LOC_File_Save, LOC_File_Accounts, LOC_File_Additions, LOC_File_Status,
    LOC_Edit_Additions,
    LOC_Format_Styles, LOC_Format_Palettes, LOC_Format_Additions, 
    LOC_Window_Commands, LOC_Window_Auxilary, LOC_Window_Fixed,
    LOC_Help_Local, LOC_Help_Web, LOC_Help_Additions,
    LOC_Contact_Manage, LOC_Contact_Action, LOC_Contact_NegativeAction, LOC_Contact_Additions,
    LOC_Dock_Status
} MENU_LOCATION;

typedef enum {
    Context_Contact_Manage, Context_Contact_Action, Context_Contact_NegativeAction, Context_Contact_Additions    
} CONTEXT_MENU_LOCATION;

typedef enum {
    AISortGroup = 0,
    AISortGroupAndSubGroups,
    AISortGroupAndSuperGroups
} AISortMode;

typedef enum {
    BOUNCE_NONE = 0,
    BOUNCE_ONCE,
    BOUNCE_REPEAT,
    BOUNCE_DELAY5,
    BOUNCE_DELAY10,
    BOUNCE_DELAY15,
    BOUNCE_DELAY30,
    BOUNCE_DELAY60
} DOCK_BEHAVIOR;

//Preference Categories
typedef enum {
    //Temporary, for transition only
    AIPref_Accounts = 0, 
    AIPref_ContactList_General,
    AIPref_ContactList_Groups,
    AIPref_ContactList_Contacts,
    AIPref_Messages_Display,
    AIPref_Messages_Sending,
    //AIPref_Messages_Receiving,
    AIPref_Status_Away,
    AIPref_Status_Idle,
    AIPref_Dock,
    AIPref_Sound,
    AIPref_Emoticons,
    AIPref_Alerts,
    
/*    AIPref_Accounts = 0,
    AIPref_ContactList,
    AIPref_Messages,
    AIPref_Sound,
    AIPref_Alerts,*/
    AIPref_Advanced_ContactList,
    AIPref_Advanced_Messages,
    AIPref_Advanced_Status,
    AIPref_Advanced_Other
    

} PREFERENCE_CATEGORY;

//File transfers
typedef enum {
    Incoming_FileTransfer = 0,
    Outgoing_FileTransfer,
    Unknown_FileTransfer
} FileTransferType;

//Preference groups
#define PREF_GROUP_GENERAL 		@"General"
#define PREF_GROUP_ACCOUNTS	 	@"Accounts"
#define PREF_GROUP_TOOLBARS 		@"Toolbars"
#define PREF_GROUP_WINDOW_POSITIONS 	@"Window Positions"
#define PREF_GROUP_SPELLING 		@"Spelling"

//Adium events
#define KEY_EVENT_DISPLAY_NAME		@"DisplayName"
#define KEY_EVENT_NOTIFICATION		@"Notification"

//Sound Controller
#define	KEY_SOUND_SET			@"Set"
#define	KEY_SOUND_SET_CONTENTS		@"Sounds"
#define KEY_SOUND_MUTE			@"Mute Sounds"
#define KEY_SOUND_TEMPORARY_MUTE        @"Mute Sounds Temporarily"
#define KEY_SOUND_USE_CUSTOM_VOLUME	@"Use Custom Volume"
#define KEY_SOUND_CUSTOM_VOLUME_LEVEL	@"Custom Volume Level"

//Dock Controller
#define KEY_ACTIVE_DOCK_ICON		@"Dock Icon"
#define FOLDER_DOCK_ICONS		@"Dock Icons"

//
#define AIViewDesiredSizeDidChangeNotification			@"AIViewDesiredSizeDidChangeNotification"

//Adium Notifications
#define Account_ListChanged 					@"Account_ListChanged"
#define Account_PropertiesChanged				@"Account_PropertiesChanged"
#define Account_HandlesChanged					@"Account_HandlesChanged"
#define ListObject_AttributesChanged				@"ListObject_AttributesChanged"
#define ListObject_StatusChanged				@"ListObject_StatusChanged"
#define Contact_OrderChanged					@"Contact_OrderChanged"
#define Contact_ListChanged					@"Contact_ListChanged"
#define Contact_SortSelectorListChanged				@"Contact_SortSelectorListChanged"


#define Contact_UpdateStatus					@"Contact_UpdateStatus"
//Whenever possible, accounts should keep their contact's status up to date.  However, sometimes this ideal situation cannot be achieved, and the account needs to be told when 'more expensive' status keys are required so it can fetch them.  This notification instructs the accounts to do just that.  It is currently used for profiles, but may be used for more information in the future.

#define Interface_ContactSelectionChanged			@"Interface_ContactSelectionChanged"
#define Interface_SendEnteredMessage				@"Interface_SendEnteredMessage"
#define Interface_WillSendEnteredMessage 			@"Interface_WillSendEnteredMessage"
#define Interface_DidSendEnteredMessage				@"Interface_DidSendEnteredMessage"
#define Interface_ErrorMessageReceived				@"Interface_ErrorMessageRecieved"
#define Content_ContentObjectAdded				@"Content_ContentObjectAdded"
#define Content_WillSendContent					@"Content_WillSendContent"
#define Content_DidSendContent					@"Content_DidSendContent"
#define Content_WillReceiveContent				@"Content_WillReceiveContent"
#define Content_DidReceiveContent				@"Content_DidReceiveContent"
#define Content_FirstContentRecieved				@"Content_FirstContentRecieved"
#define Content_ChatStatusChanged				@"Content_ChatStatusChanged"
#define Content_ChatParticipatingListObjectsChanged		@"Content_ChatParticipatingListObjectsChanged"
#define Preference_GroupChanged					@"Preference_GroupChanged"
#define Preference_WindowWillOpen				@"Preference_WindowWillOpen"
#define Preference_WindowDidClose				@"Preference_WindowDidClose"
#define Dock_IconWillChange					@"Dock_IconWillChange"
#define Dock_IconDidChange					@"Dock_IconDidChange"

// Public core controller protocols ------------------------------------------------------------
@protocol AIListObjectObserver //notified of changes
    - (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent;
@end

@protocol AIAutoSizingView //Sends Interface_ViewDesiredSizeDidChange notifications
    - (NSSize)desiredSize;
@end

@protocol AIListObjectLeftView //Draws to the left of a handle
    - (void)drawInRect:(NSRect)inRect;
    - (float)widthForHeight:(int)inHeight;
@end

@protocol AIListObjectRightView //Draws to the right of a handle

@end

@protocol AIContactListViewController <NSObject>	//Controls a contact list view
- (NSView *)contactListView;
@end

@protocol AIContactListViewPlugin <NSObject>	//Manages contact list view controllers
- (id <AIContactListViewController>)contactListViewController;
@end

@protocol AIMessageViewController <NSObject>
- (NSView *)messageView;
@end

@protocol AIMessageViewPlugin <NSObject>	//manages message view controllers
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat;
@end

@protocol AITextEntryView //Handles any attributed text entry
- (NSAttributedString *)attributedString;
- (void)setAttributedString:(NSAttributedString *)inAttributedString;
- (void)setTypingAttributes:(NSDictionary *)attrs;
- (BOOL)availableForSending;
- (AIChat *)chat;
@end

@protocol AIContentHandler //Handles the display of a content type

@end

@protocol AIContentFilter
- (void)filterContentObject:(AIContentObject *)inObject;
@end

@protocol AIServiceController <NSObject>
- (NSString *)identifier;
- (NSString *)description;
- (AIServiceType *)handleServiceType;
- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner;
@end

@protocol AIAccountViewController <NSObject>
- (NSView *)view;
- (NSArray *)auxilaryTabs;
- (void)configureViewAfterLoad;
@end

@protocol AIListSortController <NSObject>
- (NSString *)identifier;
- (NSString *)description;
- (NSString *)displayName;
- (void)sortListObjects:(NSMutableArray *)inObjects;
- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys;
- (BOOL)shouldSortForModifiedAttributeKeys:(NSArray *)inModifiedKeys;
@end

@protocol AIInterfaceController <NSObject>
- (void)openInterface;
- (void)closeInterface;
- (void)initiateNewMessage;
- (void)openChat:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (void)setActiveChat:(AIChat *)inChat;
@end

@protocol AIFlashObserver <NSObject>
- (void)flash:(int)value;
@end

@protocol AIContactListTooltipEntry <NSObject>
- (NSString *)labelForObject:(AIListObject *)inObject;
- (NSAttributedString *)entryForObject:(AIListObject *)inObject;
@end

//A contact alert provider performs contact alert actions and provides ESContactAlert instances as required for the contact alert UI
@protocol ESContactAlertProvider <NSObject>
- (NSString *)identifier;
- (ESContactAlert *)contactAlert;

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName;

- (BOOL)shouldKeepProcessing;
@end


@interface NSObject (AITextEntryFilter)
//required
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; 
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
//optional
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; //keypress
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; //delete,copy,paste,etc
@end


// Public core controller methods ------------------------------------------------------------
//*** Login ***//
@interface AILoginController : NSObject{
    IBOutlet	AIAdium		*owner;
    
    NSString			*currentUser;		//The current logged in username
    NSString			*userDirectory;		//The current user's Adium home directory
    AILoginWindowController	*loginWindowController;	//The login select window
    id				target;			//Used to send our owner a 'login complete'
    SEL				selector;		//
}

- (NSString *)userDirectory;
- (NSString *)currentUser;
- (void)switchUsers;

@end

//*** Account ***//
@interface AIAccountController : NSObject{
    IBOutlet	AIAdium		*owner;	

    NSMutableArray		*accountArray;			//Array of active accounts
    NSMutableArray		*availableServiceArray;
    NSMutableDictionary		*lastAccountIDToSendContent;
    NSMutableDictionary		*accountStatusDict;

    NSMutableArray		*sleepingOnlineAccounts;
}

//Access to the account list
- (NSArray *)accountArray;
- (AIAccount *)accountWithID:(NSString *)inID;
- (AIAccount *)accountForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject;

//Managing accounts
- (AIAccount *)newAccountAtIndex:(int)index;
- (void)deleteAccount:(AIAccount *)inAccount;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService;
- (void)connectAllAccounts;
- (void)disconnectAllAccounts;

//Account properties
- (void)setProperty:(id)inValue forKey:(NSString *)key account:(AIAccount *)inAccount;
- (id)propertyForKey:(NSString *)key account:(AIAccount *)inAccount;

//Account password storage
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;
- (NSString *)passwordForAccount:(AIAccount *)inAccount;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;

//Access to services
- (void)registerService:(id <AIServiceController>)inService;
- (NSArray *)availableServiceArray;

@end

//*** Content ***//
@interface AIContentController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSMutableArray		*outgoingContentFilterArray;
    NSMutableArray		*incomingContentFilterArray;
    NSMutableArray		*displayingContentFilterArray;

    NSMutableArray		*textEntryFilterArray;
    NSMutableArray		*textEntryContentFilterArray;
    NSMutableArray		*textEntryViews;

    NSMutableArray		*chatArray;
}

//Chats
- (NSArray *)allChatsWithListObject:(AIListObject *)inObject;
- (AIChat *)openChatOnAccount:(AIAccount *)inAccount withListObject:(AIListObject *)inListObject;
- (void)noteChat:(AIChat *)inChat forAccount:(AIAccount *)inAccount;
- (BOOL)closeChat:(AIChat *)inChat;
- (NSArray *)chatArray;

//Sending / Receiving content
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject onAccount:(AIAccount *)inAccount;
- (void)addIncomingContentObject:(AIContentObject *)inObject;
- (BOOL)sendContentObject:(AIContentObject *)inObject;
- (void)displayContentObject:(AIContentObject *)inObject;

//Filtering / Tracking text entry
- (void)registerTextEntryFilter:(id)inFilter;
- (NSArray *)openTextEntryViews;
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;

//Filtering content
- (void)registerOutgoingContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterOutgoingContentFilter:(id <AIContentFilter>)inFilter;
- (void)registerIncomingContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterIncomingContentFilter:(id <AIContentFilter>)inFilter;
- (void)registerDisplayingContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterDisplayingContentFilter:(id <AIContentFilter>)inFilter;
- (void)filterObject:(AIContentObject *)inObject isOutgoing:(BOOL)isOutgoing;
- (NSAttributedString *)filteredAttributedString:(NSAttributedString *)inString;

@end

//*** Contact ***//
@interface AIContactController : NSObject {
    IBOutlet	AIAdium		*owner;

    AIListGroup			*contactList;
    AIListGroup			*strangerGroup;
    NSMutableArray		*contactObserverArray;

    NSTimer			*delayedUpdateTimer;
    int				delayedUpdates;

    NSMutableArray		*sortControllerArray;
    id<AIListSortController> 	activeSortController;

    AIPreferenceCategory	*contactInfoCategory;

    NSMenuItem			*menuItem_getInfo;

    NSMutableDictionary		*listOrderDict;
    NSMutableDictionary		*reverseListOrderDict;
    NSMutableDictionary         *delayedDict;
    int				largestOrder;

    AIContactListGeneration	*contactListGeneration;    
}

//Account available handles changed
- (void)handlesChangedForAccount:(AIAccount *)inAccount;
- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount;
- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount;

//Contact list access
- (AIListGroup *)contactList;
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(NSString *)serviceID UID:(NSString *)UID;
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(NSString *)serviceID UID:(NSString *)UID serverGroup:(NSString *)serverGroup;
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(NSString *)serviceID UID:(NSString *)UID serverGroup:(NSString *)serverGroup create:(BOOL)create;
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups;
- (AIListGroup *)groupInGroup:(AIListGroup *)inGroup withUID:(NSString *)UID;

//Contact status & Attributes
- (void)handleStatusChanged:(AIHandle *)inHandle modifiedStatusKeys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent;
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent;
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver;
- (void)unregisterListObjectObserver:(id)inObserver;
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed;

//Contact list sorting
- (NSArray *)sortControllerArray;
- (void)registerListSortController:(id <AIListSortController>)inController;
- (void)setActiveSortController:(id <AIListSortController>)inController;
- (id <AIListSortController>)activeSortController;
- (void)sortListGroup:(AIListGroup *)inGroup mode:(AISortMode)sortMode;

//Contact info
- (IBAction)showContactInfo:(id)sender;
- (void)showInfoForContact:(AIListContact *)inContact;
- (void)addContactInfoView:(AIPreferenceViewController *)inView;

//Interface selection
- (AIListContact *)selectedContact;

//Contact ordering
- (float)orderIndexOfContact:(AIListContact *)contact;
- (float)orderIndexOfGroup:(AIListGroup *)group;
- (float)orderIndexOfKey:(NSString *)key;
- (float)setOrderIndexOfContactWithServiceID:(NSString *)serviceID UID:(NSString *)UID to:(float)index;
- (float)setOrderIndexOfGroupWithUID:(NSString *)UID to:(float)index;
        
@end

//*** Interface ***//
@interface AIInterfaceController : NSObject {
    IBOutlet	AIAdium		*owner;

    IBOutlet	NSMenuItem	*menuItem_paste;
    IBOutlet	NSMenuItem	*menuItem_pasteFormatted;
    
    IBOutlet    NSMenuItem      *menuItem_bold;
    IBOutlet    NSMenuItem      *menuItem_italic;

    NSMutableArray		*contactListViewArray;
    NSMutableArray		*messageViewArray;
    NSMutableArray		*interfaceArray;
    NSMutableArray		*contactListTooltipEntryArray;
    NSMutableArray              *contactListTooltipSecondaryEntryArray;
    float                       maxLabelWidth;
    
    NSMutableArray		*flashObserverArray;
    NSTimer			*flashTimer;
    int				flashState;
    AIListObject		*tooltipListObject;
    NSMutableAttributedString   *tooltipBody;
    NSMutableAttributedString   *tooltipTitle;
    NSImage                     *tooltipImage;

    NSString			*errorTitle;
    NSString			*errorDesc;

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
- (void)showTooltipForListObject:(AIListObject *)object atPoint:(NSPoint)point;
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary;

//Custom pasting
- (IBAction)paste:(id)sender;
- (IBAction)pasteFormatted:(id)sender;

//Custom font menus
- (IBAction)toggleFontTrait:(id)sender;

@end

//*** Plugin ***//
@interface AIPluginController : NSObject {
    IBOutlet	AIAdium		*owner;
    NSMutableArray		*pluginArray;
}

@end

//*** Preference ***//
@interface AIPreferenceController : NSObject {
    IBOutlet	AIAdium			*owner;

    NSMutableArray			*paneArray;		//An array of preference panes
    NSMutableDictionary			*groupDict;		//A dictionary of pref dictionaries
}

//Preference window
- (IBAction)showPreferenceWindow:(id)sender;
- (void)openPreferencesToPane:(AIPreferencePane *)inPane;

//Preference views
- (void)addPreferencePane:(AIPreferencePane *)inPane;

//Defaults and access to preferencecs
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)groupName;
- (NSDictionary *)preferencesForGroup:(NSString *)groupName;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName objectKey:(NSString *)prefDictKey;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName objectKey:(NSString *)prefDictKey;

@end

//*** Menu ***//
@interface AIMenuController : NSObject {
    IBOutlet	AIAdium		*owner;

    IBOutlet	NSMenuItem	*nilMenuItem;
    IBOutlet	NSMenuItem	*menu_Adium_About;
    IBOutlet	NSMenuItem	*menu_Adium_Preferences;
    IBOutlet	NSMenuItem	*menu_File_New;
    IBOutlet	NSMenuItem	*menu_File_Close;
    IBOutlet	NSMenuItem	*menu_File_Save;
    IBOutlet	NSMenuItem	*menu_File_Accounts;
    IBOutlet	NSMenuItem	*menu_File_Additions;
    IBOutlet	NSMenuItem	*menu_File_Status;
    IBOutlet	NSMenuItem	*menu_Edit_Bottom;
    IBOutlet	NSMenuItem	*menu_Edit_Additions;
    IBOutlet	NSMenuItem	*menu_Format_Styles;
    IBOutlet	NSMenuItem	*menu_Format_Palettes;
    IBOutlet	NSMenuItem	*menu_Format_Additions;
    IBOutlet	NSMenuItem	*menu_Window_Top;
    IBOutlet	NSMenuItem	*menu_Window_Commands;
    IBOutlet	NSMenuItem	*menu_Window_Auxilary;
    IBOutlet	NSMenuItem	*menu_Window_Fixed;
    IBOutlet	NSMenuItem	*menu_Help_Local;
    IBOutlet	NSMenuItem	*menu_Help_Web;
    IBOutlet	NSMenuItem	*menu_Help_Additions;
    IBOutlet	NSMenuItem	*menu_Contact_Manage;
    IBOutlet	NSMenuItem	*menu_Contact_Action;
    IBOutlet	NSMenuItem	*menu_Contact_NegativeAction;
    IBOutlet	NSMenuItem	*menu_Contact_Additions;
    IBOutlet	NSMenuItem	*menu_Dock_Status;
        
    NSMutableArray		*locationArray;

    NSMenu			*contextualMenu;
    NSMutableDictionary		*contextualMenuItemDict;

    AIListContact		*contactualMenuContact;
}

//Custom menu items
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location;
- (void)removeMenuItem:(NSMenuItem *)targetItem;

//Contextual menu items
- (void)addContextualMenuItem:(NSMenuItem *)newItem toLocation:(CONTEXT_MENU_LOCATION)location;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forContact:(AIListContact *)inContact;
- (AIListContact *)contactualMenuContact;

@end

//*** Sound ***//
@interface AISoundController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSMutableDictionary	*soundCacheDict;
    NSMutableArray	*soundCacheArray;
    BOOL		useCustomVolume;
    BOOL		muteSounds;
    int			customVolume;

    int			activeSoundThreads;
    BOOL		soundThreadActive;

    NSLock		*soundLock;

    NSMutableArray 	*speechArray;
    NSArray		*voiceArray;
    BOOL		resetNextTime;
    BOOL		speaking;
    int                 defaultRate;
    int                 defaultPitch;
    

#ifdef MAC_OS_X_VERSION_10_0
    SUSpeaker		*speaker_variableVoice;
    SUSpeaker		*speaker_defaultVoice;    
#endif

}

//Sounds
- (void)playSoundNamed:(NSString *)inName;
- (void)playSoundAtPath:(NSString *)inPath;
- (NSArray *)soundSetArray;
- (void)speakText:(NSString *)text;
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString andPitch:(float)pitch andRate:(int)rate;
- (NSArray *)voices;
- (int)defaultRate;
- (int)defaultPitch;
@end

//*** Toolbar ***//
@interface AIToolbarController : NSObject {
    IBOutlet	AIAdium		*owner;
}

@end

//*** Dock ***//
@interface AIDockController: NSObject <AIFlashObserver> {
    IBOutlet	AIAdium 	*owner;

    NSTimer 			*animationTimer;
    NSTimer			*bounceTimer;
    
    NSMutableDictionary		*availableIconStateDict;
    NSMutableDictionary		*availableDynamicIconStateDict;
    NSMutableArray		*activeIconStateArray;
    AIIconState			*currentIconState;
    
    int				currentAttentionRequest;

    BOOL			observingFlash;
    BOOL			needsDisplay;
}

//Icon animation & states
- (void)setIconStateNamed:(NSString *)inName;
- (void)removeIconStateNamed:(NSString *)inName;
- (void)setIconState:(AIIconState *)iconState named:(NSString *)inName;
- (float)dockIconScale;

//Special access to icon pack loading
- (NSMutableDictionary *)iconPackAtPath:(NSString *)folderPath;

//Bouncing & behavior
- (void)performBehavior:(DOCK_BEHAVIOR)behavior;

@end

//*** File transfer ***//
@interface ESFileTransferController : NSObject {

}

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)beganFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)transferCanceled:(ESFileTransfer *)fileTransfer;
@end

//*** Contact Alerts ***//
//ESContactAlerts is the UI conduit to the stored actions; plugins do not need to access, create, or implement ESContactAlerts
@protocol ESContactAlerts <NSObject>
- (void)configureWithSubview:(NSView *)view_inView;
@end

@interface ESContactAlertsController : NSObject <AIListObjectObserver> {
    IBOutlet            AIAdium		*owner;
    NSMutableDictionary                 *contactAlertProviderDictionary;
    AIMutableOwnerArray                 *arrayOfStateDictionaries;
    AIMutableOwnerArray                 *arrayOfAlertsArrays;
    
    NSMutableArray                      *completedActionTypes;
}
//
- (void)registerContactAlertProvider:(id <ESContactAlertProvider>)contactAlertProvider;
- (void)unregisterContactAlertProvider:(id <ESContactAlertProvider>)contactAlertProvider;
//
- (void)createAlertsArrayWithOwner:(id <ESContactAlerts>)inOwner;
- (void)destroyAlertsArrayWithOwner:(id <ESContactAlerts>)inOwner;
//
- (void)configureWithSubview:(NSView *)inView forContactAlert:(ESContactAlert *)contactAlert;
- (NSMutableArray *)eventActionArrayForContactAlert:(ESContactAlert *)contactAlert;
- (NSDictionary *)currentDictForContactAlert:(ESContactAlert *)contactAlert;
- (AIListObject *)currentObjectForContactAlert:(ESContactAlert *)contactAlert;
- (int)rowForContactAlert:(ESContactAlert *)contactAlert;
- (void)saveEventActionArrayForContactAlert:(ESContactAlert *)contactAlert;
//
- (NSMenu *)actionListMenuWithOwner:(id <ESContactAlerts>)owner;
- (void)updateOwner:(id <ESContactAlerts>)inOwner toArray:(NSArray *)eventActionArray forObject:(AIListObject *)inObject;
- (void)updateOwner:(id <ESContactAlerts>)inOwner toRow:(int)row;
//list object observer
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent;
@end


