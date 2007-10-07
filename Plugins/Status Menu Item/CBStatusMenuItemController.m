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
- (void)updateOpenChats;
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
		openChatsArray = [[NSMutableArray alloc] init];
		contactMenuItemsArray = [[NSMutableArray alloc] init];
		needsUpdate = YES;
		
		NSNotificationCenter *notificationCenter = [adium notificationCenter];
		//Register to recieve chat opened and chat closed notifications
		[notificationCenter addObserver:self
		                       selector:@selector(updateOpenChats)
		                           name:Chat_DidOpen
		                         object:nil];
		[notificationCenter addObserver:self
		                       selector:@selector(updateOpenChats)
		                           name:Chat_WillClose
		                         object:nil];
		[notificationCenter addObserver:self
		                       selector:@selector(updateOpenChats)
		                           name:Chat_OrderDidChange
		                         object:nil];		
		
		[notificationCenter addObserver:self
							   selector:@selector(updateMenuIcons)
								   name:AIStatusIconSetDidChangeNotification
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
		                       selector:@selector(updateMenuIcons)
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


//Status Menu --------------------------------------------------------
#pragma mark Status Menu
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	[stateMenuItemsArray release];
	stateMenuItemsArray = [menuItemArray retain];
	
	//We need to update next time we're clicked
	needsUpdate = YES;
}

//Contact Menu --------------------------------------------------------
#pragma mark Contact Menu
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


//Chat Observer --------------------------------------------------------
#pragma mark Chat Observer

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	[self updateOpenChats];
	
	// We didn't modify anything; return nil.
	return nil;
}

- (void)updateOpenChats
{
	int unviewedContentCount = [[adium chatController] unviewedContentCount];

	// Update our open chats
	[openChatsArray release];
	openChatsArray = [[[adium interfaceController] openChats] retain];
	
	// We think there's unviewed content, but there's not.
	if (unviewedContent && unviewedContentCount == 0) {
		// Invalidate and release the unviewed content flash timer
		[unviewedContentFlash invalidate];
		[unviewedContentFlash release]; unviewedContentFlash = nil;
		currentlyIgnoringUnviewed = NO;
		
		// Update unviewed content
		unviewedContent = NO;
		
		// Update our menu icons
		[self updateMenuIcons];
	// We think there's no unviewed content, and there is.
	} else if (!unviewedContent && unviewedContentCount > 0) {
		// If this particular Xtra wants us to flash unviewed content, start the timer up
		if ([menuIcons flashUnviewed]) {
			currentlyIgnoringUnviewed = NO;
			unviewedContentFlash = [[NSTimer scheduledTimerWithTimeInterval:1.0
																	 target:self
																   selector:@selector(updateUnviewedContentFlash:)
																   userInfo:nil
																	repeats:YES] retain];
		}
		
		// Update unviewed content
		unviewedContent = YES;
		
		// Update our menu icons
		[self updateMenuIcons];
	// If we already know there's unviewed content, just update the count.
	} else if (unviewedContent && unviewedContentCount > 0) {
		[self updateUnreadCount];
	}

	needsUpdate = YES;	
}

//Menu Delegates/Actions --------------------------------------------------------
#pragma mark Menu Delegates/Actions
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
		
		if ([accountMenuItemsArray count] > 1 || [contactMenuItemsArray count] > 0)
			[menu addItem:[NSMenuItem separatorItem]];
		
		// If there's more than one account, show the accounts menu
		if ([accountMenuItemsArray count] > 1) {
			NSMenu *accountsMenu = [[[NSMenu alloc] init] autorelease];
			NSMenuItem	*accountMenuItem;
			
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Accounts",nil)
																			 target:self
																			 action:nil
																	  keyEquivalent:@""];
			
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
			[menuItem release];
		}
		
		// Show the contacts menu if we have any contacts to display
		if ([contactMenuItemsArray count] > 0) {
			NSMenu			*contactsMenu = [[[NSMenu alloc] init] autorelease];
			NSEnumerator	*enumerator = [contactMenuItemsArray objectEnumerator];
			NSMenuItem		*contactMenuItem;
			
			// Add contacts
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Contacts",nil)
																			 target:self
																			 action:nil
																	  keyEquivalent:@""];

			while ((contactMenuItem = [enumerator nextObject])) {
				[contactsMenu addItem:contactMenuItem];
				
				//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
				if ([[contactMenuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
					[[contactMenuItem target] validateMenuItem:contactMenuItem];
				}
			}
			
			[menuItem setSubmenu:contactsMenu];
			[menu addItem:menuItem];
			[menuItem release];
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
				menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[chat displayName]
																				target:self
																				action:@selector(switchToChat:)
																		 keyEquivalent:@""];
				//Set the represented object
				[menuItem setRepresentedObject:chat];
				
				//Set the image
				
				//If there is a chat status image, use that
				image = [AIStatusIcons statusIconForChat:chat type:AIStatusIconMenu direction:AIIconNormal];
				//Otherwise use the chat's -chatMenuImage
				if (!image) {
					image = [chat chatMenuImage];
				}
				
				[menuItem setImage:image];
				
				//Add it to the menu
				[menu addItem:menuItem];
				[menuItem release];
			}
		}
		
		//Add our last few items
		[menu addItem:[NSMenuItem separatorItem]];
		
		[menu addItemWithTitle:AILocalizedString(@"Contact List", nil)
						target:self
						action:@selector(activateContactList:)
				 keyEquivalent:@""];
		
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

- (void)switchToChat:(id)sender
{
	[self activateAdium:nil];
	[[adium interfaceController] setActiveChat:[sender representedObject]];
}

- (void)activateContactList:(id)sender
{
	[self activateAdium:nil];
	[[adium interfaceController] showContactList:nil];
}

- (void)activateAdium:(id)sender
{
	if (![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
		[NSApp arrangeInFront:nil];
	}
}

#pragma mark -

- (void)menuBarIconsDidChange:(NSNotification *)notification
{
	[self updateMenuIconsBundle];
}
@end
