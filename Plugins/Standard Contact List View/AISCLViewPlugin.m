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

int availableSetSort(NSDictionary *objectA, NSDictionary *objectB, void *context);

@interface AISCLViewPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AISCLViewPlugin

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
			NSLog(@"%@",[[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME
																 group:PREF_GROUP_CONTACT_LIST]);
			[AISCLViewPlugin applySetWithName:[[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME
			 																		   group:PREF_GROUP_CONTACT_LIST]
									extension:LIST_THEME_EXTENSION
									 inFolder:LIST_THEME_FOLDER
							toPreferenceGroup:PREF_GROUP_LIST_THEME];
		}
		
		//Layout
		if(notification == nil || !key || [key isEqualToString:KEY_LIST_LAYOUT_NAME]){
			NSLog(@"%@",[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME
																 group:PREF_GROUP_CONTACT_LIST]);
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
	NSString		*destFolder, *fileName, *path;
	NSDictionary	*setDictionary;
	NSEnumerator	*enumerator;
	NSString		*key;
	
	//Load the set
	destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	fileName = [setName stringByAppendingPathExtension:extension];
	path = [destFolder stringByAppendingPathComponent:fileName];
	setDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	
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
	NSString	*destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*fileName = [setName stringByAppendingPathExtension:extension];
	NSString	*path = [destFolder stringByAppendingPathComponent:fileName];
	
	if([[[[AIObject sharedAdiumInstance] preferenceController] preferencesForGroup:preferenceGroup] writeToFile:path atomically:NO]){
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
	NSString	*destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*fileName = [setName stringByAppendingPathExtension:extension];
	NSString	*path = [destFolder stringByAppendingPathComponent:fileName];
	
	return([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]);
}

//
+ (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[AIObject sharedAdiumInstance] resourcePathsForName:folder] objectEnumerator];
	NSString		*resourcePath;
	
    while(resourcePath = [enumerator nextObject]) {
        NSEnumerator 	*fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
        NSString		*filePath;
		
        //Find all the sets
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:extension] == NSOrderedSame){					
				NSString		*themePath = [resourcePath stringByAppendingPathComponent:filePath];
				NSDictionary 	*themeDict = [NSDictionary dictionaryWithContentsOfFile:themePath];
				
				if(themeDict){
					[setArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[filePath stringByDeletingPathExtension], @"name",
						themePath, @"path",
						themeDict, @"preferences",
						nil]];
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

