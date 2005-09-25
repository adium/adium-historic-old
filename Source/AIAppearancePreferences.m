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
#import "AIEmoticonPack.h"
#import "AIEmoticonPreferences.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIEmoticonController.h>
#import <Adium/AIIconState.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/ESPresetManagementController.h>
#import <Adium/ESPresetNameSheetController.h>

#warning crosslink
#import "AISCLViewPlugin.h"

typedef enum {
	AIEmoticonMenuNone = 1,
	AIEmoticonMenuMultiple
} AIEmoticonMenuTag;

@interface AIAppearancePreferences (PRIVATE)
- (NSMenu *)_windowStyleMenu;
- (NSMenu *)_dockIconMenu;
- (NSMenu *)_emoticonPackMenu;
- (NSMenu *)_statusIconsMenu;
- (NSMenu *)_serviceIconsMenu;
- (NSMenu *)_listLayoutMenu;
- (NSMenu *)_colorThemeMenu;
- (void)_rebuildEmoticonMenuAndSelectActivePack;
- (NSMenu *)_iconPackMenuForPacks:(NSArray *)packs class:(Class)iconClass;
- (void)_addWindowStyleOption:(NSString *)option withTag:(int)tag toMenu:(NSMenu *)menu;
- (void)_updateSliderValues;
- (void)xtrasChanged:(NSNotification *)notification;
@end

@implementation AIAppearancePreferences

/*!
 * @brief Preference pane properties
 */
- (PREFERENCE_CATEGORY)category{
    return AIPref_Appearance;
}
- (NSString *)label{
    return AILocalizedString(@"Appearance","Appearance preferences label");
}
- (NSString *)nibName{
    return @"AppearancePrefs";
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
    NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_APPEARANCE];
	
	//Other list options
	[popUp_windowStyle setMenu:[self _windowStyleMenu]];
	[popUp_windowStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]];	
	[checkBox_verticalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue]];
	[checkBox_horizontalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue]];
	[slider_windowOpacity setFloatValue:([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_OPACITY] floatValue] * 100.0)];
	[slider_horizontalWidth setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue]];
	[self _updateSliderValues];

	//Localized strings
	[label_serviceIcons setLocalizedString:AILocalizedString(@"Service icons:","Label for preference to select the icon pack to used for service (AIM, MSN, etc.)")];
	[label_statusIcons setLocalizedString:AILocalizedString(@"Status icons:","Label for preference to select status icon pack")];
	[label_dockIcons setLocalizedString:AILocalizedString(@"Dock icons:","Label for preference to select dock icon")];
		
	//Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];

	//Observe xtras changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];	
	[self xtrasChanged:nil];
}

/*!
 * @brief View will close
 */
- (void)viewWillClose
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Xtras changed, update our menus to reflect the new Xtras
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	NSString		*type = [[notification object] lowercaseString];
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_APPEARANCE];

	if (!type || [type isEqualToString:@"adiumemoticonset"]) {
		[self _rebuildEmoticonMenuAndSelectActivePack];
	}
	
	if (!type || [type isEqualToString:@"adiumicon"]) {
		[popUp_dockIcon setMenu:[self _dockIconMenu]];
		[popUp_dockIcon selectItemWithRepresentedObject:[prefDict objectForKey:KEY_ACTIVE_DOCK_ICON]];
	}
	
	if (!type || [type isEqualToString:@"adiumserviceicons"]) {
		[popUp_serviceIcons setMenu:[self _serviceIconsMenu]];
		[popUp_serviceIcons selectItemWithTitle:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]];
	}
	
	if (!type || [type isEqualToString:@"adiumstatusicons"]) {
		[popUp_statusIcons setMenu:[self _statusIconsMenu]];
		[popUp_statusIcons selectItemWithTitle:[prefDict objectForKey:KEY_STATUS_ICON_PACK]];		
	}
	
	if (!type || [type isEqualToString:@"listtheme"]) {
		[popUp_colorTheme setMenu:[self _colorThemeMenu]];
		[popUp_colorTheme selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_THEME_NAME]];	
	}

	if (!type || [type isEqualToString:@"listlayout"]) {
		[popUp_listLayout setMenu:[self _listLayoutMenu]];
		[popUp_listLayout selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]];
	}
}

/*!
 * @brief Preferences changed
 *
 * Update controls in our view to reflect the changed preferences
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Emoticons
	if ([group isEqualToString:PREF_GROUP_EMOTICONS]) {
		[self _rebuildEmoticonMenuAndSelectActivePack];
	}
	
	//Appearance
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		
		//Horizontal resizing label
		if (firstTime || 
		   [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE] ||
		   [key isEqualToString:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE]) {
			
			int windowMode = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
			BOOL horizontalAutosize = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
			
			if (windowMode == WINDOW_STYLE_STANDARD) {
				//In standard mode, disable the horizontal autosizing slider if horiztonal autosizing is off
				[textField_horizontalWidthText setLocalizedString:AILocalizedString(@"Maximum width:",nil)];
				[slider_horizontalWidth setEnabled:horizontalAutosize];
				
			} else {
				//In all the borderless transparent modes, the horizontal autosizing slider becomes the
				//horizontal sizing slider when autosizing is off
				if (horizontalAutosize) {
					[textField_horizontalWidthText setLocalizedString:AILocalizedString(@"Maximum width:",nil)];
				} else {
					[textField_horizontalWidthText setLocalizedString:AILocalizedString(@"Width:",nil)];			
				}
				[slider_horizontalWidth setEnabled:YES];
			}
			
		}

		//Selected menu items
		if (firstTime || [key isEqualToString:KEY_STATUS_ICON_PACK]) {
			[popUp_statusIcons selectItemWithTitle:[prefDict objectForKey:KEY_STATUS_ICON_PACK]];
			
			//If the prefDict's item isn't present, we're using the default, so select that one
			if (![popUp_serviceIcons selectedItem]) {
				[popUp_serviceIcons selectItemWithTitle:[[adium preferenceController] defaultPreferenceForKey:KEY_STATUS_ICON_PACK
																										group:PREF_GROUP_APPEARANCE
																									   object:nil]];
			}			
		}
		if (firstTime || [key isEqualToString:KEY_SERVICE_ICON_PACK]) {
			[popUp_serviceIcons selectItemWithTitle:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]];
			
			//If the prefDict's item isn't present, we're using the default, so select that one
			if (![popUp_serviceIcons selectedItem]) {
				[popUp_serviceIcons selectItemWithTitle:[[adium preferenceController] defaultPreferenceForKey:KEY_SERVICE_ICON_PACK
																										group:PREF_GROUP_APPEARANCE
																									   object:nil]];
			}
		}		
		if (firstTime || [key isEqualToString:KEY_LIST_LAYOUT_NAME]) {
			[popUp_listLayout selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]];
		}
		if (firstTime || [key isEqualToString:KEY_LIST_THEME_NAME]) {
			[popUp_colorTheme selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_THEME_NAME]];	
		}	
		if (firstTime || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]) {
			[popUp_dockIcon selectItemWithRepresentedObject:[prefDict objectForKey:KEY_ACTIVE_DOCK_ICON]];
		}		
	}
}

/*!
 * @brief Rebuild the emoticon menu
 */
- (void)_rebuildEmoticonMenuAndSelectActivePack
{
	[popUp_emoticons setMenu:[self _emoticonPackMenu]];
	
	//Update the selected pack
	NSArray	*activeEmoticonPacks = [[adium emoticonController] activeEmoticonPacks];
	int		numActivePacks = [activeEmoticonPacks count];
	
	if (numActivePacks == 0) {
		[popUp_emoticons compatibleSelectItemWithTag:AIEmoticonMenuNone];
	} else if (numActivePacks > 1) {
		[popUp_emoticons compatibleSelectItemWithTag:AIEmoticonMenuMultiple];
	} else {
		[popUp_emoticons selectItemWithRepresentedObject:[activeEmoticonPacks objectAtIndex:0]];
	}
}

/*!
 * @brief Save changed preferences
 */
- (IBAction)changePreference:(id)sender
{
 	if (sender == popUp_statusIcons) {
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_STATUS_ICON_PACK
                                              group:PREF_GROUP_APPEARANCE];
		
	} else if (sender == popUp_serviceIcons) {
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_SERVICE_ICON_PACK
                                              group:PREF_GROUP_APPEARANCE];
		
	} else if (sender == popUp_dockIcon) {
        [[adium preferenceController] setPreference:[[sender selectedItem] representedObject]
                                             forKey:KEY_ACTIVE_DOCK_ICON
                                              group:PREF_GROUP_APPEARANCE];
		
	} else if (sender == popUp_listLayout) {
        [[adium preferenceController] setPreference:[[sender selectedItem] title]
                                             forKey:KEY_LIST_LAYOUT_NAME
                                              group:PREF_GROUP_APPEARANCE];
		
	} else if (sender == popUp_colorTheme) {
		[[adium preferenceController] setPreference:[[sender selectedItem] title]
											 forKey:KEY_LIST_THEME_NAME
											  group:PREF_GROUP_APPEARANCE];

	} else if (sender == popUp_windowStyle) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_WINDOW_STYLE
											  group:PREF_GROUP_APPEARANCE];
		
    } else if (sender == checkBox_verticalAutosizing) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE
                                              group:PREF_GROUP_APPEARANCE];
		
    } else if (sender == checkBox_horizontalAutosizing) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE
                                              group:PREF_GROUP_APPEARANCE];

    } else if (sender == slider_windowOpacity) {
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:([sender floatValue] / 100.0)]
                                             forKey:KEY_LIST_LAYOUT_WINDOW_OPACITY
                                              group:PREF_GROUP_APPEARANCE];
		[self _updateSliderValues];
		
	} else if (sender == slider_horizontalWidth) {
		int newValue = [sender intValue];
		int oldValue = [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH
																 group:PREF_GROUP_APPEARANCE] intValue];
		if (newValue != oldValue) { 
			[[adium preferenceController] setPreference:[NSNumber numberWithInt:newValue]
												 forKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH
												  group:PREF_GROUP_APPEARANCE];
			[self _updateSliderValues];
		}
		
	} else if (sender == popUp_emoticons) {
		if ([sender tag] != AIEmoticonMenuMultiple) {
			//Disable all active emoticons
			NSArray			*activePacks = [[[[adium emoticonController] activeEmoticonPacks] mutableCopy] autorelease];
			NSEnumerator	*enumerator = [activePacks objectEnumerator];
			AIEmoticonPack	*pack, *selectedPack;
			
			selectedPack = [[sender selectedItem] representedObject];
			
			[[adium preferenceController] delayPreferenceChangedNotifications:YES];

			while ((pack = [enumerator nextObject])) {
				[[adium emoticonController] setEmoticonPack:pack enabled:NO];
			}
			
			//Enable the selected pack
			if (selectedPack) [[adium emoticonController] setEmoticonPack:selectedPack enabled:YES];

			[[adium preferenceController] delayPreferenceChangedNotifications:NO];
		}
	}
}

/*!
 *
 */
- (void)_updateSliderValues
{
	[textField_windowOpacity setStringValue:[NSString stringWithFormat:@"%i%%", (int)[slider_windowOpacity floatValue]]];
	[textField_horizontalWidthIndicator setStringValue:[NSString stringWithFormat:@"%ipx",[slider_horizontalWidth intValue]]];
}


//Emoticons ------------------------------------------------------------------------------------------------------------
#pragma mark Emoticons
/*!
 *
 */
- (IBAction)customizeEmoticons:(id)sender
{
	[AIEmoticonPreferences showEmoticionCustomizationOnWindow:[[self view] window]];
}

/*!
 *
 */
- (NSMenu *)_emoticonPackMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[[adium emoticonController] availableEmoticonPacks] objectEnumerator];
	AIEmoticonPack	*pack;
	NSMenuItem		*menuItem;
		
	//Add the "No Emoticons" option
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"None",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setImage:[NSImage imageNamed:@"emoticonBlank" forClass:[self class]]];
	[menuItem setTag:AIEmoticonMenuNone];
	[menu addItem:menuItem];
	
	//Add the "Multiple packs selected" option
	if ([[[adium emoticonController] activeEmoticonPacks] count] > 1) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Multiple Packs Selected",nil)
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setImage:[NSImage imageNamed:@"emoticonBlank" forClass:[self class]]];
		[menuItem setTag:AIEmoticonMenuMultiple];
		[menu addItem:menuItem];
	}

	//Divider
	[menu addItem:[NSMenuItem separatorItem]];
	
	//Emoticon Packs
	while ((pack = [enumerator nextObject])) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[pack name]
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:pack];
		[menuItem setImage:[[[[pack emoticons] objectAtIndex:0] image] imageByScalingToSize:NSMakeSize(16,16)]];
		[menu addItem:menuItem];
	}
	
	
	return [menu autorelease];
}


//Contact list options -------------------------------------------------------------------------------------------------
#pragma mark Contact list options
/*!
 *
 */
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

	return [menu autorelease];
}
- (void)_addWindowStyleOption:(NSString *)option withTag:(int)tag toMenu:(NSMenu *)menu{
    NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:option
																				  target:nil
																				  action:nil
																		   keyEquivalent:@""] autorelease];
	[menuItem setTag:tag];
	[menu addItem:menuItem];
}


//Contact list layout & theme ----------------------------------------------------------------------------------------
#pragma mark Contact list layout & theme
/*!
 * @brief Create a new theme
 */
- (IBAction)createListTheme:(id)sender
{
	NSString *theme = [[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE];	
	
	[ESPresetNameSheetController showPresetNameSheetWithDefaultName:[theme stringByAppendingString:@" Copy"]
													explanatoryText:AILocalizedString(@"Enter a unique name for this new theme.",nil)
														   onWindow:[[self view] window]
													notifyingTarget:self
														   userInfo:@"theme"];
}

/*!
 * @brief Customize the active theme
 */
- (IBAction)customizeListTheme:(id)sender
{
	NSString *theme = [[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE];	
	
	//Allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];

	[AIListThemeWindowController editListThemeWithName:theme
											  onWindow:[[self view] window]
									   notifyingTarget:self];
}

/*!
 * @brief Save (or revert) changes made when editing a theme
 */
- (void)listThemeEditorWillCloseWithChanges:(BOOL)saveChanges forThemeNamed:(NSString *)name
{
	if (saveChanges) {
		//Update the modified theme
		if ([AISCLViewPlugin createSetFromPreferenceGroup:PREF_GROUP_LIST_THEME
												withName:name
											   extension:LIST_THEME_EXTENSION
												inFolder:LIST_THEME_FOLDER]) {
		
			[[adium preferenceController] setPreference:name
												 forKey:KEY_LIST_THEME_NAME
												  group:PREF_GROUP_APPEARANCE];
		}
		
	} else {
		//Revert back to selected theme
		NSString *theme = [[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE];	

		[AISCLViewPlugin applySetWithName:theme
								extension:LIST_THEME_EXTENSION
								 inFolder:LIST_THEME_FOLDER
						toPreferenceGroup:PREF_GROUP_LIST_THEME];
	}


	//No longer allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
}

/*!
 * @brief Manage available themes
 */
- (void)manageListThemes:(id)sender
{
	_listThemes = [AISCLViewPlugin availableThemeSets];
	[ESPresetManagementController managePresets:_listThemes
									 namedByKey:@"name"
									   onWindow:[[self view] window]
								   withDelegate:self];
	
	[popUp_colorTheme selectItemWithRepresentedObject:[[adium preferenceController] preferenceForKey:KEY_LIST_THEME_NAME
																							   group:PREF_GROUP_APPEARANCE]];		
}

/*!
 * @brief Create a new layout
 */
- (IBAction)createListLayout:(id)sender
{
	NSString *layout = [[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE];
	
	[ESPresetNameSheetController showPresetNameSheetWithDefaultName:[layout stringByAppendingString:@" Copy"]
													explanatoryText:AILocalizedString(@"Enter a unique name for this new layout.",nil)
														   onWindow:[[self view] window]
													notifyingTarget:self
														   userInfo:@"layout"];
}

/*!
 * @brief Customize the active layout
 */
- (IBAction)customizeListLayout:(id)sender
{
	NSString *theme = [[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE];	
	
	//Allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];	

	[AIListLayoutWindowController editListLayoutWithName:theme
											  onWindow:[[self view] window]
									   notifyingTarget:self];
}

/*!
 * @brief Save (or revert) changes made when editing a layout
 */
- (void)listLayoutEditorWillCloseWithChanges:(BOOL)saveChanges forLayoutNamed:(NSString *)name
{
	if (saveChanges) {
		//Update the modified layout
		if ([AISCLViewPlugin createSetFromPreferenceGroup:PREF_GROUP_LIST_LAYOUT
												withName:name
											   extension:LIST_LAYOUT_EXTENSION
												inFolder:LIST_LAYOUT_FOLDER]) {
			
			[[adium preferenceController] setPreference:name
												 forKey:KEY_LIST_LAYOUT_NAME
												  group:PREF_GROUP_APPEARANCE];
		}
		
	} else {
		//Revert back to selected layout
		NSString *layout = [[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE];	
		
		[AISCLViewPlugin applySetWithName:layout
								extension:LIST_LAYOUT_EXTENSION
								 inFolder:LIST_LAYOUT_FOLDER
						toPreferenceGroup:PREF_GROUP_LIST_LAYOUT];
	}

	//No longer allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
}

/*!
 * @brief Manage available layouts
 */
- (void)manageListLayouts:(id)sender
{
	_listLayouts = [AISCLViewPlugin availableLayoutSets];
	[ESPresetManagementController managePresets:_listLayouts
									 namedByKey:@"name"
									   onWindow:[[self view] window]
								   withDelegate:self];

	[popUp_listLayout selectItemWithRepresentedObject:[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_NAME
																							   group:PREF_GROUP_APPEARANCE]];		
}

/*!
 * @brief Validate a layout or theme name to ensure it is unique
 */
- (BOOL)presetNameSheetController:(ESPresetNameSheetController *)controller
			  shouldAcceptNewName:(NSString *)newName
						 userInfo:(id)userInfo
{
	NSEnumerator	*enumerator;
	NSDictionary	*presetDict;

	//Scan the correct presets to ensure this name doesn't already exist
	if ([userInfo isEqualToString:@"theme"]) {
		enumerator = [[AISCLViewPlugin availableThemeSets] objectEnumerator];
	} else {
		enumerator = [[AISCLViewPlugin availableLayoutSets] objectEnumerator];
	}
	
	while ((presetDict = [enumerator nextObject])) {
		if ([newName isEqualToString:[presetDict objectForKey:@"name"]]) return NO;
	}
	
	return YES;
}

/*!
 * @brief Create a new theme with the user supplied name, activate and edit it
 */
- (void)presetNameSheetControllerDidEnd:(ESPresetNameSheetController *)controller 
							 returnCode:(ESPresetNameSheetReturnCode)returnCode
								newName:(NSString *)newName
							   userInfo:(id)userInfo
{
	switch (returnCode) {
		case ESPresetNameSheetOkayReturn:
			if ([userInfo isEqualToString:@"theme"]) {
				[self performSelector:@selector(_editListThemeWithName:) withObject:newName afterDelay:0.00001];
			} else {
				[self performSelector:@selector(_editListLayoutWithName:) withObject:newName afterDelay:0.00001];
			}
		break;
			
		case ESPresetNameSheetCancelReturn:
			//Do nothing
		break;
	}
}
- (void)_editListThemeWithName:(NSString *)name{
	[AIListThemeWindowController editListThemeWithName:name
											  onWindow:[[self view] window]
									   notifyingTarget:self];
}
- (void)_editListLayoutWithName:(NSString *)name{
	[AIListLayoutWindowController editListLayoutWithName:name
												onWindow:[[self view] window]
										 notifyingTarget:self];
}

/*!
 * 
 */
- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)newName inPresets:(NSArray *)presets renamedPreset:(id *)renamedPreset
{
	NSArray		*newPresets;

	if (presets == _listLayouts) {
		[AISCLViewPlugin renameSetWithName:[preset objectForKey:@"name"]
								 extension:LIST_LAYOUT_EXTENSION
								  inFolder:LIST_LAYOUT_FOLDER
									toName:newName];		
		_listLayouts = [AISCLViewPlugin availableLayoutSets];
		newPresets = _listLayouts;
		
	} else if (presets == _listThemes) {
		[AISCLViewPlugin renameSetWithName:[preset objectForKey:@"name"]
								 extension:LIST_THEME_EXTENSION
								  inFolder:LIST_THEME_FOLDER
									toName:newName];		
		_listThemes = [AISCLViewPlugin availableThemeSets];
		newPresets = _listThemes;

	} else {
		newPresets = nil;
	}
	
	//Return the new duplicate by reference for the preset controller
	if (renamedPreset) {
		NSEnumerator	*enumerator = [newPresets objectEnumerator];
		NSDictionary	*aPreset;
		
		while ((aPreset = [enumerator nextObject])) {
			if ([newName isEqualToString:[aPreset objectForKey:@"name"]]) {
				*renamedPreset = aPreset;
				break;
			}
		}
	}
	
	return newPresets;
}

/*!
 * 
 */
- (NSArray *)duplicatePreset:(NSDictionary *)preset inPresets:(NSArray *)presets createdDuplicate:(id *)duplicatePreset
{
	NSString	*newName = [NSString stringWithFormat:@"%@ (%@)", [preset objectForKey:@"name"], AILocalizedString(@"Copy",nil)];
	NSArray		*newPresets = nil;
	
	if (presets == _listLayouts) {
		[AISCLViewPlugin duplicateSetWithName:[preset objectForKey:@"name"]
									extension:LIST_LAYOUT_EXTENSION
									 inFolder:LIST_LAYOUT_FOLDER
									  newName:newName];		
		_listLayouts = [AISCLViewPlugin availableLayoutSets];
		newPresets = _listLayouts;
		
	} else if (presets == _listThemes) {
		[AISCLViewPlugin duplicateSetWithName:[preset objectForKey:@"name"]
									extension:LIST_THEME_EXTENSION
									 inFolder:LIST_THEME_FOLDER
									  newName:newName];
		_listThemes = [AISCLViewPlugin availableThemeSets];
		newPresets = _listThemes;
	}

	//Return the new duplicate by reference for the preset controller
	if (duplicatePreset) {
		NSEnumerator	*enumerator = [newPresets objectEnumerator];
		NSDictionary	*aPreset;
		
		while ((aPreset = [enumerator nextObject])) {
			if ([newName isEqualToString:[aPreset objectForKey:@"name"]]) {
				*duplicatePreset = aPreset;
				break;
			}
		}
	}

	return newPresets;
}

/*!
 * 
 */
- (NSArray *)deletePreset:(NSDictionary *)preset inPresets:(NSArray *)presets
{
	if (presets == _listLayouts) {
		[AISCLViewPlugin deleteSetWithName:[preset objectForKey:@"name"]
								 extension:LIST_LAYOUT_EXTENSION
								  inFolder:LIST_LAYOUT_FOLDER];		
		_listLayouts = [AISCLViewPlugin availableLayoutSets];
		
		return _listLayouts;
	
	} else if (presets == _listThemes) {
		[AISCLViewPlugin deleteSetWithName:[preset objectForKey:@"name"]
								 extension:LIST_THEME_EXTENSION
								  inFolder:LIST_THEME_FOLDER];		
		_listThemes = [AISCLViewPlugin availableThemeSets];
		
		return _listThemes;

	} else {
		return nil;
	}
}

/*!
 *
 */
- (NSMenu *)_listLayoutMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[AISCLViewPlugin availableLayoutSets] objectEnumerator];
	NSDictionary	*set;
	NSMenuItem		*menuItem;
	NSString		*name;
	
	//Available Layouts
	while ((set = [enumerator nextObject])) {
		name = [set objectForKey:@"name"];
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menu addItem:menuItem];
	}
	
	//Divider
	[menu addItem:[NSMenuItem separatorItem]];

	//Preset management	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Add New Layout",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(createListLayout:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Edit Layouts",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(manageListLayouts:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	return menu;	
}

/*!
 *
 */
- (NSMenu *)_colorThemeMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[AISCLViewPlugin availableThemeSets] objectEnumerator];
	NSDictionary	*set;
	NSMenuItem		*menuItem;
	NSString		*name;
	
	//Available themes
	while ((set = [enumerator nextObject])) {
		name = [set objectForKey:@"name"];
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menu addItem:menuItem];
	}

	//Divider
	[menu addItem:[NSMenuItem separatorItem]];
	
	//Preset management	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Add New Theme",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(createListTheme:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Edit Themes",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(manageListThemes:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	return menu;	
}


//Dock icons -----------------------------------------------------------------------------------------------------------
#pragma mark Dock icons
/*!
 *
 */
- (IBAction)showAllDockIcons:(id)sender
{
	[AIDockIconSelectionSheet showDockIconSelectorOnWindow:[[self view] window]];
}

int _dockMenuItemSort(id objectA, id objectB, void *context)
{
	return ([[(NSMenuItem *)objectA title] caseInsensitiveCompare:[(NSMenuItem *)objectB title]]);
}

/*!
 * @brief Returns a menu of dock icon packs
 */
- (NSMenu *)_dockIconMenu
{
	NSMutableArray		*menuItemArray = [NSMutableArray array];
	NSMenu				*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator		*enumerator;
	NSString			*packPath;
	NSMenuItem			*menuItem;

	enumerator = [[[adium dockController] availableDockIconPacks] objectEnumerator];
	while ((packPath = [enumerator nextObject])) {
		NSString	*name = nil;
		NSString	*packName = [[packPath lastPathComponent] stringByDeletingPathExtension];
		AIIconState	*preview = nil;
		
		[[adium dockController] getName:&name
						   previewState:&preview
					  forIconPackAtPath:packPath];

		if (!name) {
			name = packName;
		}
		
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:packName];
		[menuItem setImage:[[preview image] imageByScalingToSize:NSMakeSize(18, 18)]];
		[menuItemArray addObject:menuItem];
	}

	[menuItemArray sortUsingFunction:_dockMenuItemSort context:NULL];

	enumerator = [menuItemArray objectEnumerator];
	while ((menuItem = [enumerator nextObject])) {
		[menu addItem:menuItem];
	}

	return menu;	
}


//Status and Service icons ---------------------------------------------------------------------------------------------
#pragma mark Status and service icons
/*!
 * @brief Returns a menu of status icon packs
 */
- (NSMenu *)_statusIconsMenu
{
	return [self _iconPackMenuForPacks:[adium allResourcesForName:@"Status Icons" withExtensions:@"AdiumStatusIcons"] class:[AIStatusIcons class]];
}

/*!
 * @brief Returns a menu of service icon packs
 */
- (NSMenu *)_serviceIconsMenu
{
	return [self _iconPackMenuForPacks:[adium allResourcesForName:@"Service Icons" withExtensions:@"AdiumServiceIcons"] class:[AIServiceIcons class]];
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

	while ((packPath = [enumerator nextObject])) {
		NSString	*name = [[packPath lastPathComponent] stringByDeletingPathExtension];
		NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menuItem setImage:[iconClass previewMenuImageForIconPackAtPath:packPath]];
		[serviceIconsMenu addItem:menuItem];
	}
	
	return serviceIconsMenu;	
}

@end
