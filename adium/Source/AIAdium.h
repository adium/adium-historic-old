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

@class AILoginController, AIAccountController, AIInterfaceController, AIContactController, AIPluginController, AIPreferenceController, AIPreferenceView, AIMenuController, AILoginWindowController, AIAccountWindowController, AIAccount, AIMessageObject, AIServiceType, AIPreferenceCategory, AIContactInfoView, AIMiniToolbar, AIAnimatedView, AIContentController, AIToolbarController, AIContactInfoViewController, AIPreferenceViewController, AISoundController, AIIconFamily, AIDockController, AIHandle, AIListContact, AIListGroup, AIListObject;
@protocol AIContentObject;

@interface AIAdium : NSObject {

    IBOutlet	AIMenuController	*menuController;
    IBOutlet	AILoginController	*loginController;
    IBOutlet	AIAccountController	*accountController;
    IBOutlet	AIInterfaceController	*interfaceController;
    IBOutlet	AIContactController	*contactController;
    IBOutlet	AIContentController	*contentController;
    IBOutlet	AIPluginController	*pluginController;
    IBOutlet	AIPreferenceController	*preferenceController;
    IBOutlet	AIToolbarController	*toolbarController;
    IBOutlet	AISoundController	*soundController;
    IBOutlet	AIDockController	*dockController;

    NSNotificationCenter 	*notificationCenter;
    NSMutableDictionary		*eventNotifications;
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

- (NSNotificationCenter *)notificationCenter;
- (void)registerEventNotification:(NSString *)inNotification displayName:(NSString *)displayName;
- (NSDictionary *)eventNotifications;

@end

// Public core controller typedefs and defines --------------------------------------------------
typedef enum {
    LOC_Adium_About, LOC_Adium_Preferences,
    LOC_File_New, LOC_File_Close, LOC_File_Save, LOC_File_Accounts, LOC_File_Additions, LOC_File_Status,
    LOC_Edit_Additions,
    LOC_Format_Styles, LOC_Format_Palettes, LOC_Format_Additions, 
    LOC_Window_Commands, LOC_Window_Auxilary, LOC_Window_Fixed,
    LOC_Help_Local, LOC_Help_Web, LOC_Help_Additions,
} MENU_LOCATION;

typedef enum {
    AISortGroup = 0,
    AISortGroupAndSubGroups,
    AISortGroupAndSuperGroups
} AISortMode;

//Preference Categories
#define PREFERENCE_CATEGORY_CONNECTIONS	@"Connections"
#define PREFERENCE_CATEGORY_INTERFACE	@"Interface"
#define PREFERENCE_CATEGORY_STATUS	@"Status"
#define PREFERENCE_CATEGORY_OTHER	@"Other"

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

//Notifications
#define Account_ListChanged 					@"Account_ListChanged"
#define Account_PropertiesChanged				@"Account_PropertiesChanged"
#define Account_StatusChanged					@"Account_StatusChanged"
#define Account_HandlesChanged					@"Account_HandlesChanged"
#define Contact_AttributesChanged				@"Contact_AttributesChanged"
#define Contact_StatusChanged					@"Contact_StatusChanged"
#define Contact_OrderChanged					@"Contact_OrderChanged"
#define Contact_ListChanged					@"Contact_ListChanged"
#define Contact_SortSelectorListChanged				@"Contact_SortSelectorListChanged"

#define Contact_UpdateStatus					@"Contact_UpdateStatus"
//Whenever possible, accounts should keep their contact's status up to date.  However, sometimes this ideal situation cannot be achieved, and the account needs to be told when 'more expensive' status keys are required so it can fetch them.  This notification instructs the accounts to do just that.  It is currently used for profiles, but may be used for more information in the future.

#define Interface_ContactSelectionChanged			@"Interface_ContactSelectionChanged"
#define Interface_InitiateMessage				@"Interface_InitiateMessage"
#define Interface_CloseMessage					@"Interface_CloseMessage"
#define Interface_SendEnteredMessage				@"Interface_SendEnteredMessage"
#define Interface_WillSendEnteredMessage 			@"Interface_WillSendEnteredMessage"
#define Interface_DidSendEnteredMessage				@"Interface_DidSendEnteredMessage"
#define Interface_ErrorMessageReceived				@"Interface_ErrorMessageRecieved"
#define Content_ContentObjectAdded				@"Content_ContentObjectAdded"
#define Content_WillSendContent					@"Content_WillSendContent"
#define Content_DidSendContent					@"Content_DidSendContent"
#define Content_WillReceiveContent				@"Content_WillReceiveContent"
#define Content_DidReceiveContent				@"Content_DidReceiveContent"
#define Preference_GroupChanged					@"Preference_GroupChanged"
#define Dock_IconWillChange					@"Dock_IconWillChange"
#define Dock_IconDidChange					@"Dock_IconDidChange"

// Public core controller protocols ------------------------------------------------------------
@protocol AIContactObserver //notified of changes
    - (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys;
@end

@protocol AIContactLeftView //Draws to the left of a handle
    - (void)drawInRect:(NSRect)inRect;
    - (float)widthForHeight:(int)inHeight;
@end

@protocol AIContactRightView //Draws to the right of a handle

@end

@protocol AIContactListViewController <NSObject>
- (NSView *)contactListView;
- (void)closeContactListView:(NSView *)inView;
@end

@protocol AIMessageViewController <NSObject>
- (NSView *)messageViewForContact:(AIListContact *)inContact;
- (void)closeMessageView:(NSView *)inView;
@end

@protocol AITextEntryView //Handles any attributed text entry
- (NSAttributedString *)attributedString;
- (void)setAttributedString:(NSAttributedString *)inAttributedString;
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)inRange;
@end

@protocol AIContentHandler //Handles the display of a content type

@end

@protocol AIContentObject
- (NSString *)type;		//Return the unique type identifier for this object
- (id)source;
- (id)destination;
@end

@protocol AIContentFilter
- (void)filterContentObject:(id <AIContentObject>)inObject;
@end

@protocol AITextEntryFilter //Interpret text as it's entered
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSView<AITextEntryView> *)inTextEntryView; //keypress
- (void)contentsChangedInTextEntryView:(NSView<AITextEntryView> *)inTextEntryView; //delete,copy,paste,etc
@end

@protocol AIServiceController <NSObject>
- (NSString *)identifier;
- (NSString *)description;
- (AIServiceType *)handleServiceType;
- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner;
@end

@protocol AIAccountViewController <NSObject>
- (NSView *)view;
- (void)saveChanges;
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
@end

@protocol AIFlashObserver <NSObject>
- (void)flash:(int)value;
@end

@protocol AIContactListTooltipEntry <NSObject>
- (NSString *)label;
- (NSString *)entryForObject:(AIListObject *)inObject;
@end


// Public core controller methods ------------------------------------------------------------
@interface AILoginController : NSObject{
    IBOutlet	AIAdium		*owner;
    
    NSString			*userDirectory;		//The current user's Adium home directory
    AILoginWindowController	*loginWindowController;	//The login select window
    id				target;			//Used to send our owner a 'login complete'
    SEL				selector;		//
}

- (NSString *)userDirectory;

@end

@interface AIAccountController : NSObject{

    IBOutlet	AIAdium		*owner;	

    NSMutableArray		*accountArray;			//Array of active accounts

    NSMutableArray		*availableServiceArray;
    NSString			*lastAccountIDToSendContent;

    NSMutableDictionary		*accountStatusDict;
}

- (NSArray *)accountArray;
- (AIAccount *)accountWithID:(NSString *)inID;
- (AIAccount *)newAccountAtIndex:(int)index;
- (void)deleteAccount:(AIAccount *)inAccount;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;
- (NSArray *)availableServiceArray;
- (void)registerService:(id <AIServiceController>)inService;
- (AIAccount *)accountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;
- (void)setStatusObject:(id)inValue forKey:(NSString *)key account:(AIAccount *)inAccount;
- (id)statusObjectForKey:(NSString *)key account:(AIAccount *)inAccount;
- (AIServiceType *)serviceTypeWithID:(NSString *)inServiceID;

@end

@interface AIContentController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSMutableArray		*textEntryFilterArray;

    NSMutableArray		*outgoingContentFilterArray;
    NSMutableArray		*incomingContentFilterArray;
}

- (void)registerDefaultHandler:(id <AIContentHandler>)inHandler forContentType:(NSString *)inType;
- (void)invokeDefaultHandlerForObject:(id <AIContentObject>)inObject;

- (void)addIncomingContentObject:(id <AIContentObject>)inObject;
- (void)sendContentObject:(id <AIContentObject>)inObject;

- (void)registerTextEntryFilter:(id <AITextEntryFilter>)inFilter;
//- (NSArray *)textEntryFilters;
- (void)registerOutgoingContentFilter:(id <AIContentFilter>)inFilter;
- (void)registerIncomingContentFilter:(id <AIContentFilter>)inFilter;
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSView<AITextEntryView> *)inTextEntryView;
- (void)contentsChangedInTextEntryView:(NSView<AITextEntryView> *)inTextEntryView;

@end

@interface AIContactController : NSObject {
    IBOutlet	AIAdium		*owner;

    AIListGroup			*contactList;
    AIListGroup			*strangerGroup;
    NSMutableArray		*contactObserverArray;
    BOOL			holdUpdates;

    NSMutableArray		*sortControllerArray;
    id<AIListSortController> 	activeSortController;

    AIPreferenceCategory	*contactInfoCategory;

    NSMutableDictionary		*groupDict;
    NSMutableDictionary		*abandonedContacts;
    NSMutableDictionary		*abandonedGroups;
}
- (void)handlesChangedForAccount:(AIAccount *)inAccount;
- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount;
- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount;


    /*
- (void)addAccount:(AIAccount *)inAccount toObject:(AIContactObject *)inObject;
- (void)removeAccount:(AIAccount *)inAccount fromObject:(AIContactObject *)inObject;

- (AIContactHandle *)createHandleWithService:(AIServiceType *)inService UID:(NSString *)inUID inGroup:(AIContactGroup *)inGroup forAccount:(AIAccount *)inAccount;
- (AIContactGroup *)createGroupNamed:(NSString *)inName inGroup:(AIContactGroup *)inGroup;

- (void)deleteObject:(AIContactObject *)object;
- (void)renameObject:(AIContactObject *)object to:(NSString *)newName;
- (void)moveObject:(AIContactObject *)object toGroup:(AIContactGroup *)destGroup index:(int)inIndex;

*/

- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID;
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID serverGroup:(NSString *)serverGroup;

    //Account code calls these methods after modifying its available handles
//- (void)handleWasAdded:(AIHandle *)inHandle;
//- (void)handleWasRemoved:(AIHandle *)inHandle;
//- (void)refreshContactList;


- (AIListGroup *)contactList;
/*
- (AIContactGroup *)groupWithName:(NSString *)inName;
- (AIContactHandle *)handleWithService:(AIServiceType *)inService UID:(NSString *)inUID forAccount:(AIAccount *)inAccount;
- (NSMutableArray *)allContactsInGroup:(AIContactGroup *)inGroup subgroups:(BOOL)subGroups ownedBy:(AIAccount *)inAccount;
*/
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups;

- (AIHandle *)handleOfContact:(AIListContact *)inContact forReceivingContentType:(NSString *)inType fromAccount:(AIAccount *)inAccount create:(BOOL)create;


- (void)objectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys;

- (void)handleStatusChanged:(AIHandle *)inHandle modifiedStatusKeys:(NSArray *)inModifiedKeys;
- (void)registerContactObserver:(id)inObserver;

- (void)registerListSortController:(id <AIListSortController>)inController;
- (NSArray *)sortControllerArray;

- (void)setActiveSortController:(id <AIListSortController>)inController;
- (id <AIListSortController>)activeSortController;
- (void)sortListGroup:(AIListGroup *)inGroup mode:(AISortMode)sortMode;

- (void)showInfoForContact:(AIListContact *)inContact;
- (void)addContactInfoView:(AIPreferenceViewController *)inView;

- (void)setHoldContactListUpdates:(BOOL)inHoldUpdates;
- (BOOL)holdContactListUpdates;

@end

@interface AIInterfaceController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSMutableArray		*contactListViewArray;
    NSMutableArray		*messageViewArray;
    NSMutableArray		*interfaceArray;
    NSMutableArray		*contactListTooltipEntryArray;

    NSMutableArray		*flashObserverArray;
    NSTimer			*flashTimer;
    int				flashState;
    AIListObject		*tooltipListObject;
    NSString			*tooltipString;
    
    NSString		*errorTitle;
    NSString		*errorDesc;
}

- (void)registerContactListViewController:(id <AIContactListViewController>)inController;
- (id <AIContactListViewController>)contactListViewController;
- (void)registerMessageViewController:(id <AIMessageViewController>)inController;
- (NSView *)messageViewForContact:(AIListContact *)inContact;
- (IBAction)initiateMessage:(id)sender;
- (void)registerInterfaceController:(id <AIInterfaceController>)inController;
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc;
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver;
- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver;
- (int)flashState;
- (void)showTooltipForListObject:(AIListObject *)object atPoint:(NSPoint)point;
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry;

@end

@interface AIPluginController : NSObject {
    IBOutlet	AIAdium		*owner;
    NSMutableArray		*pluginArray;
}

@end

@interface AIPreferenceController : NSObject {
    IBOutlet	AIAdium			*owner;

    NSMutableArray			*categoryArray;
    NSMutableDictionary			*groupDict;		//A dictionary of pref dictionaries
}

- (void)addPreferenceView:(AIPreferenceViewController *)inView;
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)groupName;
- (IBAction)showPreferenceWindow:(id)sender;
- (void)openPreferencesToView:(AIPreferenceViewController *)inView;

- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object;
- (NSDictionary *)preferencesForGroup:(NSString *)groupName;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;


@end

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

    NSMutableArray		*locationArray;
}

- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location;
- (void)removeMenuItem:(NSMenuItem *)targetItem;

@end

@interface AISoundController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSMovie	*sharedMovie;
}

- (void)playSoundNamed:(NSString *)inName;
- (void)playSoundAtPath:(NSString *)inPath;
- (NSArray *)soundSetArray;

@end

@interface AIToolbarController : NSObject {
    IBOutlet	AIAdium		*owner;
}

@end

@interface AIDockController: NSObject {
    IBOutlet	AIAdium 	*owner;
    
    AIIconFamily		*iconFamily;

    NSImage			*currentIcon;

    NSTimer 			*currentTimer;
}

- (AIIconFamily *)currentIconFamily;
- (void)setIconFamily:(AIIconFamily *)iconFamily;
- (void)setIconFamily:(AIIconFamily *)newIconFamily initializingClosed:(BOOL)closed;

- (void)alert;

- (void)bounce;
- (void)bounceWithInterval:(double)delay times:(int)num;
- (void)bounceForeverWithInterval:(double)delay;
- (void)stopBouncing;

@end










