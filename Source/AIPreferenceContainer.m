//
//  AIPreferenceContainer.m
//  Adium
//
//  Created by Evan Schoenberg on 1/8/08.
//

#import "AIPreferenceContainer.h"
#import "AIPreferenceController.h"
#import <Adium/AIListObject.h>
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>

@interface AIPreferenceContainer (PRIVATE)
- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject;
- (void)emptyCache;
- (void)save;
+ (void)performObjectPrefsSave;
@end

#define EMPTY_CACHE_DELAY		120.0
#define	SAVE_OBJECT_PREFS_DELAY	10.0

static NSMutableDictionary	*objectPrefs = nil;
static int					usersOfObjectPrefs = 0;
static NSTimer				*timer_savingOfObjectCache = nil;

static NSMutableDictionary	*accountPrefs = nil;
static int					usersOfAccountPrefs = 0;
static NSTimer				*timer_savingOfAccountCache = nil;

/*!
 * @brief Preference Container
 *
 * A single AIPreferenceContainer instance provides read/write access preferences to a specific preference group, either
 * for the global preferences or for a specific object.  After EMPTY_CACHE_DELAY seconds, it releases its preferences from memory;
 * it will reload them from disk as needed when accessed again.
 *
 * All contacts share a single plist on-disk, loaded into a single mutable dictionary in-memory, objectPrefs.
 * All accounts share a single plist on-disk, loaded into a single mutable dictionary in-memory, accountPrefs.
 * These global dictionaries provide per-object preference dictionaries, keyed by the object's internalObjectID.
 *
 * Individual instances of AIPreferenceContainer make use of this shared store.  Saving of changes is batched for all changes made during a
 * SAVE_OBJECT_PREFS_DELAY interval across all instances of AIPreferenceContainer for a given global dictionary. Because creating
 * the data representation of a large dictionary and writing it out can be time-consuming (certainly less than a second, but still long
 * enough to cause a perceptible delay for a user actively typing or interacting with Adium), saving is performed on a thread.
 *
 * When no instances are currently making use of a global dictionary, it is removed from memory; it will be reloaded from disk as needed.
 */
@implementation AIPreferenceContainer

+ (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	return [[[self alloc] initForGroup:inGroup object:inObject] autorelease];
}

+ (void)preferenceControllerWillClose
{
	if (timer_savingOfObjectCache) {
		[objectPrefs writeToPath:[[[AIObject sharedAdiumInstance] loginController] userDirectory]
						withName:@"ByObjectPrefs"];
	}
	
	if (timer_savingOfAccountCache) {
		[accountPrefs writeToPath:[[[AIObject sharedAdiumInstance] loginController] userDirectory]
						withName:@"AccountPrefs"];
	}
}

- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	if ((self = [super init])) {
		group = [inGroup retain];
		object = [inObject retain];
		
		if (object) {
			if ([object isKindOfClass:[AIAccount class]]) {
				myGlobalPrefs = &accountPrefs;
				myUsersOfGlobalPrefs = &usersOfAccountPrefs;
				myTimerForSavingGlobalPrefs = &timer_savingOfAccountCache;
				globalPrefsName = [@"AccountPrefs" retain];
				
			} else {
				myGlobalPrefs = &objectPrefs;
				myUsersOfGlobalPrefs = &usersOfObjectPrefs;
				myTimerForSavingGlobalPrefs = &timer_savingOfObjectCache;
				globalPrefsName = [@"ByObjectPrefs" retain];
			}
		}
	}

	return self;
}

- (void)dealloc
{
	[defaults release]; defaults = nil;
	[group release];
	[object release];
	[timer_clearingOfCache release]; timer_clearingOfCache = nil;
	[globalPrefsName release]; globalPrefsName = nil;

	[self emptyCache];
	
	[super dealloc];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
	return NO;
}

#pragma mark Cache

/*!
 * @brief Empty our cache
 */
- (void)emptyCache:(NSTimer *)inTimer
{
	if (object) (*myUsersOfGlobalPrefs)--;

	[prefs release]; prefs = nil;
	[prefsWithDefaults release]; prefsWithDefaults = nil;
	
	if (object && (*myUsersOfGlobalPrefs) == 0) {
		[*myGlobalPrefs release]; *myGlobalPrefs = nil;
	}
	
	[timer_clearingOfCache release]; timer_clearingOfCache = nil;
}

/*!
 * @brief Queue clearing of the cache
 *
 * If this method isn't called again within 30 seconds, the passed key will be removed from the passed cache dictionary.
 */
- (void)queueClearingOfCache
{
	if (!timer_clearingOfCache) {
		timer_clearingOfCache = [[NSTimer scheduledTimerWithTimeInterval:EMPTY_CACHE_DELAY
																  target:self
																selector:@selector(emptyCache:)
																userInfo:nil
																 repeats:NO] retain];
	} else {
		[timer_clearingOfCache setFireDate:[NSDate dateWithTimeIntervalSinceNow:EMPTY_CACHE_DELAY]];
	}
}

#pragma mark Defaults

- (NSDictionary *)defaults
{
	return defaults;
}

/*!
 * @brief Register defaults
 *
 * These defaults will be added to any existing defaults; if there is overlap between keys, the new key-value pair will be used.
 */
- (void)registerDefaults:(NSDictionary *)inDefaults
{
	if (!defaults) defaults = [[NSMutableDictionary alloc] init];
	
	[defaults addEntriesFromDictionary:inDefaults];
	
	//Clear the cached defaults dictionary so it will be recreated as needed
	[prefsWithDefaults release]; prefsWithDefaults = nil;
}

#pragma mark Get and set

/*!
 * @brief Return a dictionary of our preferences, loading it from disk as needed
 */
- (NSMutableDictionary *)prefs
{
	if (!prefs) {
		NSString	*userDirectory = [[adium loginController] userDirectory];
		
		if (object) {
			if (!(*myGlobalPrefs)) {
				NSString	*objectPrefsPath = [[userDirectory stringByAppendingPathComponent:globalPrefsName] stringByAppendingPathExtension:@"plist"];
				NSData		*data = [NSData dataWithContentsOfFile:objectPrefsPath];
				NSString	*errorString;

				//We want to load a mutable dictioanry of mutable dictionaries.
				*myGlobalPrefs = [[NSPropertyListSerialization propertyListFromData:data 
																   mutabilityOption:NSPropertyListMutableContainers 
																			 format:NULL 
																   errorDescription:&errorString] retain];
				if (!*myGlobalPrefs) *myGlobalPrefs = [[NSMutableDictionary alloc] init];
			}

			//For compatibility with having loaded individual object prefs from previous version of Adium, we key by the safe filename string
			NSString *globalPrefsKey = [[object internalObjectID] safeFilenameString];
			prefs = [[*myGlobalPrefs objectForKey:globalPrefsKey] retain];
			if (!prefs) {
				prefs = [[NSMutableDictionary alloc] init];
				[*myGlobalPrefs setObject:prefs
								   forKey:globalPrefsKey];
			}
			(*myUsersOfGlobalPrefs)++;

		} else {
			prefs = [[NSMutableDictionary dictionaryAtPath:userDirectory
												  withName:group
													create:YES] retain];
		}
		
		[self queueClearingOfCache];
	}
	
	return prefs;
}

/*!
 * @brief Return a dictionary of preferences and defaults, appropriately merged together
 */
- (NSDictionary *)dictionary
{
	if (!prefsWithDefaults) {
		//Add our own preferences to the defaults dictionary to get a dict with the set keys overriding the default keys
		if (defaults) {
			prefsWithDefaults = [defaults mutableCopy];
			[prefsWithDefaults addEntriesFromDictionary:[self prefs]];

		} else {
			prefsWithDefaults = [[self prefs] retain];
		}
		
		[self queueClearingOfCache];
	}

	return prefsWithDefaults;
}

/*!
 * @brief Set value for key
 *
 * This sets and saves a preference for the given key
 */
- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL	valueChanged;
	/* Comparing pointers, numbers, and strings is far cheapear than writing out to disk;
	 * check to see if we don't need to change anything at all. However, we still want to post notifications
	 * for observers that we were set.
	 */
	id oldValue;
	if ((!value && ![self valueForKey:key]) ||
		((value && (oldValue = [self valueForKey:key])) && 
		 ([value isKindOfClass:[NSNumber class]] && [(NSNumber *)value isEqualToNumber:oldValue]) ||
		 ([value isKindOfClass:[NSString class]] && [(NSString *)value isEqualToString:oldValue]))) {
		valueChanged = NO;
	} else {
		valueChanged = YES;
	}

	[self willChangeValueForKey:key];

	if (valueChanged) {
		//Clear the cached defaults dictionary so it will be recreated as needed
		if (value)
			[prefsWithDefaults setValue:value forKey:key];
		else {
			[prefsWithDefaults autorelease]; prefsWithDefaults = nil;
		}
		
		if (object) {
			@synchronized (*myGlobalPrefs) {
				[[self prefs] setValue:value forKey:key];
			}
		} else {
			[[self prefs] setValue:value forKey:key];		
		}
	}

	[self didChangeValueForKey:key];

	//Now tell the preference controller
	if (!preferenceChangeDelays) {
		[[adium preferenceController] informObserversOfChangedKey:key inGroup:group object:object];
		if (valueChanged)
			[self save];
	}
}

- (id)valueForKey:(NSString *)key
{
	return [[self dictionary] valueForKey:key];
}

/*!
 * @brief Get a preference, possibly ignoring the defaults
 *
 * @param key The key
 * @param ignoreDefaults If YES, the preferences are accessed diretly, without including the default values
 */
- (id)valueForKey:(NSString *)key ignoringDefaults:(BOOL)ignoreDefaults
{
	if (ignoreDefaults)
		return [[self prefs] valueForKey:key];
	else
		return [self valueForKey:key];
}

- (id)defaultValueForKey:(NSString *)key
{
	return [[self defaults] valueForKey:key];
}

/*!
 * @brief Set all preferences for this group
 *
 * All existing preferences are removed for this group; the passed dictionary becomes the new preferences
 */
- (void)setPreferences:(NSDictionary *)inPreferences
{
	NSEnumerator *enumerator;
	NSArray		 *oldKeys = [[self prefs] allKeys];
	NSString	 *key;
	
	[self setPreferenceChangedNotificationsEnabled:NO];

	//Will change all old keys
	enumerator = [oldKeys objectEnumerator];	
	while ((key = [enumerator nextObject])) {
		[self willChangeValueForKey:@"key"];
	}
	
	[self setValuesForKeysWithDictionary:inPreferences];
	
	//Did change all old keys
	enumerator = [oldKeys objectEnumerator];	
	while ((key = [enumerator nextObject])) {
		[self didChangeValueForKey:@"key"];
	}
	
	[self setPreferenceChangedNotificationsEnabled:YES];
}

- (void)setPreferenceChangedNotificationsEnabled:(BOOL)inEnabled
{
	if (inEnabled) 
		preferenceChangeDelays--;
	else
		preferenceChangeDelays++;
	
	if (preferenceChangeDelays == 0) {
		[[adium preferenceController] informObserversOfChangedKey:nil inGroup:group object:object];
		[self save];
	}
}

#pragma mark Saving
- (void)threadedSavePrefs:(NSDictionary *)info
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *sourcePrefsToSave = [info objectForKey:@"PrefsToSave"];
	NSDictionary *dictToSave;
	@synchronized (sourcePrefsToSave) {
		dictToSave = [[NSDictionary alloc] initWithDictionary:sourcePrefsToSave copyItems:YES];
	}
	[dictToSave writeToPath:[info objectForKey:@"DestinationDirectory"]
				   withName:[info objectForKey:@"PrefsName"]];
	[dictToSave release];

	NSTimer *inTimer = [info objectForKey:@"NSTimer"];
	if (inTimer == timer_savingOfObjectCache) {
		@synchronized(timer_savingOfObjectCache) {
			[timer_savingOfObjectCache release]; timer_savingOfObjectCache = nil;
		}
	} else if (inTimer == timer_savingOfAccountCache) {
		@synchronized(timer_savingOfAccountCache) {
			[timer_savingOfAccountCache release]; timer_savingOfAccountCache = nil;
		}
	}

	(*myUsersOfGlobalPrefs)--;
	
	[pool release];
}

- (void)performObjectPrefsSave:(NSTimer *)inTimer
{
	[NSThread detachNewThreadSelector:@selector(threadedSavePrefs:)
							 toTarget:self
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   [inTimer userInfo], @"PrefsToSave",
									   [[[AIObject sharedAdiumInstance] loginController] userDirectory], @"DestinationDirectory",
										globalPrefsName, @"PrefsName",
									    inTimer, @"NSTimer",
									   nil]];
}

/*!
 * @brief Save to disk
 */
- (void)save
{
	if (object) {
		//For an object's pref changes, batch all changes in a SAVE_OBJECT_PREFS_DELAY second period. We'll force an immediate save if Adium quits.
		if (*myTimerForSavingGlobalPrefs) {
			@synchronized(*myTimerForSavingGlobalPrefs) {
				[*myTimerForSavingGlobalPrefs setFireDate:[NSDate dateWithTimeIntervalSinceNow:SAVE_OBJECT_PREFS_DELAY]];
			}

		} else {
			(*myUsersOfGlobalPrefs)++;

			*myTimerForSavingGlobalPrefs = [[NSTimer scheduledTimerWithTimeInterval:SAVE_OBJECT_PREFS_DELAY
																			 target:self
																		   selector:@selector(performObjectPrefsSave:)
																		   userInfo:*myGlobalPrefs
																			repeats:NO] retain];
		}


	} else {
		//Save the preference change immediately
		NSString	*userDirectory = [[adium loginController] userDirectory];
		
		NSString	*path = (object ? [userDirectory stringByAppendingPathComponent:[object pathToPreferences]] : userDirectory);
		NSString	*name = (object ? [[object internalObjectID] safeFilenameString] : group);
		
		BOOL success = [[self prefs] writeToPath:path withName:name];
		if (!success)
			NSLog(@"Error writing %@ for %@", self);
	}
}

- (void)setGroup:(NSString *)inGroup
{
	if (group != inGroup) {
		[group release];
		group = [inGroup retain];
	}
}

#pragma mark Debug
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p: Group %@, object %@>", NSStringFromClass([self class]), self, group, object];
}
@end
