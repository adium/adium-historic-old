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

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIMenuController.h"
#import "AIToolbarController.h"
#import "AIInterfaceController.h"
#import "AIChatController.h"
#import "ESBlockingPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIChat.h>

#define BLOCK_CONTACT				AILocalizedString(@"Block","Block Contact menu item")
#define UNBLOCK_CONTACT				AILocalizedString(@"Unblock","Unblock Contact menu item")
#define TOOLBAR_ITEM_IDENTIFIER		@"BlockParticipants"
#define TOOLBAR_BLOCK_ICON_KEY		@"Block"
#define TOOLBAR_UNBLOCK_ICON_KEY	@"Unblock"

@interface ESBlockingPlugin(PRIVATE)
- (void)_blockContact:(AIListContact *)contact unblock:(BOOL)unblock;
- (BOOL)_searchPrivacyListsForListContact:(AIListContact *)contact withDesiredResult:(BOOL)desiredResult;
- (void)accountConnected:(NSNotification *)notification;
- (BOOL)areAllGivenContactsBlocked:(NSArray *)contacts;
- (void)setPrivacy:(BOOL)block forContacts:(NSArray *)contacts;
- (IBAction)blockOrUnblockParticipants:(NSToolbarItem *)senderItem;

//protocols
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;

//notifications
- (void)chatDidBecomeVisible:(NSNotification *)notification;
- (void)toolbarWillAddItem:(NSNotification *)notification;
- (void)toolbarDidRemoveItem:(NSNotification *)notification;

//toolbar item methods
- (void)updateToolbarIconOfChat:(AIChat *)inChat inWindow:(NSWindow *)window;
- (void)updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat;
- (void)updateToolbarItemForObject:(AIListObject *)inObject;
@end

#pragma mark -
@implementation ESBlockingPlugin

- (void)installPlugin
{
	//Install the Block menu items
	blockContactMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
													  target:self
													  action:@selector(blockContact:)
											   keyEquivalent:@"b"];
	
	[blockContactMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask|NSAlternateKeyMask)];
	
	[[adium menuController] addMenuItem:blockContactMenuItem toLocation:LOC_Contact_NegativeAction];

    //Add our get info contextual menu items
    blockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
																target:self
																action:@selector(blockContact:)
														 keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:blockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];
	
	//we want to know when an account connects
	[[adium notificationCenter] addObserver:self
								   selector:@selector(accountConnected:)
									   name:ACCOUNT_CONNECTED
									 object:nil];
	
	//create the block toolbar item
	chatToolbarItems = [[NSMutableSet alloc] init];
	//cache toolbar icons
	blockedToolbarIcons = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSImage imageNamed:@"block.png" forClass:[self class]], TOOLBAR_BLOCK_ICON_KEY, 
								[NSImage imageNamed:@"unblock.png" forClass:[self class]], TOOLBAR_UNBLOCK_ICON_KEY, 
								nil];
	NSToolbarItem	*chatItem = [AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_ITEM_IDENTIFIER
																		label:BLOCK_CONTACT
																 paletteLabel:BLOCK_CONTACT
																	  toolTip:BLOCK_CONTACT
																	   target:self
															  settingSelector:@selector(setImage:)
																  itemContent:[blockedToolbarIcons valueForKey:TOOLBAR_BLOCK_ICON_KEY]
																	   action:@selector(blockOrUnblockParticipants:)
																		 menu:nil];
	
	[[adium toolbarController] registerToolbarItem:chatItem forToolbarType:@"MessageWindow"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];
	[[adium contactController] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[[adium contactController] unregisterListObjectObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[chatToolbarItems release];
	[blockedToolbarIcons release];
	[blockContactMenuItem release];
	[blockContactContextualMenuItem release];
}

/*!
 * @brief Block or unblock contacts
 *
 * @param block Flag indicating what the operation should achieve: NO for unblock, YES for block.
 * @param contacts The contacts to block or unblock
 */
- (void)setPrivacy:(BOOL)block forContacts:(NSArray *)contacts
{
	NSEnumerator	*contactEnumerator = [contacts objectEnumerator];
	AIListContact	*currentContact = nil;
	
	while ((currentContact = [contactEnumerator nextObject])) {
		if ([currentContact isBlocked] != block) {
			[currentContact setIsBlocked:block updateList:YES];
		}
	}
}

- (IBAction)blockContact:(id)sender
{
	AIListObject	*object;
	
	object = ((sender == blockContactMenuItem) ?
			  [[adium contactController] selectedListObject] :
			  [[adium menuController] currentContextMenuObject]);
	
	//Don't do groups
	if ([object isKindOfClass:[AIListContact class]]) {
		AIListContact	*contact = (AIListContact *)object;
		BOOL			unblock;
		NSString		*format;
		
		unblock = [[sender title] isEqualToString:UNBLOCK_CONTACT];
		format = (unblock ? 
				  AILocalizedString(@"Are you sure you want to unblock %@?",nil) :
				  AILocalizedString(@"Are you sure you want to block %@?",nil));

		if (NSRunAlertPanel([NSString stringWithFormat:format, [contact displayName]],
						   @"",
						   [sender title],
						   AILocalizedString(@"Cancel", nil),
						   nil) == NSAlertDefaultReturn) {
			
			//Handle metas
			if ([object isKindOfClass:[AIMetaContact class]]) {
				AIMetaContact *meta = (AIMetaContact *)object;
									
				//Enumerate over the various list contacts contained
				NSEnumerator *enumerator = [[meta listContacts] objectEnumerator];
				AIListContact *containedContact = nil;
				
				while ((containedContact = [enumerator nextObject])) {
					AIAccount <AIAccount_Privacy> *acct = [containedContact account];
					if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
						[self _blockContact:containedContact unblock:unblock];
					} else {
						NSLog(@"Account %@ does not support blocking (contact %@ not blocked on this account)", acct, containedContact);
					}
				}
			} else {
				AIListContact *contact = (AIListContact *)object;
				AIAccount <AIAccount_Privacy> *acct = [contact account];
				if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
					[self _blockContact:contact unblock:unblock];
				} else {
					NSLog(@"Account %@ does not support blocking (contact %@ not blocked on this account)", acct, contact);
				}
			}
		}
	}
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListObject *object;
	BOOL unblock = [[menuItem title] isEqualToString:UNBLOCK_CONTACT];
	BOOL anyAccount = NO;
	
	if (menuItem == blockContactMenuItem) {
		object = [[adium contactController] selectedListObject];
	} else {
		object = [[adium menuController] currentContextMenuObject];
	}
	
	//Don't do groups
	if ([object isKindOfClass:[AIListContact class]]) {
		//Handle metas
		if ([object isKindOfClass:[AIMetaContact class]]) {
			AIMetaContact *meta = (AIMetaContact *)object;
								
			//Enumerate over the various list contacts contained
			NSEnumerator *enumerator = [[meta listContacts] objectEnumerator];
			AIListContact *contact = nil;
			
			while ((contact = [enumerator nextObject])) {
				AIAccount <AIAccount_Privacy> *acct = [contact account];
				if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
					anyAccount = YES;
					AIPrivacyType privType = [acct privacyOptions] == AIPrivacyOptionAllowUsers ? AIPrivacyTypePermit : AIPrivacyTypeDeny;
					if ([[acct listObjectsOnPrivacyList:privType] containsObject:contact]) {
						//title: "Unblock"; enabled
						if (!unblock && AIPrivacyTypePermit == privType) {
							//removing the guy is blocking him
							[menuItem setTitle:BLOCK_CONTACT];
						}
						else if (unblock && AIPrivacyTypeDeny == privType) {
							//removing him is unblocking
							[menuItem setTitle:UNBLOCK_CONTACT];
						}
						return YES;
					}
				}
			}
#warning this next block is a bogus way to handle this, but metas are such a special condition I'm not sure what to do -durin42
			if (anyAccount) {
				//title: "Block"; enabled
				if (unblock) {
					[menuItem setTitle:BLOCK_CONTACT];
				}
				return YES;
			} else {
				//title: "Block"; disabled
				[menuItem setTitle:BLOCK_CONTACT];
				return NO;
			}
		} else {
			AIListContact *contact = (AIListContact *)object;
			AIAccount <AIAccount_Privacy> *acct = [contact account];
			if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
				AIPrivacyType privType = [acct privacyOptions] == AIPrivacyOptionAllowUsers ? AIPrivacyTypePermit : AIPrivacyTypeDeny;
				if ([[acct listObjectsOnPrivacyList:privType] containsObject:contact]) {
					//title: "Unblock"; enabled
					if (!unblock && AIPrivacyTypePermit == privType) {
						[menuItem setTitle:BLOCK_CONTACT];
					}
					else if (unblock && AIPrivacyTypeDeny == privType) {
						[menuItem setTitle:UNBLOCK_CONTACT];
					}
					return YES;
				} else {
					//title: "Block"; enabled
					if (!unblock && AIPrivacyTypePermit == privType)
						[menuItem setTitle:UNBLOCK_CONTACT];
					else if (unblock && AIPrivacyTypeDeny == privType)
						[menuItem setTitle:BLOCK_CONTACT];
					return YES;
				}
			} else {
				//title: "Block"; disabled
				[menuItem setTitle:BLOCK_CONTACT];
				return NO;
			}
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Private
//Private --------------------------------------------------------------------------------------------------------------

- (void)_blockContact:(AIListContact *)contact unblock:(BOOL)unblock
{
	//We want to block on all accounts with the same service class. If you want someone gone, you want 'em GONE.
	NSEnumerator	*enumerator = [[[adium accountController] accountsCompatibleWithService:[contact service]] objectEnumerator];
	AIAccount<AIAccount_Privacy>	*account = nil;
	AIListContact	*sameContact = nil;
	
	while ((account = [enumerator nextObject])) {
		sameContact = [account contactWithUID:[contact UID]];
		if ([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
			
			if (sameContact){ 
				if ([account privacyOptions] == AIPrivacyOptionDenyUsers)
					[sameContact setIsBlocked:!unblock updateList:YES];
				else
					[sameContact setIsAllowed:unblock updateList:YES];
			}
		}
	}
}

- (BOOL)_searchPrivacyListsForListContact:(AIListContact *)contact withDesiredResult:(BOOL)desiredResult
{
	AIAccount *account = nil;
	NSEnumerator *enumerator;
	
	enumerator = [[[adium accountController] accountsCompatibleWithService:[contact service]] objectEnumerator];
	
	while ((account = [enumerator nextObject])) {
		if ([account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
			AIAccount <AIAccount_Privacy> *privacyAccount = (AIAccount <AIAccount_Privacy> *)account;
			if ([[privacyAccount listObjectIDsOnPrivacyList:AIPrivacyTypeDeny] containsObject:[contact UID]] == desiredResult) {
				return YES;
			}
		}
	}
	return NO;
}

/*!
 * @brief Inform AIListContact instances of the user's intended privacy towards the people they represent
 */
- (void)accountConnected:(NSNotification *)notification
{
	//NSLog(@"account connected: %@", notification);
	
	AIAccount		*accountConnected = [notification object];
	NSEnumerator	*contactEnumerator = nil;
	AIListContact	*currentContact = nil;
	
	if ([accountConnected conformsToProtocol:@protocol(AIAccount_Privacy)]) {
		
		//check if each contact is on the account's deny list
		contactEnumerator = [[accountConnected contacts] objectEnumerator];
		while ((currentContact = [contactEnumerator nextObject])) {
			//NSLog(@"The current contact is: %@", currentContact);
			
			if ([[(AIAccount <AIAccount_Privacy> *)accountConnected listObjectIDsOnPrivacyList:AIPrivacyTypeDeny] containsObject:[currentContact UID]]) {
				//inform the contact that they're blocked
				[currentContact setIsBlocked:YES updateList:NO];
				//NSLog(@"** %@ is blocked **", [currentContact formattedUID]);
			} else {
				[currentContact setIsBlocked:NO updateList:NO];
			}
		}
	}
}

/*!
 * @brief Determine if all the referenced contacts are blocked or unblocked
 *
 * @param contacts The contacts to query
 * @result A flag indicating if all the contacts are blocked or not
 */
- (BOOL)areAllGivenContactsBlocked:(NSArray *)contacts
{
	NSEnumerator	*contactEnumerator = [contacts objectEnumerator];
	AIListContact	*currentContact = nil;
	BOOL			areAllGivenContactsBlocked = YES;
	
	//for each contact in the array
	while ((currentContact = [contactEnumerator nextObject])) {
		
		//if the contact is unblocked, then all the contacts in the array aren't blocked
		if (![currentContact isBlocked]) {
			areAllGivenContactsBlocked = NO;
			break;
		}
	}
	
	return areAllGivenContactsBlocked;
}

/*!
 * @brief Block or unblock participants of the active chat in a chat window
 *
 * If all the participants of the chat are blocked, attempt to unblock each
 * Else, attempt to block those that are not already blocked.
 * Then, Update the item for the chat.
 *
 * We have to do it this way because a user can (un)block participants of 
 * a chat window in the background by command-clicking the toolbar item.
 *
 * @param senderItem The toolbar item that received the event
 */
- (IBAction)blockOrUnblockParticipants:(NSToolbarItem *)senderItem
{
	NSEnumerator	*windowEnumerator = [[NSApp windows] objectEnumerator];
	NSWindow		*currentWindow = nil;
	NSToolbar		*windowToolbar = nil;
	NSToolbar		*senderToolbar = [senderItem toolbar];
	AIChat			*activeChatInWindow = nil;
	NSArray			*participants = nil;
	
	//for each open window
	while ((currentWindow = [windowEnumerator nextObject])) {

		//if it has a toolbar
		if ((windowToolbar = [currentWindow toolbar])) {

			//do the toolbars match?
			if (windowToolbar == senderToolbar) {
				activeChatInWindow = [[adium interfaceController] activeChatInWindow:currentWindow];
				participants = [activeChatInWindow participatingListObjects];
				
				//do the deed
				[self setPrivacy:(![self areAllGivenContactsBlocked:participants]) forContacts:participants];
				[self updateToolbarItem:senderItem forChat:activeChatInWindow];
				break;
			}
		}
	}
}

#pragma mark -
#pragma mark Protocols

/*!
 * @brief Update any chat with the list object
 *
 * If the list object is (un)blocked, update any chats that we my have open with it.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inModifiedKeys containsObject:@"isBlocked"]) {
		[self updateToolbarItemForObject:inObject];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Notifications

/*!
 * @brief Toolbar has added an instance of the chat block toolbar item
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if ([[item itemIdentifier] isEqualToString:TOOLBAR_ITEM_IDENTIFIER]) {
		
		//If this is the first item added, start observing for chats becoming visible so we can update the item
		if ([chatToolbarItems count] == 0) {
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatDidBecomeVisible:)
											   name:@"AIChatDidBecomeVisible"
											 object:nil];
		}
		
		[self updateToolbarItem:item forChat:[[adium interfaceController] activeChat]];
		[chatToolbarItems addObject:item];
	}
}

/*!
 * @brief A toolbar item was removed
 */
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	[chatToolbarItems removeObject:item];
	
	if ([chatToolbarItems count] == 0) {
		[[adium notificationCenter] removeObserver:self
											  name:@"AIChatDidBecomeVisible"
											object:nil];
	}
}

/*!
 * @brief A chat became visible in a window.
 *
 * Update the window's (un)block toolbar item to reflect the block state of a list object
 *
 * @param notification Notification with an AIChat object and an @"NSWindow" userInfo key
 */
- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	[self updateToolbarIconOfChat:[notification object]
						  inWindow:[[notification userInfo] objectForKey:@"NSWindow"]];
}

#pragma mark -
#pragma mark Toolbar Item Update Methods

/*!
 * @brief Update the toolbar icon in a chat for a particular contact
 *
 * @param inObject The list object we want to update the toolbar item for
 */
- (void)updateToolbarItemForObject:(AIListObject *)inObject
{
	AIChat		*chat = nil;
	NSWindow	*window = nil;
	
	//Update the icon in the toolbar for this contact if a chat is open and we have any toolbar items
	if (([chatToolbarItems count] > 0) &&
		[inObject isKindOfClass:[AIListContact class]] &&
		(chat = [[adium chatController] existingChatWithContact:(AIListContact *)inObject]) &&
		(window = [[adium interfaceController] windowForChat:chat])) {
		[self updateToolbarIconOfChat:chat
							 inWindow:window];
	}
}

/*!
 * @brief Update the toolbar item for the particpants of a particular chat
 *
 * @param item The toolbar item to modify
 * @param chat The chat for which the participants are participating in
 */
- (void)updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat
{
	if ([self areAllGivenContactsBlocked:[chat participatingListObjects]]) {
		//assume unblock appearance
		[item setLabel:UNBLOCK_CONTACT];
		[item setPaletteLabel:UNBLOCK_CONTACT];
		[item setImage:[blockedToolbarIcons valueForKey:TOOLBAR_UNBLOCK_ICON_KEY]];
	} else {
		//assume block appearance
		[item setLabel:BLOCK_CONTACT];
		[item setPaletteLabel:BLOCK_CONTACT];
		[item setImage:[blockedToolbarIcons valueForKey:TOOLBAR_BLOCK_ICON_KEY]];
	}
}

/*!
 * @brief Update the (un)block toolbar icon in a chat
 *
 * @param chat The chat with the participants
 * @param window The window in which the chat resides
 */
- (void)updateToolbarIconOfChat:(AIChat *)chat inWindow:(NSWindow *)window
{
	NSToolbar		*toolbar = [window toolbar];
	NSEnumerator	*enumerator = [[toolbar items] objectEnumerator];
	NSToolbarItem	*item;
	
	while ((item = [enumerator nextObject])) {
		if ([[item itemIdentifier] isEqualToString:TOOLBAR_ITEM_IDENTIFIER]) {
			[self updateToolbarItem:item forChat:chat];
			break;
		}
	}
}

@end
