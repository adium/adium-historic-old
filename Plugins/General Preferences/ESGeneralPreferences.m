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
    NSDictionary	*prefDict;
	
	//Interface
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_INTERFACE];
    [checkBox_messagesInTabs setState:[[prefDict objectForKey:KEY_TABBED_CHATTING] boolValue]];
    [checkBox_arrangeTabs setState:[[prefDict objectForKey:KEY_SORT_CHATS] boolValue]];
	[checkBox_arrangeByGroup setState:[[prefDict objectForKey:KEY_GROUP_CHATS_BY_GROUP] boolValue]];

	//Chat Cycling
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CHAT_CYCLING];
	[popUp_tabKeys setMenu:[self tabKeysMenu]];
	[popUp_tabKeys compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]];
	
	
	//General
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    [checkBox_sendOnReturn setState:[[prefDict objectForKey:SEND_ON_RETURN] intValue]];
	[checkBox_sendOnEnter setState:[[prefDict objectForKey:SEND_ON_ENTER] intValue]];

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
    [checkBox_arrangeTabs setLocalizedString:AILocalizedString(@"Sort tabs with the current sort options",nil)];
    [checkBox_arrangeByGroup setLocalizedString:AILocalizedString(@"Organize tabs into new windows by group",nil)];
	[checkBox_enableLogging setLocalizedString:AILocalizedString(@"Log messages",nil)];
	[checkBox_sendOnReturn setLocalizedString:AILocalizedString(@"Send on Return",nil)];
	[checkBox_sendOnEnter setLocalizedString:AILocalizedString(@"Send on Enter",nil)];
	[checkBox_enableMenuItem setLocalizedString:AILocalizedString(@"Show Adium status in menu bar",nil)];
	
	[label_logging setLocalizedString:AILocalizedString(@"Messages:",nil)];
	[label_messagesSendOn setLocalizedString:AILocalizedString(@"Messages send on:",nil)];
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
		
	}else if(sender == checkBox_arrangeTabs){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_SORT_CHATS
											  group:PREF_GROUP_INTERFACE];
		
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
		
	}else if(sender == checkBox_sendOnReturn){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:SEND_ON_RETURN
                                              group:PREF_GROUP_GENERAL];
        
    }else if(sender == checkBox_sendOnEnter){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:SEND_ON_ENTER
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
	[checkBox_arrangeTabs setEnabled:[checkBox_messagesInTabs state]];
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

- (NSMenu *)outputDeviceMenu
{
	NSMenu		*outputDeviceMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem  *menuItem;
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Play through default device",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:SOUND_SYTEM_OUTPUT_DEVICE];                
	[outputDeviceMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Play through alert device",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:SOUND_SYTEM_ALERT_DEVICE];                
	[outputDeviceMenu addItem:menuItem];
	
	return ([outputDeviceMenu autorelease]);
}

- (NSMenu *)tabKeysMenu
{
	NSMenu		*tabKeysMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem  *menuItem;
	NSString	*title;
	
	title = [AILocalizedString(@"Arrows","Directional arrow keys word") stringByAppendingString:[NSString stringWithUTF8String:"  (⌘← and ⌘→)"]];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:AISwitchArrows];                
	[tabKeysMenu addItem:menuItem];

	title = [AILocalizedString(@"Shift + Arrows","Shift key word + Directional arrow keys word") stringByAppendingString:[NSString stringWithUTF8String:"  (⇧⌘← and ⇧⌘→)"]];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:AISwitchShiftArrows];                
	[tabKeysMenu addItem:menuItem];

	title = [AILocalizedString(@"Brackets","Word for [ and ] keys") stringByAppendingString:[NSString stringWithUTF8String:"  (⌘[ and ⌘])"]];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:AIBrackets];                
	[tabKeysMenu addItem:menuItem];
	
	return ([tabKeysMenu autorelease]);		
}

@end
