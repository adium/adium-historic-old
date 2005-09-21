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

#import "AIContactController.h"
#import "AIInterfaceController.h"
#import "AIMenuController.h"
#import "DCInviteToChatPlugin.h"
#import "DCInviteToChatWindowController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>

#define INVITE_CONTACT			AILocalizedString(@"Invite to Chat",nil)

@interface DCInviteToChatPlugin (PRIVATE)
- (NSMenu *)groupChatMenuForContact:(AIListContact *)contact;
@end

@implementation DCInviteToChatPlugin

- (void)installPlugin
{
	
	shouldRebuildChatList = YES;
	
	//Invite to Chat menu item
	menuItem_inviteToChat = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:INVITE_CONTACT
																				  target:self
																				  action:@selector(dummyTarget:)
																		   keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:menuItem_inviteToChat toLocation:LOC_Contact_Action];
	
	//Invite to Chat context menu item
	menuItem_inviteToChatContext = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:INVITE_CONTACT
																						 target:self
																						 action:@selector(dummyTarget:)
																				  keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem_inviteToChatContext toLocation:Context_Contact_Action];	
	
}

//Validate our menu items
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{                
	if (menuItem == menuItem_inviteToChat) {		

		AIListObject *object = [[adium contactController] selectedListObjectInContactList];

		if ([object isKindOfClass:[AIListContact class]]) {
			if ( shouldRebuildChatList ) {
				[menuItem_inviteToChat setSubmenu:[self groupChatMenuForContact:(AIListContact *)object]];
			}
                     
			return ([[menuItem_inviteToChat submenu] numberOfItems] > 0);
		} else {
                        [menuItem_inviteToChat setTitle:INVITE_CONTACT]; // hit the reset button
			return NO;
		}
		
	} else if ( menuItem == menuItem_inviteToChatContext ) {
		
		if ( shouldRebuildChatList ) {
			AIListObject *object = [[adium menuController] currentContextMenuObject];
			if ([object isKindOfClass:[AIListContact class]]) {
				[menuItem_inviteToChatContext setSubmenu:[self groupChatMenuForContact:(AIListContact *)object]];
			}
		}
		return ([[menuItem_inviteToChatContext submenu] numberOfItems] > 0);

	}
	
	return YES;
}

- (IBAction)inviteToChat:(id)sender
{
	NSArray			*repArray = [sender representedObject];
	AIListContact	*listContact = [repArray objectAtIndex:1];
	AIChat			*chat = [repArray objectAtIndex:0];
	
	[DCInviteToChatWindowController inviteToChatWindowForChat:chat contact:listContact];
}

#pragma mark Private

- (NSMenu *)groupChatMenuForContact:(AIListContact *)contact
{
	NSArray			*openChats = [[adium interfaceController] openChats];
	AIChat			*chat;
	NSMenu			*menu_chatMenu = nil;
	NSDictionary	*serviceDict;
	NSString		*serviceClass;
	int i;
	
	if (contact && ![contact isKindOfClass:[AIListGroup class]]) {
		NSEnumerator *enumerator;
		unsigned	currentNumberOfItems, numberOfMenuItems = 0;
		
		// Get a dictionary of (service class, contacts in that service)
		serviceDict = ([contact isKindOfClass:[AIMetaContact class]] ?
					   [(AIMetaContact *)contact dictionaryOfServiceClassesAndListContacts] :
					   [NSDictionary dictionaryWithObject:contact forKey:[[contact service] serviceClass]]);

		[menu_chatMenu setMenuChangedMessagesEnabled:NO];

		enumerator = [serviceDict keyEnumerator];
		while ((serviceClass = [enumerator nextObject])) {
			
			//Each iteration, if we have more menu items now than before, add a separator item
			currentNumberOfItems = [menu_chatMenu numberOfItems];
			if (currentNumberOfItems > numberOfMenuItems) {
				[menu_chatMenu addItem:[NSMenuItem separatorItem]];
				numberOfMenuItems = currentNumberOfItems + 1;
			}
			
			// Loop through all chats
			for (i = 0; i < [openChats count]; i++) {
				chat = [openChats objectAtIndex:i];
				
				// Is this the same serviceClass as this contact?				
				if ( [[[[chat account] service] serviceClass] isEqualToString:serviceClass] ) {
					
					// Is this a group chat?
					if ([chat isGroupChat]) {
						if (!menu_chatMenu) {
							menu_chatMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
						}
						
						if ( [menu_chatMenu indexOfItemWithTitle:[chat name]] == -1 ) {
							NSMenuItem *menuItem;
							menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[chat name]
																							target:self
																							action:@selector(inviteToChat:)
																					 keyEquivalent:@""];
							[menuItem setRepresentedObject:[NSArray arrayWithObjects:chat,contact,nil]];
							[menu_chatMenu addItem:menuItem];
							[menuItem release];
						}
					}
				}
			}
		}
		
		//Remove the last separator if our new number of items isn't bigger than the previous one (that is, we haven't added any items since the last separator)
		currentNumberOfItems = [menu_chatMenu numberOfItems];
		if ((currentNumberOfItems <= numberOfMenuItems) &&
			(currentNumberOfItems > 0)) {
			
			[menu_chatMenu removeItemAtIndex:(currentNumberOfItems-1)];
		}
		
		[menu_chatMenu setMenuChangedMessagesEnabled:YES];
	}
	
	return menu_chatMenu;
}

// Dummy target so that we get validateMenuItem calls
- (IBAction)dummyTarget:(id)sender { }


@end
