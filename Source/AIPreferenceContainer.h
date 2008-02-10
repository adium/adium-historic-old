//
//  AIPreferenceContainer.h
//  Adium
//
//  Created by Evan Schoenberg on 1/8/08.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <Adium/AIListObject.h>

@interface AIPreferenceContainer : AIObject {
	NSString			*group;
	AIListObject		*object;

	NSMutableDictionary	*prefs;
	NSMutableDictionary	*prefsWithDefaults;

	NSMutableDictionary	*defaults;
	
	int					preferenceChangeDelays;
}

+ (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)inGroup object:(AIListObject *)inObject;
+ (void)preferenceControllerWillClose;

//Return a dictionary of preferences and defaults, appropriately merged together
- (NSDictionary *)dictionary;

//Replace all preferences for this container with the values and keys in inPreferences
- (void)setPreferences:(NSDictionary *)inPreferences;

//Return a dictionary of just the defaults
- (NSDictionary *)defaults;
- (void)registerDefaults:(NSDictionary *)inDefaults;

- (id)valueForKey:(NSString *)key ignoringDefaults:(BOOL)ignoreDefaults;
- (id)defaultValueForKey:(NSString *)key;

- (void)setPreferenceChangedNotificationsEnabled:(BOOL)inEnbaled;

- (void)setGroup:(NSString *)inGroup;

@end
