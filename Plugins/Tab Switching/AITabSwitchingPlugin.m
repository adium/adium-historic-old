//
//  AITabSwitchingPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AITabSwitchingPlugin.h"

@implementation AITabSwitchingPlugin

- (void)installPlugin
{
	//Add our tab switching menu items
	menuItem_previousMessage = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE
														  target:self 
														  action:@selector(previousMessage:)
												   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_previousMessage toLocation:LOC_Window_Commands];
	
	menuItem_nextMessage = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE 
													  target:self
													  action:@selector(nextMessage:)
											   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_nextMessage toLocation:LOC_Window_Commands];
	
	//Observe preference changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
	[[adium menuController] removeMenuItem:menuItem_nextMessage];
	[[adium menuController] removeMenuItem:menuItem_previousMessage];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if (notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]) {
		NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

		//Configure our tab switching hotkeys
		unichar 		left = NSLeftArrowFunctionKey;
		unichar 		right = NSRightArrowFunctionKey;
		NSString		*leftKey, *rightKey;
		unsigned int	keyMask = NSCommandKeyMask;
		
		switch([[preferenceDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]){
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
		
		[menuItem_previousMessage setKeyEquivalent:@""];
		[menuItem_previousMessage setKeyEquivalent:leftKey];
		[menuItem_previousMessage setKeyEquivalentModifierMask:keyMask];
		
		[menuItem_nextMessage setKeyEquivalent:@""];
		[menuItem_nextMessage setKeyEquivalent:rightKey];
		[menuItem_nextMessage setKeyEquivalentModifierMask:keyMask];
		
		[[menuItem_previousMessage menu] update];
	}
}

//
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return([messageWindowControllerArray count] != 0);
}

//Select the next message
- (IBAction)nextMessage:(id)sender
{
	//[[adium interfaceController] selectNextContainer];
}

//Select the previous message
- (IBAction)previousMessage:(id)sender
{
	//[[adium interfaceController] selectPreviousContainer];
}


@end
