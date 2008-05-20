//
//  AdiumContactPropertiesObserverManager.h
//  Adium
//
//  Created by Evan Schoenberg on 4/16/08.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <Adium/AIContactControllerProtocol.h>

@interface AdiumContactPropertiesObserverManager : AIObject {
	//Status and Attribute updates
    NSMutableSet			*contactObservers;
	NSMutableSet			*removedContactObservers;
    NSTimer					*delayedUpdateTimer;
    int						delayedStatusChanges;
	NSMutableSet			*delayedModifiedStatusKeys;
    int						delayedAttributeChanges;
	NSMutableSet			*delayedModifiedAttributeKeys;

	BOOL					updatesAreDelayed;
	
	BOOL					informingObservers;
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

- (void)_updateAllAttributesOfObject:(AIListObject *)inObject;

@end
