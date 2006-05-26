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

#import "ESObjectWithStatus.h"
#import <AIUtilities/AIMutableOwnerArray.h>

#define KEY_KEY		@"Key"
#define KEY_VALUE	@"Value"

/*!
 * @class ESObjectWithStatus
 * @brief Abstract superclass for objects with a system of status objects and display arrays
 *
 * Status objects are an abstracted NSMutableDictionary implementation with notification of changed
 * keys and optional delayed, grouped notification.
 *
 * Display arrays utilize AIMutableOwnerArray.  See its documentation in AIUtilities.framework.
 */
@implementation ESObjectWithStatus

/*
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		statusDictionary = [[NSMutableDictionary alloc] init];
		displayDictionary = [[NSMutableDictionary alloc] init];
	}

	return self;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[statusDictionary release]; statusDictionary = nil;
	[changedStatusKeys release]; changedStatusKeys = nil;
	[displayDictionary release]; displayDictionary = nil;
	
	[super dealloc];
}

//Setting status objects -----------------------------------------------------------------------------------------------
#pragma mark Setting Status

/*
 * @brief Set a status object
 *
 * @param value The value
 * @param key The NSString key for the value
 * @param notify The notification timing. One of NotifyNow, NotifyLater, or NotifyNever.
 */
 - (void)setStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	if (key) {
		BOOL changedStatusDict = YES;
		
		if (value) {
			[statusDictionary setObject:value forKey:key];
		} else {
			//If we are already nil and being told to set nil, we don't need to do anything at all
			if ([statusDictionary objectForKey:key]) {
				[statusDictionary removeObjectForKey:key];
			} else {
				changedStatusDict = NO;
			}
		}
		
		if (changedStatusDict) {
			[self object:self didSetStatusObject:value forKey:key notify:notify];
		}
	}
}

/*
 * @brief Set a status object after a delay
 *
 * @param value The value
 * @param key The NSString key for the value
 * @param delay The delay until the change is made
 */
- (void)setStatusObject:(id)value forKey:(NSString *)key afterDelay:(NSTimeInterval)delay
{
	[self performSelector:@selector(_applyDelayedStatus:)
			   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
				   key, KEY_KEY,
				   value, KEY_VALUE,
				   nil]
			   afterDelay:delay];
}

/*
 * @brief Perform a delayed status object change
 *
 * Called as a result of -[ESObjectWithStatus setStatusObject:forKey:afterDelay:]
 */
- (void)_applyDelayedStatus:(NSDictionary *)infoDict
{
	id				object = [infoDict objectForKey:KEY_VALUE];
	NSString		*key = [infoDict objectForKey:KEY_KEY];
	
	[self setStatusObject:object forKey:key notify:NotifyNow];
}

/*
 * @brief Notify of any status object changes made with a NotifyTiming of NotifyLater
 *
 * @param silent YES if the notification should be marked as silent
 */
- (void)notifyOfChangedStatusSilently:(BOOL)silent
{
    if (changedStatusKeys && [changedStatusKeys count]) {
		//Clear changedStatusKeys in case this status change invokes another, and we re-enter this code
		NSSet	*keys = changedStatusKeys;
		changedStatusKeys = nil;
		
		[self didModifyStatusKeys:keys silent:silent];
		
		[self didNotifyOfChangedStatusSilently:silent];
		
		[keys release];
    }
}

//Getting status objects ----------------------------------------------------------------------------------------------
#pragma mark Getting Status
/*
 * @brief Status key enumeartor
 *
 * @result NSEnumerator of all status keys
 */
- (NSEnumerator	*)statusKeyEnumerator
{
	return [statusDictionary keyEnumerator];
}

/*
 * @brief Status object for key
 */
- (id)statusObjectForKey:(NSString *)key
{
    return [statusDictionary objectForKey:key];
}

/*
 * @brief Integer status object for key
 *
 * @result int value for key, or 0 if no object is set for key
 */
- (int)integerStatusObjectForKey:(NSString *)key
{
	NSNumber *number = [statusDictionary objectForKey:key];
    return number ? [number intValue] : 0;
}

/*
 * @brief Earliest date status object for key
 *
 * @result The earliest NSDate associated with this key. There can only be one NSDate for the base class, so it returns this one.
 */
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	id obj = [statusDictionary objectForKey:key];
	return ((obj && [obj isKindOfClass:[NSDate class]]) ? obj : nil);
}

/*
 * @brief Number status object for key
 *
 * @result The NSNumber for this key, or nil if no such key is set or the value is not an NSNumber
 */
- (NSNumber *)numberStatusObjectForKey:(NSString *)key
{
	id obj = [statusDictionary objectForKey:key];
	return ((obj && [obj isKindOfClass:[NSNumber class]]) ? obj : nil);
}

/*
 * @brief String from a key which stores an attributed string
 *
 * @result The NSString contents of an NSAttributedString for this key
 */
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key
{
	id obj = [statusDictionary objectForKey:key];

	return ((obj && [obj isKindOfClass:[NSAttributedString class]]) ?
			[(NSAttributedString *)obj string] :
			nil);
}

//---- fromAnyContainedObject status object behavior ----
//If fromAnyContainedObject is YES, return the best value from any contained object if the preferred object returns nil.
//If it is NO, only look at the preferred object.
//For the superclass, the fromAnyContainedObject argument has no effect
//General status object
- (id)statusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self statusObjectForKey:key];
}

//NSDate
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self earliestDateStatusObjectForKey:key];
}

//NSNumber
- (NSNumber *)numberStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self numberStatusObjectForKey:key];
}

//Integer (uses numberStatusObjectForKey:)
- (int)integerStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	NSNumber *returnValue = [self numberStatusObjectForKey:key];
	
    return returnValue ? [returnValue intValue] : 0;
}

//String from attributed string (uses statusObjectForKey:)
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self stringFromAttributedStringStatusObjectForKey:key];
}

//For Subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses

//Sublcasses should implement this method to take action when a status object changes
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify 
{
	//If the status object changed for the same object receiving this method, notification is called for.
	//Otherwise, it's just an informative message which shouldn't be triggering notification.
	if (inObject == self) {
		switch (notify) {
			case NotifyNow: {
				//Send out the notification now
				[self didModifyStatusKeys:[NSSet setWithObject:key]
								   silent:NO];
				break;
			}
			case NotifyLater: {
				//Add this key to changedStatusKeys for later notification 
				if (!changedStatusKeys) changedStatusKeys = [[NSMutableSet alloc] init];
				[changedStatusKeys addObject:key];
				break;
			}
			case NotifyNever: break; //Take no notification action
		}
	}
}

- (void)didModifyStatusKeys:(NSSet *)keys silent:(BOOL)silent {};
- (void)didNotifyOfChangedStatusSilently:(BOOL)silent {};

//Dynamic Display------------------------------------------------------------------------------------------------------
#pragma mark Dynamic Display
//Access to the display arrays for this object.  Will alloc and init an array if none exists.
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [displayDictionary objectForKey:inKey];
	
    if (!array) {
        array = [[AIMutableOwnerArray alloc] init];
		[array setDelegate:self];
        [displayDictionary setObject:array forKey:inKey];
        [array release];
    }
	
    return array;
}

//With create:YES, this is identical to displayArrayForKey:
//With create:NO, just perform the lookup and return either a mutableOwnerArray or nil
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey create:(BOOL)create
{
	AIMutableOwnerArray	*array;
	
	if (create) {
		array = [self displayArrayForKey:inKey];
	} else {
		array = [displayDictionary objectForKey:inKey];
	}
	
	return array;
}

- (id)displayArrayObjectForKey:(NSString *)inKey
{
	return ([[displayDictionary objectForKey:inKey] objectValue]);
}

//A mutable owner array (one of our displayArrays) set an object - not currently called; set the delegate 
//when the owner array is created (above) to be able to use this method.
- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
{
	
}

//Naming ---------------------------------------------------------------------------------------------------------------
#pragma mark Naming

//Subclasses should override this to provide a general display name
- (NSString *)displayName
{
	return @"";
}

//Comparing
- (BOOL)isEqual:(id)otherObject
{
	return (self == otherObject);
}
@end
