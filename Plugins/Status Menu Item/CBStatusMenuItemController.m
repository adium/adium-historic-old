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
#import "AIChatController.h"
#import "AIInterfaceController.h"
#import "AIStatusController.h"
#import "CBStatusMenuItemController.h"
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
#import <AIUtilities/AIColorAdditions.h>

#import <QuartzCore/QuartzCore.h>

#define STATUS_ITEM_MARGIN 8

@interface CBStatusMenuItemController (PRIVATE)
- (void)activateAdium:(id)sender;
- (void)setIconImage:(NSImage *)inImage;
- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)inImage;
- (NSImage *)badgeOnlineDuckWithImage:(NSImage *)inImage;
- (NSImage *)badgeOnlineHighlightDuckWithImage:(NSImage *)inImage;
- (void)setOfflineDuck;
- (void)setOnlineDuckWithBadgeImage:(NSImage *)inImage;
@end

@implementation CBStatusMenuItemController

//Returns the shared instance, possibly initializing and creating a new one.
+ (CBStatusMenuItemController *)statusMenuItemController
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		//Create and set up the status item
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
		[statusItem setHighlightMode:YES];

		unviewedContent = NO;

		if ([[adium accountController] oneOrMoreConnectedAccounts]) {
			[self setOnlineDuckWithBadgeImage:nil];
		} else {
			[self setOfflineDuck];
		}
		
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
		needsUpdate = YES;

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
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountStatusSubmenu showTitleVerbs:NO] retain];
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

	[theMenu release];
	[unviewedObjectsArray release];
	[accountMenu release];
	[statusMenu release];

	[adiumOfflineImage release]; 
	[adiumOfflineHighlightImage release];
	[adiumImage release];
	[adiumHighlightImage release];

	// Can't release this because it causes a crash on quit. rdar://4139755, rdar://4160625, and #743. --boredzo
	// [statusItem release];

	//To the superclass, Robin!
	[super dealloc];
}

//Icon State --------------------------------------------------------
#pragma mark Icon State

- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)inImage {
	NSImage *image = duckImage;

	if (inImage) {
		image = [[duckImage copy] autorelease];

		[image lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

		NSRect rect = { NSZeroPoint, [inImage size] };
		//Draw in the lower-right corner.
		NSPoint destPoint = { .x = [duckImage size].width - rect.size.width, .y = 0.0 };
		[inImage drawAtPoint:destPoint
					fromRect:rect
				   operation:NSCompositeSourceOver
					fraction:0.75];
		[image unlockFocus];
	}

	return image;
}

- (NSImage *)badgeOnlineDuckWithImage:(NSImage *)inImage
{
	if (!adiumImage) {
		adiumImage = [[NSImage imageNamed:@"adium.png" forClass:[self class]] retain];
	}
	return [self badgeDuck:adiumImage withImage:inImage];
}
- (NSImage *)badgeOnlineHighlightDuckWithImage:(NSImage *)inImage
{
	if (!adiumHighlightImage) {
		adiumHighlightImage = [[NSImage imageNamed:@"adiumHighlight.png" forClass:[self class]] retain];
	}
	return [self badgeDuck:adiumHighlightImage withImage:inImage];
}

#if 0
- (NSImage *)alternateImageForImage:(NSImage *)inImage
{
	NSImage				*altImage = [[NSImage alloc] initWithSize:[inImage size]];
	NSBitmapImageRep	*srcImageRep = [inImage bitmapRep];
	
	Class Filter = NSClassFromString(@"CIFilter");
	Class Image = NSClassFromString(@"CIImage");
	Class Color = NSClassFromString(@"CIColor");
	Class Context = NSClassFromString(@"CIContext");
	id monochromeFilter, invertFilter, alphaFilter;

	monochromeFilter = [Filter filterWithName:@"CIColorMonochrome"];
	[monochromeFilter setValue:[[[Image alloc] initWithBitmapImageRep:srcImageRep] autorelease]
						forKey:@"inputImage"]; 
	[monochromeFilter setValue:[NSNumber numberWithFloat:1.0]
						forKey:@"inputIntensity"];
	[monochromeFilter setValue:[[[Color alloc] initWithColor:[NSColor blackColor]] autorelease]
						forKey:@"inputColor"];

	//Now invert our greyscale image
	invertFilter = [Filter filterWithName:@"CIColorInvert"];
	[invertFilter setValue:[monochromeFilter valueForKey:@"outputImage"]
					forKey:@"inputImage"]; 

	//And turn the parts that were previously white (are now black) into transparent
	alphaFilter = [Filter filterWithName:@"CIMaskToAlpha"];
	[alphaFilter setValue:[invertFilter valueForKey:@"outputImage"]
			  forKey:@"inputImage"]; 

	[altImage lockFocus];
	id context = [Context contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] 
									   options:nil];
	id result = [alphaFilter valueForKey:@"outputImage"];
	[context drawImage:result
			   atPoint:CGPointZero
			  fromRect:[result extent]];
	[altImage unlockFocus];

	return [altImage autorelease];
}
#endif //0

- (void)setOfflineDuck
{
	if (!adiumOfflineImage) {
		adiumOfflineImage = [[NSImage imageNamed:@"adiumOffline.png" forClass:[self class]] retain];
	}
	if (!adiumOfflineHighlightImage) {
		adiumOfflineHighlightImage = [[NSImage imageNamed:@"adiumOfflineHighlight.png" forClass:[self class]] retain];
	}

	[statusItem setImage:adiumOfflineImage];
	[statusItem setAlternateImage:adiumOfflineHighlightImage];
}
- (void)setOnlineDuckWithBadgeImage:(NSImage *)inImage
{	
	if (!inImage) {
		inImage = [[[adium statusController] activeStatusState] icon];
	}

	[statusItem setImage:[self badgeOnlineDuckWithImage:inImage]];

	[statusItem setAlternateImage:[self badgeOnlineHighlightDuckWithImage:inImage]];
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
			if ([[adium accountController] oneOrMoreConnectedAccounts]) {
				[self setOnlineDuckWithBadgeImage:nil];
			} else {
				[self setOfflineDuck];
			}
			unviewedContent = NO;
		}

	} else {
		//If this is the first contact with unviewed content, set our icon to unviewed content.
		if (!unviewedContent) {
			unviewedContent = YES;
			[self setOnlineDuckWithBadgeImage:[AIStatusIcons statusIconForStatusName:@"content"
																		  statusType:AIAvailableStatusType
																			iconType:AIStatusIconList
																		   direction:AIIconNormal]];
		}
	}

	//If they're typing, we also need to update because we show typing within the menu itself next to chats.
	if ([inModifiedKeys containsObject:KEY_TYPING]) {
		needsUpdate = YES;
	}

	//We didn't modify attributes, so return nil
	return nil;
}

//Menu Delegate --------------------------------------------------------
#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	//If something has changed
	if (needsUpdate) {
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

		if ([accountMenuItemsArray count] > 0) {
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
				if (!(image = [AIStatusIcons statusIconForChat:chat type:AIStatusIconTab direction:AIIconNormal])) {
					//Otherwise use the contact's status image
					image = [AIStatusIcons statusIconForListObject:[chat listObject]
					                                          type:AIStatusIconTab
					                                     direction:AIIconNormal];
				}
				//Set the image
				[menuItem setImage:image];

				//Add it to the menu
				[menu addItem:menuItem];
			}
		}

		//Add our last two items
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:AILocalizedString(@"Bring Adium to Front",nil)
		                target:self
		                action:@selector(activateAdium:)
		         keyEquivalent:@""];
		[menu addItemWithTitle:AILocalizedString(@"Quit Adium",nil)
		                target:NSApp
		                action:@selector(terminate:)
		         keyEquivalent:@""];

		//Only update next time if we need to
		needsUpdate = NO;
	}
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

#pragma mark -

- (void)accountStateChanged:(NSNotification *)notification
{
	if (!unviewedContent) {
		if ([[adium accountController] oneOrMoreConnectedAccounts]) {
			[self setOnlineDuckWithBadgeImage:nil];
		} else {
			[self setOfflineDuck];
		}
	}
}

- (void)statusIconSetDidChange:(NSNotification *)notification
{
	if (unviewedContent) {
		[self setOnlineDuckWithBadgeImage:[AIStatusIcons statusIconForStatusName:@"content"
																	  statusType:AIAvailableStatusType
																		iconType:AIStatusIconList
																	   direction:AIIconNormal]];
	} else {
		if ([[adium accountController] oneOrMoreConnectedAccounts]) {
			[self setOnlineDuckWithBadgeImage:nil];
		} else {
			[self setOfflineDuck];
		}
	}
}

@end
