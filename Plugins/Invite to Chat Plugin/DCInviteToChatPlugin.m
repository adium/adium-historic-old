//
//  DCInviteToChatPlugin.m
//  Adium
//
//  Created by David Clark on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCInviteToChatPlugin.h"
#import "DCInviteToChatWindowController.h"

#define INVITE_CONTACT			NSLocalizedString(@"Invite to Chat",nil)

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
	[[adium menuController] addContextualMenuItem:menuItem_inviteToChatContext toLocation:Context_Contact_Action];	
	
}

//Validate our menu items
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	
	if(menuItem == menuItem_inviteToChat){		

		AIListObject *object = [[adium contactController] selectedListObjectInContactList];

		if ([object isKindOfClass:[AIListContact class]]){
			if( shouldRebuildChatList ) {
				[menuItem_inviteToChat setSubmenu:[self groupChatMenuForContact:(AIListContact *)object]];
			}
			return ([[menuItem_inviteToChat submenu] numberOfItems] > 0);
		}else{
			return NO;
		}
		
	} else if ( menuItem == menuItem_inviteToChatContext ) {
		
		if( shouldRebuildChatList ) {
			AIListContact *object = [[adium menuController] contactualMenuContact];
			if([object isKindOfClass:[AIListContact class]]){
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
	NSString		*service = [repArray objectAtIndex:2];
	
	[DCInviteToChatWindowController inviteToChatWindowForChat:chat contact:listContact service:service];
}

#pragma mark Private

- (NSMenu *)groupChatMenuForContact:(AIListContact *)contact
{
	NSArray			*openChats = [[adium interfaceController] openChats];
	AIChat			*chat;
	NSMenu			*menu_chatMenu = [[NSMenu alloc] initWithTitle:@""];
	NSDictionary	*serviceDict;
	AIService		*service;
	int i;
	
	if( contact && ![contact isKindOfClass:[AIListGroup class]] ) {
				
		// Get a dictionary of (service, contacts in that service)
		if([contact isKindOfClass:[AIMetaContact class]])
			serviceDict = [(AIMetaContact *)contact dictionaryOfServicesAndListContacts];
		else
			serviceDict = [NSDictionary dictionaryWithObject:contact forKey:[[contact service] serviceID]];
		
		NSEnumerator *enumerator = [serviceDict keyEnumerator];
		
		[menu_chatMenu setMenuChangedMessagesEnabled:NO];
		
		while( service = [enumerator nextObject] ) {
						
			// Loop through all chats
			for( i = 0; i < [openChats count]; i++ ) {
				chat = [openChats objectAtIndex:i];
				
				// Is this the same service as this contact?				
				if( [[chat account] service] == service ) {
					
					NSLog(@"#   Considering chat %@. Name: %@. Participants: %d",chat,[chat name],[[chat participatingListObjects] count]);
					// Is this a group chat?
					if( [chat name] ) {
						NSLog(@"##  Chat %@ has a name: %@",chat,[chat name]);
						
						if( [menu_chatMenu indexOfItemWithTitle:[chat name]] == -1 ) {

							NSLog(@"### and it's not in the menu!");
							NSMenuItem *chatItem = [[NSMenuItem alloc] initWithTitle:[chat name]
																			  target:self
																			  action:@selector(inviteToChat:)
																	   keyEquivalent:@""];
							[chatItem setRepresentedObject:[NSArray arrayWithObjects:chat,contact,service,nil]];
							[menu_chatMenu addItem:chatItem];
							[chatItem release];
						}
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
