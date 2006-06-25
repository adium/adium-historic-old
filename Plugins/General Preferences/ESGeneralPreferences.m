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
#import "PTHotKeyCenter.h"
#import "PTHotKey.h"
#import "SRRecorderControl.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import "PTHotKey.h"

@interface ESGeneralPreferences (PRIVATE)
- (NSMenu *)tabKeysMenu;
- (NSMenu *)sendKeysMenu;

- (NSMenu *)statusIconsMenu;
- (NSMenu *)serviceIconsMenu;

- (NSArray *)_allPacksWithExtension:(NSString *)extension inFolder:(NSString *)inFolder;
@end

@implementation ESGeneralPreferences

// XXX in order to use shortcutrecorder you need a palette
// grab http://brok3n.org/shortcutrecorder/ShortcutRecorder-pre-dist.zip and the updated http://brok3n.org/shortcutrecorder/ShortcutRecorderCell.m in order for this to work for you. Compile the palette and install.
// This comes from http://wafflesoftware.net/shortcut/

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
	
	//Interface
    [checkBox_messagesInTabs setState:[[[adium preferenceController] preferenceForKey:KEY_TABBED_CHATTING
																				group:PREF_GROUP_INTERFACE] boolValue]];
	[checkBox_arrangeByGroup setState:[[[adium preferenceController] preferenceForKey:KEY_GROUP_CHATS_BY_GROUP
																				group:PREF_GROUP_INTERFACE] boolValue]];

	//Chat Cycling
	[popUp_tabKeys setMenu:[self tabKeysMenu]];
	[popUp_tabKeys compatibleSelectItemWithTag:[[[adium preferenceController] preferenceForKey:KEY_TAB_SWITCH_KEYS
																						 group:PREF_GROUP_CHAT_CYCLING] intValue]];

	//General
	sendOnEnter = [[[adium preferenceController] preferenceForKey:SEND_ON_ENTER
															group:PREF_GROUP_GENERAL] boolValue];
	sendOnReturn = [[[adium preferenceController] preferenceForKey:SEND_ON_RETURN
															group:PREF_GROUP_GENERAL] boolValue];
	[popUp_sendKeys setMenu:[self sendKeysMenu]];
	
	if (sendOnEnter && sendOnReturn) {
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnBoth];
	} else if (sendOnEnter) {
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnEnter];			
	} else if (sendOnReturn) {
		[popUp_sendKeys compatibleSelectItemWithTag:AISendOnReturn];
	}

	//Global hotkey
	PTKeyCombo *keyCombo = [[[PTKeyCombo alloc] initWithPlistRepresentation:[[adium preferenceController] preferenceForKey:KEY_GENERAL_HOTKEY
																													 group:PREF_GROUP_GENERAL]] autorelease];
	[shortcutRecorder setKeyCombo:SRMakeKeyCombo([keyCombo keyCode], [shortcutRecorder carbonToCocoaFlags:[keyCombo modifiers]])];

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
	}
}

//Dim controls as needed
- (void)configureControlDimming
{
	[checkBox_arrangeByGroup setEnabled:[checkBox_messagesInTabs state]];
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

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason
{
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	if (aRecorder == shortcutRecorder) {
		PTKeyCombo *keyCombo = [PTKeyCombo keyComboWithKeyCode:[shortcutRecorder keyCombo].code
													 modifiers:[shortcutRecorder cocoaToCarbonFlags:[shortcutRecorder keyCombo].flags]];
		[[adium preferenceController] setPreference:[keyCombo plistRepresentation]
											 forKey:KEY_GENERAL_HOTKEY
											  group:PREF_GROUP_GENERAL];
	}
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
