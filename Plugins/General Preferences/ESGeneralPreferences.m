//
//  ESGeneralPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"

#define VOLUME_SOUND_PATH   @"/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/volume.aiff"

@interface ESGeneralPreferences (PRIVATE)
- (NSMenu *)outputDeviceMenu;
- (NSMenu *)tabKeysMenu;
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

	[popUp_statusIcons setMenu:[self statusIconsMenu]];
	[popUp_statusIcons selectItemWithTitle:[prefDict objectForKey:KEY_STATUS_ICON_PACK]];
//	[popUp_serviceIcons setMenu:[self serviceIconsMenu]];
//	[popUp_serviceIcons selectItemWithTitle:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]];

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

    [self configureControlDimming];
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
	}else if(sender == popUp_statusIcons){
        [[adium preferenceController] setPreference:[[popUp_statusIcons selectedItem] title]
                                             forKey:KEY_STATUS_ICON_PACK
                                              group:PREF_GROUP_INTERFACE];
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
    float			value = [slider_volume floatValue];
    BOOL			mute = (value == 0.0);
    BOOL			playSample = NO;
    
    //Volume
    if(value != [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue]){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:value]
                                             forKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
                                              group:PREF_GROUP_SOUNDS];
        playSample = YES;
    }
	
    //Muted
    if(mute != [[prefDict objectForKey:KEY_SOUND_MUTE] intValue]){
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


- (NSMenu *)statusIconsMenu
{
	NSMenu			*statusIconsMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem		*menuItem;

	NSEnumerator	*enumerator = [[self _allPacksWithExtension:@"AdiumStatusIcons" inFolder:@"Status Icons"] objectEnumerator];
	NSString		*packPath;
	while(packPath = [enumerator nextObject]){
		NSString	*name = [[packPath lastPathComponent] stringByDeletingPathExtension];
		
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menuItem setImage:[AIStatusIcons previewMenuImageForStatusIconsAtPath:packPath]];
		[statusIconsMenu addItem:menuItem];		
	}
	
	return(statusIconsMenu);
}

- (NSMenu *)serviceIconsMenu
{
	
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
