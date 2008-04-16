//
//  AdiumContactPropertiesObserverManager.m
//  Adium
//
//  Created by Evan Schoenberg on 4/16/08.
//

#import "AdiumContactPropertiesObserverManager.h"
#import "AIContactController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AISortController.h>

@interface AdiumContactPropertiesObserverManager (PRIVATE)
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)_performDelayedUpdates:(NSTimer *)timer;
@end

#define UPDATE_CLUMP_INTERVAL			1.0

#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
static BOOL unregisterListObjectObserverCalled = NO;
#endif

@implementation AdiumContactPropertiesObserverManager

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
	//If we're handed something that can contain other contacts, update the status of the contacts contained within it
	if ([inContact conformsToProtocol:@protocol(AIContainingObject)]) {
		NSEnumerator	*enumerator = [[(AIListObject<AIContainingObject> *)inContact listContacts] objectEnumerator];
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
		if (![[[adium contactController] activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys] &&
			[[[adium contactController] activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys]) {
			[[adium contactController] sortListObject:inObject];
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
        if ([[[adium contactController] activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]) {
			[[adium contactController] sortListObject:inObject];
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
			delayedContactChanges = 0;
			shouldSort = YES;
		}
		if (delayedStatusChanges) {
			if (!shouldSort &&
				[[[adium contactController] activeSortController] shouldSortForModifiedStatusKeys:delayedModifiedStatusKeys]) {
				shouldSort = YES;
			}
			[delayedModifiedStatusKeys removeAllObjects];
			delayedStatusChanges = 0;
		}
		if (delayedAttributeChanges) {
			if (!shouldSort &&
				[[[adium contactController] activeSortController] shouldSortForModifiedAttributeKeys:delayedModifiedAttributeKeys]) {
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
			[[adium contactController] sortContactList];
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

//List object observers ------------------------------------------------------------------------------------------------
#pragma mark List object observers
//Registers code to observe handle status changes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver
{
	//Add the observer
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	AILogWithSignature(@"%@", inObserver);
    [contactObservers addObject:inObserver];
#else
    [contactObservers addObject:[NSValue valueWithNonretainedObject:inObserver]];
#endif
	
    //Let the new observer process all existing objects
	[self updateAllListObjectsForObserver:inObserver];
}

- (void)unregisterListObjectObserver:(id)inObserver
{
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	AILogWithSignature(@"%@", inObserver);
    [contactObservers removeObjectIdenticalTo:inObserver];
	unregisterListObjectObserverCalled = YES;
#else
    [contactObservers removeObject:[NSValue valueWithNonretainedObject:inObserver]];
#endif
}


/*!
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
	
	enumerator = (contacts ? [contacts objectEnumerator] : [(AIContactController *)[adium contactController] contactEnumerator]);
	while ((listObject = [enumerator nextObject])) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
		
		//If this contact is within a meta contact, update the meta contact too
		AIListObject<AIContainingObject>	*containingObject = [listObject containingObject];
		if (containingObject && [containingObject isKindOfClass:[AIMetaContact class]]) {
			NSSet	*attributes = [inObserver updateListObject:containingObject
														keys:nil
													  silent:YES];
			if (attributes) [self listObjectAttributesChanged:containingObject
												 modifiedKeys:attributes];
		}
		[pool release];
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
	enumerator = [(AIContactController *)[adium contactController] groupEnumerator];
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
	
	[self endListObjectNotificationsDelay];
}


//Notify observers of a status change.  Returns the modified attribute keys
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent
{
	NSMutableSet	*attrChange = nil;
	
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	NSObject <AIListObjectObserver>	*observer;
	
	//Let our observers know
	int i;
	for (i = 0; i < [contactObservers count]; i++) {
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		NSSet				*newKeys;
		
		observer = [contactObservers objectAtIndex:i];
		
		if ([observer retainCount] == 1) {
			NSString *observerDescription = [observer description];
			
			/* This observer is fully released except for our retention (contactObservers plus its copy), which wouldn't happen without 
			 * CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG defined.  That -might- be an error... except that it
			 * might remove itself as an observer in its dealloc method, which is fine if it actually happens.
			 */
			unregisterListObjectObserverCalled = NO;
			[contactObservers removeObjectIdenticalTo:observer];
			
			//observer will have deallocated.  It should have called removeContactObserver in the process. If it didn't, that's bad.
			if (!unregisterListObjectObserverCalled) {
				AILogWithSignature(@"%@ failed at removing itself as a contact observer! This would be fatal in a release build!", observerDescription);
				NSLog(@"%@ failed at removing itself as a contact observer! This would be fatal in a release build!", observerDescription);
				NSAssert1(FALSE, @"%@ failed at removing itself as a contact observer! This would be fatal in a release build!", observerDescription);
			} else {
				AILogWithSignature(@"All is well after the dealloc of %@", observerDescription);
			}
		} else {
			if ((newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent])) {
				if (!attrChange) attrChange = [[NSMutableSet alloc] init];
				[attrChange unionSet:newKeys];
			}
		}
		[pool release];
	}	
#else
	NSEnumerator	*enumerator;
	NSValue			*observerValue;
	
	//Let our observers know
	enumerator = [contactObservers objectEnumerator];
	while ((observerValue = [enumerator nextObject])) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		id <AIListObjectObserver>	observer;
		NSSet						*newKeys;
		
		observer = [observerValue nonretainedObjectValue];
		if ((newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent])) {
			if (!attrChange) attrChange = [[NSMutableSet alloc] init];
			[attrChange unionSet:newKeys];
		}
		[pool release];
	}
#endif
	//Send out the notification for other observers
	[[adium notificationCenter] postNotificationName:ListObject_StatusChanged
											  object:inObject
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys
																								 forKey:@"Keys"] : nil)];
	
	return [attrChange autorelease];
}

//Command all observers to apply their attributes to an object
- (void)_updateAllAttributesOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [contactObservers objectEnumerator];
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	id <AIListObjectObserver> observer;
	
	while ((observer = [enumerator nextObject])) {		
		[observer updateListObject:inObject keys:nil silent:YES];
	}
#else
	NSValue			*observerValue;
	
	while ((observerValue = [enumerator nextObject])) {		
		id <AIListObjectObserver> observer = [observerValue nonretainedObjectValue];
		
		[observer updateListObject:inObject keys:nil silent:YES];
	}
#endif	
}



@end
