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

#import <Adium/ESObjectWithProperties.h>
#import <AIUtilities/AIMutableOwnerArray.h>

#define KEY_KEY		@"Key"
#define KEY_VALUE	@"Value"

/*!
 * @class ESObjectWithProperties
 * @brief Abstract superclass for objects with a system of properties and display arrays
 *
 * Properties are an abstracted NSMutableDictionary implementation with notification of changed
 * keys and optional delayed, grouped notification.  They allow storage of arbitrary information associate with
 * an ESObjectWithProperties subclass. Such information is not persistent across sessions.
 *
 * Properties are KVO compliant.
 *
 * Display arrays utilize AIMutableOwnerArray.  See its documentation in AIUtilities.framework.
 */
@implementation ESObjectWithProperties

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		propertiesDictionary = [[NSMutableDictionary alloc] init];
		displayDictionary = [[NSMutableDictionary alloc] init];
	}

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[propertiesDictionary release]; propertiesDictionary = nil;
	[changedProperties release]; changedProperties = nil;
	[displayDictionary release]; displayDictionary = nil;
	
	[super dealloc];
}

//Setting properties ---------------------------------------------------------------------------------------------------
#pragma mark Setting Properties

/*!
 * @brief Set a property
 *
 * @param value The value
 * @param key The property to set the value to.
 * @param notify The notification timing. One of NotifyNow, NotifyLater, or NotifyNever.
 */
 - (void)setValue:(id)value forProperty:(NSString *)key notify:(NotifyTiming)notify
{
	if (key) {
		BOOL changedPropertiesDict = YES;

		[self willChangeValueForKey:key];
		if (value) {
			[propertiesDictionary setObject:value forKey:key];
		} else {
			//If we are already nil and being told to set nil, we don't need to do anything at all
			if ([propertiesDictionary objectForKey:key]) {
				[propertiesDictionary removeObjectForKey:key];
			} else {
				changedPropertiesDict = NO;
			}
		}
		
		if (changedPropertiesDict) {
			[self object:self didSetValue:value forProperty:key notify:notify];
		}
		[self didChangeValueForKey:key];
	}
}

/*!
 * @brief Set a property after a delay
 *
 * @param value The value
 * @param key The property to set the value to.
 * @param delay The delay until the change is made
 */
- (void)setValue:(id)value forProperty:(NSString *)key afterDelay:(NSTimeInterval)delay
{
	[self performSelector:@selector(_applyDelayedProperties:)
			   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
				   key, KEY_KEY,
				   value, KEY_VALUE,
				   nil]
			   afterDelay:delay];
}

- (id)valueForUndefinedKey:(NSString *)inKey
{
	return [self valueForProperty:inKey];
}

/*!
 * @brief Perform a delayed property change
 *
 * Called as a result of -[ESObjectWithProperties setValue:forProperty:afterDelay:]
 */
- (void)_applyDelayedProperties:(NSDictionary *)infoDict
{
	id				object = [infoDict objectForKey:KEY_VALUE];
	NSString		*key = [infoDict objectForKey:KEY_KEY];
	
	[self setValue:object forProperty:key notify:NotifyNow];
}

/*!
 * @brief Notify of any property changes made with a NotifyTiming of NotifyLater
 *
 * @param silent YES if the notification should be marked as silent
 */
- (void)notifyOfChangedPropertiesSilently:(BOOL)silent
{
    if (changedProperties && [changedProperties count]) {
		//Clear changedProperties in case this status change invokes another, and we re-enter this code
		NSSet	*keys = changedProperties;
		changedProperties = nil;
		
		[self didModifyProperties:keys silent:silent];
		
		[self didNotifyOfChangedPropertiesSilently:silent];
		
		[keys release];
    }
}

//Getting properties ---------------------------------------------------------------------------------------------------
#pragma mark Getting Properties
/*!
 * @brief Properties enumeartor
 *
 * @result NSEnumerator of all properties
 */
- (NSEnumerator	*)propertyEnumerator
{
	return [propertiesDictionary keyEnumerator];
}

/*!
 * @brief Value for a property
 * @result The value associated with the passed key, or nil if none has been set.
 */
- (id)valueForProperty:(NSString *)key
{
    return [propertiesDictionary objectForKey:key];
}

/*!
 * @brief Integer for a property
 *
 * @result int value for key, or 0 if no value is set for key
 */
- (int)integerValueForProperty:(NSString *)key
{
	NSNumber *number = [self valueForProperty:key];
    return number ? [number intValue] : 0;
}

/*!
 * @brief Earliest date value for a property
 *
 * @result The earliest NSDate associated with this key. There can only be one NSDate for the base class, so it returns this one.
 */
- (NSDate *)earliestDateValueForProperty:(NSString *)key
{
	id obj = [propertiesDictionary objectForKey:key];
	return ((obj && [obj isKindOfClass:[NSDate class]]) ? obj : nil);
}

/*!
 * @brief NSNumber value for a property
 *
 * @result The NSNumber for this key, or nil if no such key is set or the value is not an NSNumber
 */
- (NSNumber *)numberValueForProperty:(NSString *)key
{
	id obj = [propertiesDictionary objectForKey:key];
	return ((obj && [obj isKindOfClass:[NSNumber class]]) ? obj : nil);
}

/*!
 * @brief String from a key which stores an attributed string
 *
 * @result The NSString contents of an NSAttributedString for this key
 */
- (NSString *)stringFromAttributedStringValueForProperty:(NSString *)key
{
	id obj = [propertiesDictionary objectForKey:key];

	return ((obj && [obj isKindOfClass:[NSAttributedString class]]) ?
			[(NSAttributedString *)obj string] :
			nil);
}

/*!
 * @brief Retrieve the value for a property
 *
 * Note that fromAnyContainedObject is useful for subclasses; this default implementation ignores it.
 *
 * @param key The key
 * @param fromAnyContainedObject If YES, return the best value from any contained object if the preferred object returns nil. If NO, only look at the preferred object.
 */
- (id)valueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self valueForProperty:key];
}

/*!
 * @brief Earliest date value for a property
 *
 * Note that fromAnyContainedObject is useful for subclasses; this default implementation ignores it.
 *
 * @param key The key
 * @param fromAnyContainedObject If YES, return the best value from any contained object if the preferred object returns nil. If NO, only look at the preferred object.
 * @result The earliest NSDate associated with this key.
 */
- (NSDate *)earliestDateValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self earliestDateValueForProperty:key];
}

/*!
 * @brief NSNumber value for a property
 *
 * Note that fromAnyContainedObject is useful for subclasses; this default implementation ignores it.
 *
 * @param key The key
 * @param fromAnyContainedObject If YES, return the best value from any contained object if the preferred object returns nil. If NO, only look at the preferred object. 
 * @result The NSNumber for this key, or nil if no such key is set or the value is not an NSNumber
 */
- (NSNumber *)numberValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self numberValueForProperty:key];
}

/*!
 * @brief Integer value for a property
 *
 * Note that fromAnyContainedObject is useful for subclasses; this default implementation ignores it.
 *
 * @param key The key
 * @param fromAnyContainedObject If YES, return the best value from any contained object if the preferred object returns nil. If NO, only look at the preferred object. 
 * @result int value for key, or 0 if no object is set for key
 */
- (int)integerValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	NSNumber *returnValue = [self numberValueForProperty:key];
	
    return returnValue ? [returnValue intValue] : 0;
}

/*!
 * @brief String from a key which stores an attributed string
 *
 * Note that fromAnyContainedObject is useful for subclasses; this default implementation ignores it.
 *
 * @param key The key
 * @param fromAnyContainedObject If YES, return the best value from any contained object if the preferred object returns nil. If NO, only look at the preferred object. 
 * @result The NSString contents of an NSAttributedString for this key
 */
- (NSString *)stringFromAttributedStringValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self stringFromAttributedStringValueForProperty:key];
}

//For Subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses

/*!
 * @brief Sublcasses should implement this method to take action when a property changes for this object or a contained one
 *
 * @param inObject An object, which may be this object or any object contained by this one
 * @param value The new value
 * @param key The key
 * @param notify A NotifyTiming value determining when notification is desired
 */
- (void)object:(id)inObject didSetValue:(id)value forProperty:(NSString *)key notify:(NotifyTiming)notify 
{
	/* If the property changed for the same object receiving this method, we should send out a notification or note it for later.
	 * If we get passed another object, it's just an informative message which shouldn't be triggering notification.
	 */
	if (inObject == self) {
		switch (notify) {
			case NotifyNow: {
				//Send out the notification now
				[self didModifyProperties:[NSSet setWithObject:key]
								   silent:NO];
				break;
			}
			case NotifyLater: {
				//Add this key to changedStatusKeys for later notification 
				if (!changedProperties) changedProperties = [[NSMutableSet alloc] init];
				[changedProperties addObject:key];
				break;
			}
			case NotifyNever: break; //Take no notification action
		}
	}
}

/*!
 * @brief Subclasses should implement this method to respond to a change of a property.
 *
 * The subclass should post appropriate notifications at this time.
 *
 * @param keys The keys
 * @param silent YES indicates that this should not trigger 'noisy' notifications - it is appropriate for notifications as an account signs on and notes tons of contacts.
 */
- (void)didModifyProperties:(NSSet *)keys silent:(BOOL)silent {};


/*!
 * @brief Subclasses should implement this method to respond to a change of properties after notifications have been posted.
 *
 * @param keys The keys
 * @param silent YES indicates that this should not trigger 'noisy' notifications - it is appropriate for notifications as an account signs on and notes tons of contacts.
 */
- (void)didNotifyOfChangedPropertiesSilently:(BOOL)silent {};

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
