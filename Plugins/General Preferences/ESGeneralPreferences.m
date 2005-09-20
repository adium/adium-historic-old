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

#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AISoundController.h"
#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIFontSelectionPopUpButton.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

#define VOLUME_SOUND_PATH   [NSString pathWithComponents:[NSArray arrayWithObjects: \
	@"/", @"System", @"Library", @"LoginPlugins", \
	[@"BezelServices" stringByAppendingPathExtension:@"loginPlugin"], \
	@"Contents", @"Resources", \
	[@"volume" stringByAppendingPathExtension:@"aiff"], \
	nil]];

@interface ESGeneralPreferences (PRIVATE)
- (NSMenu *)outputDeviceMenu;
- (NSMenu *)tabKeysMenu;
- (NSMenu *)sendKeysMenu;

- (NSMenu *)statusIconsMenu;
- (NSMenu *)serviceIconsMenu;

- (NSArray *)_allPacksWithExtension:(NSString *)extension inFolder:(NSString *)inFolder;
@end

@implementation ESGeneralPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_General;
}
- (NSString *)label{
    return AILocalizedString(@"General","General preferences label");
}
- (NSString *)nibName{
    return @"GeneralPreferences";
}

//Configure the preference view
- (void)viewDidLoad
{
	BOOL			sendOnEnter, sendOnReturn;
    NSDictionary	*prefDict;
	
	//Interface
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_INTERFACE];
    [checkBox_messagesInTabs setState:[[prefDict objectForKey:KEY_TABBED_CHATTING] boolValue]];
	[checkBox_arrangeByGroup setState:[[prefDict objectForKey:KEY_GROUP_CHATS_BY_GROUP] boolValue]];

	//Chat Cycling
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CHAT_CYCLING];
	[popUp_tabKeys setMenu:[self tabKeysMenu]];
	[popUp_tabKeys compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]];

	//General
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
	sendOnEnter = [[prefDict objectForKey:SEND_ON_ENTER] boolValue];
	sendOnReturn = [[prefDict objectForKey:SEND_ON_RETURN] boolValue];
	[popUp_sendKeys setMenu:[self sendKeysMenu]];
	
	if (sendOnEnter && sendOnReturn) {
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnBoth];
	} else if (sendOnEnter) {
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnEnter];			
	} else if (sendOnReturn) {
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnReturn];
	}

	//Sounds
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
	[slider_volume setFloatValue:[[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]];
	
	//Logging
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];
	[checkBox_enableLogging setState:[[prefDict objectForKey:KEY_LOGGER_ENABLE] boolValue]];

	//Status Menu
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_MENU_ITEM];
	[checkBox_enableMenuItem setState:[[prefDict objectForKey:KEY_STATUS_MENU_ITEM_ENABLED] boolValue]];
		
	//Formatting
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
	[colorPopUp_text setColor:[[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor]];
	[colorPopUp_background setColor:[[prefDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor]];
	[fontPopUp_text setAvailableFonts:[NSArray arrayWithObjects:
		@"Arial", [NSFont fontWithName:@"Arial" size:12],
		@"Comic Sans MS", [NSFont fontWithName:@"Comic Sans MS" size:12],
		@"Courier", [NSFont fontWithName:@"Courier" size:12],
		@"Helvetica", [NSFont fontWithName:@"Helvetica" size:12],
		@"Times", [NSFont fontWithName:@"Times" size:12],
		@"Trebuchet MS", [NSFont fontWithName:@"Trebuchet MS" size:12],
		@"Verdana", [NSFont fontWithName:@"Verdana" size:12],
		nil]];
	[fontPopUp_text setFont:[[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont]];
	
    [self configureControlDimming];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if (sender == checkBox_messagesInTabs) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TABBED_CHATTING
                                              group:PREF_GROUP_INTERFACE];
		[self configureControlDimming];
		
	} else if (sender == checkBox_arrangeByGroup) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_GROUP_CHATS_BY_GROUP
											  group:PREF_GROUP_INTERFACE];
		
	} else if (sender == checkBox_enableLogging) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
		
    } else if (sender == popUp_tabKeys) {
		AITabKeys keySelection = [[sender selectedItem] tag];

		[[adium preferenceController] setPreference:[NSNumber numberWithInt:keySelection]
											 forKey:KEY_TAB_SWITCH_KEYS
											  group:PREF_GROUP_CHAT_CYCLING];
		
	} else if (sender == popUp_sendKeys) {
		AISendKeys 	keySelection = [[sender selectedItem] tag];
		BOOL		sendOnEnter = (keySelection == AISendOnEnter || keySelection == AISendOnBoth);
		BOOL		sendOnReturn = (keySelection == AISendOnReturn || keySelection == AISendOnBoth);
		
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:sendOnEnter]
											 forKey:SEND_ON_ENTER
											  group:PREF_GROUP_GENERAL];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:sendOnReturn]
											 forKey:SEND_ON_RETURN
                                              group:PREF_GROUP_GENERAL];
	} else if (sender == checkBox_enableMenuItem) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_enableMenuItem state]] 
											 forKey:KEY_STATUS_MENU_ITEM_ENABLED
											  group:PREF_GROUP_STATUS_MENU_ITEM];
	} else if (sender == colorPopUp_text) {
		[[adium preferenceController] setPreference:[[sender color] stringRepresentation]
											 forKey:KEY_FORMATTING_TEXT_COLOR
											  group:PREF_GROUP_FORMATTING];

	} else if (sender == colorPopUp_background) {
		[[adium preferenceController] setPreference:[[sender color] stringRepresentation]
											 forKey:KEY_FORMATTING_BACKGROUND_COLOR
											  group:PREF_GROUP_FORMATTING];
		
	} else if (sender == fontPopUp_text) {
		[[adium preferenceController] setPreference:[[sender font] stringRepresentation]
											 forKey:KEY_FORMATTING_FONT
											  group:PREF_GROUP_FORMATTING];
		
	}
}

//Dim controls as needed
- (void)configureControlDimming
{
	[checkBox_arrangeByGroup setEnabled:[checkBox_messagesInTabs state]];
}

//New value selected on the volume slider or chosen by clicking a volume icon
- (IBAction)selectVolume:(id)sender
{
    NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
    float			volume, oldVolume;
	
	if (sender == slider_volume) {
		volume = [slider_volume floatValue];
	} else if (sender == button_maxvolume) {
		volume = [slider_volume maxValue];
		[slider_volume setDoubleValue:volume];
	} else if (sender == button_minvolume) {
		volume = [slider_volume minValue];
		[slider_volume setDoubleValue:volume];
	} else {
		volume = 0;
	}
	oldVolume = [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];

    //Volume
    if (volume != oldVolume) {
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:volume]
                                             forKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
                                              group:PREF_GROUP_SOUNDS];

		//Play a sample sound
        [[adium soundController] playSoundAtPath:VOLUME_SOUND_PATH];
    }
}

/*!
 * @brief Construct our menu by hand for easy localization
 */
- (NSMenu *)tabKeysMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Arrows (%@ and %@)","Directional arrow keys word"), [NSString stringWithUTF8String:"⌘←"], [NSString stringWithUTF8String:"⌘→"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISwitchArrows];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Shift + Arrows (%@ and %@)","Shift key word + Directional arrow keys word"), [NSString stringWithUTF8String:"⇧⌘←"], [NSString stringWithUTF8String:"⇧⌘→"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISwitchShiftArrows];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Brackets (%@ and %@)","Word for [ and ] keys"), [NSString stringWithUTF8String:"⌘["], [NSString stringWithUTF8String:"⌘]"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIBrackets];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Curly braces (%@ and %@)","Word for { and } keys"), [NSString stringWithUTF8String:"⌘{"], [NSString stringWithUTF8String:"⌘}"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIBraces];
	
	return [menu autorelease];		
}

/*!
 * @brief Construct our menu by hand for easy localization
 */
- (NSMenu *)sendKeysMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];

	[menu addItemWithTitle:AILocalizedString(@"Enter","Enter key for sending messages")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnEnter];

	[menu addItemWithTitle:AILocalizedString(@"Return","Return key for sending messages")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnReturn];

	[menu addItemWithTitle:AILocalizedString(@"Enter and Return","Enter and return key for sending messages")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnBoth];

	return [menu autorelease];		
}

@end
