/* 
Adium, Copyright 2001-2004, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/*
 Core - Preference Controller
 
 Handles loading and saving preferences and preference changed notifications
 
 */

#import "AIPreferenceController.h"
#import "AIPreferenceWindowController.h"

#define PREFS_DEFAULT_PREFS 	@"PrefsPrefs.plist"

@interface AIPreferenceController (PRIVATE)
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName;
- (void)savePreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)groupName;
@end

@implementation AIPreferenceController

//init
- (void)initController
{
    //
    paneArray = [[NSMutableArray alloc] init];
    prefCache = [[NSMutableDictionary alloc] init];
	objectPrefCache = [[NSMutableDictionary alloc] init];
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

//We can't do these in initing, since the toolbar controller hasn't loaded yet
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

//We must close the preference window before plugins and the other controllers are unloaded.
- (void)beginClosing
{
    [AIPreferenceWindowController closeSharedInstance];
}

//close
- (void)closeController
{
    //Preferences are (always) saved as they're modified, so there's no need to save them here.
} 

//dealloc
- (void)dealloc
{
    [delayedNotificationGroups release]; delayedNotificationGroups = nil;
    [paneArray release]; paneArray = nil;
    [prefCache release]; prefCache = nil;
	[objectPrefCache release]; objectPrefCache = nil;
    [super dealloc];
}

//This code will move the preferences from "../Adium 2.0" to "../Adium X", if we ever want to do that
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
//Show the preference window
- (IBAction)showPreferenceWindow:(id)sender
{
    [[AIPreferenceWindowController preferenceWindowController] showWindow:nil];
}

//Show a specific category of the preference window
- (void)openPreferencesToCategory:(PREFERENCE_CATEGORY)category
{
	AIPreferenceWindowController	*preferenceWindow = [AIPreferenceWindowController preferenceWindowController];
    [preferenceWindow showCategory:category];
    [preferenceWindow showWindow:nil];
}

- (void)openPreferencesToAdvancedPane:(NSString *)paneName inCategory:(PREFERENCE_CATEGORY)category
{
	AIPreferenceWindowController	*preferenceWindow = [AIPreferenceWindowController preferenceWindowController];
	[preferenceWindow showAdvancedPane:paneName inCategory:category];
	[preferenceWindow showWindow:nil];
}

//Add a view to the preferences
- (void)addPreferencePane:(AIPreferencePane *)inPane
{
    [paneArray addObject:inPane];
}

//Returns all currently available preference panes
- (NSArray *)paneArray
{
    return(paneArray);
}


//Observing ------------------------------------------------------------------------------------------------------------
#pragma mark Observing
//Register a preference observer
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
						  preferenceDict:[self cachedPreferencesForGroup:group object:nil]
							   firstTime:YES];
}

//Unregister a preference observer
- (void)unregisterPreferenceObserver:(id)observer
{
	NSEnumerator	*enumerator = [observers objectEnumerator];
	NSMutableArray	*observerArray;
	
	while(observerArray = [enumerator nextObject]){
		[observerArray removeObject:observer];
	}
}

//Broadcast a key changed notification.  If notifications are delayed, remember the group that changed and broadcast
//this notification when the delay is lifted instead of immediately.
//Currently, our delayed notification system isn't setup to handle object-specific preferences, so always
//notify if there is an object present for now.
- (void)informObserversOfChangedKey:(NSString *)key inGroup:(NSString *)group object:(AIListObject *)object
{
	if(!object && preferenceChangeDelays > 0){
        [delayedNotificationGroups addObject:group];
    }else{
		NSDictionary	*preferenceDict = [self cachedPreferencesForGroup:group object:object];
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

//Changing large amounts of preferences at once causes a lot of notification overhead
//This should be used like [lockFocus] / [unlockFocus] around groups of preference changes to improve performance
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
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group{
	[self setPreference:value forKey:key group:group object:nil];
}
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
//Retrieve a preference
- (id)preferenceForKey:(NSString *)key group:(NSString *)group
{
	return([[self cachedPreferencesForGroup:group object:nil] objectForKey:key]);
}

//Retrieve an object specific preference (With inheritance)
- (id)preferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	id	result = [[self cachedPreferencesForGroup:group object:object] objectForKey:key];
	
	//If there is no object specific preference, inherit the value from the object containing this one
	if(!result && object){
		return([self preferenceForKey:key group:group object:[object containingObject]]);
	}else{
		return(result);
	}
}

//Retrieve an object specific preference (Ignoring inheritance)
- (id)preferenceForKey:(NSString *)key group:(NSString *)group objectIgnoringInheritance:(AIListObject *)object
{
	return([[self cachedPreferencesForGroup:group object:object] objectForKey:key]);
}

//Retrieve all the preferences in a group
- (NSDictionary *)preferencesForGroup:(NSString *)group
{
    return([self cachedPreferencesForGroup:group object:nil]);    
}


//Defaults -------------------------------------------------------------------------------------------------------------
#pragma mark Defaults
//Register a dictionary of defaults.  Defaults are only available for preferences in the advanced category.
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group
{
    NSMutableDictionary	*prefDict = [self cachedPreferencesForGroup:group object:nil];
    NSEnumerator		*enumerator;
    NSString			*key;
	
	//This is a poor way to handle defaults, since it means the defaults will be written as the users preferences
	//if they ever change any key in this group.
    enumerator = [[defaultDict allKeys] objectEnumerator];
    while((key = [enumerator nextObject])){
        if(![prefDict objectForKey:key]){
            [prefDict setObject:[defaultDict objectForKey:key] forKey:key];
        }
    }
}

//Reset the preferences of a pane to their default values.  This only works for preference panes, and only panes
//in the advanced preferences have a reset defaults button
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
//Fetch cached preferences
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

//Write preference changes back to the cache (The cache will be written to disk at a later time)
- (void)updateCachedPreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)group object:(AIListObject *)object
{
	if(object){
		NSString	*path = [object pathToPreferences];
		NSString	*uniqueID = [object internalObjectID];
		NSString	*cacheKey = [NSString stringWithFormat:@"%@:%@", path, uniqueID];

		[objectPrefCache setObject:prefDict forKey:cacheKey];
		
		//Save the preference change immediately (Probably not the best idea?)
		[prefDict writeToPath:[userDirectory stringByAppendingPathComponent:path]
					 withName:[uniqueID safeFilenameString]];
		
	}else{
		//Save the preference change immediately (Probably not the best idea?)
		[prefDict writeToPath:userDirectory withName:group];
		
	}
}

//Default download locaiton --------------------------------------------------------------------------------------------
#pragma mark Default download location
- (NSString *) userPreferredDownloadFolder
{
	OSStatus		err = noErr;
	ICInstance		inst = NULL;
	ICFileSpec		folder;
	unsigned long	length = kICFileSpecHeaderSize;
	FSRef			ref;
	unsigned char	path[1024];
	
	memset( path, 0, 1024 ); //clear path's memory range
	
	if( ( err = ICStart( &inst, 'AdiM' ) ) != noErr )
		goto finish;
	
	ICGetPref( inst, kICDownloadFolder, NULL, &folder, &length );
	ICStop( inst );
	
	if( ( err = FSpMakeFSRef( &folder.fss, &ref ) ) != noErr )
		goto finish;
	
	if( ( err = FSRefMakePath( &ref, path, 1024 ) ) != noErr )
		goto finish;
	
finish:
		if( ! strlen( path ) )
			return [@"~/Desktop" stringByExpandingTildeInPath];
	
	return [NSString stringWithUTF8String:path];
}

- (void)setUserPreferredDownloadFolder:(NSString *)path {
	OSStatus		err = noErr;
	ICInstance		inst = NULL;
	ICFileSpec		*dir = NULL;
	FSRef			ref;
	AliasHandle		alias;
	unsigned long	length = 0;
	
	if( ( err = FSPathMakeRef( [path UTF8String], &ref, NULL ) ) != noErr )
		return;
	
	if( ( err = FSNewAliasMinimal( &ref, &alias ) ) != noErr )
 		return;
	
	length = ( kICFileSpecHeaderSize + GetHandleSize( (Handle) alias ) );
	dir = malloc( length );
	memset( dir, 0, length );
	
	if( ( err = FSGetCatalogInfo( &ref, kFSCatInfoNone, NULL, NULL, &dir -> fss, NULL ) ) != noErr )
		return;
	
	memcpy( &dir -> alias, *alias, length - kICFileSpecHeaderSize );
	
	if( ( err = ICStart( &inst, 'AdiM' ) ) != noErr )
		return;
	
	ICSetPref( inst, kICDownloadFolder, NULL, dir, length );
	ICStop( inst );
	
	free( dir );
	DisposeHandle( (Handle) alias );
}


@end

