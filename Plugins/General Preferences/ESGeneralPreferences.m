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

#import "AIInterfaceController.h"
#import "AISoundController.h"
#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

#define VOLUME_SOUND_PATH   @"/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/volume.aiff"

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
    return(AIPref_General);
}
- (NSString *)label{
    return(AILocalizedString(@"General","General preferences label"));
}
- (NSString *)nibName{
    return(@"GeneralPreferences");
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
	
	if(sendOnEnter && sendOnReturn){
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnBoth];
	}else if(sendOnEnter){
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnEnter];			
	}else if(sendOnReturn){
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnReturn];
	}

	//Sounds
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
	[popUp_outputDevice setMenu:[self outputDeviceMenu]];
	[popUp_outputDevice compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_SOUND_SOUND_DEVICE_TYPE] intValue]];
	
    if([[prefDict objectForKey:KEY_SOUND_MUTE] intValue] == YES){
        [slider_volume setFloatValue:0.0];
    }else{
        [slider_volume setFloatValue:[[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]];
    }
	
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];
	[checkBox_enableLogging setState:[[prefDict objectForKey:KEY_LOGGER_ENABLE] boolValue]];


	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_MENU_ITEM];
	[checkBox_enableMenuItem setState:[[prefDict objectForKey:KEY_STATUS_MENU_ITEM_ENABLED] boolValue]];
		
    [self configureControlDimming];

	[checkBox_messagesInTabs setLocalizedString:AILocalizedString(@"Create new messages in tabs",nil)];
    [checkBox_arrangeByGroup setLocalizedString:AILocalizedString(@"Organize tabs into new windows by group",nil)];
	[checkBox_enableLogging setLocalizedString:AILocalizedString(@"Log messages",nil)];
	[checkBox_enableMenuItem setLocalizedString:AILocalizedString(@"Show Adium status in menu bar",nil)];
	
	[label_logging setLocalizedString:AILocalizedString(@"Messages:",nil)];
	[label_messagesSendOn setLocalizedString:AILocalizedString(@"Send messages with:",nil)];
	[label_messagesTabs setLocalizedString:AILocalizedString(@"Message tabs:",nil)];
	[label_menuItem setLocalizedString:AILocalizedString(@"Menu item:","The option '[ ] Show Adium status in menu bar' follows")];
	[label_switchTabsWith setLocalizedString:AILocalizedString(@"Switch tabs with:","Selections for what keys to use to switch message tabs will follow")];
	[label_sound setLocalizedString:AILocalizedString(@"Sound:",nil)];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_messagesInTabs){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TABBED_CHATTING
                                              group:PREF_GROUP_INTERFACE];
		[self configureControlDimming];
		
	}else if(sender == checkBox_arrangeByGroup){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_GROUP_CHATS_BY_GROUP
											  group:PREF_GROUP_INTERFACE];
		
	}else if(sender == checkBox_enableLogging){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
		
    }else if(sender == popUp_tabKeys){
		AITabKeys keySelection = [[sender selectedItem] tag];

		[[adium preferenceController] setPreference:[NSNumber numberWithInt:keySelection]
											 forKey:KEY_TAB_SWITCH_KEYS
											  group:PREF_GROUP_CHAT_CYCLING];
		
	}else if(sender == popUp_sendKeys){
		AISendKeys 	keySelection = [[sender selectedItem] tag];
		BOOL		sendOnEnter = (keySelection == AISendOnEnter || keySelection == AISendOnBoth);
		BOOL		sendOnReturn = (keySelection == AISendOnReturn || keySelection == AISendOnBoth);
		
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:sendOnEnter]
											 forKey:SEND_ON_ENTER
											  group:PREF_GROUP_GENERAL];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:sendOnReturn]
											 forKey:SEND_ON_RETURN
                                              group:PREF_GROUP_GENERAL];
		
    }else if(sender == popUp_outputDevice){
		SoundDeviceType soundType = [[popUp_outputDevice selectedItem] tag];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:soundType]
											 forKey:KEY_SOUND_SOUND_DEVICE_TYPE
											  group:PREF_GROUP_SOUNDS];

	}else if(sender == checkBox_enableMenuItem){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_enableMenuItem state]] 
											 forKey:KEY_STATUS_MENU_ITEM_ENABLED
											  group:PREF_GROUP_STATUS_MENU_ITEM];
	}
}

//Dim controls as needed
- (void)configureControlDimming
{
	[checkBox_arrangeByGroup setEnabled:[checkBox_messagesInTabs state]];
}

//New value selected on the volume slider
- (IBAction)selectVolume:(id)sender
{
    NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
    float			volume, oldVolume;
    BOOL			mute, oldMute;
    BOOL			playSample = NO;

	volume = [slider_volume floatValue];
	oldVolume = [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];

	mute = (volume == 0.0);
	oldMute = [[prefDict objectForKey:KEY_SOUND_MUTE] intValue];

    //Volume
    if(volume != oldVolume){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:volume]
                                             forKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
                                              group:PREF_GROUP_SOUNDS];
        playSample = YES;
    }

    //Muted
    if(mute != oldMute){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:mute]
                                             forKey:KEY_SOUND_MUTE
                                              group:PREF_GROUP_SOUNDS];
        playSample = NO;
    }
	
    //Play a sample sound
    if(playSample){
        [[adium soundController] playSoundAtPath:VOLUME_SOUND_PATH];
    }
}

/*!
 * @brief Construct our menu by hand for easy localization
 */
- (NSMenu *)outputDeviceMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	[menu addItemWithTitle:AILocalizedString(@"Play through default device",nil)
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:SOUND_SYTEM_OUTPUT_DEVICE];

	[menu addItemWithTitle:AILocalizedString(@"Play through alert device",nil)
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:SOUND_SYTEM_ALERT_DEVICE];

	return([menu autorelease]);
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
	
	return([menu autorelease]);		
}

/*!
 * @brief Construct our menu by hand for easy localization
 */
- (NSMenu *)sendKeysMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Enter","Enter key for sending messages"), [NSString stringWithUTF8String:"⌘←"], [NSString stringWithUTF8String:"⌘→"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnEnter];
		
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Return","Return key for sending messages"), [NSString stringWithUTF8String:"⇧⌘←"], [NSString stringWithUTF8String:"⇧⌘→"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnReturn];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Enter and Return","Enter and return key for sending messages"), [NSString stringWithUTF8String:"⌘["], [NSString stringWithUTF8String:"⌘]"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnBoth];
	
	return([menu autorelease]);		
}

@end
