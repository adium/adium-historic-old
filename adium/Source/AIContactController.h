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

@class AIContactHandle, AIMessageObject;

#define ListObject_AttributesChanged			@"ListObject_AttributesChanged"
#define ListObject_StatusChanged				@"ListObject_StatusChanged"
#define Contact_OrderChanged					@"Contact_OrderChanged"
#define Contact_ListChanged						@"Contact_ListChanged"
#define Contact_SortSelectorListChanged			@"Contact_SortSelectorListChanged"

//Whenever possible, accounts should keep their contact's status up to date.  However, sometimes this ideal situation
//cannot be achieved, and the account needs to be told when 'more expensive' status keys are required so it can fetch
//them.  This notification instructs the accounts to do just that.  It is currently used for profiles, but may be
//used for more information in the future.
#define Contact_UpdateStatus					@"Contact_UpdateStatus"

typedef enum {
    AISortGroup = 0,
    AISortGroupAndSubGroups,
    AISortGroupAndSuperGroups
} AISortMode;

@protocol AIListObjectObserver //notified of changes
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
@end

@protocol AIListObjectView
- (void)drawInRect:(NSRect)inRect;
- (float)widthForHeight:(int)inHeight;
@end


@interface AIContactController : NSObject {
    IBOutlet	AIAdium		*owner;
	
	NSMutableDictionary		*contactDict;
	NSMutableDictionary		*groupDict;
	
    AIListGroup				*contactList;
    AIListGroup				*strangerGroup;
    NSMutableArray			*contactObserverArray;
	
    NSTimer					*delayedUpdateTimer;
    int						delayedStatusChanges;
    int						delayedAttributeChanges;
    int						delayedContentChanges;
	BOOL					updatesAreDelayed;
	
    NSMutableArray			*sortControllerArray;
    AISortController	 	*activeSortController;
	
    AIPreferenceCategory	*contactInfoCategory;
	
    NSMenuItem				*menuItem_getInfo;
	
    NSMutableDictionary		*listOrderDict;
    NSMutableDictionary		*reverseListOrderDict;
    int						largestOrder;
}

//Contact list access
- (AIListGroup *)contactList;
- (AIListContact *)contactWithService:(NSString *)serviceID UID:(NSString *)UID;
- (AIListGroup *)groupWithUID:(NSString *)groupUID createInGroup:(AIListGroup *)targetGroup;
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups;

//Contact status & Attributes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver;
- (void)unregisterListObjectObserver:(id)inObserver;
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver;

//
- (void)delayListObjectNotifications;
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inObject oldGroupName:(NSString *)oldGroupName;
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys;

//Contact list sorting
- (NSArray *)sortControllerArray;
- (void)registerListSortController:(AISortController *)inController;
- (void)setActiveSortController:(AISortController *)inController;
- (AISortController *)activeSortController;
- (void)sortContactList;
- (void)sortListObject:(AIListObject *)inObject;

//Editing
- (void)removeListObject:(AIListObject *)object fromGroup:(AIListGroup *)group;


//Contact info
- (IBAction)showContactInfo:(id)sender;
- (void)showInfoForContact:(AIListContact *)inContact;
- (void)addContactInfoView:(AIPreferenceViewController *)inView;

//Interface selection
- (AIListContact *)selectedContact;

//Private
- (void)initController;
- (void)finishIniting;
- (void)closeController;
- (void)addMessageObject:(AIMessageObject *)inObject toHandle:(AIContactHandle *)inHandle;
- (IBAction)showContactListEditor:(id)sender;

@end
