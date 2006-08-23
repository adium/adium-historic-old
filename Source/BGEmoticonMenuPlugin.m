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
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
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
	
	/* Create a submenu for these so menu:updateItem:atIndex:shouldCancel: will be called 
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
    [[adium menuController] addContextualMenuItem:quickContextualMenuItem toLocation:Context_TextView_Edit];    
    [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Edit_Additions];
	
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
		NSMenu		*theEmoticonMenu = [[[NSMenu alloc] init] autorelease];
		
		[theEmoticonMenu setDelegate:self];

		//Add menu to view
		[[item view] setMenu:theEmoticonMenu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
		[mItem setSubmenu:theEmoticonMenu];
		[mItem setTitle:TITLE_EMOTICON];
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
 * Called each time before any of our menus are displayed.  This rebuilds menus incrimentially, in place.
 *
 */
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	NSArray			*activePacks = [[adium emoticonController] activeEmoticonPacks];
	AIEmoticonPack	*pack = [activePacks objectAtIndex:0];
	NSToolbarItem	*toolbar;
	NSEnumerator	*enumerator = [toolbarItems objectEnumerator];
	
	#warning earthmkii: There has *got* to be a better way to see if a menu is attached to a toolbar
   /* We need special voodoo here to identify if the menu belongs to a toolbar,
	* adds the necessary pad item, and then adjusts the index accordingly.
	* this shouldn't be necessary, but NSToolbar is evil.
	*/
	while ((toolbar = [enumerator nextObject])) {
		if (([[[toolbar menuFormRepresentation] submenu] isEqualTo:menu] && index == 0)) {
			item = [[NSMenuItem alloc] init];
			return YES;
		} else if (([[[toolbar menuFormRepresentation] submenu] isEqualTo:menu])) {
			--index;
		}
	} 
	
	// Add in flat emoticon menu
	if ([activePacks count] == 1) {
		AIEmoticon	*emoticon = [[pack emoticons] objectAtIndex:index];
		if ([emoticon isEnabled] && ![[item representedObject] isEqualTo:emoticon]) {
			[item setTitle:[emoticon name]];
			[item setTarget:self];
			[item setAction:@selector(insertEmoticon:)];
			[item setKeyEquivalent:@""];
			[item setImage:[[emoticon image] imageByScalingToSize:NSMakeSize(16, 16)]];
			[item setRepresentedObject:emoticon];
			[item setSubmenu:nil];
		}
	// Add in multi-pack menu
	} else {
		pack = [activePacks objectAtIndex:index];
		if (![[item title] isEqualToString:[pack name]]){
			[item setTitle:[pack name]];
			[item setTarget:nil];
			[item setAction:nil];
			[item setKeyEquivalent:@""];
			[item setImage:[[pack menuPreviewImage] imageByScalingToSize:NSMakeSize(16, 16)]];
			[item setRepresentedObject:nil];
			[item setSubmenu:[self flatEmoticonMenuForPack:pack]];
		}
		
	}
	
	return YES;
}

/*!
 * @brief Set the number of items that should be in the menu.
 *
 * Toolbars need one empty item to display properly.  We increase the number by 1, if the menu
 * is in a toolbar
 *
 */
- (int)numberOfItemsInMenu:(NSMenu *)menu
{	
	NSToolbarItem	*item;
	NSEnumerator	*enumerator = [toolbarItems objectEnumerator];
	NSArray			*activePacks = [[adium emoticonController] activeEmoticonPacks];
	int				 itemCounts = -1;
	
	itemCounts = [activePacks count];
	
	if (itemCounts == 1)
		itemCounts = [[[activePacks objectAtIndex:0] emoticons] count];
	
	#warning earthmkii: There has *got* to be a better way to see if a menu is attached to a toolbar
	while ((item = [enumerator nextObject])) {
		if ([[[item menuFormRepresentation] submenu] isEqualTo:menu])
			++itemCounts;
	}
	return itemCounts;
}

@end
