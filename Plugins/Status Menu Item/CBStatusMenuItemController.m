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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListObject.h>
#import "CBStatusMenuItemController.h"
#import "AIMenuBarIcons.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIAccountMenu.h>
#import <Adium/AIContactMenu.h>
#import <AIUtilities/AIColorAdditions.h>
#import <Adium/AIPreferenceControllerProtocol.h>

#define STATUS_ITEM_MARGIN 8

@interface CBStatusMenuItemController (PRIVATE)
- (void)activateAdium:(id)sender;
- (void)setIconImage:(NSImage *)inImage;
- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)inImage;
- (void)updateMenuIcons;
- (void)updateMenuIconsBundle;
- (void)updateUnreadCount;
@end

@implementation CBStatusMenuItemController

+ (CBStatusMenuItemController *)statusMenuItemController
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		//Create and set up the status item
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
		[statusItem setHighlightMode:YES];
		
		unviewedContent = NO;
		[self updateMenuIconsBundle];
		
		//Create and install the menu
		theMenu = [[NSMenu alloc] init];
		[theMenu setAutoenablesItems:YES];
		[statusItem setMenu:theMenu];
		[theMenu setDelegate:self];
		
		//Setup for open chats and unviewed content catching
		accountMenuItemsArray = [[NSMutableArray alloc] init];
		stateMenuItemsArray = [[NSMutableArray alloc] init];
		unviewedObjectsArray = [[NSMutableArray alloc] init];
		openChatsArray = [[NSMutableArray alloc] init];
		contactMenuItemsArray = [[NSMutableArray alloc] init];
		needsUpdate = YES;
		contactListOpen = [[adium interfaceController] contactListIsVisible];
		
		NSNotificationCenter *notificationCenter = [adium notificationCenter];
		//Register to recieve chat opened and chat closed notifications
		[notificationCenter addObserver:self
		                       selector:@selector(chatOpened:)
		                           name:Chat_DidOpen
		                         object:nil];
		[notificationCenter addObserver:self
		                       selector:@selector(chatClosed:)
		                           name:Chat_WillClose
		                         object:nil];
		
		[notificationCenter addObserver:self
							   selector:@selector(statusIconSetDidChange:)
								   name:AIStatusIconSetDidChangeNotification
								 object:nil];
		
		// Register for contact list open and close notifications
		[notificationCenter addObserver:self
							   selector:@selector(contactListDidClose:)
								   name:Interface_ContactListDidClose
								 object:nil];
		
		[notificationCenter addObserver:self
							   selector:@selector(contactListDidOpen:)
								   name:Interface_ContactListDidBecomeMain
								 object:nil];
		
		// Register for our menu bar icon set changing
		[[adium notificationCenter] addObserver:self
									   selector:@selector(menuBarIconsDidChange:)
										   name:AIMenuBarIconsDidChangeNotification
										 object:nil];
		
		//Register as a chat observer (So we can catch the unviewed content status flag)
		[[adium chatController] registerChatObserver:self];
		
		//Register to recieve active state changed notifications
		[notificationCenter addObserver:self
		                       selector:@selector(accountStateChanged:)
		                           name:AIStatusActiveStateChangedNotification
		                         object:nil];
		
		//Register ourself for the status menu items
		statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];
		
		//Account menu
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
												  submenuType:AIAccountStatusSubmenu
											   showTitleVerbs:NO] retain];
		
		//Contact menu
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self
										  forContactsInObject:[[adium contactController] contactList]] retain];
	}
	
	return self;
}

- (void)dealloc
{
	//Unregister ourself
	[[adium chatController] unregisterChatObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	//Release our objects
	[[statusItem statusBar] removeStatusItem:statusItem];

	// All the temporary NSMutableArrays we store
	[accountMenuItemsArray release];
	[stateMenuItemsArray release];
	[unviewedObjectsArray release];
	[openChatsArray release];
	[contactMenuItemsArray release];
	
	// The main menu
	[theMenu release];
	
	// Release our various menus.
	[accountMenu release];
	[contactMenu release];
	[statusMenu release];
	
	// Release our AIMenuBarIcons bundle
	[menuIcons release];
	
	// Invalidate and release the unviewed content flash NSTimer
	[unviewedContentFlash invalidate];
	[unviewedContentFlash release];

	// Can't release this because it causes a crash on quit. rdar://4139755, rdar://4160625, and #743. --boredzo
	// [statusItem release];
	
	//To the superclass, Robin!
	[super dealloc];
}

//Icon State --------------------------------------------------------
#pragma mark Icon State

#define PREF_GROUP_APPEARANCE		@"Appearance"
#define	KEY_MENU_BAR_ICONS			@"Menu Bar Icons"
#define EXTENSION_MENU_BAR_ICONS	@"AdiumMenuBarIcons"
#define	RESOURCE_MENU_BAR_ICONS		@"Menu Bar Icons"

- (void)updateMenuIconsBundle
{
	NSString *menuIconPath = nil, *menuIconName;
	
	menuIconName = [[adium preferenceController] preferenceForKey:KEY_MENU_BAR_ICONS
															group:PREF_GROUP_APPEARANCE
														   object:nil];
	
	// Get the path of the pack if found.
	if (menuIconName) {
		menuIconPath = [adium pathOfPackWithName:menuIconName
									   extension:EXTENSION_MENU_BAR_ICONS
							  resourceFolderName:RESOURCE_MENU_BAR_ICONS];
	}
	
	// If the pack is not found, get the default one.
	if (!menuIconPath || !menuIconName) {
		menuIconName = [[adium preferenceController] defaultPreferenceForKey:KEY_MENU_BAR_ICONS
																	   group:PREF_GROUP_APPEARANCE
																	  object:nil];																	  
		menuIconPath = [adium pathOfPackWithName:menuIconName
									   extension:EXTENSION_MENU_BAR_ICONS
							  resourceFolderName:RESOURCE_MENU_BAR_ICONS];
	}
	
	[menuIcons release];
	menuIcons = [[AIMenuBarIcons alloc] initWithURL:[NSURL fileURLWithPath:menuIconPath]];
	
	[self updateMenuIcons];
}

// Updates the unread count of the status item.
- (void)updateUnreadCount
{
	// Use AIChatController's method instead of our our array of unread chats (unviewedObjectsArray)
	// so we can get the true number of unread messages.
	int unreadCount = [[adium chatController] unviewedContentCount];

	// Only show if greater-than zero, otherwise set to nil.
	if (unreadCount > 0) {
		[statusItem setTitle:[NSString stringWithFormat:@"%i", unreadCount]];
	} else {
		[statusItem setTitle:@""];
	}
}

// Flashes unviewed content.
- (void)updateUnviewedContentFlash:(NSTimer *)timer
{
	// Invert our current setting
	currentlyIgnoringUnviewed = !currentlyIgnoringUnviewed;
	// Update our current menu icon
	[self updateMenuIcons];
}

#define	IMAGE_TYPE_CONTENT		@"Content"
#define	IMAGE_TYPE_AWAY			@"Away"
#define IMAGE_TYPE_IDLE			@"Idle"
#define	IMAGE_TYPE_INVISIBLE	@"Invisible"
#define	IMAGE_TYPE_OFFLINE		@"Offline"
#define	IMAGE_TYPE_ONLINE		@"Online"

- (void)updateMenuIcons
{
	NSImage			*badge = nil;
	BOOL			showBadge = [menuIcons showBadge], isIdle;
	NSString		*imageName;
	NSEnumerator	*enumerator;
	AIAccount		*account;

	// If there's content, set our badge to the "content" icon.
	if (unviewedContent && !currentlyIgnoringUnviewed) {
		if (showBadge) {
			badge = [AIStatusIcons statusIconForStatusName:@"content"
												statusType:AIAvailableStatusType
											      iconType:AIStatusIconList
												 direction:AIIconNormal];
		}
		
		imageName = IMAGE_TYPE_CONTENT;
	} else {
		// Get the correct icon for our current state.
		switch([[[adium statusController] activeStatusState] statusType]) {
			case AIAwayStatusType:
				if (showBadge) {
					badge = [[[adium statusController] activeStatusState] icon];
				}
				
				imageName = IMAGE_TYPE_AWAY;
				break;
			
			case AIInvisibleStatusType:
				if (showBadge) {
					badge = [[[adium statusController] activeStatusState] icon];
				}
				
				imageName = IMAGE_TYPE_INVISIBLE;
				break;
				
			case AIOfflineStatusType:
				imageName = IMAGE_TYPE_OFFLINE;
				break;
				
			default:
				// Check idle here, since it has less precedence than offline, invisible, or away.
				isIdle = FALSE;
				enumerator = [[[adium accountController] accounts] objectEnumerator];
				
				// Check each account for IdleSince
				while ((account = [enumerator nextObject])) {
					if ([account online] && [account statusObjectForKey:@"IdleSince"]) {
						isIdle = TRUE;
						break;
					}
				}
				
				// If any of the accounts were idle...
				if (isIdle) {
					if (showBadge) {
						badge = [AIStatusIcons statusIconForStatusName:@"Idle"
															statusType:AIAvailableStatusType
															  iconType:AIStatusIconList
															 direction:AIIconNormal];
					}
					
					imageName = IMAGE_TYPE_IDLE;
				} else {
					// Show badge if an available message is set.
					if (showBadge) {
						enumerator = [[[adium accountController] accounts] objectEnumerator];
						
						while ((account = [enumerator nextObject])) {
							// If the account has a status message...
							if ([account online] && [[account statusObjectForKey:@"StatusState"] statusMessage]) {
								// Set the badge for the "available" status.
								badge = [[[adium statusController] activeStatusState] icon];
								break;
							}
						}
					}
				
					imageName = IMAGE_TYPE_ONLINE;
				}
				break;
		}
	}
	
	NSImage *menuIcon = [menuIcons imageOfType:imageName alternate:NO];
	NSImage *alternateMenuIcon = [menuIcons imageOfType:imageName alternate:YES];
	
	// Set our icon.
	[statusItem setImage:[self badgeDuck:menuIcon withImage:badge]];
	// Badge the highlight image and set it.
	[statusItem setAlternateImage:[self badgeDuck:alternateMenuIcon withImage:badge]];
	// Update our unread count.
	[self updateUnreadCount];
}

- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)badgeImage 
{
	NSImage *image = duckImage;
	
	if (badgeImage) {
		image = [[duckImage copy] autorelease];
		
		[image lockFocus];
		
		NSRect srcRect = { NSZeroPoint, [badgeImage size] };
		//Draw in the lower-right quadrant.
		NSRect destRect = {
			{ .x = srcRect.size.width, .y = 0.0 },
			[duckImage size]
		};
		destRect.size.width  *= 0.5;
		destRect.size.height *= 0.5;
		
		//If the badge is bigger than that portion, resize proportionally. Otherwise, leave it alone and adjust the destination origin appropriately.
		if ((srcRect.size.width > destRect.size.width) || (srcRect.size.height > destRect.size.height)) {
			//Resize the dest rect.
			float scale;
			if (srcRect.size.width > srcRect.size.height) {
				scale = destRect.size.width  / srcRect.size.width;
			} else {
				scale = destRect.size.height / srcRect.size.height;
			}
			
			destRect.size.width  = srcRect.size.width  * scale;
			destRect.size.height = srcRect.size.height * scale;
			
			//Make sure we scale in a pretty manner.
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		}
		
		//Move the drawing origin.
		destRect.origin.x = [duckImage size].width - destRect.size.width;
		
		[badgeImage drawInRect:destRect
					  fromRect:srcRect
					 operation:NSCompositeSourceOver
					  fraction:1.0];
		[image unlockFocus];
	}
	
	return image;
}

//Account Menu --------------------------------------------------------
#pragma mark Account Menu
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	[accountMenuItemsArray release];
	accountMenuItemsArray = [menuItems retain];
	
	//We need to update next time we're clicked
	needsUpdate = YES;
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[inAccount toggleOnline];
}


//StateMenuPlugin --------------------------------------------------------
#pragma mark StateMenuPlugin
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	//Pull 'em out!
	[stateMenuItemsArray removeAllObjects];
	
	//Stick 'em in!
	[stateMenuItemsArray addObjectsFromArray:menuItemArray];
	
	//We need to update next time we're clicked
	needsUpdate = YES;
}

- (BOOL)showStatusSubmenu
{
	return YES;
}

//Chat Observer --------------------------------------------------------
#pragma mark Chat Observer

- (void)chatOpened:(NSNotification *)notification
{
	//Add it to the array
	[openChatsArray addObject:[notification object]];
	
	//We need to update the menu next time we are clicked
	needsUpdate = YES;
}

- (void)chatClosed:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	//Remove it from the array
	[openChatsArray removeObjectIdenticalTo:chat];
	
	[unviewedObjectsArray removeObjectIdenticalTo:chat];
	
	int index = [theMenu indexOfItemWithRepresentedObject:chat];
	if (index != -1) {
		[theMenu removeItemAtIndex:index];
		/* Check to see if we have no openChats left, in which case we
		 * need to remove the extra menu seperator, which is now in the index'th spot.
		 */
		if (([openChatsArray count] == 0) && [[theMenu itemAtIndex:index] isSeparatorItem]) {
			[theMenu removeItemAtIndex:index];
		}
	}
}

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	//If the contact's unviewed content state has changed
	if (inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		//If there is new unviewed content
		if ([inChat unviewedContentCount]) {
			//If we're not already watching it
			if (![unviewedObjectsArray containsObjectIdenticalTo:inChat]) {
				//Add it, we're watching it now
				[unviewedObjectsArray addObject:inChat];
				//We need to update our menu
				needsUpdate = YES;
			}
			//If they've viewed the content
		} else {
			//If we're tracking this object
			if ([unviewedObjectsArray containsObjectIdenticalTo:inChat]) {
				//Remove it, it's not unviewed anymore
				[unviewedObjectsArray removeObjectIdenticalTo:inChat];
				//We need to update our menu
				needsUpdate = YES;
			}
		}
	}
	
	if ([unviewedObjectsArray count] == 0) {
		//If there are no more contacts with unviewed content, set our icon to normal.
		if (unviewedContent) {
			[unviewedContentFlash invalidate];
			[unviewedContentFlash release]; unviewedContentFlash = nil;
			currentlyIgnoringUnviewed = NO;
			unviewedContent = NO;
			[self updateMenuIcons];
		}
	} else {
		//If this is the first contact with unviewed content, set our icon to unviewed content.
		if (!unviewedContent) {
			if ([menuIcons flashUnviewed]) {
				currentlyIgnoringUnviewed = NO;
				unviewedContentFlash = [[NSTimer scheduledTimerWithTimeInterval:1.0
																		 target:self
																	   selector:@selector(updateUnviewedContentFlash:)
																	   userInfo:nil
																		repeats:YES] retain];
			}
			unviewedContent = YES;
			[self updateMenuIcons];
		} else {
			// Update our unread count.
			[self updateUnreadCount];
		}
	}
	
	//If they're typing, we also need to update because we show typing within the menu itself next to chats.
	if ([inModifiedKeys containsObject:KEY_TYPING]) {
		needsUpdate = YES;
	}
	
	//We didn't modify attributes, so return nil
	return nil;
}

//Delegates --------------------------------------------------------
#pragma mark Delegates
- (void)contactMenu:(AIContactMenu *)inContactMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[contactMenuItemsArray release];
	contactMenuItemsArray = [menuItems retain];

	// Update the next time we're clicked.
	needsUpdate = YES;
}

- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact
{
	[[adium interfaceController] setActiveChat:[[adium chatController] openChatWithContact:inContact
							 onPreferredAccount:YES]];
	[self activateAdium:nil];
}

- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact
{
	// Show only online contacts.
	return [inContact online];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	//If something has changed
	if (needsUpdate && menu == theMenu) {
		NSEnumerator    *enumerator;
		NSMenuItem      *menuItem;
		AIChat          *chat;
		
		//Clear out all the items, start from scratch
		[menu removeAllItems];
		
		//Add the state menu items
		enumerator = [stateMenuItemsArray objectEnumerator];
		menuItem = nil;
		while ((menuItem = [enumerator nextObject])) {
			[menu addItem:menuItem];
			
			//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
			if ([[menuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
				[[menuItem target] validateMenuItem:menuItem];
			}
		}
		
		// If there's more than one account, show the accounts menu
		if ([accountMenuItemsArray count] > 1) {
			NSMenu *accountsMenu = [[[NSMenu alloc] init] autorelease];
			NSMenuItem	*accountMenuItem;
			
			[menu addItem:[NSMenuItem separatorItem]];
			
			menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Accounts",nil)
																			 target:self
																			 action:nil
																	  keyEquivalent:@""] autorelease];
			
			//Add the account menu items
			enumerator = [accountMenuItemsArray objectEnumerator];
			while ((accountMenuItem = [enumerator nextObject])) {
				NSMenu	*submenu;
				
				[accountsMenu addItem:accountMenuItem];
				
				//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
				if ([[accountMenuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
					[[accountMenuItem target] validateMenuItem:accountMenuItem];
				}
				
				submenu = [accountMenuItem submenu];
				if (submenu) {
					NSEnumerator	*submenuEnumerator = [[submenu itemArray] objectEnumerator];
					NSMenuItem		*submenuItem;
					while ((submenuItem = [submenuEnumerator nextObject])) {
						//Validate the submenu items as they are added since they weren't previously validated when the menu was clicked
						if ([[submenuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
							[[submenuItem target] validateMenuItem:submenuItem];
						}
					}
				}
			}
			
			[menuItem setSubmenu:accountsMenu];
			[menu addItem:menuItem];
		}
		
		//If there exist any open chats, add them
		if ([openChatsArray count] > 0) {
			enumerator = [openChatsArray objectEnumerator];
			chat = nil;
			
			//Add a seperator
			[menu addItem:[NSMenuItem separatorItem]];
			
			//Create and add the menu items
			while ((chat = [enumerator nextObject])) {
				NSImage *image = nil;
				
				//Create a menu item from the chat
				menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[chat displayName]
				                                                                 target:self
				                                                                 action:@selector(switchToChat:)
				                                                          keyEquivalent:@""] autorelease];
				//Set the represented object
				[menuItem setRepresentedObject:chat];
				
				//If there is a chat status image, use that
				if (!(image = [AIStatusIcons statusIconForChat:chat type:AIStatusIconMenu direction:AIIconNormal])) {
					//Otherwise use the contact's status image
					image = [AIStatusIcons statusIconForListObject:[chat listObject]
					                                          type:AIStatusIconMenu
					                                     direction:AIIconNormal];
				}
				//Set the image
				[menuItem setImage:image];
				
				//Add it to the menu
				[menu addItem:menuItem];
			}
		}
		
		// Show the contacts menu if we have any contacts to display
		if ([contactMenuItemsArray count] > 0) {
			NSMenu			*contactsMenu = [[[NSMenu alloc] init] autorelease];
			NSEnumerator	*enumerator = [contactMenuItemsArray objectEnumerator];
			NSMenuItem		*contactMenuItem;
			
			[menu addItem:[NSMenuItem separatorItem]];
			
			// Add contacts
			menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Contacts",nil)
																			 target:self
																			 action:nil
																	  keyEquivalent:@""] autorelease];

			while ((contactMenuItem = [enumerator nextObject])) {
				[contactsMenu addItem:contactMenuItem];
				
				//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
				if ([[contactMenuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
					[[contactMenuItem target] validateMenuItem:contactMenuItem];
				}
			}
			
			[menuItem setSubmenu:contactsMenu];
			[menu addItem:menuItem];
		}
		
		//Add our last two items
		[menu addItem:[NSMenuItem separatorItem]];
		
		if (contactListOpen) {
			[menu addItemWithTitle:AILocalizedString(@"Hide Contact List", nil)
							target:self
							action:@selector(hideContactList:)
					 keyEquivalent:@""];
		} else {
			[menu addItemWithTitle:AILocalizedString(@"Show Contact List", nil)
							target:self
							action:@selector(activateContactList:)
					 keyEquivalent:@""];
		}
		
		[menu addItemWithTitle:AILocalizedString(@"Bring Adium to Front",nil)
		                target:self
		                action:@selector(activateAdium:)
		         keyEquivalent:@""];

		[menu addItem:[NSMenuItem separatorItem]];
		
		[menu addItemWithTitle:AILocalizedString(@"Quit Adium",nil)
		                target:NSApp
		                action:@selector(terminate:)
		         keyEquivalent:@""];
		
		//Only update next time if we need to
		needsUpdate = NO;
	}
}

// Contact List Notifications

#pragma mark Contact List Notifications
- (void)contactListDidClose:(id)sender
{
	contactListOpen = NO;
	needsUpdate = YES;
}

- (void)contactListDidOpen:(id)sender
{
	contactListOpen = YES;
	needsUpdate = YES;
}

//Menu Actions --------------------------------------------------------
#pragma mark Menu Actions
- (void)switchToChat:(id)sender
{
	//If we're not the active app, activate
	if (![NSApp isActive]) {
		[self activateAdium:nil];
	}
	
	[[adium interfaceController] setActiveChat:[sender representedObject]];
}

- (void)activateAdium:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp arrangeInFront:nil];
}

- (void)activateContactList:(id)sender
{
	[[adium interfaceController] showContactList:nil];
	// Bring Adium to front if it's not the active app.
	if (![NSApp isActive]) {
		[self activateAdium:nil];
	}
}

- (void)hideContactList:(id)sender
{
	[[adium interfaceController] closeContactList:nil];
}

#pragma mark -

- (void)accountStateChanged:(NSNotification *)notification
{
	[self updateMenuIcons];
}

- (void)statusIconSetDidChange:(NSNotification *)notification
{
	[self updateMenuIcons];
}

- (void)menuBarIconsDidChange:(NSNotification *)notification
{
	[self updateMenuIconsBundle];
}
@end
