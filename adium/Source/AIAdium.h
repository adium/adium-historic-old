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

@class AILoginController, AIAccountController, AIInterfaceController, AIContactController, AIPluginController, AIPreferenceController, AIPreferenceView, AIMenuController, AILoginWindowController, AIAccountWindowController, AIContactHandle, AIAccount, AIContactGroup, AIMessageObject, AIServiceType, AIPreferenceCategory, AIContactInfoView, AIMiniToolbar, AIAnimatedView, AIContentController, AIToolbarController, AIContactObject, AIContactInfoViewController, AIPreferenceViewController, AISoundController;
@protocol AIContentObject, AIAccount_Handles;

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

//Preference Categories
#define PREFERENCE_CATEGORY_CONNECTIONS	@"Connections"
#define PREFERENCE_CATEGORY_INTERFACE		@"Interface"

//Preference groups
#define PREF_GROUP_GENERAL 		@"General"
#define PREF_GROUP_ACCOUNTS	 	@"Accounts"
#define PREF_GROUP_TOOLBARS 		@"Toolbars"
#define PREF_GROUP_WINDOW_POSITIONS 	@"Window Positions"



//Notifications
#define	Adium_LaunchComplete					@"Adium_LaunchComplete"
#define Account_ListChanged 					@"Account_ListChanged"
#define Account_PropertiesChanged				@"Account_PropertiesChanged"
#define Account_StatusChanged					@"Account_StatusChanged"
#define Account_IdleStatusChanged					@"Account_IdleStatusChanged"
#define Contact_ObjectChanged					@"Contact_ObjectChanged"
#define Contact_ListChanged						@"Contact_ListChanged"
#define Interface_ContactSelectionChanged		@"Interface_ContactSelectionChanged"
// Interface_ContactDefaultAction ... make double click generic?
#define Interface_InitiateMessage				@"Interface_InitiateMessage"
#define Interface_CloseMessage					@"Interface_CloseMessage"
#define Interface_SendEnteredMessage			@"Interface_SendEnteredMessage"
#define Interface_WillSendEnteredMessage 		@"Interface_WillSendEnteredMessage"
#define Interface_DidSendEnteredMessage		@"Interface_DidSendEnteredMessage"
#define Interface_ErrorMessageRecieved		@"Interface_ErrorMessageRecieved"
#define Content_ContentObjectAdded				@"Content_ContentObjectAdded"
#define Content_WillSendContent				@"Content_WillSendContent"
#define Content_DidSendContent					@"Content_DidSendContent"
#define Content_WillReceiveContent				@"Content_WillReceiveContent"
#define Content_DidReceiveContent				@"Content_DidReceiveContent"
#define Preference_GroupChanged					@"Preference_GroupChanged"



// Public core controller protocols ------------------------------------------------------------
@protocol AIHandleObserver //notified of changes
    - (BOOL)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys;
@end

@protocol AIHandleLeftView //Draws to the left of a handle
    - (void)drawInRect:(NSRect)inRect;
    - (int)widthForHeight:(int)inHeight;
@end

@protocol AIHandleRightView //Draws to the right of a handle

@end

@protocol AIContactListViewController
- (NSView *)contactListView;
@end

@protocol AIMessageViewController
- (NSView *)messageViewForHandle:(AIContactHandle *)inHandle;
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
    NSNotificationCenter 	*accountNotificationCenter;	//Shared account notification center

    NSMutableArray		*availableServiceArray;
}

- (NSNotificationCenter *)accountNotificationCenter;
- (NSArray *)accountArray;
- (AIAccount *)newAccountAtIndex:(int)index;
- (void)deleteAccount:(AIAccount *)inAccount;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;
- (NSArray *)availableServiceArray;
- (void)registerService:(id <AIServiceController>)inService;

@end

@interface AIContentController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSNotificationCenter	*contentNotificationCenter;
    NSMutableArray		*textEntryFilterArray;

}

- (NSNotificationCenter *)contentNotificationCenter;
- (void)registerDefaultHandler:(id <AIContentHandler>)inHandler forContentType:(NSString *)inType;
- (void)invokeDefaultHandlerForObject:(id <AIContentObject>)inObject;
- (void)addIncomingContentObject:(id <AIContentObject>)inObject toHandle:(AIContactHandle *)inHandle;
- (void)sendContentObject:(id <AIContentObject>)inObject toHandle:(AIContactHandle *)inHandle;
- (void)registerTextEntryFilter:(id <AITextEntryFilter>)inFilter;
- (NSArray *)textEntryFilters;

@end

@interface AIContactController : NSObject {
    IBOutlet	AIAdium		*owner;

    AIContactGroup		*contactList;
    AIContactGroup		*strangerGroup;
    NSNotificationCenter	*contactNotificationCenter;
    NSMutableArray		*handleObserverArray;
    int				delayedUpdating;

    AIPreferenceCategory	*contactInfoCategory;
}

- (NSNotificationCenter *)contactNotificationCenter;

- (void)addAccount:(AIAccount<AIAccount_Handles> *)inAccount toObject:(AIContactObject *)inObject;
- (void)removeAccount:(AIAccount<AIAccount_Handles> *)inAccount fromObject:(AIContactObject *)inObject;

- (AIContactHandle *)createHandleWithService:(AIServiceType *)inService UID:(NSString *)inUID inGroup:(AIContactGroup *)inGroup forAccount:(AIAccount *)inAccount;
- (void)deleteHandle:(AIContactHandle *)inHandle;
- (void)renameHandle:(AIContactHandle *)inHandle to:(NSString *)newName;
- (void)moveHandle:(AIContactHandle *)inHandle toGroup:(AIContactGroup *)inGroup index:(int)inIndex;

- (AIContactGroup *)createGroupNamed:(NSString *)inName inGroup:(AIContactGroup *)inGroup;
- (void)deleteGroup:(AIContactGroup *)inGroup;
- (void)renameGroup:(AIContactGroup *)inGroup to:(NSString *)newName;
- (void)moveGroup:(AIContactGroup *)inGroup toGroup:(AIContactGroup *)destGroup index:(int)inIndex;

- (AIContactGroup *)contactList;
- (AIContactGroup *)groupWithName:(NSString *)inName;
- (AIContactHandle *)handleWithService:(AIServiceType *)inService UID:(NSString *)inUID forAccount:(AIAccount *)inAccount;
- (NSMutableArray *)allContactsInGroup:(AIContactGroup *)inGroup subgroups:(BOOL)subGroups ownedBy:(AIAccount *)inAccount;

- (void)handleStatusChanged:(AIContactHandle *)inHandle modifiedStatusKeys:(NSArray *)InModifiedKeys;
- (void)registerHandleObserver:(id)inObserver;

- (void)showInfoForContact:(AIContactHandle *)inContact;
- (void)addContactInfoView:(AIContactInfoViewController *)inView;

- (void)delayContactListUpdatesFor:(int)seconds;
- (BOOL)contactListUpdatesDelayed;

@end

@interface AIInterfaceController : NSObject {
    IBOutlet	AIAdium		*owner;

    NSNotificationCenter	*interfaceNotificationCenter;

    NSMutableArray		*contactListViewArray;
    NSMutableArray		*messageViewArray;
    
    NSString		*errorTitle;
    NSString		*errorDesc;
}

- (NSNotificationCenter *)interfaceNotificationCenter;
- (void)registerContactListViewController:(id <AIContactListViewController>)inController;
- (NSView *)contactListView;
- (void)registerMessageViewController:(id <AIMessageViewController>)inController;
- (NSView *)messageViewForHandle:(AIContactHandle *)inHandle;
- (IBAction)initiateMessage:(id)sender;

- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc;

@end

@interface AIPluginController : NSObject {
    IBOutlet	AIAdium		*owner;
    NSMutableArray		*pluginArray;
}

@end

@interface AIPreferenceController : NSObject {
    IBOutlet	AIAdium			*owner;

    NSNotificationCenter		*preferenceNotificationCenter;
    NSMutableArray			*categoryArray;
    NSMutableDictionary			*groupDict;		//A dictionary of pref dictionaries
}

- (NSNotificationCenter *)preferenceNotificationCenter;

- (void)addPreferenceView:(AIPreferenceViewController *)inView;
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)groupName;
- (IBAction)showPreferenceWindow:(id)sender;
- (void)openPreferencesToView:(AIPreferenceViewController *)inView;

- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName object:(AIContactObject *)object;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName object:(AIContactObject *)object;
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

@end

@interface AIToolbarController : NSObject {
    IBOutlet	AIAdium		*owner;
}

@end











