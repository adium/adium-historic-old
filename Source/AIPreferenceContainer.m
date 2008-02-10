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

@interface AIPreferenceContainer (PRIVATE)
- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject;
- (void)emptyCache;
- (void)save;
+ (void)performObjectPrefsSave;
@end

#define EMPTY_CACHE_DELAY 120.0

static NSMutableDictionary *objectPrefs = nil;
static BOOL					awaitingSave = NO;
static int					usersOfObjectPrefs = 0;

@implementation AIPreferenceContainer

+ (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	return [[[self alloc] initForGroup:inGroup object:inObject] autorelease];
}

+ (void)preferenceControllerWillClose
{
	if (awaitingSave)
		[self performObjectPrefsSave];
}

- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	if ((self = [super init])) {
		group = [inGroup retain];
		object = [inObject retain];
	}
	
	return self;
}

- (void)dealloc
{
	[defaults release]; defaults = nil;
	[group release];
	[object release];

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
- (void)emptyCache
{
	if (object) usersOfObjectPrefs--;

	[prefs release]; prefs = nil;
	[prefsWithDefaults release]; prefsWithDefaults = nil;
	
	if (object && usersOfObjectPrefs == 0) {
		[objectPrefs release]; objectPrefs = nil;
	}
}

/*!
 * @brief Queue clearing of the cache
 *
 * If this method isn't called again within 30 seconds, the passed key will be removed from the passed cache dictionary.
 */
- (void)queueClearingOfCache
{
	//Cache only for 30 seconds, then release the memory
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(emptyCache)
											   object:nil];
	[self performSelector:@selector(emptyCache)
			   withObject:nil
			   afterDelay:EMPTY_CACHE_DELAY];
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
			if (!objectPrefs) {
				NSString	*objectPrefsPath = [[userDirectory stringByAppendingPathComponent:OBJECT_PREFS_DICTIONARY_NAME] stringByAppendingPathExtension:@"plist"];
				NSData		*data = [NSData dataWithContentsOfFile:objectPrefsPath];
				NSString	*errorString;

				//We want to load a mutable dictioanry of mutable dictionaries.
				objectPrefs = [[NSPropertyListSerialization propertyListFromData:data 
															   mutabilityOption:NSPropertyListMutableContainers 
																		 format:NULL 
															   errorDescription:&errorString] retain];
				if (!objectPrefs) objectPrefs = [[NSMutableDictionary alloc] init];
			}

			//For compatibility with having loaded individual object prefs from previous version of Adium, we key by the safe filename string
			prefs = [[objectPrefs objectForKey:[[object internalObjectID] safeFilenameString]] retain];
			if (!prefs) prefs = [[NSMutableDictionary alloc] init];

			usersOfObjectPrefs++;

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
	[self willChangeValueForKey:key];
	//Clear the cached defaults dictionary so it will be recreated as needed
	[prefsWithDefaults autorelease];
	prefsWithDefaults = nil;

	[[self prefs] setValue:value forKey:key];
	[self didChangeValueForKey:key];

	//Now tell the preference controller
	if (!preferenceChangeDelays) {
		[[adium preferenceController] informObserversOfChangedKey:key inGroup:group object:object];
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
+ (void)performObjectPrefsSave
{
	[objectPrefs writeToPath:[[[AIObject sharedAdiumInstance] loginController] userDirectory]
					withName:OBJECT_PREFS_DICTIONARY_NAME];
	awaitingSave = NO;
}

/*!
 * @brief Save to disk
 */
- (void)save
{
	if (object) {
		//For an object's pref changes, batch all changes in a 10 second period. We'll force an immediate save if Adium quits.
		NSDictionary *myPrefs = [self prefs];
		if (![myPrefs count]) myPrefs = nil;
		[objectPrefs setValue:myPrefs
					   forKey:[[object internalObjectID] safeFilenameString]];

		awaitingSave = YES;
		[NSObject cancelPreviousPerformRequestsWithTarget:[self class]
												 selector:@selector(performObjectPrefsSave)
												   object:nil];
		[[self class] performSelector:@selector(performObjectPrefsSave)
						   withObject:nil
						   afterDelay:10];

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
