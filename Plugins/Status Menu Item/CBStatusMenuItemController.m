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
#import "CBStatusMenuItemPlugin.h"
#import "CBStatusMenuItemController.h"
#import "AIMenuBarIcons.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIEventAdditions.h>
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
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIPreferenceControllerProtocol.h>
// For the KEY_SHOW_OFFLINE_CONTACTS and PREF_GROUP_CONTACT_LIST_DISPLAY
#import "AIContactController.h"

@interface CBStatusMenuItemController (PRIVATE)
- (void)activateAdium:(id)sender;
- (void)setIconImage:(NSImage *)inImage;
- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)inImage;
- (void)updateMenuIcons;
- (void)updateMenuIconsBundle;
- (void)updateUnreadCount;
- (void)updateOpenChats;
- (void)updateStatusItemLength;
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
		
		// Create our menus
		mainMenu = [[NSMenu alloc] init];
		[mainMenu setDelegate:self];

		mainContactsMenu = [[NSMenu alloc] init];
		[mainContactsMenu setDelegate:self];

		mainAccountsMenu = [[NSMenu alloc] init];
		[mainAccountsMenu setDelegate:self];

		// Set the main menu as the status item's menu
		[statusItem setMenu:mainMenu];
		
		// Create the caches for our menu items
		accountMenuItemsArray = [[NSMutableArray alloc] init];
		stateMenuItemsArray = [[NSMutableArray alloc] init];
		openChatsArray = [[NSMutableArray alloc] init];
		contactMenuItemsArray = [[NSMutableArray alloc] init];

		// Flag all the menus as needing updates
		mainMenuNeedsUpdate = YES;
		contactsMenuNeedsUpdate = YES;
		accountsMenuNeedsUpdate = YES;
		
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
		
		// Register as a chat observer so we can know the status of unread messages
		[[adium chatController] registerChatObserver:self];
		
		// Register as a list object observer so we can know when accounts need to show reconnecting
	    [[adium contactController] registerListObjectObserver:self];
		
		// Register as an observer of the preference group so we can update our "show offline contacts" option
		[[adium preferenceController] registerPreferenceObserver:self
														forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		
		// Register as an observer of our own preference group
		[[adium preferenceController] registerPreferenceObserver:self
														forGroup:PREF_GROUP_STATUS_MENU_ITEM];		
		
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
											   showTitleVerbs:YES] retain];
		
		//Contact menu
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self
										  forContactsInObject:nil] retain];
	}
	
	return self;
}

- (void)dealloc
{
	// Invalidate and release our timers
	[self invalidateTimers];
	
	//Unregister ourself
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium chatController] unregisterChatObserver:self];
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	//Release our objects
	[[statusItem statusBar] removeStatusItem:statusItem];

	// All the temporary NSMutableArrays we store
	[accountMenuItemsArray release];
	[stateMenuItemsArray release];
	[openChatsArray release];
	[contactMenuItemsArray release];
	
	// The menus
	[mainMenu release];
	[mainContactsMenu release];
	[mainAccountsMenu release];
	
	// Release our various menus.
	[accountMenu setDelegate:nil]; [accountMenu release];
	[contactMenu setDelegate:nil]; [contactMenu release];
	[statusMenu setDelegate:nil]; [statusMenu release];

	// Release our AIMenuBarIcons bundle
	[menuIcons release];
	
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

	// Only show if enabled and greater-than zero; otherwise, set to nil.
	if (showUnreadCount && unreadCount > 0) {
		[statusItem setTitle:[NSString stringWithFormat:@"%i", unreadCount]];
	} else {
		[statusItem setTitle:nil];
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

- (void)invalidateTimers
{
	currentlyIgnoringUnviewed = NO;
	[unviewedContentFlash invalidate];
	[unviewedContentFlash release]; unviewedContentFlash = nil;
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
	BOOL			anyAccountHasStatusMessage;
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
				// Online badging order of presence: idle > reconnecting account > status message
				
				// Assuming we're using an online image unless proven otherwise
				imageName = IMAGE_TYPE_ONLINE;

				// Check idle here, since it has less precedence than offline, invisible, or away.
				anyAccountHasStatusMessage = NO;
				enumerator = [[[adium accountController] accounts] objectEnumerator];

				// Check each account for IdleSince, a StatusState status message, or "Waiting to Reconnect"
				while ((account = [enumerator nextObject])) {
					if ([account online] && [account statusObjectForKey:@"IdleSince"]) {
						if (showBadge) {
							badge = [AIStatusIcons statusIconForStatusName:@"Idle"
																statusType:AIAvailableStatusType
																  iconType:AIStatusIconList
																 direction:AIIconNormal];
						}
						
						imageName = IMAGE_TYPE_IDLE;
						
						// We don't need to check anymore; idle has high precedence than offline or available with a status message.
						break;
					} else if (showBadge &&
							   ([account statusObjectForKey:@"Waiting to Reconnect"] ||
								[[account statusObjectForKey:@"Connecting"] boolValue])) {
						badge = [AIStatusIcons statusIconForStatusName:@"Offline"
															statusType:AIOfflineStatusType
															  iconType:AIStatusIconList
															 direction:AIIconNormal];
					} else if ([account online] && [[account statusObjectForKey:@"StatusState"] statusMessage]) {
						anyAccountHasStatusMessage = YES;
					}
				}
				
				// If we already haven't chosen a badge (for example, offline for a reconnecting account)
				// and we have a status message set on any online account, use an online badge
				if (showBadge && !badge && anyAccountHasStatusMessage) {
					badge = [[[adium statusController] activeStatusState] icon];
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
	if (showUnreadCount) {
		[self updateUnreadCount];
	}
	// Update the status item length
	[self updateStatusItemLength];
}

- (void)updateStatusItemLength
{
	if (showUnreadCount && [[adium chatController] unviewedContentCount] > 0) {
		[statusItem setLength:NSVariableStatusItemLength];
	} else {
		//We're showing only the image, so we want the status item to use the menu bar height.
		//Due to a bug in Mac OS X 10.4.10 and 10.5.2, NSVariableStatusItemLength puts too much space on the right side of the image—probably the separator between image and title, even when the title is nil.
		//Until this problem (rdar://problem/5829508) is fixed, we must use NSSquareStatusItemLength instead of NSVariableStatusItemLength.
		[statusItem setLength:NSSquareStatusItemLength];
	}
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
	// Going from or to 1 account requires a main menu update
	if ([accountMenuItemsArray count] == 1 || [menuItems count] == 1)
		mainMenuNeedsUpdate = YES;
	
	
	[accountMenuItemsArray release];
	accountMenuItemsArray = [menuItems retain];
	
	//We need to update next time we're clicked
	accountsMenuNeedsUpdate = YES;
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
	mainMenuNeedsUpdate = YES;
}

//Contact Menu --------------------------------------------------------
#pragma mark Contact Menu
- (void)contactMenu:(AIContactMenu *)inContactMenu didRebuildMenuItems:(NSArray *)menuItems
{
	// Going from or to 0 contacts requires a main menu update
	if ([contactMenuItemsArray count] == 0 || [menuItems count] == 0)
		mainMenuNeedsUpdate = YES;

	[contactMenuItemsArray release];
	contactMenuItemsArray = [menuItems retain];
	
	// Update the next time we're clicked.
	contactsMenuNeedsUpdate = YES;
}

- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact
{
	[[adium interfaceController] setActiveChat:[[adium chatController] openChatWithContact:inContact
																		onPreferredAccount:YES]];
	[self activateAdium:nil];
}

- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact
{
	// Show this contact if we're showing offline contacts or if this contact is online.
	return [inContact visible];
}

- (BOOL)contactMenuShouldDisplayGroupHeaders:(AIContactMenu *)inContactMenu
{
	return showContactGroups;
}

- (BOOL)contactMenuShouldUseDisplayName:(AIContactMenu *)inContactMenu
{
	return YES;
}

- (BOOL)contactMenuShouldUseUserIcon:(AIContactMenu *)inContactMenu
{
	return YES;
}

- (BOOL)contactMenuShouldSetTooltip:(AIContactMenu *)inContactMenu
{
	return YES;
}

//List Object Observer -------------------------------------------------
#pragma mark List Object Observer
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"Connecting"] ||
			[inModifiedKeys containsObject:@"Waiting to Reconnect"]) {
			[self updateMenuIcons];
		}
	}
	
	return nil;
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
	[self retain];
	
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
		if (flashUnviewed) {
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

	mainMenuNeedsUpdate = YES;	
	
	[self release];
}

//Menu Delegates/Actions --------------------------------------------------------
#pragma mark Menu Delegates/Actions
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	// Main menu if not holding option key
	if (![NSEvent optionKey] && (menu == mainMenu && mainMenuNeedsUpdate)) {
		NSEnumerator    *enumerator;
		NSMenuItem      *menuItem;
		
		//Clear out all the items, start from scratch
		[menu removeAllItems];
		
		// If there's more than one account, show the accounts menu
		if ([accountMenuItemsArray count] > 1) {
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Accounts",nil)
																			target:self
																			action:nil
																	 keyEquivalent:@""];
			
			[menuItem setSubmenu:mainAccountsMenu];
			[menu addItem:menuItem];
			[menuItem release];
		}
		
		// Show the contacts menu if we have any contacts to display
		if ([contactMenuItemsArray count] > 0) {
			// Add contacts
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Contacts",nil)
																			target:self
																			action:nil
																	 keyEquivalent:@""];
			
			[menuItem setSubmenu:mainContactsMenu];
			[menu addItem:menuItem];
			[menuItem release];
		} else {
			[menu addItemWithTitle:[AILocalizedString(@"Contact List", nil) stringByAppendingEllipsis]
							target:self
							action:@selector(activateContactList:)
					 keyEquivalent:@""];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];

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

		//If there exist any open chats, add them
		if ([openChatsArray count] > 0) {
			AIChat          *chat = nil;

			enumerator = [openChatsArray objectEnumerator];
			
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
		
		//Only update next time if we need to
		mainMenuNeedsUpdate = NO;
	// Contacts menu - or, override the main menu with option held down
	} else if (((menu == mainMenu) && [NSEvent optionKey]) || ((menu == mainContactsMenu) && contactsMenuNeedsUpdate)) {
		NSEnumerator    *enumerator = [contactMenuItemsArray objectEnumerator];
		NSMenuItem      *menuItem;
		
		// Remove previous menu items.
		[menu removeAllItems];
		
		// If this is the contact menu being pushed into the main one, force an update next time
		if ([NSEvent optionKey]) {
			// Remove contact menu items from the old menu
			[mainContactsMenu removeAllItems];
			// Have both menus update next time
			mainMenuNeedsUpdate = YES;
			contactsMenuNeedsUpdate = YES;
		} else {
			contactsMenuNeedsUpdate = NO;
		}
		
		[menu addItemWithTitle:[AILocalizedString(@"Contact List", nil) stringByAppendingEllipsis]
						target:self
						action:@selector(activateContactList:)
				 keyEquivalent:@""];
		
		if ([contactMenuItemsArray count] > 0)
			[menu addItem:[NSMenuItem separatorItem]];
		
		while ((menuItem = [enumerator nextObject])) {
			[menu addItem:menuItem];
			
			//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
			if ([[menuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
				[[menuItem target] validateMenuItem:menuItem];
			}
		}
	// Accounts menu
	} else if (menu == mainAccountsMenu && accountsMenuNeedsUpdate) {
		NSEnumerator    *enumerator = [accountMenuItemsArray objectEnumerator];
		NSMenuItem      *menuItem;
		
		[menu removeAllItems];
		
		[menu addItemWithTitle:[AILocalizedString(@"Account List", nil) stringByAppendingEllipsis]
									target:self
									action:@selector(activateAccountList:)
							 keyEquivalent:@""];
		
		[menu addItem:[NSMenuItem separatorItem]];
		
		//Add the account menu items
		enumerator = [accountMenuItemsArray objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			NSMenu	*submenu;
			
			[menu addItem:menuItem];
			
			//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
			if ([[menuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
				[[menuItem target] validateMenuItem:menuItem];
			}
			
			submenu = [menuItem submenu];
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
		
		accountsMenuNeedsUpdate = NO;
	}
}

- (void)switchToChat:(id)sender
{
	[[adium interfaceController] setActiveChat:[sender representedObject]];
	[self activateAdium:nil];
}

- (void)activateContactList:(id)sender
{
	[[adium interfaceController] showContactList:nil];
	[self activateAdium:nil];
}

- (void)activateAccountList:(id)sender
{
	[[adium preferenceController] openPreferencesToCategoryWithIdentifier:@"Accounts"];
	[self activateAdium:nil];
}

- (void)activateAdium:(id)sender
{
	if (![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
		[NSApp arrangeInFront:nil];
	}
}

#pragma mark Preferences Observer
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) {
		showContactGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
		[contactMenu rebuildMenu];
	}
	
	if ([group isEqualToString:PREF_GROUP_STATUS_MENU_ITEM]) {
		showUnreadCount = [[prefDict objectForKey:KEY_STATUS_MENU_ITEM_COUNT] boolValue];
		showBadge = [[prefDict objectForKey:KEY_STATUS_MENU_ITEM_BADGE] boolValue];
		flashUnviewed = [[prefDict objectForKey:KEY_STATUS_MENU_ITEM_FLASH] boolValue];
		
		[self updateMenuIcons];
		[self updateUnreadCount];
		[self updateStatusItemLength];
	}
}

#pragma mark -

- (void)menuBarIconsDidChange:(NSNotification *)notification
{
	[self updateMenuIconsBundle];
}
@end
