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

@protocol AIListObjectObserver, AIContainingObject;

@class AIContactHandle, AIMessageObject, AIMetaContact;

#define ListObject_AttributesChanged			@"ListObject_AttributesChanged"
#define ListObject_StatusChanged				@"ListObject_StatusChanged"
#define Contact_OrderChanged					@"Contact_OrderChanged"
#define Contact_ListChanged						@"Contact_ListChanged"
#define Contact_SortSelectorListChanged			@"Contact_SortSelectorListChanged"

#define Contact_ApplyDisplayName				@"Contact_ApplyDisplayName"
#define Contact_AddNewContact					@"Contact_AddNewContact"

//Whenever possible, accounts should keep their contact's status up to date.  However, sometimes this ideal situation
//cannot be achieved, and the account needs to be told when 'more expensive' status keys are required so it can fetch
//them.  This notification instructs the accounts to do just that.  It is currently used for profiles, but may be
//used for more information in the future.
#define Contact_UpdateStatus					@"Contact_UpdateStatus"

//A unique group name for our root group
#define ADIUM_ROOT_GROUP_NAME					@"ROOTJKSHFOEIZNGIOEOP"	

//Preference groups and keys used for contacts throughout Adium
#define	PREF_GROUP_ALIASES						@"Aliases"			//Preference group in which to store aliases
#define PREF_GROUP_USERICONS					@"User Icons"
#define KEY_USER_ICON							@"User Icon"
#define PREF_GROUP_NOTES						@"Notes"			//Preference group to store notes in
#define PREF_GROUP_ADDRESSBOOK                  @"Address Book"

typedef enum {
    AIInfo_Profile = 1, 
    AIInfo_Accounts,
    AIInfo_Alerts,
    AIInfo_Settings
} CONTACT_INFO_CATEGORY;

typedef enum {
    AISortGroup = 0,
    AISortGroupAndSubGroups,
    AISortGroupAndSuperGroups
} AISortMode;

//Observer which receives notifications of changes in list object status
@protocol AIListObjectObserver
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
@end

@protocol AIListObjectView
- (void)drawInRect:(NSRect)inRect;
- (float)widthForHeight:(int)inHeight;
@end

//Empty protocol to allow easy checking for if a particular object is a contact list outline view
@protocol ContactListOutlineView
@end

@class AIContactInfoPane, AIListContact, AIListGroup, AISortController;

@interface AIContactController : NSObject {
    IBOutlet	AIAdium		*owner;
    IBOutlet 	NSMenuItem  *menuItem_getInfo;
	IBOutlet	NSMenuItem  *menuItem_getInfoAlternate;
	
	NSMenuItem				*menuItem_getInfoContextualContact;
	NSMenuItem				*menuItem_getInfoContextualGroup;
	
	NSMutableDictionary		*contactDict;
	NSMutableDictionary		*groupDict;
	NSMutableDictionary		*metaContactDict;
	NSMutableDictionary		*contactToMetaContactLookupDict;
	
    AIListGroup				*contactList;
    AIListGroup				*strangerGroup;
    NSMutableArray			*contactObserverArray;
	
    NSTimer					*delayedUpdateTimer;
    int						delayedStatusChanges;
	NSMutableSet			*delayedModifiedStatusKeys;
    int						delayedAttributeChanges;
	NSMutableSet			*delayedModifiedAttributeKeys;
    int						delayedContactChanges;
	int						delayedUpdateRequests;
	BOOL					updatesAreDelayed;
	
    NSMutableArray			*sortControllerArray;
    AISortController	 	*activeSortController;
	
    NSMutableArray			*contactInfoPanes;
	
	float					nextOrderIndex;

    int		signedOffLength;
    int		signedOnLength;
}

//Contact list access
- (AIListGroup *)contactList;
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact;
- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID;
- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListGroup *)groupWithUID:(NSString *)groupUID;
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups onAccount:(AIAccount *)inAccount;
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListGroup *)inGroup withTarget:(id)target;
- (NSMenu *)menuOfAllGroupsInGroup:(AIListGroup *)inGroup withTarget:(id)target;
- (NSArray *)allContactsWithService:(AIService *)service UID:(NSString *)inUID;

- (AIMetaContact *)groupUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray;
- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray;
- (void)removeAllListObjectsMatching:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact;
- (AIListGroup *)remoteGroupForContact:(AIListContact *)inContact;
//Return either the highest metaContact containing this list object, or the list object itself.  Appropriate for when
//preferences should be read from/to the most generalized contact possible.
- (AIListObject *)parentContactForListObject:(AIListObject *)listObject;

- (NSMenu *)menuOfContainedContacts:(AIListObject *)inContact forService:(AIService *)service withTarget:(id)target includeOffline:(BOOL)includeOffline;
- (NSMenu *)menuOfContainedContacts:(AIListObject *)inContact withTarget:(id)target;

//Contact status & Attributes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver;
- (void)unregisterListObjectObserver:(id)inObserver;
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver;

//
- (void)delayListObjectNotifications;
- (void)endListObjectNotificationsDelay;
- (void)delayListObjectNotificationsUntilInactivity;
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inObject;
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys;

//Contact list sorting
- (NSArray *)sortControllerArray;
- (void)registerListSortController:(AISortController *)inController;
- (void)setActiveSortController:(AISortController *)inController;
- (AISortController *)activeSortController;
- (void)sortContactList;
- (void)sortListObject:(AIListObject *)inObject;

//Preferred contacts
- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact;
- (AIListContact *)preferredContactWithUID:(NSString *)UID andServiceID:(NSString *)serviceID forSendingContentType:(NSString *)inType;

//Editing
- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group;
- (void)removeListObjects:(NSArray *)objectArray;
- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService;
- (void)moveListObjects:(NSArray *)objectArray toGroup:(AIListObject<AIContainingObject> *)group index:(int)index;
- (void)moveContact:(AIListContact *)listContact toGroup:(AIListObject<AIContainingObject> *)group;
- (void)_moveContactLocally:(AIListContact *)listContact toGroup:(AIListGroup *)group;

//Contact info
- (IBAction)showContactInfo:(id)sender;
- (void)addContactInfoPane:(AIContactInfoPane *)inPane;
- (void)updateListContactStatus:(AIListContact *)inContact;
- (NSArray *)contactInfoPanes;

//Interface selection
- (AIListObject *)selectedListObject;
- (AIListObject *)selectedListObjectInContactList;
- (NSArray *)arrayOfSelectedListObjectsInContactList;

//Private
- (void)initController;
- (void)finishIniting;
- (void)closeController;

- (float)nextOrderIndex;

@end
