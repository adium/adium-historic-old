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
#import "AIToolbarController.h"
#import "ESSecureMessagingPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>

#define	TITLE_MAKE_SECURE		AILocalizedString(@"Initiate Encrypted OTR Chat",nil)
#define	TITLE_MAKE_INSECURE		AILocalizedString(@"Cancel Encrypted Chat",nil)
#define TITLE_SHOW_DETAILS		AILocalizedString(@"Show Details...",nil)
#define TITLE_ABOUT_ENCRYPTION	AILocalizedString(@"About Encryption...",nil)

#define TITLE_ENCRYPTION		AILocalizedString(@"Encryption",nil)

#define CHAT_NOW_SECURE			AILocalizedString(@"This line secured, sir.", nil)
#define CHAT_NO_LONGER_SECURE	AILocalizedString(@"Warning: Project Carnivore detected.", nil)

@interface ESSecureMessagingPlugin (PRIVATE)
- (void)registerToolbarItem;
- (NSMenu *)_secureMessagingMenu;
- (void)_updateToolbarIconOfChat:(AIChat *)inChat inWindow:(NSWindow *)window;
@end

@implementation ESSecureMessagingPlugin

- (void)installPlugin
{
	_secureMessagingMenu = nil;
	lockImage_Locked = [[NSImage imageNamed:@"Lock_Locked State" forClass:[self class]] retain];
	lockImage_Unlocked = [[NSImage imageNamed:@"Lock_Unlocked State" forClass:[self class]] retain];

	/*
	lockImageAnimation[i] = [[NSImage imageNamed:[NSString stringWithFormat:@"Lock_Open Anim %02i",i]
										forClass:[self class]] retain];
	 */
	
	[self registerToolbarItem];
	
	[[adium contentController] registerChatObserver:self];
}

- (void)uninstallPlugin
{
	
}

- (void)registerToolbarItem
{	
	toolbarItems = [[NSMutableSet alloc] init];
	
	//Toolbar item registration
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];

	//Register our toolbar item
	NSToolbarItem	*toolbarItem;
	MVMenuButton	*button;
	button = [[[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)] autorelease];
	[button setImage:lockImage_Locked];

    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"Encryption"
														  label:TITLE_ENCRYPTION
												   paletteLabel:AILocalizedString(@"Encrypted Messaging",nil)
														toolTip:AILocalizedString(@"Toggle encrypted messaging. Shows a closed lock when secure and an open lock when insecure.",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:button
														 action:@selector(toggleSecureMessaging:)
														   menu:nil];
	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];
	
	//Register our toolbar item
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"MessageWindow"];
}


//After the toolbar has added the item we can set up the submenus
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	if([[item itemIdentifier] isEqualToString:@"Encryption"]){
		[item setEnabled:YES];
		
		//If this is the first item added, start observing for chats becoming visible so we can update the icon
		if([toolbarItems count] == 0){
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatDidBecomeVisible:)
											   name:@"AIChatDidBecomeVisible"
											 object:nil];
		}
		
		NSMenu		*menu = [self _secureMessagingMenu];
		
		//Add menu to view
		[[item view] setMenu:menu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
		[mItem setSubmenu:menu];
		[mItem setTitle:[menu title]];
		[item setMenuFormRepresentation:mItem];

		[toolbarItems addObject:item];
	}
}

- (void)toolbarDidRemoveItem: (NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	if([toolbarItems containsObject:item]){
		[toolbarItems removeObject:item];
		
		if([toolbarItems count] == 0){
			[[adium notificationCenter] removeObserver:self
												  name:@"AIChatDidBecomeVisible"
												object:nil];
		}
	}
}

//A chat became visible in a window.  Update the item with the @"Encryption" identifier to show the IsSecure state for this chat
- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	[self _updateToolbarIconOfChat:[notification object]
						  inWindow:[[notification userInfo] objectForKey:@"NSWindow"]];
}

//When the IsSecure key of a chat changes, update the @"Encryption" item immediately
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if([inModifiedKeys containsObject:@"SecurityDetails"]){
		[self _updateToolbarIconOfChat:inChat
							  inWindow:[[adium interfaceController] windowForChat:inChat]];
		
		/* Add a status message to the chat */
		NSNumber	*lastEncryptedNumber = [inChat statusObjectForKey:@"secureMessagingLastEncryptedState"];
		BOOL		chatIsSecure = [inChat isSecure];
		if(!lastEncryptedNumber || (chatIsSecure != [lastEncryptedNumber boolValue])){
			NSString	*message;
			
			[inChat setStatusObject:[NSNumber numberWithBool:chatIsSecure]
							 forKey:@"secureMessagingLastEncryptedState"
							 notify:NotifyNever];
			
			message = (chatIsSecure ? CHAT_NOW_SECURE : CHAT_NO_LONGER_SECURE);
			
			[[adium contentController] displayStatusMessage:message
													 ofType:@"encryption"
													 inChat:inChat];
		}
	}
	
	return nil;
}

- (void)_updateToolbarIconOfChat:(AIChat *)chat inWindow:(NSWindow *)window
{
	NSToolbar		*toolbar = [window toolbar];
	NSEnumerator	*enumerator = [[toolbar items] objectEnumerator];
	NSToolbarItem	*item;
	
	while(item = [enumerator nextObject]){
		if([[item itemIdentifier] isEqualToString:@"Encryption"]){
			NSImage			*image;
			
			if([chat isSecure]){
				image = lockImage_Locked;
			}else{
				image = lockImage_Unlocked;				
			}

			[item setEnabled:[chat supportsSecureMessagingToggling]];
			[(MVMenuButton *)[item view] setImage:image];
			break;
		}
	}	
}

- (IBAction)toggleSecureMessaging:(id)sender
{
	AIChat	*chat = [[adium interfaceController] activeChat];

	[[chat account] requestSecureMessaging:![chat isSecure]
									inChat:chat];
}

- (IBAction)showDetails:(id)sender
{
	NSRunInformationalAlertPanel(@"Details",
								 [[[[adium interfaceController] activeChat] securityDetails] objectForKey:@"Description"],
								 AILocalizedString(@"OK",nil),
								 nil,
								 nil);
}

- (IBAction)showAbout:(id)sender
{
	NSString	*aboutEncryption;
	
	aboutEncryption = [[[[adium interfaceController] activeChat] account] aboutEncryption];
	
	if(aboutEncryption){
		NSRunInformationalAlertPanel(@"About Encryption",
									 aboutEncryption,
									 AILocalizedString(@"OK",nil),
									 nil,
									 nil);
	}
}

//Disable the insertion if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AISecureMessagingMenuTag tag = [menuItem tag];
	AIChat					*chat = [[adium interfaceController] activeChat];

	switch(tag){
		case AISecureMessagingMenu_Toggle:
			//The menu item should indicate what will happen if it is selected.. the opposite of our secure state
			[menuItem setTitle:([chat isSecure] ? TITLE_MAKE_INSECURE : TITLE_MAKE_SECURE)];
			return YES;
			break;
			
		case AISecureMessagingMenu_ShowDetails:
			//Only enable show details if the chat is secure
			return [chat isSecure];
			break;
		case AISecureMessagingMenu_ShowAbout:
			return [chat supportsSecureMessagingToggling];
			break;
	}
	
	return YES;
}

- (NSMenu *)_secureMessagingMenu
{
	if(!_secureMessagingMenu){
		NSMenuItem	*item;

		_secureMessagingMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
		[_secureMessagingMenu setTitle:TITLE_ENCRYPTION];

		item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:TITLE_MAKE_SECURE
																	 target:self
																	 action:@selector(toggleSecureMessaging:)
															  keyEquivalent:@""] autorelease];
		[item setTag:AISecureMessagingMenu_Toggle];
		[_secureMessagingMenu addItem:item];
		
		item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:TITLE_SHOW_DETAILS
																	 target:self
																	 action:@selector(showDetails:)
															  keyEquivalent:@""] autorelease];
		[item setTag:AISecureMessagingMenu_ShowDetails];
		[_secureMessagingMenu addItem:item];
		
		item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:TITLE_ABOUT_ENCRYPTION
																	 target:self
																	 action:@selector(showAbout:)
															  keyEquivalent:@""] autorelease];
		[item setTag:AISecureMessagingMenu_ShowAbout];
		[_secureMessagingMenu addItem:item];
	}
	
	return([[_secureMessagingMenu copy] autorelease]);
}

@end
