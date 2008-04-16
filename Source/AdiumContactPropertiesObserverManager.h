//
//  AdiumContactPropertiesObserverManager.h
//  Adium
//
//  Created by Evan Schoenberg on 4/16/08.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <Adium/AIContactControllerProtocol.h>

#ifdef DEBUG_BUILD
	#define CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG	TRUE
#endif

@interface AdiumContactPropertiesObserverManager : AIObject {
	//Status and Attribute updates
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
    NSMutableArray			*contactObservers;
#else
    NSMutableSet			*contactObservers;	
#endif
    NSTimer					*delayedUpdateTimer;
    int						delayedStatusChanges;
	NSMutableSet			*delayedModifiedStatusKeys;
    int						delayedAttributeChanges;
	NSMutableSet			*delayedModifiedAttributeKeys;

	BOOL					updatesAreDelayed;
	/* Only the contact controller can speak to us directly, and it's allowed to access these ivars */
@public
    int						delayedContactChanges;
	int						delayedUpdateRequests;
}

- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver;
- (void)unregisterListObjectObserver:(id)inObserver;
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver;
- (void)updateContacts:(NSSet *)contacts forObserver:(id <AIListObjectObserver>)inObserver;
- (void)delayListObjectNotifications;
- (void)endListObjectNotificationsDelay;
- (BOOL)updatesAreDelayed;
- (void)delayListObjectNotificationsUntilInactivity;
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSSet *)inModifiedKeys;
- (void)updateListContactStatus:(AIListContact *)inContact;

@end
