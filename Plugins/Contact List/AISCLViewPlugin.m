/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AISCLViewPlugin.h"
#import "AICLPreferences.h"
#import "AIStandardListWindowController.h"
#import "AIBorderlessListWindowController.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"

#define DEFAULT_LIST_THEME_NAME		@"Aqua (Tiger)"
#define DEFAULT_LIST_LAYOUT_NAME	@"Standard"

int availableSetSort(NSDictionary *objectA, NSDictionary *objectB, void *context);

@interface AISCLViewPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
+ (NSDictionary *)cachedSetDictWithName:(NSString *)setName extension:(NSString *)extension;
@end

@implementation AISCLViewPlugin

static 	NSMutableDictionary	*_xtrasDict = nil;

- (void)installPlugin
{
    [[adium interfaceController] registerContactListController:self];

	[adium createResourcePathForName:LIST_LAYOUT_FOLDER];
	[adium createResourcePathForName:LIST_THEME_FOLDER];

    //Register our default preferences and install our preference views
//    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    preferences = [[AICLPreferences preferencePane] retain];
	
	//Observe list closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListDidClose)
									   name:Interface_ContactListDidClose
									 object:nil];
	
    //Observe window style changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	//Apply the default contact list layout and style (If no style is currently active)
	if(![[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_CONTACT_LIST]){
		[[adium preferenceController] setPreference:DEFAULT_LIST_THEME_NAME
											 forKey:KEY_LIST_THEME_NAME
											  group:PREF_GROUP_CONTACT_LIST];
	}
	if(![[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_CONTACT_LIST]){
		[[adium preferenceController] setPreference:DEFAULT_LIST_LAYOUT_NAME
											 forKey:KEY_LIST_LAYOUT_NAME
											  group:PREF_GROUP_CONTACT_LIST];
	}
	
    [self preferencesChanged:nil];
}




//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//Show contact list
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
    if(!contactListWindowController){ //Load the window
		if(windowStyle == WINDOW_STYLE_STANDARD){
			contactListWindowController = [[AIStandardListWindowController listWindowController] retain];
		}else{
			contactListWindowController = [[AIBorderlessListWindowController listWindowController] retain];
		}
    }

	[contactListWindowController showWindowInFront:bringToFront];
}

//Returns YES if the contact list is visible and in front
- (BOOL)contactListIsVisibleAndMain
{
	return(contactListWindowController && [[contactListWindowController window] isMainWindow]);
}

//Close contact list
- (void)closeContactList
{
    if(contactListWindowController){
        [[contactListWindowController window] performClose:nil];
		[self contactListDidClose];
    }
}

//Callback when the contact list closes, clear our reference to it
- (void)contactListDidClose
{
	[contactListWindowController release];
	contactListWindowController = nil;
}


//Themes and Layouts ---------------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//Apply any theme/layout changes
- (void)preferencesChanged:(NSNotification *)notification
{
	NSString	*group = [[notification userInfo] objectForKey:@"Group"];

	if(notification == nil || [group isEqualToString:PREF_GROUP_CONTACT_LIST]){
		NSString	*key = [[notification userInfo] objectForKey:@"Key"];

		//Theme
		if(notification == nil || !key || [key isEqualToString:KEY_LIST_THEME_NAME]){
			[AISCLViewPlugin applySetWithName:[[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME
			 																		   group:PREF_GROUP_CONTACT_LIST]
									extension:LIST_THEME_EXTENSION
									 inFolder:LIST_THEME_FOLDER
							toPreferenceGroup:PREF_GROUP_LIST_THEME];
		}
		
		//Layout
		if(notification == nil || !key || [key isEqualToString:KEY_LIST_LAYOUT_NAME]){
			[AISCLViewPlugin applySetWithName:[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME
			 																		   group:PREF_GROUP_CONTACT_LIST]
									extension:LIST_LAYOUT_EXTENSION
									 inFolder:LIST_LAYOUT_FOLDER
							toPreferenceGroup:PREF_GROUP_LIST_LAYOUT];
		}
	}
	
	if(notification == nil || [group isEqualToString:PREF_GROUP_LIST_LAYOUT]){
		NSString	*key = [[notification userInfo] objectForKey:@"Key"];
		
		if(notification == nil || !key || [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE]){
			int	newWindowStyle = [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE
																		   group:PREF_GROUP_LIST_LAYOUT] intValue];
			if(newWindowStyle != windowStyle){
				windowStyle = newWindowStyle;
				
				//If a contact list is visible and the window style has changed, update for the new window style
				if(contactListWindowController){
					[self closeContactList];
					[self showContactListAndBringToFront:NO];
				}
			}
		}
	}
}

//Apply a set of preferences
+ (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup
{
	AIAdium			*adiumInstance = [AIObject sharedAdiumInstance];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSEnumerator	*enumerator;
	NSString		*fileName, *resourcePath;
	NSString		*key;
	NSDictionary	*setDict, *setDictionary = nil;

	if (setDict = [self cachedSetDictWithName:setName extension:extension]){
		setDictionary = [setDict objectForKey:@"preferences"];
	}
	
	if (!setDictionary){
		//If we didn't find a setDictionary already loaded, look in each resource location until we find it
		fileName = [setName stringByAppendingPathExtension:extension];
		
		enumerator = [[adiumInstance resourcePathsForName:folder] objectEnumerator];
		while((resourcePath = [enumerator nextObject]) && !setDictionary) {
			NSString		*filePath = [resourcePath stringByAppendingPathComponent:fileName];
			
			if ([defaultManager fileExistsAtPath:filePath]){
				setDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
			}
		}
	}
	
	//Apply its values
	[[adiumInstance preferenceController] delayPreferenceChangedNotifications:YES];
	enumerator = [setDictionary keyEnumerator];
	while(key = [enumerator nextObject]){
		[[adiumInstance preferenceController] setPreference:[setDictionary objectForKey:key]
													 forKey:key
													  group:preferenceGroup];
	}
	[[adiumInstance preferenceController] delayPreferenceChangedNotifications:NO];
}

//Create a layout or theme set
+ (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	NSString		*path, *destFolder;
	NSString		*fileName = [[setName safeFilenameString] stringByAppendingPathExtension:extension];
	AIAdium			*sharedAdiumInstance = [AIObject sharedAdiumInstance];

	//If we don't find one, create a path to the application support directory
	destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	path = [destFolder stringByAppendingPathComponent:fileName];
	
	if([[[sharedAdiumInstance preferenceController] preferencesForGroup:preferenceGroup] writeToFile:path atomically:NO]){
		
		[[sharedAdiumInstance notificationCenter] postNotificationName:Adium_Xtras_Changed object:extension];

		return(YES);
	}else{
		NSRunAlertPanel(@"Error Saving Theme",
						@"Unable to write file %@ to %@",
						@"Okay",
						nil,
						nil,
						fileName,
						path);
		return(NO);
	}
}

//Delete a layout or theme set
+ (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	NSString		*path = nil;
	NSDictionary	*setDict;
	BOOL			success;
	
	if (setDict = [self cachedSetDictWithName:setName extension:extension]){
		path = [setDict objectForKey:@"path"];
	}
	
	if (!path){
		NSString	*destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
		NSString	*fileName = [setName stringByAppendingPathExtension:extension];
		path = [destFolder stringByAppendingPathComponent:fileName];
	}
	
	success = [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:Adium_Xtras_Changed object:extension];
	
	return(success);
}

//When our preferences view closes, clear out the cache of all the various themes and layouts which we had in memory
+ (void)resetXtrasCache
{
	[_xtrasDict release]; _xtrasDict = nil;
}

+ (NSArray *)availableLayoutSets
{
	NSArray	*availableLayoutSets = [_xtrasDict objectForKey:LIST_LAYOUT_EXTENSION];

	if (!availableLayoutSets){
		availableLayoutSets = [AISCLViewPlugin availableSetsWithExtension:LIST_LAYOUT_EXTENSION 
															   fromFolder:LIST_LAYOUT_FOLDER];

		if (!_xtrasDict) _xtrasDict = [[NSMutableDictionary alloc] init];
		[_xtrasDict setObject:availableLayoutSets
					   forKey:LIST_LAYOUT_EXTENSION];
	}

	return availableLayoutSets;
}
+ (NSArray *)availableThemeSets
{
	NSArray	*availableThemeSets = [_xtrasDict objectForKey:LIST_THEME_EXTENSION];

	if (!availableThemeSets){
		availableThemeSets = [AISCLViewPlugin availableSetsWithExtension:LIST_THEME_EXTENSION fromFolder:LIST_THEME_FOLDER];
		
		if (!_xtrasDict) _xtrasDict = [[NSMutableDictionary alloc] init];
		[_xtrasDict setObject:availableThemeSets
					   forKey:LIST_THEME_EXTENSION];
	}

	return availableThemeSets;
}

+ (NSDictionary *)cachedSetDictWithName:(NSString *)setName extension:(NSString *)extension
{
	NSArray			*setArray = [_xtrasDict objectForKey:extension];
	NSEnumerator	*enumerator;
	NSDictionary	*setDict;
	
	//Try to find an existing object with this name to overwrite
	enumerator = [setArray objectEnumerator];
	while (setDict = [enumerator nextObject]){
		if ([[setDict objectForKey:@"name"] isEqualToString:setName]) break;
	}
	
	return(setDict);
}

//
+ (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[AIObject sharedAdiumInstance] resourcePathsForName:folder] objectEnumerator];
	NSString		*resourcePath;
	NSMutableArray	*alreadyAddedArray = [NSMutableArray array];
	
    while(resourcePath = [enumerator nextObject]) {
        NSEnumerator 	*fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
        NSString		*filePath;
		
        //Find all the sets
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:extension] == NSOrderedSame){					
				NSString		*themePath = [resourcePath stringByAppendingPathComponent:filePath];
				NSDictionary 	*themeDict = [NSDictionary dictionaryWithContentsOfFile:themePath];
				
				if(themeDict){
					NSString	*name = [filePath stringByDeletingPathExtension];
					
					//The Adium resource path is last in our resourcePaths array; by only adding sets we haven't
					//already added, we allow precedence to occur rather than conflict.
					if ([alreadyAddedArray indexOfObject:name] == NSNotFound){
						[setArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							name, @"name",
							themePath, @"path",
							themeDict, @"preferences",
							nil]];
						[alreadyAddedArray addObject:name];
					}
				}
			}
		}
	}
	
	return([setArray sortedArrayUsingFunction:availableSetSort context:nil]);
}

//Sort sets
int availableSetSort(NSDictionary *objectA, NSDictionary *objectB, void *context){
	return([[objectA objectForKey:@"name"] caseInsensitiveCompare:[objectB objectForKey:@"name"]]);
}

@end

