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

#import "AIChatCyclingPlugin.h"
#import "AIInterfaceController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>

#define PREVIOUS_MESSAGE_MENU_TITLE		AILocalizedString(@"Previous Chat",nil)
#define NEXT_MESSAGE_MENU_TITLE			AILocalizedString(@"Next Chat",nil)

@interface AIChatCyclingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIChatCyclingPlugin

- (void)installPlugin
{
	//Cycling menu items
	previousChatMenuItem = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE
													  target:self 
													  action:@selector(previousChat:)
											   keyEquivalent:@""];
	[[adium menuController] addMenuItem:previousChatMenuItem toLocation:LOC_Window_Commands];
	
	nextChatMenuItem = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE 
												  target:self
												  action:@selector(nextChat:)
										   keyEquivalent:@""];
	[[adium menuController] addMenuItem:nextChatMenuItem toLocation:LOC_Window_Commands];
	
	//Prefs
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CHAT_CYCLING];
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{	
	//Configure our tab switching hotkeys
	unichar 		left = NSLeftArrowFunctionKey;
	unichar 		right = NSRightArrowFunctionKey;
	NSString		*leftKey, *rightKey;
	unsigned int	keyMask = NSCommandKeyMask;
	
	switch([[prefDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]){
		case AISwitchArrows:
			leftKey = [NSString stringWithCharacters:&left length:1];
			rightKey = [NSString stringWithCharacters:&right length:1];
			break;
		case AISwitchShiftArrows:
			leftKey = [NSString stringWithCharacters:&left length:1];
			rightKey = [NSString stringWithCharacters:&right length:1];
			keyMask = (NSCommandKeyMask | NSShiftKeyMask);
			break;
		default://case AIBrackets:
			leftKey = @"[";
			rightKey = @"]";
			break;
	}
	//Previous and nextMessage menuItems are in the same menu, so the setMenuChangedMessagesEnabled applies to both.
	[[previousChatMenuItem menu] setMenuChangedMessagesEnabled:NO];		
	[previousChatMenuItem setKeyEquivalent:@""];
	[previousChatMenuItem setKeyEquivalent:leftKey];
	[previousChatMenuItem setKeyEquivalentModifierMask:keyMask];
	[nextChatMenuItem setKeyEquivalent:@""];
	[nextChatMenuItem setKeyEquivalent:rightKey];
	[nextChatMenuItem setKeyEquivalentModifierMask:keyMask];
	[[previousChatMenuItem menu] setMenuChangedMessagesEnabled:YES];
}

//Menu item validation
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return([[[adium interfaceController] openChats] count] != 0);
}

//Select the next chat
- (IBAction)nextChat:(id)sender
{
	[[adium interfaceController] nextMessage:nil];
}

//Select the previous chat
- (IBAction)previousChat:(id)sender
{
	[[adium interfaceController] previousMessage:nil];
}	

@end
