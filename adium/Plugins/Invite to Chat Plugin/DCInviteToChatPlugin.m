//
//  DCInviteToChatPlugin.m
//  Adium
//
//  Created by David Clark on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCInviteToChatPlugin.h"
#import "DCInviteToChatWindowController.h"

#define INVITE_CONTACT			AILocalizedString(@"Invite to Chat",nil)

@interface DCInviteToChatPlugin (PRIVATE)
- (NSMenu *)groupChatMenuForContact:(AIListContact *)contact;
@end

@implementation DCInviteToChatPlugin

- (void)installPlugin
{

	shouldRebuildChatList = YES;
	
	//Invite to Chat menu item
	menuItem_inviteToChat = [[[NSMenuItem alloc] initWithTitle:INVITE_CONTACT
														target:self
														action:@selector(dummyTarget:)
												 keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:menuItem_inviteToChat toLocation:LOC_Contact_Action];
	
	//Invite to Chat context menu item
	menuItem_inviteToChatContext = [[[NSMenuItem alloc] initWithTitle:INVITE_CONTACT
															   target:self
															   action:@selector(dummyTarget:)
														keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem_inviteToChatContext toLocation:Context_Contact_ListAction];	
	
}

//Validate our menu items
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	
	if(menuItem == menuItem_inviteToChat){		

		if( shouldRebuildChatList ) {
			AIListObject *object = [[adium contactController] selectedListObjectInContactList];
			if( ![object isKindOfClass:[AIListGroup class]] )
				[menuItem_inviteToChat setSubmenu:[self groupChatMenuForContact:object]];
		}
		return ([[menuItem_inviteToChat submenu] numberOfItems] > 0);

		
	} else if ( menuItem == menuItem_inviteToChatContext ) {
		
		if( shouldRebuildChatList ) {
			AIListContact *object = [[adium menuController] contactualMenuContact];
			if( ![object isKindOfClass:[AIListGroup class]] )
				[menuItem_inviteToChatContext setSubmenu:[self groupChatMenuForContact:object]];
		}
		return ([[menuItem_inviteToChatContext submenu] numberOfItems] > 0);

	}
	
	return YES;
}

- (IBAction)inviteToChat:(id)sender
{
	NSArray			*repArray = [sender representedObject];
	AIListObject	*listObject = [repArray objectAtIndex:1];
	AIChat			*chat = [repArray objectAtIndex:0];
	NSString		*service = [repArray objectAtIndex:2];
	
	[DCInviteToChatWindowController inviteToChatWindowForChat:chat contact:listObject service:service];
}

#pragma mark Private

- (NSMenu *)groupChatMenuForContact:(AIListContact *)contact
{
	NSArray			*openChats = [[adium interfaceController] openChats];
	AIChat			*chat;
	NSMenu			*menu_chatMenu = [[NSMenu alloc] initWithTitle:@""];
	NSDictionary	*serviceDict;
	NSString		*serviceID;
	int i;
	
	if( contact ) {
				
		// Get a dictionary of (service, contacts in that service)
		if( [contact isKindOfClass:[AIMetaContact class]] )
			serviceDict = [contact dictionaryOfServicesAndListContacts];
		else
			serviceDict = [NSDictionary dictionaryWithObject:contact forKey:[contact serviceID]];
		
		NSEnumerator *enumerator = [serviceDict keyEnumerator];
		
		[menu_chatMenu setMenuChangedMessagesEnabled:NO];
		
		while( serviceID = [enumerator nextObject] ) {
						
			// Loop through all chats
			for( i = 0; i < [openChats count]; i++ ) {
				chat = [openChats objectAtIndex:i];
				
				// Is this the same service as this contact?				
				if( [[[[[chat account] service] handleServiceType] identifier] isEqualToString:serviceID] ) {
					
					// Is this a group chat?
					if( [[chat participatingListObjects] count] > 1 ) {
						if( ![chat name] )
							[chat setName:@"BOZO THE CLOWN"];
						
						// Future: sort by service, add dividers
						NSMenuItem *chatItem = [[NSMenuItem alloc] initWithTitle:[chat name]
															   target:self
															   action:@selector(inviteToChat:)
														keyEquivalent:@""];
						[chatItem setRepresentedObject:[NSArray arrayWithObjects:chat,contact,serviceID,nil]];
						[menu_chatMenu addItem:chatItem];
						[chatItem release];
					}
				}
			}
			
			[menu_chatMenu addItem:[NSMenuItem separatorItem]];
		}
		
		// Remove the last separator
		[menu_chatMenu removeItemAtIndex:([menu_chatMenu numberOfItems]-1)];
		[menu_chatMenu setMenuChangedMessagesEnabled:YES];
		
		return menu_chatMenu;
	}
	
	return nil;
}

// Dummy target so that we get validateMenuItem calls
- (IBAction)dummyTarget:(id)sender { }


@end
