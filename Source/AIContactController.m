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

// $Id$

//#define CONTACTS_INFO_WITH_PROMPT

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContactInfoWindowController.h"
#import "AIInterfaceController.h"
#import "AILoginController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "AIToolbarController.h"
#import "AIToolbarController.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AISortController.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIServiceIcons.h>

#import "ESShowContactInfoPromptController.h"

#define PREF_GROUP_CONTACT_LIST			@"Contact List"			//Contact list preference group
#define KEY_FLAT_GROUPS					@"FlatGroups"			//Group storage
#define KEY_FLAT_CONTACTS				@"FlatContacts"			//Contact storage
#define KEY_FLAT_METACONTACTS			@"FlatMetaContacts"		//Metacontact objectID storage

#define	OBJECT_STATUS_CACHE				@"Object Status Cache"

#define VIEW_CONTACTS_INFO				AILocalizedString(@"Get Info",nil)
#define VIEW_CONTACTS_INFO_WITH_PROMPT	[AILocalizedString(@"Get Info for Contact", nil) stringByAppendingEllipsis]
#define GET_INFO_MASK					(NSCommandKeyMask | NSShiftKeyMask)
#define ALTERNATE_GET_INFO_MASK			(NSCommandKeyMask | NSShiftKeyMask | NSControlKeyMask)

#define	TITLE_SHOW_INFO					AILocalizedString(@"Show Info",nil)
#define	TOOLTIP_SHOW_INFO				AILocalizedString(@"Show information about this contact or group and change settings specific to it","Tooltip for the Show Info toolbar button")
#define UPDATE_CLUMP_INTERVAL			1.0

#define TOP_METACONTACT_ID				@"TopMetaContactID"
#define KEY_IS_METACONTACT				@"isMetaContact"
#define KEY_OBJECTID					@"objectID"
#define KEY_METACONTACT_OWNERSHIP		@"MetaContact Ownership"
#define CONTACT_DEFAULT_PREFS			@"ContactPrefs"

#define	SHOW_GROUPS_MENU_TITLE			AILocalizedString(@"Show Groups",nil)
#define SHOW_GROUPS_IDENTIFER			@"ShowGroups"

#define	KEY_HIDE_CONTACT_LIST_GROUPS	@"Hide Contact List Groups"
#define	KEY_USE_OFFLINE_GROUP			@"Use Offline Group"
#define KEY_SHOW_OFFLINE_CONTACTS		@"Show Offline Contacts"

#define	PREF_GROUP_CONTACT_LIST_DISPLAY	@"Contact List Display"

#define SERVICE_ID_KEY					@"ServiceID"
#define UID_KEY							@"UID"

@interface AIContactController (PRIVATE)
- (AIListGroup *)processGetGroupNamed:(NSString *)serverGroup;
- (void)_performDelayedUpdates:(NSTimer *)timer;
- (void)loadContactList;
- (void)saveContactList;
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)_updateAllAttributesOfObject:(AIListObject *)inObject;
- (void)prepareContactInfo;

- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inGroup withTarget:(id)target firstLevel:(BOOL)firstLevel;
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level;

- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector;
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol;

- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects;
- (void)_loadGroupsFromArray:(NSArray *)array;

- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object;
- (void)prepareShowHideGroups;
- (void)_performChangeOfUseContactListGroups;

- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListObject<AIContainingObject> *)group;
- (void)_moveObjectServerside:(AIListObject *)listObject toGroup:(AIListGroup *)group;
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName;

//MetaContacts
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID;
- (BOOL)_restoreContactsToMetaContact:(AIMetaContact *)metaContact;
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact fromContainedContactsArray:(NSArray *)containedContactsArray;
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact;
- (void)_loadMetaContactsFromArray:(NSArray *)array;
- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict;
- (void)breakdownAndRemoveMetaContact:(AIMetaContact *)metaContact;
- (void)_storeListObject:(AIListObject *)listObject inMetaContact:(AIMetaContact *)metaContact;

- (void)_addMenuItemsFromArray:(NSArray *)contactArray toMenu:(NSMenu *)contactMenu target:(id)target offlineContacts:(BOOL)offlineContacts;

- (void)_performChangeOfUseOfflineGroup;

@end

@implementation AIContactController

//init
- (id)init
{
	if ((self = [super init])) {
		//
		contactObservers = [[NSMutableSet alloc] init];
		sortControllerArray = [[NSMutableArray alloc] init];
		activeSortController = nil;
		delayedStatusChanges = 0;
		delayedModifiedStatusKeys = [[NSMutableSet alloc] init];
		delayedAttributeChanges = 0;
		delayedModifiedAttributeKeys = [[NSMutableSet alloc] init];
		delayedContactChanges = 0;
		delayedUpdateRequests = 0;
		updatesAreDelayed = NO;
		
		//
		contactDict = [[NSMutableDictionary alloc] init];
		groupDict = [[NSMutableDictionary alloc] init];
		metaContactDict = [[NSMutableDictionary alloc] init];
		contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

//finish initing
- (void)controllerDidLoad
{	
	//Default contact preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST];
	
	contactList = [[AIListGroup alloc] initWithUID:ADIUM_ROOT_GROUP_NAME];
	
	//Get Info window and menu items
	[self prepareContactInfo];
	
	//Show Groups menu item
	[self prepareShowHideGroups];
	
	//Observe content (for preferredContactForContentType:forListContact:)
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:CONTENT_MESSAGE_SENT
                                     object:nil];

	[self loadContactList];
	[self sortContactList];

	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

//close
- (void)controllerWillClose
{
	[self saveContactList];
}

//dealloc
- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];

    [contactList release];
    [contactObservers release]; contactObservers = nil;

    [super dealloc];
}

- (void)clearAllMetaContactData
{
	NSString		*path;
	NSDictionary	*metaContactDictCopy = [metaContactDict copy];
	NSEnumerator	*enumerator;
	AIMetaContact	*metaContact;

	if ([metaContactDictCopy count]) {
		[self delayListObjectNotifications];

		//Remove all the metaContacts to get any existing objects out of them
		enumerator = [metaContactDictCopy objectEnumerator];
		while ((metaContact = [enumerator nextObject])) {
			[self breakdownAndRemoveMetaContact:metaContact];
		}

		[self endListObjectNotificationsDelay];
	}

	[metaContactDict release]; metaContactDict = [[NSMutableDictionary alloc] init];
	[contactToMetaContactLookupDict release]; contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];

	//Clear the preferences for good measure
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];

	//Clear out old metacontact files
	path = [[[adium loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH];
	[[NSFileManager defaultManager] removeFilesInDirectory:path
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
	[[NSFileManager defaultManager] removeFilesInDirectory:[adium cachesPath]
												withPrefix:@"MetaContact"
											 movingToTrash:NO];

	[metaContactDictCopy release];
}

//Local Contact List Storage -------------------------------------------------------------------------------------------
#pragma mark Local Contact List Storage
//Load the contact list
- (void)loadContactList
{
	//We must load all the groups before loading contacts for the ordering system to work correctly.
	[self _loadGroupsFromArray:[[adium preferenceController] preferenceForKey:KEY_FLAT_GROUPS
																		group:PREF_GROUP_CONTACT_LIST]];
	[self _loadMetaContactsFromArray:[[adium preferenceController] preferenceForKey:KEY_FLAT_METACONTACTS
																			  group:PREF_GROUP_CONTACT_LIST]];
}

//Save the contact list
- (void)saveContactList
{
	[[adium preferenceController] setPreference:[self _arrayRepresentationOfListObjects:[groupDict allValues]]
										 forKey:KEY_FLAT_GROUPS
										  group:PREF_GROUP_CONTACT_LIST];
}

//List objects from flattened array
- (void)_loadGroupsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSDictionary	*infoDict;

	NSString	*Expanded = @"Expanded";

	while ((infoDict = [enumerator nextObject])) {
		AIListObject	*object = nil;

		object = [self groupWithUID:[infoDict objectForKey:UID_KEY]];
		[(AIListGroup *)object setExpanded:[[infoDict objectForKey:Expanded] boolValue]];
	}
}

- (void)_loadMetaContactsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSString		*identifier;

	while ((identifier = [enumerator nextObject])) {
		NSNumber *objectID = [NSNumber numberWithInt:[[[identifier componentsSeparatedByString:@"-"] objectAtIndex:1] intValue]];
		[self metaContactWithObjectID:objectID];
	}
}

//Flattened array of the contact list content
- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects
{
	NSMutableArray	*array = [NSMutableArray array];
	NSEnumerator	*enumerator = [listObjects objectEnumerator];;
	AIListObject	*object;

	//Create temporary strings outside the loop
	NSString	*Group = @"Group";
	NSString	*Type = @"Type";
	NSString	*Expanded = @"Expanded";

	while ((object = [enumerator nextObject])) {
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				Group, Type,
				[object UID], UID_KEY,
				[NSNumber numberWithBool:[(AIListGroup *)object isExpanded]], Expanded,
				nil]];
	}

	return array;
}


//Status and Display updates -------------------------------------------------------------------------------------------
#pragma mark Status and Display updates
//These delay Contact_ListChanged, ListObject_AttributesChanged, Contact_OrderChanged notificationsDelays,
//sorting and redrawing to prevent redundancy when making a large number of changes
//Explicit delay.  Call endListObjectNotificationsDelay to end
- (void)delayListObjectNotifications
{
	delayedUpdateRequests++;
	updatesAreDelayed = YES;
}

//End an explicit delay
- (void)endListObjectNotificationsDelay
{
	delayedUpdateRequests--;
	if (delayedUpdateRequests == 0 && !delayedUpdateTimer) {
		[self _performDelayedUpdates:nil];
	}
}

//Delay all list object notifications until a period of inactivity occurs.  This is useful for accounts that do not
//know when they have finished connecting but still want to mute events.
- (void)delayListObjectNotificationsUntilInactivity
{
    if (!delayedUpdateTimer) {
		updatesAreDelayed = YES;
		delayedUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_CLUMP_INTERVAL
															   target:self
															 selector:@selector(_performDelayedUpdates:)
															 userInfo:nil
															  repeats:YES] retain];
    } else {
		//Reset the timer
		[delayedUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:UPDATE_CLUMP_INTERVAL]];
	}
}

//Update the status of a list object.  This will update any information that is otherwise too expensive to update
//automatically, such as their profile.
- (void)updateListContactStatus:(AIListContact *)inContact
{
	//If we're dealing with a meta contact, update the status of the contacts contained within it
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		NSEnumerator	*enumerator = [[(AIMetaContact *)inContact listContacts] objectEnumerator];
		AIListContact	*contact;

		while ((contact = [enumerator nextObject])) {
			[self updateListContactStatus:contact];
		}

	} else {
		AIAccount *account = [inContact account];
		if (![account online]) {
			account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			 toContact:inContact];
		}

		[account updateContactStatus:inContact];
	}
}

//Called after modifying a contact's status
// Silent: Silences all events, notifications, sounds, overlays, etc. that would have been associated with this status change
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet			*modifiedAttributeKeys;

    //Let all observers know the contact's status has changed before performing any sorting or further notifications
	modifiedAttributeKeys = [self _informObserversOfObjectStatusChange:inObject withKeys:inModifiedKeys silent:silent];

    //Resort the contact list
	if (updatesAreDelayed) {
		delayedStatusChanges++;
		[delayedModifiedStatusKeys unionSet:inModifiedKeys];
	} else {
		//We can safely skip sorting if we know the modified attributes will invoke a resort later
		if (![[self activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys] &&
		   [[self activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys]) {
			[self sortListObject:inObject];
		}
	}

    //Post an attributes changed message (if necessary)
    if ([modifiedAttributeKeys count]) {
		[self listObjectAttributesChanged:inObject modifiedKeys:modifiedAttributeKeys];
    }
}

//Call after modifying an object's display attributes
//(When modifying display attributes in response to a status change, this is not necessary)
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSSet *)inModifiedKeys
{
	if (updatesAreDelayed) {
		delayedAttributeChanges++;
		[delayedModifiedAttributeKeys unionSet:inModifiedKeys];
	} else {
        //Resort the contact list if necessary
        if ([[self activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]) {
			[self sortListObject:inObject];
        }

        //Post an attributes changed message
		[[adium notificationCenter] postNotificationName:ListObject_AttributesChanged
												  object:inObject
												userInfo:(inModifiedKeys ?
														  [NSDictionary dictionaryWithObject:inModifiedKeys
																					  forKey:@"Keys"] :
														  nil)];
	}
}

//Performs any delayed list object/handle updates
- (void)_performDelayedUpdates:(NSTimer *)timer
{
	BOOL	updatesOccured = (delayedStatusChanges || delayedAttributeChanges || delayedContactChanges);

	//Send out global attribute & status changed notifications (to cover any delayed updates)
	if (updatesOccured) {
		BOOL shouldSort = NO;

		//Inform observers of any changes
		if (delayedContactChanges) {
//			[[adium notificationCenter] postNotificationName:Contact_ListChanged object:nil];
			delayedContactChanges = 0;
			shouldSort = YES;
		}
		if (delayedStatusChanges) {
			if (!shouldSort &&
			   [[self activeSortController] shouldSortForModifiedStatusKeys:delayedModifiedStatusKeys]) {
				shouldSort = YES;
			}
			[delayedModifiedStatusKeys removeAllObjects];
			delayedStatusChanges = 0;
		}
		if (delayedAttributeChanges) {
			if (!shouldSort &&
			   [[self activeSortController] shouldSortForModifiedAttributeKeys:delayedModifiedAttributeKeys]) {
				shouldSort = YES;
			}
			[[adium notificationCenter] postNotificationName:ListObject_AttributesChanged
													  object:nil
													userInfo:(delayedModifiedAttributeKeys ?
															  [NSDictionary dictionaryWithObject:delayedModifiedAttributeKeys
																						  forKey:@"Keys"] :
															  nil)];
			[delayedModifiedAttributeKeys removeAllObjects];
			delayedAttributeChanges = 0;
		}

		//Sort only if necessary
		if (shouldSort) {
			[self sortContactList];
		}
	}

    //If no more updates are left to process, disable the update timer
	//If there are no delayed update requests, remove the hold
	if (!delayedUpdateTimer || !updatesOccured) {
		if (delayedUpdateTimer) {
			[delayedUpdateTimer invalidate];
			[delayedUpdateTimer release];
			delayedUpdateTimer = nil;
		}
		if (delayedUpdateRequests == 0) {
			updatesAreDelayed = NO;
		}
    }
}

#pragma mark Contact Grouping
//Contact Grouping -----------------------------------------------------------------------------------------------------

//Redetermine the local grouping of a contact in response to server grouping information or an external change
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inContact
{
	AIListObject<AIContainingObject>	*containingObject;
	NSString							*remoteGroupName = [inContact remoteGroupName];

	[inContact retain];

	containingObject = [inContact containingObject];

	if ([containingObject isKindOfClass:[AIMetaContact class]]) {

		/* If inContact's containingObject is a metaContact, and that metaContact has no containingObject,
		 * use inContact's remote grouping as the metaContact's grouping.
		 */
		if (![containingObject containingObject] && [remoteGroupName length]) {
			//If no similar objects exist, we add this contact directly to the list
			AIListGroup *targetGroup;

			targetGroup = (useContactListGroups ?
						   ((useOfflineGroup && ![inContact online]) ? [self offlineGroup] : [self groupWithUID:remoteGroupName]) :
						   contactList);

			[targetGroup addObject:containingObject];
			[self _listChangedGroup:targetGroup object:containingObject];
		}

	} else {
		//If we have a remoteGroupName, add the contact locally to the list
		if (remoteGroupName) {
			AIListGroup *localGroup;

			localGroup = (useContactListGroups ?
						  ((useOfflineGroup && ![inContact online]) ? [self offlineGroup] : [self groupWithUID:remoteGroupName]) :
						  contactList);

			[self _moveContactLocally:inContact
							  toGroup:localGroup];

		} else {
			//If !remoteGroupName, remove the contact from any local groups
			if (containingObject) {
				//Remove the object
				[(AIListGroup *)containingObject removeObject:inContact];

				[self _listChangedGroup:(AIListGroup *)containingObject object:inContact];
			}
		}
	}

	BOOL	isCurrentlyAStranger = [inContact isStranger];
	if ((isCurrentlyAStranger && (remoteGroupName != nil)) ||
	   (!isCurrentlyAStranger && (remoteGroupName == nil))) {
		[inContact setStatusObject:(remoteGroupName ? [NSNumber numberWithBool:YES] : nil)
							forKey:@"NotAStranger"
							notify:NotifyLater];
		[inContact notifyOfChangedStatusSilently:YES];
	}

	[inContact release];
}

- (void)_moveContactLocally:(AIListContact *)listContact toGroup:(AIListGroup *)localGroup
{
	AIListObject	*containingObject;
	AIListObject	*existingObject;
	BOOL			performedGrouping = NO;

	//Protect with a retain while we are removing and adding the contact to our arrays
	[listContact retain];

	//Remove this object from any local groups we have it in currently
	if ((containingObject = [listContact containingObject]) &&
	   ([containingObject isKindOfClass:[AIListGroup class]])) {
		//Remove the object
		[(AIListGroup *)containingObject removeObject:listContact];
		[self _listChangedGroup:(AIListGroup *)containingObject object:listContact];
	}

	if ((existingObject = [localGroup objectWithService:[listContact service] UID:[listContact UID]])) {
		//If an object exists in this group with the same UID and serviceID, create a MetaContact
		//for the two.
		[self groupListContacts:[NSArray arrayWithObjects:listContact,existingObject,nil]];
		performedGrouping = YES;

	} else {
		AIMetaContact	*metaContact;

		//If no object exists in this group which matches, we should check if there is already
		//a MetaContact holding a matching ListContact, since we should include this contact in it
		//If we found a metaContact to which we should add, do it.
		if ((metaContact = [contactToMetaContactLookupDict objectForKey:[listContact internalObjectID]])) {
			[self addListObject:listContact toMetaContact:metaContact];
			performedGrouping = YES;
		}
	}

	if (!performedGrouping) {
		//If no similar objects exist, we add this contact directly to the list
		[localGroup addObject:listContact];

		//Add
		[self _listChangedGroup:localGroup object:listContact];
	}

	//Cleanup
	[listContact release];
}

- (AIListGroup *)remoteGroupForContact:(AIListContact *)inContact
{
	AIListGroup		*group;

	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		//For a metaContact, the closest we have to a remote group is the group it is within locally
		group = [(AIMetaContact *)inContact parentGroup];

	} else {
		NSString	*remoteGroup = [inContact remoteGroupName];
		group = (remoteGroup ? [self groupWithUID:remoteGroup] : nil);
	}

	return group;
}

//Post a list grouping changed notification for the object and group
- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object
{
	if (updatesAreDelayed) {
		delayedContactChanges++;
	} else {
		[[adium notificationCenter] postNotificationName:Contact_ListChanged
												  object:object
												userInfo:(group ? [NSDictionary dictionaryWithObject:group forKey:@"ContainingGroup"] : nil)];
	}
}

- (BOOL)useContactListGroups
{
	return useContactListGroups;
}

- (void)setUseContactListGroups:(BOOL)inFlag
{
	if (inFlag != useContactListGroups) {
		useContactListGroups = inFlag;

		[self _performChangeOfUseContactListGroups];
	}
}

- (void)_performChangeOfUseContactListGroups
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;

	[self delayListObjectNotifications];

	//Store the preference
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!useContactListGroups]
										 forKey:KEY_HIDE_CONTACT_LIST_GROUPS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];

	//Configure the sort controller to force ignoring of groups as appropriate
	[[self activeSortController] forceIgnoringOfGroups:(useContactListGroups ? NO : YES)];

	enumerator = [[[[contactList containedObjects] copy] autorelease] objectEnumerator];

	if (useContactListGroups) { /* We are now using contact list groups, but we weren't before. */

		//Restore the grouping of all root-level contacts
		while ((listObject = [enumerator nextObject])) {
			if ([listObject isKindOfClass:[AIListContact class]]) {
				[(AIListContact *)listObject restoreGrouping];
			}
		}

	} else { /* We are no longer using contact list groups, but we were before. */

		while ((listObject = [enumerator nextObject])) {
			if ([listObject isKindOfClass:[AIListGroup class]]) {
				NSArray			*containedObjects;
				NSEnumerator	*groupEnumerator;
				AIListObject	*containedListObject;

				containedObjects = [[(AIListGroup *)listObject containedObjects] copy];
				groupEnumerator = [containedObjects objectEnumerator];
				while ((containedListObject = [groupEnumerator nextObject])) {
					if ([containedListObject isKindOfClass:[AIListContact class]]) {
						[self _moveContactLocally:(AIListContact *)containedListObject
										  toGroup:contactList];
					}
				}
				[containedObjects release];
			}
		}
	}

	//Stop delaying object notifications; this will automatically resort the contact list, so we're done.
	[self endListObjectNotificationsDelay];
}

- (void)prepareShowHideGroups
{
	//Load the preference
	useContactListGroups = ![[[adium preferenceController] preferenceForKey:KEY_HIDE_CONTACT_LIST_GROUPS
																	  group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];

	//Show offline contacts menu item
    menuItem_showGroups = [[NSMenuItem alloc] initWithTitle:SHOW_GROUPS_MENU_TITLE
													target:self
													action:@selector(toggleShowGroups:)
											 keyEquivalent:@""];
	[menuItem_showGroups setState:useContactListGroups];
	[[adium menuController] addMenuItem:menuItem_showGroups toLocation:LOC_View_Toggles];

	//Toolbar
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SHOW_GROUPS_IDENTIFER
														  label:AILocalizedString(@"Show Groups",nil)
												   paletteLabel:AILocalizedString(@"Toggle Groups Display",nil)
														toolTip:AILocalizedString(@"Toggle display of groups",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:(useContactListGroups ?
																					 @"togglegroups_transparent" :
																					 @"togglegroups")
																		   forClass:[self class]]
														 action:@selector(toggleShowGroupsToolbar:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ContactList"];
}

- (IBAction)toggleShowGroups:(id)sender
{
	//Flip-flop.
	useContactListGroups = !useContactListGroups;
	[menuItem_showGroups setState:useContactListGroups];

	//Update the contact list.  Do it on the next run loop for better menu responsiveness, as it may be a lengthy procedure.
	[self performSelector:@selector(_performChangeOfUseContactListGroups)
			   withObject:nil
			   afterDelay:0.000001];
}

- (IBAction)toggleShowGroupsToolbar:(id)sender
{
	[self toggleShowGroups:sender];

	[sender setImage:[NSImage imageNamed:(useContactListGroups ?
										  @"togglegroups_transparent" :
										  @"togglegroups")
								forClass:[self class]]];
}

- (BOOL)useOfflineGroup
{
	return useOfflineGroup;
}

- (void)setUseOfflineGroup:(BOOL)inFlag
{
	if (inFlag != useOfflineGroup) {
		useOfflineGroup = inFlag;
		
		if (useOfflineGroup) {
			[self registerListObjectObserver:self];	
		} else {
			[self updateAllListObjectsForObserver:self];
			[self unregisterListObjectObserver:self];	
		}
	}
}

- (AIListGroup *)offlineGroup
{
	return [self groupWithUID:AILocalizedString(@"Offline", "Name of offline group")];
}

#pragma mark Meta Contacts
//Meta Contacts --------------------------------------------------------------------------------------------------------
/*
 * @brief Create or load a metaContact
 *
 * @param inObjectID The objectID of an existing but unloaded metaContact, or nil to create and save a new metaContact
 */
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID
{
	NSString		*metaContactDictKey;
	AIMetaContact   *metaContact;
	BOOL			shouldRestoreContacts = YES;

	//If no object ID is provided, use the next available object ID
	//(MetaContacts should always have an individually unique object id)
	if (!inObjectID) {
		int topID = [[[adium preferenceController] preferenceForKey:TOP_METACONTACT_ID
															  group:PREF_GROUP_CONTACT_LIST] intValue];
		inObjectID = [NSNumber numberWithInt:topID];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:([inObjectID intValue] + 1)]
											 forKey:TOP_METACONTACT_ID
											  group:PREF_GROUP_CONTACT_LIST];

		//No reason to waste time restoring contacts when none are in the meta contact yet.
		shouldRestoreContacts = NO;
	}

	//Look for a metacontact with this object ID.  If none is found, create one
	//and add its contained contacts to it.
	metaContactDictKey = [AIMetaContact internalObjectIDFromObjectID:inObjectID];

	metaContact = [metaContactDict objectForKey:metaContactDictKey];
	if (!metaContact) {
		metaContact = [[AIMetaContact alloc] initWithObjectID:inObjectID];

		//Keep track of it in our metaContactDict for retrieval by objectID
		[metaContactDict setObject:metaContact forKey:metaContactDictKey];

		//Add it to our more general contactDict, as well
		[contactDict setObject:metaContact forKey:[metaContact internalUniqueObjectID]];

		/* We restore contacts (actually, internalIDs for contacts, to be added as necessary later) if the metaContact
		 * existed before this call to metaContactWithObjectID:
		 */
		if (shouldRestoreContacts) {
			if (![self _restoreContactsToMetaContact:metaContact]) {

				//If restoring the metacontact did not actually add any contacts, delete it since it is invalid
				[self breakdownAndRemoveMetaContact:metaContact];
				metaContact = nil;
			}
		}
		
		/* As with contactWithService:account:UID, update all attributes so observers are initially informed of
		 * this object's existence.
		 */
		[self _updateAllAttributesOfObject:metaContact];
		
		[metaContact release];
	}

	return (metaContact);
}

/*
 * @brief Associate the appropriate internal IDs for contained contacts with a metaContact
 *
 * @result YES if one or more contacts was associated with the metaContact; NO if none were.
 */
- (BOOL)_restoreContactsToMetaContact:(AIMetaContact *)metaContact
{
	NSDictionary	*allMetaContactsDict = [[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																					group:PREF_GROUP_CONTACT_LIST];
	NSArray			*containedContactsArray = [allMetaContactsDict objectForKey:[metaContact internalObjectID]];
	BOOL			restoredContacts;

	if ([containedContactsArray count]) {
		[self _restoreContactsToMetaContact:metaContact
				 fromContainedContactsArray:containedContactsArray];

		restoredContacts = YES;

	} else {
		restoredContacts = NO;
	}

	return restoredContacts;
}

/*
 * @brief Associate the internal IDs for an array of contacts with a specific metaContact
 *
 * This does not actually place any AIListContacts within the metaContact.  Instead, it updates the contactToMetaContactLookupDict
 * dictionary to have metaContact associated with the list contacts specified by containedContactsArray. This
 * allows us to add them lazily to the metaContact (in contactWithService:account:UID:) as necessary.
 *
 * @param metaContact The metaContact to which contact referneces are added
 * @param containedContactsArray An array of NSDictionary objects, each of which has SERVICE_ID_KEY and UID_KEY which together specify an internalObjectID of an AIListContact
 */
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact fromContainedContactsArray:(NSArray *)containedContactsArray
{
	NSEnumerator		*enumerator = [containedContactsArray objectEnumerator];
	NSDictionary		*containedContactDict;

	while ((containedContactDict = [enumerator nextObject])) {
		/* Before Adium 0.80, metaContacts could be created within metaContacts. Simply ignore any attempt to restore
		* such irroneous data, which will have a YES boolValue for KEY_IS_METACONTACT. */
		if (![[containedContactDict objectForKey:KEY_IS_METACONTACT] boolValue]) {
			/* Assign this metaContact to the appropriate internalObjectID for containedContact's represented listObject.
			 *
			 * As listObjects are loaded/created/requested which match this internalObjectID, 
			 * they will be inserted into the metaContact.
			 */
			NSString	*internalObjectID = [AIListObject internalObjectIDForServiceID:[containedContactDict objectForKey:SERVICE_ID_KEY]
																				   UID:[containedContactDict objectForKey:UID_KEY]];
			[contactToMetaContactLookupDict setObject:metaContact
											   forKey:internalObjectID];
		}
	}
}


//Add a list object to a meta contact, setting preferences and such
//so the association is lasting across program launches.
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	if (listObject != metaContact) {

		//If listObject is a metaContact, perform addListObject:toMetaContact: recursively
		if ([listObject isKindOfClass:[AIMetaContact class]]) {
			NSEnumerator	*enumerator = [[[[(AIMetaContact *)listObject containedObjects] copy] autorelease] objectEnumerator];
			AIListObject	*someObject;

			while ((someObject = [enumerator nextObject])) {

				[self addListObject:someObject toMetaContact:metaContact];
			}

		} else {
			AIMetaContact		*oldMetaContact;

			//Obtain any metaContact this listObject is currently within, so we can remove it later
			oldMetaContact = [contactToMetaContactLookupDict objectForKey:[listObject internalObjectID]];

			if ([self _performAddListObject:listObject toMetaContact:metaContact]) {
				//If this listObject was not in this metaContact in any form before, store the change
				if (metaContact != oldMetaContact) {
					//Remove the list object from any other metaContact it is in at present
					if (oldMetaContact) {
						[self removeListObject:listObject fromMetaContact:oldMetaContact];
					}

					[self _storeListObject:listObject inMetaContact:metaContact];
				}
			}
		}
	}
}

- (void)_storeListObject:(AIListObject *)listObject inMetaContact:(AIMetaContact *)metaContact
{
	AILog(@"MetaContacts: Storing %@ in %@",listObject, metaContact);
	NSDictionary		*containedContactDict;
	NSMutableDictionary	*allMetaContactsDict;
	NSMutableArray		*containedContactsArray;

	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];

	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																	group:PREF_GROUP_CONTACT_LIST] mutableCopy];
	if (!allMetaContactsDict) {
		allMetaContactsDict = [[NSMutableDictionary alloc] init];
	}

	//Load the array for the new metaContact
	containedContactsArray = [[allMetaContactsDict objectForKey:metaContactInternalObjectID] mutableCopy];
	if (!containedContactsArray) containedContactsArray = [[NSMutableArray alloc] init];
	containedContactDict = nil;

	//Create the dictionary describing this list object
	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],KEY_IS_METACONTACT,
			[(AIMetaContact *)listObject objectID],KEY_OBJECTID,nil];

	} else if ([listObject isKindOfClass:[AIListContact class]]) {
		containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[[listObject service] serviceID],SERVICE_ID_KEY,
			[listObject UID],UID_KEY,nil];
	}

	//Only add if this dict isn't already in the array
	if (containedContactDict && ([containedContactsArray indexOfObject:containedContactDict] == NSNotFound)) {
		[containedContactsArray addObject:containedContactDict];
		[allMetaContactsDict setObject:containedContactsArray forKey:metaContactInternalObjectID];

		//Save
		[self _saveMetaContacts:allMetaContactsDict];

		[[adium contactAlertsController] mergeAndMoveContactAlertsFromListObject:listObject
																  intoListObject:metaContact];
	}

	[allMetaContactsDict release];
	[containedContactsArray release];
}

//Actually adds a list object to a meta contact. No preferences are changed.
//Attempts to add the list object, causing group reassignment and updates our contactToMetaContactLookupDict
//for quick lookup of the MetaContact given a AIListContact uniqueObjectID if successful.
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	AIListObject<AIContainingObject>	*localGroup;
	BOOL								success;

	localGroup = [listObject containingObject];

	//Remove the object from its previous containing group
	if (localGroup && (localGroup != metaContact)) {
		[localGroup removeObject:listObject];
		[self _listChangedGroup:localGroup object:listObject];
	}

	//AIMetaContact will handle reassigning the list object's grouping to being itself
	if ((success = [metaContact addObject:listObject])) {
		[contactToMetaContactLookupDict setObject:metaContact forKey:[listObject internalObjectID]];

		[self _listChangedGroup:metaContact object:listObject];
		//If the metaContact isn't in a group yet, use the group of the object we just added
		if ((![metaContact containingObject]) && localGroup) {
			//Add the new meta contact to our list
			[(AIMetaContact *)localGroup addObject:metaContact];
			[self _listChangedGroup:localGroup object:metaContact];
		}
	}

	return success;
}

- (void)removeAllListObjectsMatching:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	NSEnumerator	*enumerator;
	AIListObject	*theObject;
	
	enumerator = [[self allContactsWithService:[listObject service]
										   UID:[listObject UID]
								  existingOnly:YES] objectEnumerator];

	//Remove from the contactToMetaContactLookupDict first so we don't try to reinsert into this metaContact
	[contactToMetaContactLookupDict removeObjectForKey:[listObject internalObjectID]];

	[self delayListObjectNotifications];
	while ((theObject = [enumerator nextObject])) {
		[self removeListObject:theObject fromMetaContact:metaContact];
	}
	[self endListObjectNotificationsDelay];
}

- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	NSEnumerator		*enumerator;
	NSArray				*containedContactsArray;
	NSDictionary		*containedContactDict = nil;
	NSMutableDictionary	*allMetaContactsDict;
	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];

	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																   group:PREF_GROUP_CONTACT_LIST];

	//Load the array for the metaContact
	containedContactsArray = [allMetaContactsDict objectForKey:metaContactInternalObjectID];

	//Enumerate it, looking only for the appropriate type of containedContactDict
	enumerator = [containedContactsArray objectEnumerator];

	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		NSNumber	*listObjectObjectID = [(AIMetaContact *)listObject objectID];

		while ((containedContactDict = [enumerator nextObject])) {
			if (([[containedContactDict objectForKey:KEY_IS_METACONTACT] boolValue]) &&
				(([(NSNumber *)[containedContactDict objectForKey:KEY_OBJECTID] compare:listObjectObjectID]) == 0)) {
				break;
			}
		}

	} else if ([listObject isKindOfClass:[AIListContact class]]) {

		NSString	*listObjectUID = [listObject UID];
		NSString	*listObjectServiceID = [[listObject service] serviceID];

		while ((containedContactDict = [enumerator nextObject])) {
			if ([[containedContactDict objectForKey:UID_KEY] isEqualToString:listObjectUID] &&
				[[containedContactDict objectForKey:SERVICE_ID_KEY] isEqualToString:listObjectServiceID]) {
				break;
			}
		}
	}

	//If we found a matching dict (referring to our contact in the old metaContact), remove it and store the result
	if (containedContactDict) {
		NSMutableArray		*newContainedContactsArray;
		NSMutableDictionary	*newAllMetaContactsDict;

		newContainedContactsArray = [containedContactsArray mutableCopy];
		[newContainedContactsArray removeObjectIdenticalTo:containedContactDict];

		newAllMetaContactsDict = [allMetaContactsDict mutableCopy];
		[newAllMetaContactsDict setObject:newContainedContactsArray
								   forKey:metaContactInternalObjectID];

		[self _saveMetaContacts:newAllMetaContactsDict];

		[newContainedContactsArray release];
		[newAllMetaContactsDict release];
	}

	//The listObject can be within the metaContact without us finding a containedContactDict if we are removing multiple
	//listContacts referring to the same UID & serviceID combination - that is, on multiple accounts on the same service.
	//We therefore request removal of the object regardless of the if (containedContactDict) check above.
	[metaContact removeObject:listObject];
}


/*!
 * @brief Groups UIDs for services into a single metacontact
 *
 * UIDsArray and servicesArray should be a paired set of arrays, with each index corresponding to
 * a UID and a service, respectively, which together define a contact which should be included in the grouping.
 *
 * Assumption: This is only called after the contact list is finished loading, which occurs via
 * -(void)controllerDidLoad above.
 *
 * @param UIDsArray NSArray of UIDs
 * @param servicesArray NSArray of serviceIDs corresponding to entries in UIDsArray
 */
- (AIMetaContact *)groupUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray
{
	NSMutableSet	*internalObjectIDs = [[NSMutableSet alloc] init];
	AIMetaContact	*metaContact = nil;
	NSEnumerator	*enumerator;
	NSString		*internalObjectID;
	int				count = [UIDsArray count];
	int				i;
				
	//Build an array of all contacts matching this description (multiple accounts on the same service listing
	//the same UID mean that we can have multiple AIListContact objects with a UID/service combination)
	for (i = 0; i < count; i++) {
		NSString	*serviceID = [servicesArray objectAtIndex:i];
		NSString	*UID = [UIDsArray objectAtIndex:i];
		
		internalObjectID = [AIListObject internalObjectIDForServiceID:serviceID
																  UID:UID];
		if(!metaContact) {
			metaContact = [contactToMetaContactLookupDict objectForKey:internalObjectID];
		}
		
		[internalObjectIDs addObject:internalObjectID];
	}
	
	//Create a new metaContact is we didn't find one.
	if (!metaContact) {
		metaContact = [self metaContactWithObjectID:nil];
	}
	
	enumerator = [internalObjectIDs objectEnumerator];
	while ((internalObjectID = [enumerator nextObject])) {
		AIListObject	*existingObject;
		if ((existingObject = [self existingListObjectWithUniqueID:internalObjectID])) {
			/* If there is currently an object (or multiple objects) matching this internalObjectID
			 * we should add immediately.
			 */
			[self addListObject:existingObject
				  toMetaContact:metaContact];	
		} else {
			/* If no objects matching this internalObjectID exist, we can simply add to the 
			 * contactToMetaContactLookupDict for use if such an object is created later.
			 */
			[contactToMetaContactLookupDict setObject:metaContact
											   forKey:internalObjectID];			
		}
	}

	return metaContact;
}

/* @brief Group an NSArray of AIListContacts, returning the meta contact into which they are added.
 *
 * This will reuse an existing metacontact (for one of the contacts in the array) if possible.
 * @param contactsToGroupArray Contacts to group together
 */
- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray
{
	NSEnumerator	*enumerator;
	AIListContact   *listContact;
	AIMetaContact   *metaContact = nil;

	//Look for an existing MetaContact we can use.  The first one we find is the lucky winner.
	enumerator = [contactsToGroupArray objectEnumerator];
	while ((listContact = [enumerator nextObject]) && (metaContact == nil)) {
		if ([listContact isKindOfClass:[AIMetaContact class]]) {
			metaContact = (AIMetaContact *)listContact;
		} else {
			metaContact = [contactToMetaContactLookupDict objectForKey:[listContact internalObjectID]];
		}
	}

	//Create a new metaContact is we didn't find one.
	if (!metaContact) {
		metaContact = [self metaContactWithObjectID:nil];
	}
	
	/* Add all these contacts to our MetaContact.
		* Some may already be present, but that's fine, as nothing will happen.
		*/
	enumerator = [contactsToGroupArray objectEnumerator];
	while ((listContact = [enumerator nextObject])) {
		[self addListObject:listContact toMetaContact:metaContact];
	}
	
	return metaContact;
}

- (void)breakdownAndRemoveMetaContact:(AIMetaContact *)metaContact
{
	//Remove the objects within it from being inside it
	NSArray								*containedObjects = [[metaContact containedObjects] copy];
	NSEnumerator						*metaEnumerator = [containedObjects objectEnumerator];
	AIListObject<AIContainingObject>	*containingObject = [metaContact containingObject];
	AIListObject						*object;

	NSMutableDictionary *allMetaContactsDict = [[[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																						 group:PREF_GROUP_CONTACT_LIST] mutableCopy];

	while ((object = [metaEnumerator nextObject])) {

		//Remove from the contactToMetaContactLookupDict first so we don't try to reinsert into this metaContact
		[contactToMetaContactLookupDict removeObjectForKey:[object internalObjectID]];

		[self removeListObject:object fromMetaContact:metaContact];
	}

	//Then, procede to remove the metaContact

	//Protect!
	[metaContact retain];

	//Remove it from its containing group
	[containingObject removeObject:metaContact];

	NSString	*metaContactInternalObjectID = [metaContact internalObjectID];

	//Remove our reference to it internally
	[metaContactDict removeObjectForKey:metaContactInternalObjectID];

	//Remove it from the preferences dictionary
	[allMetaContactsDict removeObjectForKey:metaContactInternalObjectID];

	//XXX - contactToMetaContactLookupDict

	//Post the list changed notification for the old containingObject
	[self _listChangedGroup:containingObject object:metaContact];

	//Save the updated allMetaContactsDict which no longer lists the metaContact
	[self _saveMetaContacts:allMetaContactsDict];

	//Protection is overrated.
	[metaContact release];
	[containedObjects release];
	[allMetaContactsDict release];
}

- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict
{
	AILog(@"MetaContacts: Saving!");
	[[adium preferenceController] setPreference:allMetaContactsDict
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	[[adium preferenceController] setPreference:[allMetaContactsDict allKeys]
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
}

//Sort list objects alphabetically by their display name
int contactDisplayNameSort(AIListObject *objectA, AIListObject *objectB, void *context)
{
	return [[objectA displayName] caseInsensitiveCompare:[objectB displayName]];
}

//Return either the highest metaContact containing this list object, or the list object itself.  Appropriate for when
//preferences should be read from/to the most generalized contact possible.
- (AIListObject *)parentContactForListObject:(AIListObject *)listObject
{
	if ([listObject isKindOfClass:[AIListContact class]]) {
		//Find the highest-up metaContact
		AIListObject	*containingObject;
		while ([(containingObject = [listObject containingObject]) isKindOfClass:[AIMetaContact class]]) {
			listObject = (AIMetaContact *)containingObject;
		}
	}

	return listObject;
}

#pragma mark Preference observing
/*!
* @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime ||
		[key isEqualToString:KEY_USE_OFFLINE_GROUP]) {

		[self setUseOfflineGroup:[[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]];
	}
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (!inModifiedKeys ||
		[inModifiedKeys containsObject:@"Online"]) {

		if ([inObject isKindOfClass:[AIListContact class]]) {			
			//If this contact is not its own parent contact, don't bother since we'll get an update for the parent if appropriate
			if (inObject == [(AIListContact *)inObject parentContact]) {
				if (useOfflineGroup) {
					AIListObject *containingObject = [inObject containingObject];
					
					if ([inObject online] &&
						(containingObject == [self offlineGroup])) {
						[(AIListContact *)inObject restoreGrouping];
						
					} else if (![inObject online] &&
							   containingObject &&
							   (containingObject != [self offlineGroup])) {
						[self _moveContactLocally:(AIListContact *)inObject
										  toGroup:[self offlineGroup]];
					}
					
				} else {
					if ([inObject containingObject] == [self offlineGroup]) {
						[(AIListContact *)inObject restoreGrouping];
					}
				}
			}
		}
	}
	
	return nil;
}

//Contact Info --------------------------------------------------------------------------------
#pragma mark Contact Info
//Show info for the selected contact
- (IBAction)showContactInfo:(id)sender
{
	AIListObject *listObject = nil;

	if ((sender == menuItem_getInfoContextualContact) || (sender == menuItem_getInfoContextualGroup)) {
		listObject = [[adium menuController] currentContextMenuObject];
	} else {
		listObject = [self selectedListObject];
	}

	if (listObject) {
		[NSApp activateIgnoringOtherApps:YES];
		[[[AIContactInfoWindowController showInfoWindowForListObject:listObject] window] makeKeyAndOrderFront:nil];
	}
}

- (void)showSpecifiedContactInfo:(id)sender
{
	[ESShowContactInfoPromptController showPrompt];
}

//Add a contact info view
- (void)addContactInfoPane:(AIContactInfoPane *)inPane
{
    [contactInfoPanes addObject:inPane];
}

//Prepare the contact info menu and toolbar items
- (void)prepareContactInfo
{
	contactInfoPanes = [[NSMutableArray alloc] init];

	//Add our get info contextual menu item
	menuItem_getInfoContextualContact = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																							 target:self
																							 action:@selector(showContactInfo:)
																					  keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_getInfoContextualContact
									   toLocation:Context_Contact_Manage];

	menuItem_getInfoContextualGroup = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																						   target:self
																						   action:@selector(showContactInfo:)
																					keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_getInfoContextualGroup
									   toLocation:Context_Group_Manage];

	//Install the standard Get Info menu item which will always be command-shift-I
	menuItem_getInfo = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																			target:self
																			action:@selector(showContactInfo:)
																	 keyEquivalent:@"i"];
	[menuItem_getInfo setKeyEquivalentModifierMask:GET_INFO_MASK];
	[[adium menuController] addMenuItem:menuItem_getInfo toLocation:LOC_Contact_Info];

	/* Install the alternate Get Info menu item which will be alternately command-I and command-shift-I, in the contact list
	 * and in all other places, respectively.
	 */
	menuItem_getInfoAlternate = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																					 target:self
																					 action:@selector(showContactInfo:)
																			  keyEquivalent:@"i"];
	[menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
	[menuItem_getInfoAlternate setAlternate:YES];
	[[adium menuController] addMenuItem:menuItem_getInfoAlternate toLocation:LOC_Contact_Info];

	//Register for the contact list notifications
	[[adium notificationCenter] addObserver:self selector:@selector(contactListDidBecomeMain:)
									   name:Interface_ContactListDidBecomeMain
									 object:nil];
	[[adium notificationCenter] addObserver:self selector:@selector(contactListDidResignMain:)
									   name:Interface_ContactListDidResignMain
									 object:nil];

	//Watch changes in viewContactInfoMenuItem_alternate's menu so we can maintain its alternate status
	//(it will expand into showing both the normal and the alternate items when the menu changes)
	[[adium notificationCenter] addObserver:self selector:@selector(menuChanged:)
									   name:Menu_didChange
									 object:[menuItem_getInfoAlternate menu]];

	//Install the Get Info (prompting for a contact name) menu item
	menuItem_getInfoWithPrompt = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO_WITH_PROMPT
																					  target:self
																					  action:@selector(showSpecifiedContactInfo:)
																			   keyEquivalent:@"i"];
	[menuItem_getInfoWithPrompt setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];

	[[adium menuController] addMenuItem:menuItem_getInfo toLocation:LOC_Contact_Info];

	//Add our get info toolbar item
	NSToolbarItem   *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowInfo"
																		   label:AILocalizedString(@"Info",nil)
																	paletteLabel:TITLE_SHOW_INFO
																		 toolTip:TOOLTIP_SHOW_INFO
																		  target:self
																 settingSelector:@selector(setImage:)
																	 itemContent:[NSImage imageNamed:@"info" forClass:[self class]]
																		  action:@selector(showContactInfo:)
																			menu:nil];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

//Always be able to show the inspector
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ((menuItem == menuItem_getInfo) || (menuItem == menuItem_getInfoAlternate)) {
		return [self selectedListObject] != nil;

	} else if ((menuItem == menuItem_getInfoContextualContact) || (menuItem == menuItem_getInfoContextualGroup)) {
		return [[adium menuController] currentContextMenuObject] != nil;

	} else if (menuItem == menuItem_getInfoWithPrompt) {
		return [[adium accountController] oneOrMoreConnectedAccounts];
	}

	return YES;
}

//
- (NSArray *)contactInfoPanes
{
	return contactInfoPanes;
}

- (void)contactListDidBecomeMain:(NSNotification *)notification
{
    [[adium menuController] removeItalicsKeyEquivalent];
    [menuItem_getInfoAlternate setKeyEquivalentModifierMask:(NSCommandKeyMask)];
	[menuItem_getInfoAlternate setAlternate:YES];
}

- (void)contactListDidResignMain:(NSNotification *)notification
{
    //set our alternate modifier mask back to the obscure combination
    [menuItem_getInfoAlternate setKeyEquivalent:@"i"];
    [menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
    [menuItem_getInfoAlternate setAlternate:YES];

    //Now give the italics its combination back
    [[adium menuController] restoreItalicsKeyEquivalent];
}

- (void)menuChanged:(NSNotification *)notification
{
	[NSMenu updateAlternateMenuItem:menuItem_getInfoAlternate];
}


//Selected contact ------------------------------------------------
#pragma mark Selected contact
//Returns the "selected"(represented) contact (By finding the first responder that returns a contact)
//If no listObject is found, try to find a list object selected in a group chat
- (AIListObject *)selectedListObject
{
	AIListObject *listObject = [self _performSelectorOnFirstAvailableResponder:@selector(listObject)];
	if ( !listObject) {
		listObject = [self _performSelectorOnFirstAvailableResponder:@selector(preferredListObject)];
	}
	return listObject;
}
- (AIListObject *)selectedListObjectInContactList
{
	return [self _performSelectorOnFirstAvailableResponder:@selector(listObject) conformingToProtocol:@protocol(ContactListOutlineView)];
}
- (NSArray *)arrayOfSelectedListObjectsInContactList
{
	return [self _performSelectorOnFirstAvailableResponder:@selector(arrayOfListObjects) conformingToProtocol:@protocol(ContactListOutlineView)];
}

- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector
{
    NSResponder	*responder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
    //Check the first responder
    if ([responder respondsToSelector:selector]) {
        return [responder performSelector:selector];
    }

    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if ([responder respondsToSelector:selector]) {
            return [responder performSelector:selector];
        }

    } while (responder != nil);

    //None found, return nil
    return nil;
}
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol
{
	NSResponder *responder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
	//Check the first responder
	if ([responder conformsToProtocol:protocol] && [responder respondsToSelector:selector]) {
		return [responder performSelector:selector];
	}

    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if ([responder conformsToProtocol:protocol] && [responder respondsToSelector:selector]) {
            return [responder performSelector:selector];
        }

    } while (responder != nil);

    //None found, return nil
    return nil;
}

//Contact Sorting --------------------------------------------------------------------------------
#pragma mark Contact Sorting
//Register sorting code
- (void)registerListSortController:(AISortController *)inController
{
    [sortControllerArray addObject:inController];
}
- (NSArray *)sortControllerArray
{
    return sortControllerArray;
}

//Set and get the active sort controller
- (void)setActiveSortController:(AISortController *)inController
{
    activeSortController = inController;

	[activeSortController didBecomeActive];

	//The newly-active sort controller needs to know whether it should be forced to ignore groups
	[[self activeSortController] forceIgnoringOfGroups:(useContactListGroups ? NO : YES)];

    //Resort the list
    [self sortContactList];
}
- (AISortController *)activeSortController
{
    return activeSortController;
}

//Sort the entire contact list
- (void)sortContactList
{
    [contactList sortGroupAndSubGroups:YES sortController:activeSortController];
	[[adium notificationCenter] postNotificationName:Contact_OrderChanged object:nil];
}

//Sort an individual object
- (void)sortListObject:(AIListObject *)inObject
{
	if (updatesAreDelayed) {
		delayedContactChanges++;
	} else {
		AIListObject		*group = [inObject containingObject];

		if ([group isKindOfClass:[AIListGroup class]]) {
			//Sort the groups containing this object
			[(AIListGroup *)group sortListObject:inObject sortController:activeSortController];
			[[adium notificationCenter] postNotificationName:Contact_OrderChanged object:inObject];
		}
	}
}

//List object observers ------------------------------------------------------------------------------------------------
#pragma mark List object observers
//Registers code to observe handle status changes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver
{
	//Add the observer
    [contactObservers addObject:[NSValue valueWithNonretainedObject:inObserver]];

    //Let the new observer process all existing objects
	[self updateAllListObjectsForObserver:inObserver];
}

- (void)unregisterListObjectObserver:(id)inObserver
{
    [contactObservers removeObject:[NSValue valueWithNonretainedObject:inObserver]];
}


/*
 * @brief Update all contacts for an observer, notifying the observer of each one in turn
 *
 * @param contacts The contacts to update, or nil to update all contacts
 * @param inObserver The observer
 */
- (void)updateContacts:(NSSet *)contacts forObserver:(id <AIListObjectObserver>)inObserver
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;

	[self delayListObjectNotifications];
	
	enumerator = (contacts ? [contacts objectEnumerator] : [contactDict objectEnumerator]);
	while ((listObject = [enumerator nextObject])) {
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
		
		//If this contact is within a meta contact, update the meta contact too
		AIListObject	*containingObject = [listObject containingObject];
		if (containingObject && [containingObject isKindOfClass:[AIMetaContact class]]) {
			NSSet	*attributes = [inObserver updateListObject:containingObject
														  keys:nil
														silent:YES];
			if (attributes) [self listObjectAttributesChanged:containingObject
												 modifiedKeys:attributes];
		}
	}
	
	[self endListObjectNotificationsDelay];
}

//Instructs a controller to update all available list objects
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;

	[self delayListObjectNotifications];

	//All contacts
	[self updateContacts:nil forObserver:inObserver];

    //Reset all groups
	enumerator = [groupDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
	}

	//Reset all accounts
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
	}

	//
	[self endListObjectNotificationsDelay];
}


//Notify observers of a status change.  Returns the modified attribute keys
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent
{
	NSMutableSet	*attrChange = nil;
	NSEnumerator	*enumerator;
	NSValue			*observerValue;
	
	//Let our observers know
	enumerator = [contactObservers objectEnumerator];
	while ((observerValue = [enumerator nextObject])) {
		id <AIListObjectObserver>	observer;
		NSSet						*newKeys;

		observer = [observerValue nonretainedObjectValue];
		if ((newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent])) {
			if (!attrChange) attrChange = [NSMutableSet set];
			[attrChange unionSet:newKeys];
		}
	}

	//Send out the notification for other observers
	[[adium notificationCenter] postNotificationName:ListObject_StatusChanged
											  object:inObject
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys
																								 forKey:@"Keys"] : nil)];

	return attrChange;
}

//Command all observers to apply their attributes to an object
- (void)_updateAllAttributesOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [contactObservers objectEnumerator];
	NSValue			*observerValue;

	while ((observerValue = [enumerator nextObject])) {
		id <AIListObjectObserver>	observer;
		
		observer = [observerValue nonretainedObjectValue];

		[observer updateListObject:inObject keys:nil silent:YES];
	}
}



//Contact List Access --------------------------------------------------------------------------------------------------
#pragma mark Contact List Access
//Returns the main contact list group
- (AIListGroup *)contactList
{
    return contactList;
}

//Return a flat array of all the objects in a group on an account (and all subgroups, if desired)
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups onAccount:(AIAccount *)inAccount
{
	NSMutableArray	*contactArray = [NSMutableArray array];
	NSEnumerator	*enumerator;
    AIListObject	*object;

	if (inGroup == nil) inGroup = contactList;  //Passing nil scans the entire contact list

	enumerator = [[inGroup containedObjects] objectEnumerator];
    while ((object = [enumerator nextObject])) {
        if ([object isMemberOfClass:[AIMetaContact class]] || [object isMemberOfClass:[AIListGroup class]]) {
            if (subGroups) {
				[contactArray addObjectsFromArray:[self allContactsInGroup:(AIListGroup *)object
																 subgroups:subGroups
																 onAccount:inAccount]];
			}
		} else if ([object isMemberOfClass:[AIListContact class]]) {
			if (!inAccount ||
			   ([(AIListContact *)object account] == inAccount)) {
				[contactArray addObject:object];
			}
		}
	}

	return contactArray;
}

//Contact List Menus- --------------------------------------------------------------------------------------------------
#pragma mark Contact List Menus

//Returns a menu containing all the groups within a group
//- Selector called on group selection is selectGroup:
//- The menu items represented object is the group it represents
- (NSMenu *)menuOfAllGroupsInGroup:(AIListGroup *)inGroup withTarget:(id)target
{
	NSMenu	*menu = [[NSMenu alloc] initWithTitle:@""];

	[menu setAutoenablesItems:NO];
	[self _menuOfAllGroups:menu forGroup:inGroup withTarget:target level:0];

	return [menu autorelease];
}
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level
{
	NSEnumerator	*enumerator;
	AIListObject	*object;

	//Passing nil scans the entire contact list
	if (group == nil) group = contactList;

	//Enumerate this group and process all groups we find within it
	enumerator = [[group containedObjects] objectEnumerator];
	while ((object = [enumerator nextObject])) {
		if ([object isKindOfClass:[AIListGroup class]]) {
			NSMenuItem	*menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[object displayName]
																						 target:target
																						 action:@selector(selectGroup:)
																				  keyEquivalent:@""];
			[menuItem setRepresentedObject:object];
			if ([menuItem respondsToSelector:@selector(setIndentationLevel:)]) {
				[menuItem setIndentationLevel:level];
			}
			[menu addItem:menuItem];
			[menuItem release];
			
			[self _menuOfAllGroups:menu forGroup:(AIListGroup *)object withTarget:target level:level+1];
		}
	}
}


//Returns a menu containing all the objects in a group on an account
//- Selector called on contact selection is selectContact:
//- The menu item's represented object is the contact it represents
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inObject withTarget:(id)target{
	return [self menuOfAllContactsInContainingObject:inObject withTarget:target firstLevel:YES];
}
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inObject withTarget:(id)target firstLevel:(BOOL)firstLevel
{
    NSEnumerator				*enumerator;
    AIListObject				*object;

	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];

	//Passing nil scans the entire contact list
	if (inObject == nil) inObject = contactList;

	//The pull down menu needs an extra item at the top of its root menu to handle the selection.
	if (firstLevel) [menu addItemWithTitle:@"" action:nil keyEquivalent:@""];

	//All menu items for all contained objects
	enumerator = [[inObject listContacts] objectEnumerator];
    while ((object = [enumerator nextObject])) {
		NSImage		*menuServiceImage;
		NSMenuItem	*menuItem;
		BOOL		needToCreateSubmenu;
		BOOL		isGroup = [object isKindOfClass:[AIListGroup class]];
		BOOL		isValidGroup = (isGroup &&
									[[(AIListGroup *)object containedObjects] count]);

		//We don't want to include empty groups
		if (!isGroup || isValidGroup) {

			needToCreateSubmenu = (isValidGroup ||
								   ([object isKindOfClass:[AIMetaContact class]] && ([[(AIMetaContact *)object listContacts] count] > 1)));

			
			menuServiceImage = [AIUserIcons menuUserIconForObject:object];
			
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(needToCreateSubmenu ?
																					[object displayName] :
																					[object formattedUID])
																			target:target
																			action:@selector(selectContact:)
																	 keyEquivalent:@""];
			
			if (needToCreateSubmenu) {
				[menuItem setSubmenu:[self menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)object withTarget:target firstLevel:NO]];
			}

			[menuItem setRepresentedObject:object];
			[menuItem setImage:menuServiceImage];
			[menu addItem:menuItem];
			[menuItem release];
		}
	}

	return [menu autorelease];
}

//Retrieving Specific Contacts -----------------------------------------------------------------------------------------
#pragma mark Retrieving Specific Contacts

//Retrieve a contact from the contact list (Creating if necessary)
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	AIListContact	*contact = nil;

	if (inUID && [inUID length] && inService) { //Ignore invalid requests
		NSString		*key = [AIListContact internalUniqueObjectIDForService:inService
																	   account:inAccount
																		   UID:inUID];

		contact = [contactDict objectForKey:key];
		if (!contact) {
			//Create
			contact = [[AIListContact alloc] initWithUID:inUID account:inAccount service:inService];

			//Do the update thing
			[self _updateAllAttributesOfObject:contact];

			//Check to see if we should add to a metaContact
			AIMetaContact *metaContact = [contactToMetaContactLookupDict objectForKey:[contact internalObjectID]];
			if (metaContact) {
				/* We already know to add this object to the metaContact, since we did it before with another object,
				   but this particular listContact is new and needs to be added directly to the metaContact
				   (on future launches, the metaContact will obtain it automatically since all contacts matching this UID
				   and serviceID should be included). */
				[self _performAddListObject:contact toMetaContact:metaContact];
			}
			
			//Set the contact as mobile if it is a phone number
			if ([inUID characterAtIndex:0] == '+') {
				[contact setIsMobile:YES notify:NotifyNever];
			}

			//Add
			[contactDict setObject:contact forKey:key];
			[contact release];
		}
	}

	return contact;
}

- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	if (inService && [inUID length]) {
		return [contactDict objectForKey:[AIListContact internalUniqueObjectIDForService:inService
																				 account:inAccount
																					 UID:inUID]];
	} else {
		return nil;
	}
}

/*
 * @brief Return a set of all contacts with a specified UID and service
 *
 * @param service The AIService in question
 * @param inUID The UID, which should be normalized (lower case, no spaces, etc.) as appropriate for the service
 * @param existingOnly If YES, only pre-existing contacts. If NO, an AIListContact is guaranteed to be returned
 *					   on each compatible account, even if one did not previously exist.
 */
- (NSSet *)allContactsWithService:(AIService *)service UID:(NSString *)inUID existingOnly:(BOOL)existingOnly
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSMutableSet	*returnContactSet = [NSMutableSet set];

	enumerator = [[[adium accountController] accountsCompatibleWithService:service] objectEnumerator];

	while ((account = [enumerator nextObject])) {
		AIListContact	*listContact;
		
		if (existingOnly) {
			listContact = [self existingContactWithService:service
												   account:account
													   UID:inUID];
		} else {
			listContact = [self contactWithService:service
										   account:account
											   UID:inUID];
		}

		if (listContact) {
			[returnContactSet addObject:listContact];
		}
	}

	return returnContactSet;
}

- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;

	//Contact
	enumerator = [contactDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([[listObject internalObjectID] isEqualToString:uniqueID]) return listObject;
	}

	//Group
	enumerator = [groupDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([[listObject internalObjectID] isEqualToString:uniqueID]) return listObject;
	}

	//Metacontact
	enumerator = [metaContactDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([[listObject internalObjectID] isEqualToString:uniqueID]) return listObject;
	}

	return nil;
}

- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact
{
	AIListContact   *returnContact = nil;
	AIAccount		*account;

	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		AIListObject	*preferredContact;
		NSString		*internalObjectID;


		//If we've messaged this object previously, prefer the last contact we sent to if that
		//contact is currently available
        internalObjectID = [inContact preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT
												 group:OBJECT_STATUS_CACHE];

        if ((internalObjectID) &&
		   (preferredContact = [self existingListObjectWithUniqueID:internalObjectID]) &&
		   ([preferredContact isKindOfClass:[AIListContact class]]) &&
		   ([preferredContact statusSummary] == AIAvailableStatus)) {
			returnContact = [self preferredContactForContentType:inType
												  forListContact:(AIListContact *)preferredContact];
        }

		//If the last contact we sent to is not available, use the metaContact's preferredContact
		if (!returnContact || ![returnContact online]) {
			//Recurse into metacontacts if necessary
			returnContact = [self preferredContactForContentType:inType
												  forListContact:[(AIMetaContact *)inContact preferredContact]];
		}

	} else {

		//We have a flat contact; find the best account for talking to this contact,
		//and return an AIListContact on that account
		account = [[adium accountController] preferredAccountForSendingContentType:inType
																		 toContact:inContact];
		if (account) {
			if ([inContact account] == account) {
				returnContact = inContact;
			} else {
				returnContact = [self contactWithService:[inContact service]
												 account:account
													 UID:[inContact UID]];
			}
		}
 	}

	return returnContact;
}

//Retrieve a list contact matching the UID and serviceID of the passed contact but on the specified account.
//In many cases this will be the same as inContact.
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact
{
	if (account && ([inContact account] != account)) {
		return [self contactWithService:[inContact service] account:account UID:[inContact UID]];
	} else {
		return inContact;
	}
}

//XXX - This is ridiculous.
- (AIListContact *)preferredContactWithUID:(NSString *)inUID andServiceID:(NSString *)inService forSendingContentType:(NSString *)inType
{
	AIService		*theService = [[adium accountController] firstServiceWithServiceID:inService];
	AIListContact	*tempListContact = [[AIListContact alloc] initWithUID:inUID
																service:theService];
	AIAccount		*account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																					  toContact:tempListContact
																				 includeOffline:YES];
	[tempListContact release];

	return [self contactWithService:theService account:account UID:inUID];
}


/*
 * @brief Watch outgoing content, remembering the user's choice of destination contact for contacts within metaContacts
 *
 * If the destination contact's parent contact differs from the destination contact itself, the chat is with a metaContact.
 * If that metaContact's preferred destination for messaging isn't the same as the contact which was just messaged,
 * update the preference so that a new chat with this metaContact would default to the proper contact.
 */
- (void)didSendContent:(NSNotification *)notification
{
    AIChat			*chat = [[notification userInfo] objectForKey:@"AIChat"];
    AIListContact	*destContact = [chat listObject];
    AIListContact	*metaContact;

    if (((metaContact = [destContact parentContact]) != destContact)) {
		NSString	*destinationInternalObjectID = [destContact internalObjectID];
		NSString	*currentPreferredDestination = [metaContact preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT
																		   group:OBJECT_STATUS_CACHE];

		if (![destinationInternalObjectID isEqualToString:currentPreferredDestination]) {
			[metaContact setPreference:destinationInternalObjectID
								forKey:KEY_PREFERRED_DESTINATION_CONTACT
								 group:OBJECT_STATUS_CACHE];
		}
    }
}

//Retrieving Groups ----------------------------------------------------------------------------------------------------
#pragma mark Retrieving Groups

//Retrieve a group from the contact list (Creating if necessary)
- (AIListGroup *)groupWithUID:(NSString *)groupUID
{
	AIListGroup		*group;

	if (!groupUID || ![groupUID length] || [groupUID isEqualToString:ADIUM_ROOT_GROUP_NAME]) {
		//Return our root group if it is requested
		group = contactList;
	} else {
		if (!(group = [groupDict objectForKey:groupUID])) {
			//Create
			group = [[AIListGroup alloc] initWithUID:groupUID];

			//Add
			[self _updateAllAttributesOfObject:group];
			[groupDict setObject:group forKey:groupUID];

			//Add to the contact list
			[contactList addObject:group];
			[self _listChangedGroup:contactList object:group];
			[group release];
		}
	}

	return group;
}

- (AIListGroup *)existingGroupWithUID:(NSString *)groupUID
{
	AIListGroup		*group;

	if (!groupUID || ![groupUID length] || [groupUID isEqualToString:ADIUM_ROOT_GROUP_NAME]) {
		//Return our root group if it is requested
		group = contactList;
	} else {
		group = [groupDict objectForKey:groupUID];
	}
	
	return group;
}

//Contact list editing -------------------------------------------------------------------------------------------------
#pragma mark Contact list editing
- (void)removeListObjects:(NSArray *)objectArray
{
	NSEnumerator	*enumerator = [objectArray objectEnumerator];
	AIListObject	*listObject;

	while ((listObject = [enumerator nextObject])) {
		if ([listObject isKindOfClass:[AIMetaContact class]]) {
			NSSet	*objectsToRemove = nil;

			//If the metaContact only has one listContact, we will remove that contact from all accounts
			if ([[(AIMetaContact *)listObject listContacts] count] == 1) {
				AIListContact	*listContact = [[(AIMetaContact *)listObject listContacts] objectAtIndex:0];
				
				objectsToRemove = [self allContactsWithService:[listContact service]
														   UID:[listContact UID]
												  existingOnly:YES];
			}

			//And actually remove the single contact if applicable
			if (objectsToRemove) {
				[self removeListObjects:[objectsToRemove allObjects]];
			}
			
			//Now break the metaContact down, taking out all contacts and putting them back in the main list
			[self breakdownAndRemoveMetaContact:(AIMetaContact *)listObject];				

		} else if ([listObject isKindOfClass:[AIListGroup class]]) {
			AIListObject	*containingObject = [listObject containingObject];
			NSEnumerator	*enumerator;
			AIAccount		*account;

			//If this is a group, delete all the objects within it
			[self removeListObjects:[(AIListGroup *)listObject containedObjects]];

			//Delete the list off of all active accounts
			enumerator = [[[adium accountController] accounts] objectEnumerator];
			while ((account = [enumerator nextObject])) {
				if ([account online]) {
					[account deleteGroup:(AIListGroup *)listObject];
				}
			}

			//Then, procede to delete the group
			[listObject retain];
			[(AIMetaContact *)containingObject removeObject:listObject];
			[groupDict removeObjectForKey:[listObject UID]];
			[self _listChangedGroup:containingObject object:listObject];
			[listObject release];

		} else {
			AIAccount	*account = [(AIListContact *)listObject account];
			if ([account online]) {
				[account removeContacts:[NSArray arrayWithObject:listObject]];
			}
		}
	}
}

- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;

	[self delayListObjectNotifications];

	enumerator = [contactArray objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if(![group containsObject:listObject]) //don't add it if it's already there.
			[[listObject account] addContacts:[NSArray arrayWithObject:listObject] toGroup:group];
	}

	[self endListObjectNotificationsDelay];
}

- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:contactUID, UID_KEY, inService, @"service",nil];
	[[adium notificationCenter] postNotificationName:Contact_AddNewContact
											  object:nil
											userInfo:userInfo];
}

- (void)moveListObjects:(NSArray *)objectArray toGroup:(AIListObject<AIContainingObject> *)group index:(int)index
{
	NSEnumerator	*enumerator;
	AIListContact	*listContact;

	[self delayListObjectNotifications];

	if ([group respondsToSelector:@selector(setDelayContainedObjectSorting:)]) {
		[(id)group setDelayContainedObjectSorting:YES];
	}

	enumerator = [objectArray objectEnumerator];
	while ((listContact = [enumerator nextObject])) {
		[self moveContact:listContact toGroup:group];

		//Set the new index / position of the object
		[self _positionObject:listContact atIndex:index inGroup:group];
	}

	[self endListObjectNotificationsDelay];

	if ([group respondsToSelector:@selector(setDelayContainedObjectSorting:)]) {
		[(id)group setDelayContainedObjectSorting:NO];
	}

	/*
	 Resort the entire list if we are moving within or between AIListGroup objects
	 (other containing objects such as metaContacts will handle their own sorting).
	*/
	if ([group isKindOfClass:[AIListGroup class]]) {
		[self sortContactList];
	}
}

- (void)moveContact:(AIListContact *)listContact toGroup:(AIListObject<AIContainingObject> *)group
{
	//Move the object to the new group if necessary
	if (group != [listContact containingObject]) {

		if ([group isKindOfClass:[AIListGroup class]]) {
			if ([listContact isKindOfClass:[AIMetaContact class]]) {
				//This is a meta contact, move the objects within it.  listContacts will give us a flat array of AIListContacts.
				[self _moveContactLocally:listContact toGroup:(AIListGroup *)group];

			} else if ([listContact isKindOfClass:[AIListContact class]]) {
				//Move the object
				[self _moveObjectServerside:listContact toGroup:(AIListGroup *)group];
			}

		} else if ([group isKindOfClass:[AIMetaContact class]]) {
			//Moving a contact into a meta contact
			[self addListObject:listContact toMetaContact:(AIMetaContact *)group];
		}
	}
}

//Move an object to another group
- (void)_moveObjectServerside:(AIListObject *)listObject toGroup:(AIListGroup *)group
{
	AIAccount	*account = [(AIListContact *)listObject account];
	if ([account online]) {
		[account moveListObjects:[NSArray arrayWithObject:listObject] toGroup:group];
	}
}

//Rename a group
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName
{
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;

	//Since Adium has no memory of what accounts a group is on, we have to send this message to all available accounts
	//The accounts without this group will just ignore it
	while ((account = [enumerator nextObject])) {
		[account renameGroup:listGroup to:newName];
	}

	//Remove the old group if it's empty
	if ([listGroup containedObjectsCount] == 0) {
		[self removeListObjects:[NSArray arrayWithObject:listGroup]];
	}
}

//Position a list object within a group
- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListObject<AIContainingObject> *)group
{
	if (index == 0) {
		//Moved to the top of a group.  New index is between 0 and the lowest current index
		[listObject setOrderIndex:([group smallestOrder] / 2.0)];

	} else if (index >= [group visibleCount]) {
		//Moved to the bottom of a group.  New index is one higher than the highest current index
		[listObject setOrderIndex:([group largestOrder] + 1.0)];

	} else {
		//Moved somewhere in the middle.  New index is the average of the next largest and smallest index
		AIListObject	*previousObject = [group objectAtIndex:index-1];
		AIListObject	*nextObject = [group objectAtIndex:index];
		float nextLowest = [previousObject orderIndex];
		float nextHighest = [nextObject orderIndex];

		//
		[listObject setOrderIndex:((nextHighest + nextLowest) / 2.0)];
	}
}

@end


