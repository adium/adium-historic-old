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
#import "AIContactHidingController.h"

#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIContactController.h"

NSString *AIOfflineContactHidingReason = @"offlineContactHiding";
NSString *AIContactFilteringReason = @"contactFiltering";

@interface AIContactHidingController (PRIVATE)
- (BOOL)visibilityBasedOnOfflineContactHidingPreferencesOfListContact:(AIListContact *)listContact;
- (BOOL)evaluatePredicateOnListContact:(AIListContact *)listContact withSearchString:(NSString *)aSearchString;
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end;

/*!
 *	@class AIContactHidingController
 *	@brief Manages the visibility state of contacts. 
 *	Currently, it prevents conflicts between offline contact hiding and contact list filtering by following a set of rules in setVisibility:ofListContact:withReason
 *	It also handles actually filtering contacts based on a search string and keeping track of offline/idle/mobile contacts
 */

@implementation AIContactHidingController

- (id) init
{
	self = [super init];
	if (self != nil) {
		
		//Register preference observer first so values will be correct for the following calls
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
						
	}
	return self;
}


- (void)setVisibility:(BOOL)visibleFlag
		ofListContact:(AIListContact *)listContact
		   withReason:(NSString *)reason;
{	
	if([listContact visible] == visibleFlag) {
		// No change needed
		return;
	}

	if (reason == AIOfflineContactHidingReason) {
		// If the contact is to be shown, make sure it also matches the current search term.
		// -evaluatePredicateOnListObject:withSearchString: returns YES on an empty search string.
		[listContact setVisible:(visibleFlag && [self evaluatePredicateOnListContact:listContact withSearchString:searchString])];
	} else if (reason == AIContactFilteringReason) {
		// visibilityFlag = YES if we're part of the search set, otherwise NO if we're no longer part of the search.
		[listContact setVisible:(visibleFlag && [self visibilityBasedOnOfflineContactHidingPreferencesOfListContact:listContact])];
	}
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
		
	hideOfflineIdleOrMobileContacts = [[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue];
	showOfflineContacts = [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue];
	showIdleContacts = [[prefDict objectForKey:KEY_SHOW_IDLE_CONTACTS] boolValue];
	showMobileContacts = [[prefDict objectForKey:KEY_SHOW_MOBILE_CONTACTS] boolValue];
	
	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = (useContactListGroups && [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);
	
	if(firstTime) {
		[[adium contactController] registerListObjectObserver:self];
	} else {
		//Refresh visibility of all contacts
		[[adium contactController] updateAllListObjectsForObserver:self];
		
		//Resort the entire list, forcing the visibility changes to hae an immediate effect (we return nil in the 
		//updateListObject: method call, so the contact controller doesn't know we changed anything)
		[[adium contactController] sortContactList];
	}
}

/*!
 * @brief Update visibility of a list object
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:@"Online"] ||
		[inModifiedKeys containsObject:@"IdleSince"] ||
		[inModifiedKeys containsObject:@"Signed Off"] ||
		[inModifiedKeys containsObject:@"New Object"] ||
		[inModifiedKeys containsObject:@"VisibleObjectCount"] ||
		[inModifiedKeys containsObject:@"IsMobile"] ||
		[inModifiedKeys containsObject:@"AlwaysVisible"]) {
		
		if ([inObject isKindOfClass:[AIListContact class]]) {
			[self setVisibility:[self visibilityBasedOnOfflineContactHidingPreferencesOfListContact:(AIListContact *)inObject]
				  ofListContact:(AIListContact *)inObject
					 withReason:AIOfflineContactHidingReason];
			
		} else if ([inObject isKindOfClass:[AIListGroup class]]) {
			BOOL	newObject = [inObject integerStatusObjectForKey:@"New Object"];
			
			[inObject setVisible:((useContactListGroups) &&
								  ([(AIListGroup *)inObject visibleCount] > 0 || newObject) &&
								  (useOfflineGroup || ((AIListGroup *)inObject != [[adium contactController] offlineGroup])))];
		}
	}
	
	return nil;
}
- (BOOL)visibilityBasedOnOfflineContactHidingPreferencesOfListContact:(AIListContact *)listContact;
{
	// Don't do any processing for a contact that's always visible.
	if ([listContact alwaysVisible]) {
		return YES;
	}
	
	BOOL visible = YES;
	
	// If we're hiding contacts, and these meet a criteria for hiding
	if (hideOfflineIdleOrMobileContacts && ((!showIdleContacts &&
											 [listContact statusObjectForKey:@"IdleSince"]) ||
											(!showOfflineContacts &&
											 ![listContact online] &&
											 ![listContact integerStatusObjectForKey:@"Signed Off"] &&
											 ![listContact integerStatusObjectForKey:@"New Object"]) ||
											(!showMobileContacts && 
											 [listContact isMobile]))) {
		visible = NO;
	}
	
	if ([listContact conformsToProtocol:@protocol(AIContainingObject)]) {
		//A metaContact must meet the criteria for a contact to be visible and also have at least 1 contained contact
		visible = (visible && ([(AIListContact<AIContainingObject> *)listContact visibleCount] > 0));
	} 
	
	return visible;
}
	



- (NSString *)contactFilteringSearchString
{
    return searchString; 
}
- (void)setContactFilteringSearchString:(NSString *)aSearchString refilterContacts:(BOOL)flag;
{
    [aSearchString retain];
    [searchString release];
    searchString = aSearchString;
	
	if(flag)
		[self refilterContacts];
}



- (void)refilterContacts;
{
	if (!searchString)
		return;
	
	NSMutableArray *listContacts = [[adium contactController]allContacts];
	[listContacts addObjectsFromArray:[[adium contactController]allBookmarks]];
	
	//we will be making a lot of calls to setVisible:, which is very expensive because it resorts the contact list each time
	//instead, hold off on sorting the list until we have searched through all contacts
	[[adium contactController] delayListObjectNotifications];
	
	//now, go through all the contacts and make sure only those that that predicate matches are displayed
	NSEnumerator *e = [listContacts objectEnumerator];
	AIListContact *aListContact;
	while ((aListContact = [e nextObject])) {
		BOOL contactMatchesPredicate = [self evaluatePredicateOnListContact:aListContact withSearchString:searchString];
		
		if ([[aListContact containingObject] isKindOfClass:[AIMetaContact class]]) {
			//if listContact is contained in a meta contact, we actually apply the new visiblity to the meta contact
			[self setVisibility:contactMatchesPredicate
				  ofListContact:(AIListContact *)[aListContact containingObject]
					 withReason:AIContactFilteringReason];
		} else {
			[self setVisibility:contactMatchesPredicate
				  ofListContact:aListContact
					 withReason:AIContactFilteringReason];
		}
	}
	
	[[adium contactController] endListObjectNotificationsDelay];
	
}	

static NSPredicate *filterPredicateTemplate;
- (BOOL)evaluatePredicateOnListContact:(AIListContact *)listContact withSearchString:(NSString *)aSearchString;
{	
	if (!listContact)
		return NO;
	if(!searchString)
		return YES;
	
	
	//create a predicate to search all display properties of a contact
	//"$SEARCH_STRING.length == 0" just ensures that the predicate will evaluate to YES when the search is canceled or deleted so that all contacts will be shown
	if(!filterPredicateTemplate)
		filterPredicateTemplate = [[NSPredicate predicateWithFormat:@"$SEARCH_STRING.length == 0 OR displayName contains[cd] $SEARCH_STRING OR formattedUID contains[cd] $SEARCH_STRING OR statusMessageString contains[cd] $SEARCH_STRING"] retain];
	
	NSPredicate *predicate = [filterPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:searchString forKey:@"SEARCH_STRING"]];
	
	if ([[listContact containingObject] isKindOfClass:[AIMetaContact class]]) {
		//meta contacts (contacts containing more than one screen name, for example), should be shown if ANY of its contacts match the predicate
		NSEnumerator *eForMetaContacts = [[(AIMetaContact *)[listContact containingObject]containedObjects]objectEnumerator];
		AIListContact *aContactInMetaContacts;
		BOOL someContactInMetaContactMatchesPredicate = NO;
		while ((aContactInMetaContacts = [eForMetaContacts nextObject]))
		{
			if([predicate evaluateWithObject:aContactInMetaContacts])
				someContactInMetaContactMatchesPredicate = YES;
		}
		
		return someContactInMetaContactMatchesPredicate;

	} else {
		return [predicate evaluateWithObject:listContact];

	}
}	



- (void) dealloc
{
	[[adium contactController] unregisterListObjectObserver:self];
	[searchString release];
	[super dealloc];
}

@end
