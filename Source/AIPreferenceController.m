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

#import "AIContactController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIPreferenceWindowController.h"
#import "AIToolbarController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIPreferencePane.h>

#define PREFS_DEFAULT_PREFS 	@"PrefsPrefs.plist"

@interface AIPreferenceController (PRIVATE)
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName;
- (void)savePreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)groupName;
- (NSDictionary *)cachedDefaultsForGroup:(NSString *)group object:(AIListObject *)object;
- (NSDictionary *)cachedPreferencesWithDefaultsForGroup:(NSString *)group object:(AIListObject *)object;
@end

/*!
 * @class AIPreferenceController
 * @brief Preference Controller
 *
 * Handles loading and saving preferences, default preferences, and preference changed notifications
 */
@implementation AIPreferenceController

/*!
 * @brief Initialize
 */
- (void)initController
{
    //
    paneArray = [[NSMutableArray alloc] init];

    defaults = [[NSMutableDictionary alloc] init];
	prefCache = [[NSMutableDictionary alloc] init];
    prefWithDefaultsCache = [[NSMutableDictionary alloc] init];

	objectDefaults = [[NSMutableDictionary alloc] init];
	objectPrefCache = [[NSMutableDictionary alloc] init];
	objectPrefWithDefaultsCache = [[NSMutableDictionary alloc] init];

	observers = [[NSMutableDictionary alloc] init];
    delayedNotificationGroups = [[NSMutableSet alloc] init];
    preferenceChangeDelays = 0;

	//
	userDirectory = [[[adium loginController] userDirectory] retain];
	
    //Create the 'ByObject' and 'Accounts' object specific preference directory
	[[NSFileManager defaultManager] createDirectoriesForPath:[userDirectory stringByAppendingPathComponent:OBJECT_PREFS_PATH]];
	[[NSFileManager defaultManager] createDirectoriesForPath:[userDirectory stringByAppendingPathComponent:ACCOUNT_PREFS_PATH]];
	
	//Register our default preferences
    [self registerDefaults:[NSDictionary dictionaryNamed:PREFS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];
}

/*!
 * @brief Finish initialization
 *
 * Sets up the toolbar items.
 * We can't do these in initing, since the toolbar controller hasn't loaded yet at that point.
 */
- (void)willFinishIniting
{
    NSToolbarItem	*toolbarItem;

    //Show preference window toolabr item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowPreferences"
														  label:@"Preferences"
												   paletteLabel:@"Open Preferences"
														toolTip:@"Open Preferences"
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"settings" forClass:[self class]]
														 action:@selector(showPreferenceWindow:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"General"];
}

/*!
 * @brief Begin closing
 * 
 * We must close the preference window before plugins and the other controllers are unloaded.
 */
- (void)beginClosing
{
    [AIPreferenceWindowController closePreferenceWindow];
}

/*!
 * @brief Close
 */
- (void)closeController
{
    //Preferences are (always) saved as they're modified, so there's no need to save them here.
} 

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
    [delayedNotificationGroups release]; delayedNotificationGroups = nil;
    [paneArray release]; paneArray = nil;
    [prefCache release]; prefCache = nil;
	[objectPrefCache release]; objectPrefCache = nil;
    [super dealloc];
}

/*!
 * @brief Adium 2 to Adium X preference migration
 *
 * This code will move the preferences from "../Adium 2.0" to "../Adium X", if we ever want to do that.
 * Not currently used.
 */
- (void)movePreferenceFolderFromAdium2ToAdium
{
    NSFileManager *manager = [NSFileManager defaultManager];
	NSString      *appSupport = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    NSString *oldPath, *newPath;
    BOOL 	 isDir, oldExists, newExists;
	
	//Check for a preference folder in the old and new locations
	oldPath = [appSupport stringByAppendingPathComponent:@"Adium 2.0"];
    newPath = [appSupport stringByAppendingPathComponent:@"Adium X"];
    oldExists = ([manager fileExistsAtPath:oldPath isDirectory:&isDir] && isDir);
    newExists = ([manager fileExistsAtPath:newPath isDirectory:&isDir] && isDir);
	
	//If we find an old preference folder (and no new one) migrate it to the new location
    if(oldExists & !newExists){
        [manager movePath:oldPath toPath:newPath handler:nil];
    }
}


//Preference Window ----------------------------------------------------------------------------------------------------
#pragma mark Preference Window
/*!
 * @brief Show the preference window
 */
- (IBAction)showPreferenceWindow:(id)sender
{
	[AIPreferenceWindowController openPreferenceWindow];
}

/*!
 * @brief Show a specific category of the preference window
 *
 * Opens the preference window if necessary
 *
 * @param category The category to show
 */
- (void)openPreferencesToCategoryWithIdentifier:(NSString *)identifier
{
	[AIPreferenceWindowController openPreferenceWindowToCategoryWithIdentifier:identifier];
}

/*!
 * @brief Show a specific category within the advanced pane of the preference window
 *
 * Opens the preference window if necessary
 *
 */
- (void)openPreferencesToAdvancedPane:(NSString *)paneName
{
	[AIPreferenceWindowController openPreferenceWindowToAdvancedPane:paneName];
}

/*!
 * @brief Add a view to the preferences
 */
- (void)addPreferencePane:(AIPreferencePane *)inPane
{
    [paneArray addObject:inPane];
}

/*!
 * @brief Returns all currently available preference panes
 */
- (NSArray *)paneArray
{
    return(paneArray);
}


//Observing ------------------------------------------------------------------------------------------------------------
#pragma mark Observing
/*!
 * @brief Register a preference observer
 *
 * The preference observer will be notified when preferences in group change and passed the preference dictionary for that group
 * The observer must implement:
 *		- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
 *
 */
- (void)registerPreferenceObserver:(id)observer forGroup:(NSString *)group
{
	NSMutableArray	*groupObservers;
	
	NSParameterAssert([observer respondsToSelector:@selector(preferencesChangedForGroup:key:object:preferenceDict:firstTime:)]);
	
	//Fetch the observers for this group
	if(!(groupObservers = [observers objectForKey:group])){
		groupObservers = [[NSMutableArray alloc] init];
		[observers setObject:groupObservers forKey:group];
		[groupObservers release];
	}

	//Add our new observer
	[groupObservers addObject:observer];
	
	//Blanket change notification for initialization
	[observer preferencesChangedForGroup:group
									 key:nil
								  object:nil
						  preferenceDict:[self cachedPreferencesWithDefaultsForGroup:group object:nil]
							   firstTime:YES];
}

/*!
 * @brief Unregister a preference observer
 */
- (void)unregisterPreferenceObserver:(id)observer
{
	NSEnumerator	*enumerator = [observers objectEnumerator];
	NSMutableArray	*observerArray;
	
	while(observerArray = [enumerator nextObject]){
		[observerArray removeObject:observer];
	}
}

/*!
 * @brief Broadcast a key changed notification.  
 *
 * Broadcasts a group changed notification if key is nil.
 *
 * If notifications are delayed, remember the group that changed and broadcast this notification when the delay is
 * lifted instead of immediately. Currently, our delayed notification system isn't setup to handle object-specific 
 * preferences, so always notify if there is an object present for now.
 *
 * @param key The key
 * @param group The group
 * @param object The object, or nil if global
 */
- (void)informObserversOfChangedKey:(NSString *)key inGroup:(NSString *)group object:(AIListObject *)object
{
	if(!object && preferenceChangeDelays > 0){
        [delayedNotificationGroups addObject:group];
    }else{
		NSDictionary	*preferenceDict = [self cachedPreferencesWithDefaultsForGroup:group object:object];
		NSEnumerator	*enumerator = [[observers objectForKey:group] objectEnumerator];
		id				observer;

		while(observer = [enumerator nextObject]){
			[observer preferencesChangedForGroup:group
											 key:key
										  object:object
								  preferenceDict:preferenceDict
									   firstTime:NO];
		}
    }
}

/*!
 * @brief Set if preference changed notifications should be delayed
 *
 * Changing large amounts of preferences at once causes a lot of notification overhead. This should be used like
 * [lockFocus] / [unlockFocus] around groups of preference changes to improve performance.
 */
- (void)delayPreferenceChangedNotifications:(BOOL)inDelay
{
	if(inDelay){
		preferenceChangeDelays++;
	}else{
		preferenceChangeDelays--;
	}
	
	//If changes are no longer delayed, save and notify of all preferences modified while delayed
    if(!preferenceChangeDelays){
		NSEnumerator    *enumerator = [delayedNotificationGroups objectEnumerator];
		NSString        *group;
		
		[[adium contactController] delayListObjectNotifications];

		while(group = [enumerator nextObject]){
			[self informObserversOfChangedKey:nil inGroup:group object:nil];
		}

		[[adium contactController] endListObjectNotificationsDelay];
		
		[delayedNotificationGroups removeAllObjects];
    }
}

    
//Setting Preferences -------------------------------------------------------------------
#pragma mark Setting Preferences
/*!
 * @brief Set a global preference
 *
 * Set and save a preference at the global level.
 *
 * @param value The preference, which must be plist-encodable
 * @param key An arbitrary NSString key
 * @param group An arbitrary NSString group
 */
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group{
	[self setPreference:value forKey:key group:group object:nil];
}

/*!
 * @brief Set a global or object-specific preference
 *
 * Set and save a preference.  This should not be called directly from plugins or components.  To set an object-specific
 * preference, use the appropriate method on the object. To set a global preference, use setPreference:forKey:group:
 */
- (void)setPreference:(id)value
			   forKey:(NSString *)key
				group:(NSString *)group
			   object:(AIListObject *)object
{
	NSMutableDictionary	*prefDict = [self cachedPreferencesForGroup:group object:object];
	
    //Set the new value
    if(value != nil){
        [prefDict setObject:value forKey:key];
    }else{
        [prefDict removeObjectForKey:key];
    }
	
	//Update the preference cache with our changes
	[self updateCachedPreferences:prefDict forGroup:group object:object];
	[self informObserversOfChangedKey:key inGroup:group object:object];
}


//Retrieving Preferences ----------------------------------------------------------------
#pragma mark Retrieving Preferences
/*!
 * @brief Retrieve a preference
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group
{
	return([self preferenceForKey:key group:group objectIgnoringInheritance:nil]);
}

/*!
 * @brief Retrieve an object specific preference with inheritance, ignoring defaults
 *
 * Should only be used within AIPreferenceController. See preferenceForKey:group:object: for details.
 */
- (id)_noDefaultsPreferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	id	result = [[self cachedPreferencesForGroup:group object:object] objectForKey:key];
	
	//If there is no object specific preference, inherit the value from the object containing this one
	if(!result && object){
		return([self _noDefaultsPreferenceForKey:key group:group object:[object containingObject]]);
	}else{
		//If we have no object (either were passed no object initially or got here recursively) use defaults if necessary
		return(result);
	}
}

/*!
 * @brief Retrieve an object specific default preference with inheritance
 */
- (id)defaultPreferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	//Don't use the defaults initially
	id	result = [[self cachedDefaultsForGroup:group object:object] objectForKey:key];
	
	//If there is no object specific preference, inherit the value from the object containing this one
	if(!result && object){
		return([self defaultPreferenceForKey:key group:group object:[object containingObject]]);
	}else{
		//If we have no object (either were passed no object initially or got here recursively) use defaults if necessary
		return(result);
	}	
}

/*!
 * @brief Retrieve an object specific preference with inheritance.
 *
 * Objects inherit from their containing objects, up to the global preference.  If this entire tree has no preference
 * defaults are searched starting with the object and continuing up to global.
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	//Don't use the defaults initially
	id result = [self _noDefaultsPreferenceForKey:key group:group object:object];
	
	//If no result, try defaults
	if(!result) result = [self defaultPreferenceForKey:key group:group object:object];
	
	return(result);
}

/*!
 * @brief Retrieve an object specific preference ignoring inheritance.
 *
 * If object is nil, this returns the global preference.  Uses defaults only for the specified preference level,
 * not inherited defaults, as expected.
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group objectIgnoringInheritance:(AIListObject *)object
{
	//We are ignoring inheritance, so we can ignore inherited defaults, too, and use the cachedPreferencesWithDefaultsForGroup:object: dict
	id result = [[self cachedPreferencesWithDefaultsForGroup:group object:object] objectForKey:key];
	
	return(result);
}

/*!
 * @brief Retrieve all the preferences in a group
 *
 * @result A dictionary of preferences for the group, including default values as appropriate
 */
- (NSDictionary *)preferencesForGroup:(NSString *)group
{
	
    return([self cachedPreferencesWithDefaultsForGroup:group object:nil]);
}

//Defaults -------------------------------------------------------------------------------------------------------------
#pragma mark Defaults
/*!
 * @brief Register a dictionary of defaults.
 */
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group{
	[self registerDefaults:defaultDict forGroup:group object:nil];
}

/*!
 * @brief Register a dictionary of object-specific defaults.
 */
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group object:(AIListObject *)object
{
	NSMutableDictionary	*targetDefaultsDict;
	NSMutableDictionary	*activeDefaultsCache;
	NSMutableDictionary *actualDefaultsDict;
	NSString			*cacheKey;	
	
	//Object specific preferences are stored by path and objectID, while regular preferences are stored by group.
	if(object){
		NSString	*path = [object pathToPreferences];
		NSString	*uniqueID = [object internalObjectID];
		cacheKey = [NSString stringWithFormat:@"%@:%@", path, uniqueID];
		activeDefaultsCache = objectPrefWithDefaultsCache;
		targetDefaultsDict = objectDefaults;
		
	}else{
		cacheKey = group;
		activeDefaultsCache = prefWithDefaultsCache;
		targetDefaultsDict = defaults;
		
	}
	
	actualDefaultsDict = [targetDefaultsDict objectForKey:cacheKey];
	if(!actualDefaultsDict) actualDefaultsDict = [NSMutableDictionary dictionary];
	
	[actualDefaultsDict addEntriesFromDictionary:defaultDict];
	[targetDefaultsDict setObject:actualDefaultsDict
						   forKey:cacheKey];

	//Now clear our current prefWithDefaults cache so it will be regenerated with these entries included on next call
	[activeDefaultsCache removeObjectForKey:cacheKey];
}

/*!
 * @brief Reset an advanced preference pane to default values
 *
 * This only works for preference panes, and only panes in the advanced preferences have a reset defaults button.
 */
- (void)resetPreferencesInPane:(AIPreferencePane *)preferencePane
{
	NSDictionary	*allDefaults, *groupDefaults;
	NSEnumerator	*enumerator, *keyEnumerator;
	NSString		*group, *key;
	
	[self delayPreferenceChangedNotifications:YES];
	
	//Get the restorable prefs dictionary of the pref pane
	allDefaults = [preferencePane restorablePreferences];
	
	//They keys are preference groups, run through all of them
	enumerator = [allDefaults keyEnumerator];
	while(group = [enumerator nextObject]){
		
		//Get the dictionary of keys for each group, and reset them all
		groupDefaults = [allDefaults objectForKey:group];
		keyEnumerator = [groupDefaults keyEnumerator];
		while(key = [keyEnumerator nextObject]){
			[[adium preferenceController] setPreference:[groupDefaults objectForKey:key]
												 forKey:key
												  group:group];
		}
	}
	
	[self delayPreferenceChangedNotifications:NO];
}


//Preference Cache -----------------------------------------------------------------------------------------------------
//We cache the preferences locally to avoid loading them each time we need a value
#pragma mark Preference Cache
/*!
 * @brief Fetch cached preferences
 *
 * @param group The group
 * @param object The object, or nil for global
 */
- (NSMutableDictionary *)cachedPreferencesForGroup:(NSString *)group object:(AIListObject *)object
{
	NSMutableDictionary	*prefDict;
	
	//Object specific preferences are stored by path and objectID, while regular preferences are stored by group.
	if(object){
		NSString	*path = [object pathToPreferences];
		NSString	*uniqueID = [object internalObjectID];
		NSString	*cacheKey = [NSString stringWithFormat:@"%@:%@", path, uniqueID];
		
		if(!(prefDict = [objectPrefCache objectForKey:cacheKey])){
			prefDict = [NSMutableDictionary dictionaryAtPath:[userDirectory stringByAppendingPathComponent:path]
													withName:[uniqueID safeFilenameString]
													  create:YES];
			[objectPrefCache setObject:prefDict forKey:cacheKey];
		}

	}else{
		if(!(prefDict = [prefCache objectForKey:group])){
			prefDict = [NSMutableDictionary dictionaryAtPath:userDirectory
													withName:group
													  create:YES];
			[prefCache setObject:prefDict forKey:group];
		}
	}
	
	return(prefDict);
}

/*!
 * @brief Return just the defaults for a specified group and object
 *
 * @param group The group
 * @param object The object, or nil for global defaults
 */
- (NSDictionary *)cachedDefaultsForGroup:(NSString *)group object:(AIListObject *)object
{
	NSDictionary		*sourceDefaultsDict;
	NSString			*cacheKey;

	//Object specific preferences are stored by path and objectID, while regular preferences are stored by group.
	if(object){
		NSString	*path = [object pathToPreferences];
		NSString	*uniqueID = [object internalObjectID];
		cacheKey = [NSString stringWithFormat:@"%@:%@", path, uniqueID];
		sourceDefaultsDict = objectDefaults;
		
	}else{
		cacheKey = group;
		sourceDefaultsDict = defaults;
	}
	
	return([sourceDefaultsDict objectForKey:cacheKey]);
}

/*!
 * @brief Return the result of taking the defaults and superceding them with any set preferences
 *
 * @param group The group
 * @param object The object, or nil for global
 */
- (NSDictionary *)cachedPreferencesWithDefaultsForGroup:(NSString *)group object:(AIListObject *)object
{
	NSDictionary		*prefWithDefaultsDict;
	NSMutableDictionary	*activeDefaultsCache;
	NSDictionary		*sourceDefaultsDict;
	NSString			*cacheKey;
	
	//Object specific preferences are stored by path and objectID, while regular preferences are stored by group.
	if(object){
		NSString	*path = [object pathToPreferences];
		NSString	*uniqueID = [object internalObjectID];
		cacheKey = [NSString stringWithFormat:@"%@:%@", path, uniqueID];
		activeDefaultsCache = objectPrefWithDefaultsCache;
		sourceDefaultsDict = objectDefaults;

	}else{
		cacheKey = group;
		activeDefaultsCache = prefWithDefaultsCache;
		sourceDefaultsDict = defaults;

	}
	
	if(!(prefWithDefaultsDict = [activeDefaultsCache objectForKey:cacheKey])){		
		NSDictionary	*userPrefs = [self cachedPreferencesForGroup:group object:object];
		NSDictionary	*defaultPrefs = [sourceDefaultsDict objectForKey:cacheKey];
		if(defaultPrefs){
			//Add the object's own preferences to the defaults dictionary to get a dict with the object's keys
			//overriding the default keys
			prefWithDefaultsDict = [[defaultPrefs mutableCopy] autorelease];
			[(NSMutableDictionary *)prefWithDefaultsDict addEntriesFromDictionary:userPrefs];
		}else{
			//With no defaults, just use the userPrefs
			prefWithDefaultsDict = userPrefs;
		}
		
		//And cache the result; the cache should be updated or cleared when the dictionary changes
		[activeDefaultsCache setObject:prefWithDefaultsDict forKey:cacheKey];
	}

	return(prefWithDefaultsDict);
}

/*!
 * @brief Write preference changes back to the cache and to disk
 *
 * @param prefDict The user-specified preferences (not including defaults)
 * @param group The group
 * @param object The object, or nil for global
 */
- (void)updateCachedPreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)group object:(AIListObject *)object
{
	if(object){
		NSString	*path = [object pathToPreferences];
		NSString	*uniqueID = [object internalObjectID];
		NSString	*cacheKey = [NSString stringWithFormat:@"%@:%@", path, uniqueID];

		//Store to our object pref cache
		[objectPrefCache setObject:prefDict forKey:cacheKey];
		
		/* Retain and autorelease the current prefDict so it remains viable for this run loop, since code should be
		 * able to depend upon a retrieved prefDict remaining usable without bracketing a set of 
		 * -[AIPreferenceController setPreference:forKey:group:] calls with retain/release. */
		[[[objectPrefWithDefaultsCache objectForKey:group] retain] autorelease];

		//Clear the cache so the union of defaults and preferences will be recalculated on next call
		[objectPrefWithDefaultsCache removeObjectForKey:cacheKey];

		//Save the preference change immediately (Probably not the best idea?)
		[prefDict writeToPath:[userDirectory stringByAppendingPathComponent:path]
					 withName:[uniqueID safeFilenameString]];

	}else{
		/* Retain and autorelease the current prefDict so it remains viable for this run loop, since code should be
		 * able to depend upon a retrieved prefDict remaining usable without bracketing a set of 
		 * -[AIPreferenceController setPreference:forKey:group:] calls with retain/release. */
		[[[prefWithDefaultsCache objectForKey:group] retain] autorelease];
		
		//Clear the cache so the union of defaults and preferences will be recalculated on next call
		[prefWithDefaultsCache removeObjectForKey:group];
		
		//Save the preference change immediately (Probably not the best idea?)
		[prefDict writeToPath:userDirectory withName:group];
		
	}
}

//Default download locaiton --------------------------------------------------------------------------------------------
#pragma mark Default download location
/*!
 * @brief Get the default download location
 *
 * This will use an Adium-specific preference if set, or the systemwide download location if not
 *
 * @result A full path to the download location
 */
- (NSString *) userPreferredDownloadFolder
{
	NSString	*userPreferredDownloadFolder;
	
	userPreferredDownloadFolder = [self preferenceForKey:@"UserPreferredDownloadFolder"
												   group:PREF_GROUP_GENERAL];
	
	if(!userPreferredDownloadFolder){
		OSStatus		err = noErr;
		ICInstance		inst = NULL;
		ICFileSpec		folder;
		unsigned long	length = kICFileSpecHeaderSize;
		FSRef			ref;
		unsigned char	path[1024];
		
		memset( path, 0, 1024 ); //clear path's memory range
		
		if((err = ICStart(&inst, 'AdiM')) == noErr){
			ICGetPref( inst, kICDownloadFolder, NULL, &folder, &length );
			ICStop( inst );
			
			if(((err = FSpMakeFSRef(&folder.fss, &ref)) == noErr) &&
			   ((err = FSRefMakePath(&ref, path, 1024)) == noErr) &&
			   ((path != NULL) && (strlen(path) > 0))){
				userPreferredDownloadFolder = [NSString stringWithUTF8String:path];
			}
		}
	}
	
	if(!userPreferredDownloadFolder){
		userPreferredDownloadFolder = @"~/Desktop";
	}

	return [userPreferredDownloadFolder stringByExpandingTildeInPath];
}

/*!
 * @brief Set the location Adium should use for saving files
 *
 * @param A path to an existing folder
 */
- (void)setUserPreferredDownloadFolder:(NSString *)path
{
	[self setPreference:[path stringByAbbreviatingWithTildeInPath]
				 forKey:@"UserPreferredDownloadFolder"
				  group:PREF_GROUP_GENERAL];
}


@end

