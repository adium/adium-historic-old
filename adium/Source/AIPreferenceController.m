/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

// $Id: AIPreferenceController.m,v 1.42 2004/02/26 23:22:51 adamiser Exp $

#import "AIPreferenceController.h"
#import "AIPreferenceWindowController.h"
#import "AIPreferenceCategory.h"

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
    groupDict = [[NSMutableDictionary alloc] init];
	objectPrefCache = [[NSMutableDictionary alloc] init];
    themablePreferences = [[NSMutableDictionary alloc] init];
    delayedNotificationGroups = [[NSMutableSet alloc] init];
    shouldDelay = NO;
    
    //
    [owner registerEventNotification:Preference_GroupChanged displayName:@"Preferences Changed"];    

    //Create the 'ByObject' and 'Accounts' object specific preference directory
    [AIFileUtilities createDirectory:[[[owner loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH]];
    [AIFileUtilities createDirectory:[[[owner loginController] userDirectory] stringByAppendingPathComponent:ACCOUNT_PREFS_PATH]];

	//
	userDirectory = [[[owner loginController] userDirectory] retain];
	
}

//We can't do these in initing, since the toolbar controller hasn't loaded yet
- (void)finishIniting
{
    NSToolbarItem	*toolbarItem;

    //Show preference window toolabr item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowPreferences"
					    label:@"Preferences"
				     paletteLabel:@"Open Preferences"
				          toolTip:@"Open Preferences"
				           target:self
				  settingSelector:@selector(setImage:)
				      itemContent:[AIImageUtilities imageNamed:@"settings" forClass:[self class]]
				           action:@selector(showPreferenceWindow:)
					     menu:nil];
    [[owner toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"General"];
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
    [groupDict release]; groupDict = nil;
	[objectPrefCache release];
    [themablePreferences release]; themablePreferences = nil;
    [super dealloc];
}


//Preference Window ----------------------------------------------------------------------------------------------------
#pragma mark Preference Window
//Show the preference window
- (IBAction)showPreferenceWindow:(id)sender
{
    [[AIPreferenceWindowController preferenceWindowController] showWindow:nil];
}

//Show a specific pane of the preference window
- (void)openPreferencesToPane:(AIPreferencePane *)inPane
{
	/*    AIPreferenceWindowController	*preferenceWindow = [AIPreferenceWindowController preferenceWindowController];
    [preferenceWindow showView:inView];
    [preferenceWindow showWindow:nil];*/
}

//Return the array of preference panes
- (NSArray *)paneArray
{
    return(paneArray);
}


//Adding Preferences ---------------------------------------------------------------------------------------------------
#pragma mark Adding Preferences
//Add a view to the preferences
- (void)addPreferencePane:(AIPreferencePane *)inPane
{
    //Add the pane to our array
    [paneArray addObject:inPane];
}

//Register a dictionary of defaults
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;
    NSEnumerator	*enumerator;
    NSString		*key;

    //Load the group if necessary
    prefDict = [self loadPreferenceGroup:groupName];

    //Set defaults for any value that doesn't have a key
    enumerator = [[defaultDict allKeys] objectEnumerator];
    while((key = [enumerator nextObject])){
        if(![prefDict objectForKey:key]){
            [prefDict setObject:[defaultDict objectForKey:key] forKey:key];
        }
    }
}


- (void)registerThemableKeys:(NSArray *)keysArray forGroup:(NSString *)groupName
{
    NSMutableSet *keySet = [themablePreferences objectForKey:groupName];
    if (!keySet)
	keySet = [[[NSMutableSet alloc] init] autorelease];
    
    [keySet addObjectsFromArray:keysArray];
    
    [themablePreferences setObject:keySet forKey:groupName];
}
- (NSDictionary *)themablePreferences
{
    return (themablePreferences);
}


//Contact/Group Specific Preferences -----------------------------------------------------------------------------------
#pragma mark Contact/Group Specific Preferences
//Private: For AIListObject only.  Access to a shared object specific preference dict.
//This code would be within AIListObject, but since several objects share the same preference file it would prevent
//caching.  By moving the preference dicts in here we can share the caches between our objects, improving performance.
- (NSMutableDictionary *)cachedObjectPrefsForKey:(NSString *)objectKey path:(NSString *)path
{
	NSString			*cacheKey = [NSString stringWithFormat:@"%@:%@", path, objectKey];
	NSMutableDictionary	*prefs = [objectPrefCache objectForKey:cacheKey]; 
	
	//Load if necessary
	if(!prefs){
		prefs = [NSMutableDictionary dictionaryAtPath:[userDirectory stringByAppendingPathComponent:path]
											 withName:objectKey
											   create:YES];
		[objectPrefCache setObject:prefs forKey:cacheKey];
	}
	
	return(prefs);
}

//Write prefs back to the cache
- (void)setCachedObjectPrefs:(NSMutableDictionary *)prefs forKey:(NSString *)objectKey path:(NSString *)path
{
	NSString			*cacheKey = [NSString stringWithFormat:@"%@:%@", path, objectKey];

	//Add back to cache and save
	[objectPrefCache setObject:prefs forKey:cacheKey];
    [prefs writeToPath:[userDirectory stringByAppendingPathComponent:path]
			  withName:objectKey];
}

//Private
- (BOOL)tempImportOldPreferenceForKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object
{
    if(![object isKindOfClass:[AIAccount class]]){
		NSString		*objectKey = [NSString stringWithFormat:@"(%@)", [object UIDAndServiceID]];
		NSMutableDictionary     *prefDict = [self loadPreferenceGroup:groupName];
		NSMutableDictionary     *objectPrefDict = [prefDict objectForKey:objectKey];
		id			oldValue;
		
		if(oldValue = [objectPrefDict objectForKey:inKey]){
			NSLog(@"Imported preference: %@ : %@",objectKey,inKey);
			[object setPreference:oldValue forKey:inKey group:groupName];
			
			//Delete old
			[objectPrefDict removeObjectForKey:inKey];
			[prefDict setObject:objectPrefDict forKey:objectKey];
			[self savePreferences:prefDict forGroup:groupName];
			
			return(YES);
		}
    }
	
    return(NO);
}

    
//General Preferences --------------------------------------------------------------------------------------------------
#pragma mark General Preferences
//Return a dictionary of preferences
- (NSDictionary *)preferencesForGroup:(NSString *)groupName
{
    return([self loadPreferenceGroup:groupName]);    
}

//Return a preference key
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
    return([[self loadPreferenceGroup:groupName] objectForKey:inKey]);
}

//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;
    
    //Load the preferences
    prefDict = [self loadPreferenceGroup:groupName];
	
    //Set and save the new value
    if(value != nil){
        [prefDict setObject:value forKey:inKey];
    }else{
        [prefDict removeObjectForKey:inKey];
    }
    [self savePreferences:prefDict forGroup:groupName];
	
	if (shouldDelay) {
        [delayedNotificationGroups addObject:groupName];
    } else {
        //Broadcast a group changed notification
        [[owner notificationCenter] postNotificationName:Preference_GroupChanged
												  object:nil
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",inKey,@"Key",nil]];
    }
}

//Delay preference changed notifications
//This should be used like [lockFocus] / [unlockFocus] around groups of preference changes
- (void)delayPreferenceChangedNotifications:(BOOL)inDelay
{
    if (inDelay != shouldDelay) {
        shouldDelay = inDelay;
        if (!inDelay) {
            NSEnumerator    *enumerator = [delayedNotificationGroups objectEnumerator];
            NSString        *groupName;
            while (groupName = [enumerator nextObject])
                [[owner notificationCenter] postNotificationName:Preference_GroupChanged
														  object:nil
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",nil]];
            [delayedNotificationGroups removeAllObjects];
        }
    }
}


//Internal -------------------------------------------------------------------------------------------------------------
#pragma mark Internal
//Load a preference group
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict = nil;
    
    //We may not have logged in as a user yet.
    if([[owner loginController] userDirectory] && !(prefDict = [groupDict objectForKey:groupName])){
        NSString 	*path = [[owner loginController] userDirectory];

        prefDict = [NSMutableDictionary dictionaryAtPath:path withName:groupName create:YES];
        [groupDict setObject:prefDict forKey:groupName];
    }
    
    return(prefDict);
}

//Save a preference group
- (void)savePreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)groupName
{
    NSString	*path = [[owner loginController] userDirectory];
    
    [prefDict writeToPath:path withName:groupName];
}

@end

