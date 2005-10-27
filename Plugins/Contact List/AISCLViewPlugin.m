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

#import "AIBorderlessListWindowController.h"
#import "AIInterfaceController.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"
#import "AISCLViewPlugin.h"
#import "AIStandardListWindowController.h"
#import "ESContactListAdvancedPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AIXtrasManager.h"

#warning crosslink
#import "AIAppearancePreferencesPlugin.h"

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

    //Install our preference views
	advancedPreferences = [[ESContactListAdvancedPreferences preferencePane] retain];
	   
	//Observe list closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListDidClose)
									   name:Interface_ContactListDidClose
									 object:nil];

	AIPreferenceController *preferenceController = [adium preferenceController];
	
	//Now register our other defaults, which are 
    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTACT_LIST_DEFAULTS
																forClass:[self class]]
	                              forGroup:PREF_GROUP_CONTACT_LIST];
	
	//Observe window style changes
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller

- (AIListWindowController *)contactListWindowController {
	return contactListWindowController;
}

//Show contact list
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
    if (!contactListWindowController) { //Load the window
		if (windowStyle == WINDOW_STYLE_STANDARD) {
			contactListWindowController = [[AIStandardListWindowController listWindowController] retain];
		} else {
			contactListWindowController = [[AIBorderlessListWindowController listWindowController] retain];
		}
    }

	[contactListWindowController showWindowInFront:bringToFront];
}

//Returns YES if the contact list is visible and in front
- (BOOL)contactListIsVisibleAndMain
{
	return (contactListWindowController && [[contactListWindowController window] isMainWindow]);
}

//Close contact list
- (void)closeContactList
{
    if (contactListWindowController) {
        [[contactListWindowController window] performClose:nil];
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
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime || [group isEqualToString:PREF_GROUP_APPEARANCE]) {
		//Theme
		if (firstTime || !key || [key isEqualToString:KEY_LIST_THEME_NAME]) {
			[AISCLViewPlugin applySetWithName:[prefDict objectForKey:KEY_LIST_THEME_NAME]
									extension:LIST_THEME_EXTENSION
									 inFolder:LIST_THEME_FOLDER
							toPreferenceGroup:PREF_GROUP_LIST_THEME];
		}
		
		//Layout
		if (firstTime || !key || [key isEqualToString:KEY_LIST_LAYOUT_NAME]) {
			[AISCLViewPlugin applySetWithName:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]
									extension:LIST_LAYOUT_EXTENSION
									 inFolder:LIST_LAYOUT_FOLDER
							toPreferenceGroup:PREF_GROUP_LIST_LAYOUT];
		}

		if (firstTime || !key || [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE]) {
			int	newWindowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];

			if (newWindowStyle != windowStyle) {
				windowStyle = newWindowStyle;
				
				//If a contact list is visible and the window style has changed, update for the new window style
				if (contactListWindowController) {
					//XXX - Evan: I really do not like this at all.  What to do?
					//We can't close and reopen the contact list from within a preferencesChanged call, as the
					//contact list itself is a preferences observer and will modify the array for its group as it
					//closes... and you can't modify an array while enuemrating it, which the preferencesController is
					//currently doing.  This isn't pretty, but it's the most efficient fix I could come up with.
					//It has the obnoxious side effect of the contact list changing its view prefs and THEN closing and
					//reopening with the right windowStyle.
					[self performSelector:@selector(closeAndReopencontactList)
							   withObject:nil
							   afterDelay:0.00001];
				}
			}
		}
	}
}

- (void)closeAndReopencontactList
{
	[self closeContactList];
	[self showContactListAndBringToFront:NO];
}

//Apply a set of preferences
+ (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup
{
	AIAdium			*adiumInstance = [AIObject sharedAdiumInstance];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSEnumerator	*enumerator;
	NSString		*fileName, *resourcePath;
	NSString		*key;
	NSDictionary	*setDictionary = nil;

	//Look in each resource location until we find it
	fileName = [setName stringByAppendingPathExtension:extension];
	
	enumerator = [[adiumInstance resourcePathsForName:folder] objectEnumerator];
	while ((resourcePath = [enumerator nextObject]) && !setDictionary) {
		NSString		*filePath = [resourcePath stringByAppendingPathComponent:fileName];
		
		if ([defaultManager fileExistsAtPath:filePath]) {
			setDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
		}
	}
	
	//Apply its values
	[[adiumInstance preferenceController] delayPreferenceChangedNotifications:YES];
	enumerator = [setDictionary keyEnumerator];
	while ((key = [enumerator nextObject])) {
		[[adiumInstance preferenceController] setPreference:[setDictionary objectForKey:key]
													 forKey:key
													  group:preferenceGroup];
	}
	[[adiumInstance preferenceController] delayPreferenceChangedNotifications:NO];
}

//Create a layout or theme set
+ (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	NSString		*path;
	NSString		*fileName = [[setName safeFilenameString] stringByAppendingPathExtension:extension];
	AIAdium			*sharedAdiumInstance = [AIObject sharedAdiumInstance];

	//If we don't find one, create a path to a bundle in the application support directory
	path = [[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder] stringByAppendingPathComponent:fileName];
	[AIXtrasManager createXtraBundleAtPath:path];
	path = [path stringByAppendingPathComponent:@"Contents/Resources/Data.plist"];
	
	if ([[[sharedAdiumInstance preferenceController] preferencesForGroup:preferenceGroup] writeToFile:path atomically:NO]) {
		
		[[sharedAdiumInstance notificationCenter] postNotificationName:Adium_Xtras_Changed object:extension];

		return YES;
	} else {
		NSRunAlertPanel(AILocalizedString(@"Error Saving Theme",nil),
						AILocalizedString(@"Unable to write file %@ to %@",nil),
						AILocalizedString(@"OK",nil),
						nil,
						nil,
						fileName,
						path);
		return NO;
	}
}

//Delete a layout or theme set
+ (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	BOOL		success;
	
	success = [[NSFileManager defaultManager] removeFileAtPath:[[AIObject sharedAdiumInstance] pathOfPackWithName:setName
																										extension:extension
																							   resourceFolderName:folder]
													   handler:nil];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:Adium_Xtras_Changed object:extension];
	
	return success;
}

//
+ (BOOL)renameSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toName:(NSString *)newName
{
	BOOL		success;
	
	NSString	*destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*newFileName = [newName stringByAppendingPathExtension:extension];
	
	success = [[NSFileManager defaultManager] movePath:[[AIObject sharedAdiumInstance] pathOfPackWithName:setName
																								extension:extension
																					   resourceFolderName:folder]
												toPath:[destFolder stringByAppendingPathComponent:newFileName]
											   handler:nil];

	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:Adium_Xtras_Changed object:extension];
	
	return success;
}

//
+ (BOOL)duplicateSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder newName:(NSString *)newName
{
	BOOL		success;
	
	//Duplicate the set
	NSString	*destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*newFileName = [newName stringByAppendingPathExtension:extension];
	
	success = [[NSFileManager defaultManager] copyPath:[[AIObject sharedAdiumInstance] pathOfPackWithName:setName
																								extension:extension
																					   resourceFolderName:folder]
												toPath:[destFolder stringByAppendingPathComponent:newFileName]
											   handler:nil];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:Adium_Xtras_Changed object:extension];

	return success;
}

+ (NSArray *)availableLayoutSets
{
	return [AISCLViewPlugin availableSetsWithExtension:LIST_LAYOUT_EXTENSION 
											fromFolder:LIST_LAYOUT_FOLDER];
}
+ (NSArray *)availableThemeSets
{
	return [AISCLViewPlugin availableSetsWithExtension:LIST_THEME_EXTENSION fromFolder:LIST_THEME_FOLDER];
}

//
+ (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[AIObject sharedAdiumInstance] allResourcesForName:folder withExtensions:extension] objectEnumerator];
	NSMutableArray	*alreadyAddedArray = [NSMutableArray array];
	NSString		*filePath, *name;
	NSBundle		*xtraBundle;
	
    while ((filePath = [enumerator nextObject])) {
		name = [[filePath lastPathComponent] stringByDeletingPathExtension];
		xtraBundle = [NSBundle bundleWithPath:filePath];
		if(xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1))
			filePath = [[xtraBundle resourcePath] stringByAppendingPathComponent:@"Data.plist"];
		NSDictionary 	*themeDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
		
		if (themeDict) {			
			//The Adium resource path is last in our resourcePaths array; by only adding sets we haven't
			//already added, we allow precedence to occur rather than conflict.
			if ([alreadyAddedArray indexOfObject:name] == NSNotFound) {
				[setArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					name, @"name",
					filePath, @"path",
					themeDict, @"preferences",
					nil]];
				[alreadyAddedArray addObject:name];
			}
		}
	}
	
	return [setArray sortedArrayUsingFunction:availableSetSort context:nil];
}

//Sort sets
int availableSetSort(NSDictionary *objectA, NSDictionary *objectB, void *context) {
	return [[objectA objectForKey:@"name"] caseInsensitiveCompare:[objectB objectForKey:@"name"]];
}

@end

