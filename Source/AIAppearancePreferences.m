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

#import "AIAppearancePreferences.h"
#import "AIAppearancePreferencesPlugin.h"
#import "AIDockController.h"
#import "AIDockIconSelectionSheet.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIIconState.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"


#warning crosslink
#import "AISCLViewPlugin.h"

@interface AIAppearancePreferences (PRIVATE)
- (NSMenu *)_windowStyleMenu;
- (NSMenu *)_dockIconMenu;
- (NSMenu *)_statusIconsMenu;
- (NSMenu *)_serviceIconsMenu;
- (NSMenu *)_iconPackMenuForPacks:(NSArray *)packs class:(Class)iconClass;
- (NSArray *)_allPacksWithExtension:(NSString *)extension inFolder:(NSString *)inFolder;
- (void)_addWindowStyleOption:(NSString *)option withTag:(int)tag toMenu:(NSMenu *)menu;
@end

@implementation AIAppearancePreferences

/*!
 * @brief Preference pane properties
 */
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Appearance);
}
- (NSString *)label{
    return(AILocalizedString(@"Appearance","Appearance preferences label"));
}
- (NSString *)nibName{
    return(@"AppearancePrefs");
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
    NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_APPEARANCE];
	
	//Service and status icons
	[popUp_statusIcons setMenu:[self _statusIconsMenu]];
	[popUp_statusIcons selectItemWithTitle:[prefDict objectForKey:KEY_STATUS_ICON_PACK]];
	[popUp_serviceIcons setMenu:[self _serviceIconsMenu]];
	[popUp_serviceIcons selectItemWithTitle:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]];

	//Dock icons
	[popUp_dockIcon setMenu:[self _dockIconMenu]];
	[popUp_dockIcon selectItemWithTitle:[prefDict objectForKey:KEY_ACTIVE_DOCK_ICON]];
	
	//List layout and theme
	[popUp_listLayout setMenu:[self _listLayoutMenu]];
	[popUp_listLayout selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]];
	[popUp_colorTheme setMenu:[self _colorThemeMenu]];
	[popUp_colorTheme selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_THEME_NAME]];	
	
	//Other list options
	[popUp_windowStyle setMenu:[self _windowStyleMenu]];
	[popUp_windowStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]];	
	[checkBox_verticalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue]];
	[checkBox_horizontalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue]];
	
	//Localized strings
	[label_serviceIcons setStringValue:AILocalizedString(@"Service icons:","Label for preference to select the icon pack to used for service (AIM, MSN, etc.)")];
	[label_statusIcons setStringValue:AILocalizedString(@"Status icons:","Label for preference to select status icon pack")];
	[label_dockIcons setStringValue:AILocalizedString(@"Dock icons:","Label for preference to select dock icon")];
}

/*!
 * @brief Save changed preferences
 */
- (IBAction)changePreference:(id)sender
{
 	if(sender == popUp_statusIcons){
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_STATUS_ICON_PACK
                                              group:PREF_GROUP_APPEARANCE];
		
	}else if(sender == popUp_serviceIcons){
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_SERVICE_ICON_PACK
                                              group:PREF_GROUP_APPEARANCE];
		
	}else if(sender == popUp_dockIcon){
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_ACTIVE_DOCK_ICON
                                              group:PREF_GROUP_APPEARANCE];
		
	}else if(sender == popUp_listLayout){
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_LIST_LAYOUT_NAME
                                              group:PREF_GROUP_APPEARANCE];
		
	}else if(sender == popUp_colorTheme){
		[[adium preferenceController] setPreference:[[sender selectedItem] title]
											 forKey:KEY_LIST_THEME_NAME
											  group:PREF_GROUP_APPEARANCE];

	}else if(sender == popUp_windowStyle){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_WINDOW_STYLE
											  group:PREF_GROUP_LIST_LAYOUT];
		
    }else if(sender == checkBox_verticalAutosizing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE
                                              group:PREF_GROUP_LIST_LAYOUT];
		
    }else if(sender == checkBox_horizontalAutosizing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE
                                              group:PREF_GROUP_LIST_LAYOUT];
	}
}

/*!
 *
 */
- (IBAction)showAllDockIcons:(id)sender
{
	[AIDockIconSelectionSheet showDockIconSelectorOnWindow:[[self view] window]];
}

/*!
 *
 */
- (IBAction)customizeListLayout:(id)sender
{
	[AIListLayoutWindowController listLayoutOnWindow:[[self view] window]
											withName:[NSString stringWithFormat:@"%@ Copy",[popUp_listLayout titleOfSelectedItem]]];
}

/*!
 *
 */
- (IBAction)customizeListTheme:(id)sender
{
	[AIListThemeWindowController listThemeOnWindow:[[self view] window]
										  withName:[NSString stringWithFormat:@"%@ Copy",[popUp_colorTheme titleOfSelectedItem]]];
}


//Contact list options -------------------------------------------------------------------------------------------------
#pragma mark Contact list options
- (NSMenu *)_windowStyleMenu
{
	NSMenu	*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];

	[self _addWindowStyleOption:AILocalizedString(@"Regular Window",nil)
						withTag:WINDOW_STYLE_STANDARD
						 toMenu:menu];
	[menu addItem:[NSMenuItem separatorItem]];
	[self _addWindowStyleOption:AILocalizedString(@"Borderless Window",nil)
						withTag:WINDOW_STYLE_BORDERLESS
						 toMenu:menu];
	[self _addWindowStyleOption:AILocalizedString(@"Group Bubbles",nil)
						withTag:WINDOW_STYLE_MOCKIE
						 toMenu:menu];
	[self _addWindowStyleOption:AILocalizedString(@"Contact Bubbles",nil)
						withTag:WINDOW_STYLE_PILLOWS
						 toMenu:menu];
	[self _addWindowStyleOption:AILocalizedString(@"Contact Bubbles (To Fit)",nil)
						withTag:WINDOW_STYLE_PILLOWS_FITTED
						 toMenu:menu];

	return([menu autorelease]);
}
- (void)_addWindowStyleOption:(NSString *)option withTag:(int)tag toMenu:(NSMenu *)menu{
    NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:option
																				  target:nil
																				  action:nil
																		   keyEquivalent:@""] autorelease];
	[menuItem setTag:tag];
	[menu addItem:menuItem];
}


//Contact list layout and theme ----------------------------------------------------------------------------------------
#pragma mark Contact list layout and theme
- (NSMenu *)_listLayoutMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[AISCLViewPlugin availableLayoutSets] objectEnumerator];
	NSDictionary	*set;
	
	while(set = [enumerator nextObject]){
		NSString	*name = [set objectForKey:@"name"];
		NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menu addItem:menuItem];
	}
	
	return(menu);	
}

- (NSMenu *)_colorThemeMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[AISCLViewPlugin availableThemeSets] objectEnumerator];
	NSDictionary	*set;
	
	while(set = [enumerator nextObject]){
		NSString	*name = [set objectForKey:@"name"];
		NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menu addItem:menuItem];
	}
	
	return(menu);	
}


//Dock icons -----------------------------------------------------------------------------------------------------------
#pragma mark Dock icons
/*!
 * @brief Returns a menu of dock icon packs
 */
- (NSMenu *)_dockIconMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[[adium dockController] availableDockIconPacks] objectEnumerator];
	NSString		*packPath;
	
	while(packPath = [enumerator nextObject]){
		NSString	*name = [[packPath lastPathComponent] stringByDeletingPathExtension];
		AIIconState	*preview = [[adium dockController] previewStateForIconPackAtPath:packPath];
		
		NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menuItem setImage:[[preview image] imageByScalingToSize:NSMakeSize(18,18)]];
		[menu addItem:menuItem];
	}
	
	return(menu);	
}


//Status and Service icons ---------------------------------------------------------------------------------------------
#pragma mark Status and service icons
/*!
 * @brief Returns a menu of status icon packs
 */
- (NSMenu *)_statusIconsMenu
{
	return([self _iconPackMenuForPacks:[self _allPacksWithExtension:@"AdiumStatusIcons" inFolder:@"Status Icons"]
								 class:[AIStatusIcons class]]);
}

/*!
 * @brief Returns a menu of service icon packs
 */
- (NSMenu *)_serviceIconsMenu
{
	return([self _iconPackMenuForPacks:[self _allPacksWithExtension:@"AdiumServiceIcons" inFolder:@"Service Icons"]
								 class:[AIServiceIcons class]]);
}

/*!
 * @brief Builds and returns an icon pack menu
 *
 * @param packs NSArray of icon pack file paths
 * @param iconClass The controller class (AIStatusIcons, AIServiceIcons) for icon pack previews
 */
- (NSMenu *)_iconPackMenuForPacks:(NSArray *)packs class:(Class)iconClass
{
	NSMenu			*serviceIconsMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [packs objectEnumerator];
	NSString		*packPath;

	while(packPath = [enumerator nextObject]){
		NSString	*name = [[packPath lastPathComponent] stringByDeletingPathExtension];
		NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menuItem setImage:[iconClass previewMenuImageForIconPackAtPath:packPath]];
		[serviceIconsMenu addItem:menuItem];
	}
	
	return(serviceIconsMenu);	
}

- (NSArray *)_allPacksWithExtension:(NSString *)extension inFolder:(NSString *)inFolder
{
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSMutableArray	*packsArray = [NSMutableArray array];
	NSEnumerator	*enumerator;
	NSString		*path;
	
	enumerator = [[adium resourcePathsForName:inFolder] objectEnumerator];

	while(path = [enumerator nextObject]){            
		NSEnumerator	*fileEnumerator;
		NSString		*filePath;
		fileEnumerator = [defaultManager enumeratorAtPath:path];
		
		//Find all the appropriate packs
		while((filePath = [fileEnumerator nextObject])){
			if([[filePath pathExtension] caseInsensitiveCompare:extension] == NSOrderedSame){
				NSString		*fullPath;
				
				//Get the icon pack's full path and preview state
				fullPath = [path stringByAppendingPathComponent:filePath];

				[packsArray addObject:fullPath];
			}
		}
	}
	
	return(packsArray);
}

@end
