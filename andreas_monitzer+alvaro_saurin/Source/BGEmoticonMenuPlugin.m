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

#import "AIEmoticonController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "AIToolbarController.h"
#import "BGEmoticonMenuPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>
#import <Adium/AIEmoticon.h>

@interface BGEmoticonMenuPlugin(PRIVATE)
- (void)registerToolbarItem;
- (void)menuNeedsUpdate:(NSMenu *)inMenu;
@end

/*!
 * @class BGEmoticonMenuPlugin
 * @brief Component to manage the Emoticons menu in its various forms
 */
@implementation BGEmoticonMenuPlugin

#define PREF_GROUP_EMOTICONS			@"Emoticons"

#define	TITLE_INSERT_EMOTICON			AILocalizedString(@"Insert Emoticon",nil)
#define	TOOLTIP_INSERT_EMOTICON			AILocalizedString(@"Insert an emoticon into the text",nil)
#define	TITLE_EMOTICON					AILocalizedString(@"Emoticon",nil)

#define	TOOLBAR_EMOTICON_IDENTIFIER		@"InsertEmoticon"

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //init the menus and menuItems
    quickMenuItem = [[NSMenuItem alloc] initWithTitle:TITLE_INSERT_EMOTICON
											   target:self
											   action:@selector(dummyTarget:) 
										keyEquivalent:@""];
    quickContextualMenuItem = [[NSMenuItem alloc] initWithTitle:TITLE_INSERT_EMOTICON
														 target:self
														 action:@selector(dummyTarget:)
												  keyEquivalent:@""];
	needToRebuildMenus = YES;
	
	/* Create a submenu for these so menuNeedsUpdate will be called 
	 * to populate them later. Don't need to check respondsToSelector:@selector(setDelegate:).
	 */
	NSMenu	*tempMenu;
	tempMenu = [[NSMenu alloc] init];
	[tempMenu setDelegate:self];
	[quickMenuItem setSubmenu:tempMenu];
	[tempMenu release];
	
	tempMenu = [[NSMenu alloc] init];
	[tempMenu setDelegate:self];
	[quickContextualMenuItem setSubmenu:tempMenu];
	[tempMenu release];

    //add the items to their menus.
    AIMenuController *menuController = [adium menuController];
    [menuController addContextualMenuItem:quickContextualMenuItem toLocation:Context_TextView_Edit];    
    [menuController addMenuItem:quickMenuItem toLocation:LOC_Edit_Additions];
	
	toolbarItems = [[NSMutableSet alloc] init];
	[self registerToolbarItem];
	
	//
	[[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(toolbarWillAddItem:)
                                                    name:NSToolbarWillAddItemNotification
                                                  object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];

	//Observe prefs    
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[toolbarItems release];
	
	[super dealloc];
}

/*!
 * @brief Add the emoticon menu as an item goes into a toolbar
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if ([[item itemIdentifier] isEqualToString:TOOLBAR_EMOTICON_IDENTIFIER]) {
		NSMenu		*theEmoticonMenu = [self emoticonMenu];

		//Add menu to view
		[[item view] setMenu:theEmoticonMenu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
		[mItem setSubmenu:theEmoticonMenu];
		[mItem setTitle:AILocalizedString(@"Emoticon",nil)];
		[item setMenuFormRepresentation:mItem];
		
		[toolbarItems addObject:item];
	}
}

/*!
 * @brief Stop tracking when an item is removed from a toolbar
 */
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	if ([[item itemIdentifier] isEqualToString:TOOLBAR_EMOTICON_IDENTIFIER]) {
		[toolbarItems removeObject:item];
	}
}

/*!
 * @brief Emoticons changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Flush the cached emoticon menu
	[emoticonMenu release]; emoticonMenu = nil;
	
	//Flag our menus as dirty
	needToRebuildMenus = YES;
}

/*!
 * @brief Register our toolbar item
 */
- (void)registerToolbarItem
{
	NSToolbarItem	*toolbarItem;
	MVMenuButton	*button;

	//Register our toolbar item
	button = [[[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)] autorelease];
	[button setImage:[NSImage imageNamed:@"emoticon32" forClass:[self class]]];
	toolbarItem = [[AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_EMOTICON_IDENTIFIER
														   label:TITLE_EMOTICON
													paletteLabel:TITLE_INSERT_EMOTICON
														 toolTip:TOOLTIP_INSERT_EMOTICON
														  target:self
												 settingSelector:@selector(setView:)
													 itemContent:button
														  action:@selector(insertEmoticon:)
															menu:nil] retain];
	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}


//Menu Generation ------------------------------------------------------------------------------------------------------
#pragma mark Menu Generation
/*!
 * @brief Build the emoticon menu
 *
 * Generation of the menu itself is cached.
 *
 * @result An autoreleased copy of the cached emoticon menu
 */
- (NSMenu *)emoticonMenu
{
	NSMenu	*emoticonMenuCopy;
	
	if (!emoticonMenu) {
		NSArray		*emoticonPacks = [[adium emoticonController] activeEmoticonPacks];

		if ([emoticonPacks count] == 1) {
			//If there is only 1 emoticon pack loaded, do not create submenus
			emoticonMenu = [[self flatEmoticonMenuForPack:[emoticonPacks objectAtIndex:0]] retain];

		} else {
			NSEnumerator	*packEnum = [emoticonPacks objectEnumerator];
			AIEmoticonPack  *pack;
			NSMenuItem 		*packItem;
			
			emoticonMenu = [[NSMenu alloc] initWithTitle:@""];
			
			[emoticonMenu setMenuChangedMessagesEnabled:NO];
			while ((pack = [packEnum nextObject])) {
				packItem = [[NSMenuItem alloc] initWithTitle:[pack name] action:nil keyEquivalent:@""];
				[packItem setSubmenu:[self flatEmoticonMenuForPack:pack]]; 
				[emoticonMenu addItem:packItem];
				[packItem release];
			}
			[emoticonMenu setMenuChangedMessagesEnabled:YES];
		}
	}
	
	//Always return a copy so we can freely modify the menu's item array without messing up our cached copy
	emoticonMenuCopy = [emoticonMenu copy];
	if ([emoticonMenuCopy respondsToSelector:@selector(setDelegate:)]) {
		[emoticonMenuCopy setDelegate:self];
	}
	
	return [emoticonMenuCopy autorelease];
}

/*!
 * @brief Build a flat emoticon menu for a single pack
 *
 * @result A menu for the pack
 */
- (NSMenu *)flatEmoticonMenuForPack:(AIEmoticonPack *)incomingPack
{
    NSMenu			*packMenu = [[NSMenu alloc] initWithTitle:TITLE_EMOTICON];
    NSEnumerator	*emoteEnum = [[incomingPack emoticons] objectEnumerator];
    AIEmoticon		*anEmoticon;
	
	[packMenu setMenuChangedMessagesEnabled:NO];
	
    //loop through each emoticon and add a menu item for each
    while ((anEmoticon = [emoteEnum nextObject])) {
        if ([anEmoticon isEnabled] == YES) {
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[anEmoticon name]
                                                             target:self
                                                             action:@selector(insertEmoticon:)
                                                      keyEquivalent:@""];

			//We need to make a copy of the emoticons for our menu, otherwise the menu flips them in an unpredictable
			//way, causing problems in the emoticon preferences
            [newItem setImage:[[anEmoticon image] imageByScalingToSize:NSMakeSize(16, 16)]];
			[newItem setRepresentedObject:anEmoticon];
			[packMenu addItem:newItem];
			[newItem release];
        }
    }
    
    [packMenu setMenuChangedMessagesEnabled:YES];
	
    return [packMenu autorelease];
}


//Menu Control ---------------------------------------------------------------------------------------------------------
#pragma mark Menu Control
/*!
 * @brief Insert an emoticon into the first responder if possible
 *
 * First responder must be an editable NSTextView.
 *
 * @param sender An NSMenuItem whose representedObject is an AIEmoticon
 */
- (void)insertEmoticon:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		NSString *emoString = [[[sender representedObject] textEquivalents] objectAtIndex:0];
		
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if (emoString && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]) {
			NSRange tmpRange = [(NSTextView *)responder selectedRange];
			if (0 != tmpRange.length) {
				[(NSTextView *)responder setSelectedRange:NSMakeRange((tmpRange.location + tmpRange.length),0)];
			}
			[responder insertText:emoString];
		}
    }
}

/*!
 * @brief Just a target so we get the validateMenuItem: call for the emoticon menu
 */
- (IBAction)dummyTarget:(id)sender
{
	//Empty
}

/*!
 * @brief Validate menu item
 *
 * Disable the emoticon menu if a text field is not active
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if (menuItem == quickMenuItem || menuItem == quickContextualMenuItem) {
		BOOL	haveEmoticons = ([[[adium emoticonController] activeEmoticonPacks] count] != 0);

		//Disable the main emoticon menu items if no emoticons are available
		return haveEmoticons;
		
	} else {
		//Disable the emoticon menu items if we're not in a text field
		NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if (responder && [responder isKindOfClass:[NSText class]]) {
			return [(NSText *)responder isEditable];
		} else {
			return NO;
		}
		
	}
}

/*!
 * @brief We don't want to get -menuNeedsUpdate: called on every keystroke. This method suppresses that.
 */
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action {
	*target = nil;  //use menu's target
	*action = NULL; //use menu's action
	return NO;
}

/*!
 * @brief Update our menus if necessary
 *
 * Called each time before any of our menus are displayed.  If needToRebuildMenus is YES, rebuild them all now,
 * then set needToRebuildMenus to NO so we don't have to do it next time.
 *
 * We set the delegate each time we copy because it seems that NSMenu doesn't do so itself when copying. Odd.
 */
- (void)menuNeedsUpdate:(NSMenu *)inMenu
{	
	//Build the emoticon menus if necessary
	if (needToRebuildMenus) {
		NSMenu			*theEmoticonMenu, *tempMenu;
		NSMenuItem		*menuItem;
		NSEnumerator	*enumerator;
		NSToolbarItem	*toolbarItem;
		
		//Build the new emoticon menu
		theEmoticonMenu = [self emoticonMenu];
		
		/* For each item, only set its submenu (so we won't have to worry about it in the future) if its current
		 * submenu isn't the one for which we are currently updating. One of them WILL be identical to inMenu, as
		 * that's why we got here (the delegate call) in the first place.  For that one, we'll remove inMenu's items
		 * and then add the items from emoticonMenu. */
		if ([quickMenuItem submenu] != inMenu) {
			tempMenu = [theEmoticonMenu copy];
			[quickMenuItem setSubmenu:tempMenu];
			if ([tempMenu respondsToSelector:@selector(setDelegate:)]) {
				[tempMenu setDelegate:self];
			}
			[tempMenu release];
		}
		
		if ([quickContextualMenuItem submenu] != inMenu) {
			tempMenu = [theEmoticonMenu copy];
			[quickContextualMenuItem setSubmenu:tempMenu];
			if ([tempMenu respondsToSelector:@selector(setDelegate:)]) {
				[tempMenu setDelegate:self];
			}
			[tempMenu release];
		}
		
		enumerator = [toolbarItems objectEnumerator];
		while ((toolbarItem = [enumerator nextObject])) {
			if ([[toolbarItem view] menu] != inMenu) {
				//We can use the same menu for both
				tempMenu = [theEmoticonMenu copy];

				if ([tempMenu respondsToSelector:@selector(setDelegate:)]) {
					[tempMenu setDelegate:self];
				}
				
				//Add menu to view
				[[toolbarItem view] setMenu:tempMenu];
				
				//Add menu to toolbar item (for text mode)
				[[toolbarItem menuFormRepresentation] setSubmenu:tempMenu];
				
				[tempMenu release];
			}
		}
		
		/* Now update inMenu.  We update the menu rather than replacing it with another menu so that
		 * the menu will appear properly immediately rather than next time it is viewed.  Also, I suspect
		 * it's a bad idea to release inMenu (by replacing it with another one) in the middle of this
		 * delegate call.
		 * 
		 * Have to copy and autorelease here since the itemArray will change as we go through the items.
		 */
		[inMenu removeAllItems];
		enumerator = [[[[theEmoticonMenu itemArray] copy] autorelease] objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			[menuItem retain];
			[theEmoticonMenu removeItem:menuItem];
			[inMenu addItem:menuItem];
			[menuItem release];
		}
		
		needToRebuildMenus = NO;
	}
}	

@end
