//
//  ESObjectWithStatus.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 31 2004.
//

#import "AIObject.h"

typedef enum {
	NotifyNever = -9999,
	NotifyLater = NO,   /* 0 */
	NotifyNow = YES		/* 1 */
} NotifyTiming;
	
@interface ESObjectWithStatus : AIObject {
    NSMutableDictionary		*statusDictionary;
    NSMutableArray			*changedStatusKeys;		//Status keys that have changed since the last notification
	NSMutableArray			*delayedStatusTimers;
	
	NSMutableDictionary		*displayDictionary;		//A dictionary of values affecting this object's display
}

//Setting status objects
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify;
- (void)setStatusObject:(id)value forKey:(NSString *)key afterDelay:(NSTimeInterval)delay;
- (void)delayedStatusChange:(NSDictionary *)statusChangeDict;
- (void)notifyOfChangedStatusSilently:(BOOL)silent;

//Getting status objects
- (NSEnumerator *)statusKeyEnumerator;
- (id)statusObjectForKey:(NSString *)key;
- (int)integerStatusObjectForKey:(NSString *)key;
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key;
- (NSNumber *)numberStatusObjectForKey:(NSString *)key;
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key;

//Status objects: Specifically for subclasses
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify;
- (void)didModifyStatusKeys:(NSArray *)keys silent:(BOOL)silent;
- (void)didNotifyOfChangedStatusSilently:(BOOL)silent;

//Display array
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey create:(BOOL)create;
- (id)displayArrayObjectForKey:(NSString *)inKey;

//Name
- (NSString *)displayName;


@end
