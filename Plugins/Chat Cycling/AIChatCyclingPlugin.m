//
//  AIChatCyclingPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu Jul 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIChatCyclingPlugin.h"
#import "AIChatCyclingPreferences.h"

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
	preferences = [[AIChatCyclingPreferences preferencePane] retain];
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
