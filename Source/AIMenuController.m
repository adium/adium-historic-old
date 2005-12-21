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

// $Id$

#import "AIMenuController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface AIMenuController (PRIVATE)
- (void)localizeMenuTitles;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray usingMenu:(NSMenu *)inMenu;
- (void)addMenuItemsForContact:(AIListContact *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem;
@end

@implementation AIMenuController

- (id)init
{
	if ((self = [super init])) {
		//Set up our contextual menu stuff
		contextualMenu = [[NSMenu alloc] init];
		contextualMenuItemDict = [[NSMutableDictionary alloc] init];
		currentContextMenuObject = nil;
		textViewContextualMenu = [[NSMenu alloc] init];
		contextualMenu_TextView = nil;
	}
	
	return self;
}

- (void)awakeFromNib
{
	//Build the array of menu locations
	locationArray = [[NSMutableArray alloc] initWithObjects:menu_Adium_About, menu_Adium_Preferences,
		menu_File_New, menu_File_Close, menu_File_Save, menu_File_Additions,	
		menu_Edit_Bottom, menu_Edit_Additions,
		menu_View_General, menu_View_Unnamed_A, menu_View_Unnamed_B, menu_View_Unnamed_C, 
		menu_Contact_Manage, menu_Contact_Info, menu_Contact_Action, menu_Contact_NegativeAction, menu_Contact_Additions,
		menu_Status_State, menu_Status_Accounts, menu_Status_Additions,
		menu_Format_Styles, menu_Format_Palettes, menu_Format_Additions,
		menu_Window_Top, menu_Window_Commands, menu_Window_Auxiliary, menu_Window_Fixed,
		menu_Help_Local, menu_Help_Web, menu_Help_Additions,
		menu_Dock_Status, nil];
}

- (void)controllerDidLoad
{	
	[self localizeMenuTitles];	
}

//Close
- (void)controllerWillClose
{
	//There's no need to remove the menu items, the system will take them out for us.
}

//Add a menu item
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location
{
	NSMenuItem  *menuItem;
	NSMenu		*targetMenu = nil;
	int			targetIndex;
	int			destination;

	//Find the menu item (or the closest one above it)
	destination = location;
	menuItem = [locationArray objectAtIndex:destination];
	while ((menuItem == nilMenuItem) && (destination > 0)) {
		destination--;
		menuItem = [locationArray objectAtIndex:destination];
	}
	if ([menuItem isKindOfClass:[NSMenuItem class]]) {
		//If attached to a menu item, insert below that item
		targetMenu = [menuItem menu];
		targetIndex = [targetMenu indexOfItem:menuItem];
	} else {
		//If it's attached to an NSMenu (and not an NSMenuItem), insert at the top of the menu
		targetMenu = (NSMenu *)menuItem;
		targetIndex = -1;
	}

	//Insert the new item and a divider (if necessary)
	if (location != destination) {
		[targetMenu insertItem:[NSMenuItem separatorItem] atIndex:++targetIndex];
	}
	[targetMenu insertItem:newItem atIndex:targetIndex+1];

	//update the location array
	[locationArray replaceObjectAtIndex:location withObject:newItem];

	[[adium notificationCenter] postNotificationName:Menu_didChange object:[newItem menu] userInfo:nil];
}

//Remove a menu item
- (void)removeMenuItem:(NSMenuItem *)targetItem
{
	NSMenu		*targetMenu = [targetItem menu];
	int			targetIndex = [targetMenu indexOfItem:targetItem];
	unsigned	loop, maxLoop;

	//Fix the pointer if this is one
	for (loop = 0, maxLoop = [locationArray count]; loop < maxLoop; loop++) {
		NSMenuItem	*menuItem = [locationArray objectAtIndex:loop];

		//Move to the item above it, nil if a divider
		if (menuItem == targetItem) {
			if (targetIndex != 0) {
				NSMenuItem	*previousItem = [targetMenu itemAtIndex:(targetIndex - 1)];

				if ([previousItem isSeparatorItem]) {
					[locationArray replaceObjectAtIndex:loop withObject:nilMenuItem];
				} else {
					[locationArray replaceObjectAtIndex:loop withObject:previousItem];
				}
			} else {
				//If there are no more items, attach to the menu
				[locationArray replaceObjectAtIndex:loop withObject:targetMenu];
			}
		}
	}

	//Remove the item
	[targetMenu removeItem:targetItem];

	//Remove any double dividers (And dividers at the bottom)
	for (loop = 0; loop < [targetMenu numberOfItems]; loop++) {
		if (([[targetMenu itemAtIndex:loop] isSeparatorItem]) && 
		   (loop == [targetMenu numberOfItems]-1 || [[targetMenu itemAtIndex:loop+1] isSeparatorItem])) {
			[targetMenu removeItemAtIndex:loop];
			loop--;//re-search the location
		}
	}

	[[adium notificationCenter] postNotificationName:Menu_didChange object:targetMenu userInfo:nil];
}

- (void)addContextualMenuItem:(NSMenuItem *)newItem toLocation:(CONTEXT_MENU_LOCATION)location
{
	NSNumber			*key;
	NSMutableArray		*itemArray;

	//Search for an existing item array for menu items in this location
	key = [NSNumber numberWithInt:location];
	itemArray = [contextualMenuItemDict objectForKey:key];

	//If one is not found, create it
	if (!itemArray) {
		itemArray = [[NSMutableArray alloc] init];
		[contextualMenuItemDict setObject:itemArray forKey:key];
	}

	//Add the passed menu item to the array
	[itemArray addObject:newItem];
}

//Pass an array of NSNumbers corresponding to the desired contextual menu locations
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject
{
	NSMenu		*workingMenu;
	BOOL		separatorItem;

	//Remember what our menu is configured for
	[currentContextMenuObject release];
	currentContextMenuObject = [inObject retain];

	//Get the pre-created contextual menu items
	workingMenu = [self contextualMenuWithLocations:inLocationArray usingMenu:contextualMenu];

	//Add any account-specific menu items
	separatorItem = YES;
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		NSEnumerator	*enumerator;
		AIListContact	*aListContact;
		enumerator = [[(AIMetaContact *)inObject listContacts] objectEnumerator];

		while ((aListContact = [enumerator nextObject])) {
			[self addMenuItemsForContact:aListContact
								  toMenu:workingMenu
						   separatorItem:&separatorItem];
		}

	} else  if ([inObject isKindOfClass:[AIListContact class]]) {
		[self addMenuItemsForContact:(AIListContact *)inObject
							  toMenu:workingMenu
					   separatorItem:&separatorItem];
	}

	return workingMenu;
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject inChat:(AIChat *)inChat
{
	[currentContextMenuChat release];
	currentContextMenuChat = [inChat retain];
	
	return [self contextualMenuWithLocations:inLocationArray forListObject:inObject];
}

//Add menuItems for a passed contact to a specified menu.  *seperatorItem can be YES to indicate that a 
//separator item should be inserted before the menu items if desired. It will then be set to NO.
- (void)addMenuItemsForContact:(AIListContact *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem
{
	NSArray			*itemArray = [[inContact account] menuItemsForContact:inContact];

	if (itemArray && [itemArray count]) {
		NSEnumerator	*enumerator;
		NSMenuItem		*menuItem;

		if (*separatorItem == YES) {
			[workingMenu addItem:[NSMenuItem separatorItem]];
			*separatorItem = NO;
		}

		enumerator = [itemArray objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			[workingMenu addItem:menuItem];
		}
	}
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forTextView:(NSTextView *)inTextView
{
	//remember menu config
	[contextualMenu_TextView release];
	contextualMenu_TextView = [inTextView retain];

	return [self contextualMenuWithLocations:inLocationArray usingMenu:textViewContextualMenu];
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray usingMenu:(NSMenu *)inMenu
{
	NSEnumerator	*enumerator;
	NSNumber		*location;
	NSMenuItem		*menuItem;
	BOOL			itemsAbove = NO;

	//Remove all items from the existing menu
	[inMenu removeAllItems];

	//Process each specified location
	enumerator = [inLocationArray objectEnumerator];
	while ((location = [enumerator nextObject])) {
		NSArray			*menuItems = [contextualMenuItemDict objectForKey:location];
		NSEnumerator	*itemEnumerator;

		//Add a seperator
		if (itemsAbove && [menuItems count]) {
			[inMenu addItem:[NSMenuItem separatorItem]];
			itemsAbove = NO;
		}

		//Add each menu item in the location
		itemEnumerator = [menuItems objectEnumerator];
		while ((menuItem = [itemEnumerator nextObject])) {
			//Add the menu item
			[inMenu addItem:menuItem];
			itemsAbove = YES;
		}
	}

	return inMenu;
}

- (AIListObject *)currentContextMenuObject
{
	return currentContextMenuObject;
}

- (AIChat *)currentContextMenuChat
{
	return currentContextMenuChat;
}

- (NSTextView *)contextualMenuTextView
{
	return contextualMenu_TextView;
}

- (void)removeItalicsKeyEquivalent
{
	[menuItem_Format_Italics setKeyEquivalent:@""];
}

- (void)restoreItalicsKeyEquivalent
{
	[menuItem_Format_Italics setKeyEquivalent:@"i"];
}

- (void)localizeMenuTitles
{
	//Menu items in MainMenu.nib for localization purposes
	[menuItem_file setTitle:AILocalizedString(@"File",nil)];
	[menuItem_edit setTitle:AILocalizedString(@"Edit",nil)];
	[menuItem_view setTitle:AILocalizedString(@"View",nil)];
	[menuItem_status setTitle:AILocalizedString(@"Status",nil)];
	[menuItem_contact setTitle:AILocalizedString(@"Contact",nil)];
	[menuItem_format setTitle:AILocalizedString(@"Format",nil)];
	[menuItem_window setTitle:AILocalizedString(@"Window",nil)];
	[menuItem_help setTitle:AILocalizedString(@"Help",nil)];

	//Adium menu
	[menuItem_aboutAdium setTitle:AILocalizedString(@"About Adium",nil)];
	[menuItem_adiumXtras setTitle:AILocalizedString(@"Xtras Manager",nil)];
	[menuItem_preferences setTitle:[AILocalizedString(@"Preferences",nil) stringByAppendingEllipsis]];
	[menuItem_services setTitle:AILocalizedString(@"Services","Services menu item in the Adium menu")];
	[menuItem_hideAdium setTitle:AILocalizedString(@"Hide Adium",nil)];
	[menuItem_hideOthers setTitle:AILocalizedString(@"Hide Others",nil)];
	[menuItem_showAll setTitle:AILocalizedString(@"Show All",nil)];
	[menuItem_quitAdium setTitle:AILocalizedString(@"Quit Adium",nil)];

	//File menu	
	[menuItem_close setTitle:AILocalizedString(@"Close","Title for the close menu item")];
	[menuItem_closeChat setTitle:AILocalizedString(@"Close Chat","Title for the close chat menu item")];
	[menuItem_closeAllChats setTitle:AILocalizedString(@"Close All Chats","Title for the close all chats menu item")];
	[menuItem_saveAs setTitle:[AILocalizedString(@"Save As",nil) stringByAppendingEllipsis]];
	[menuItem_pageSetup setTitle:[AILocalizedString(@"Page Setup",nil) stringByAppendingEllipsis]];
	[menuItem_print setTitle:[AILocalizedString(@"Print",nil) stringByAppendingEllipsis]];

	//Edit menu
	[menuItem_cut setTitle:AILocalizedString(@"Cut",nil)];
	[menuItem_copy setTitle:AILocalizedString(@"Copy",nil)];
	[menuItem_paste setTitle:AILocalizedString(@"Paste",nil)];
	[menuItem_pasteAndMatchStyle setTitle:AILocalizedString(@"Paste and Match Style",nil)];
	[menuItem_clear setTitle:AILocalizedString(@"Clear",nil)];
	[menuItem_selectAll setTitle:AILocalizedString(@"Select All",nil)];

#define TITLE_FIND AILocalizedString(@"Find",nil)
	[menuItem_find setTitle:TITLE_FIND];
	[menuItem_findCommand setTitle:[TITLE_FIND stringByAppendingEllipsis]];
	[menuItem_findNext setTitle:AILocalizedString(@"Find Next",nil)];
	[menuItem_findPrevious setTitle:AILocalizedString(@"Find Previous",nil)];
	[menuItem_findUseSelectionForFind setTitle:AILocalizedString(@"Use Selection for Find",nil)];
	[menuItem_findJumpToSelection setTitle:AILocalizedString(@"Jump to Selection",nil)];

#define TITLE_SPELLING AILocalizedString(@"Spelling",nil)
	[menuItem_spelling setTitle:TITLE_SPELLING];
	[menuItem_spellingCommand setTitle:[TITLE_SPELLING stringByAppendingEllipsis]];
	[menuItem_spellingCheckSpelling setTitle:AILocalizedString(@"Check Spelling",nil)];
	[menuItem_spellingCheckSpellingAsYouType setTitle:AILocalizedString(@"Check Spelling As You Type",nil)];

	[menuItem_speech setTitle:AILocalizedString(@"Speech",nil)];
	[menuItem_startSpeaking setTitle:AILocalizedString(@"Start Speaking",nil)];
	[menuItem_stopSpeaking setTitle:AILocalizedString(@"Stop Speaking",nil)];
	
	//View menu
	[menuItem_customizeToolbar setTitle:[AILocalizedString(@"Customize Toolbar",nil) stringByAppendingEllipsis]];

	//Format menu
	[menuItem_bold setTitle:AILocalizedString(@"Bold",nil)];
	[menuItem_italic setTitle:AILocalizedString(@"Italic",nil)];
	[menuItem_underline setTitle:AILocalizedString(@"Underline",nil)];
	[menuItem_showFonts setTitle:AILocalizedString(@"Show Fonts",nil)];
	[menuItem_showColors setTitle:AILocalizedString(@"Show Colors",nil)];
	[menuItem_copyStyle setTitle:AILocalizedString(@"Copy Style",nil)];
	[menuItem_pasteStyle setTitle:AILocalizedString(@"Paste Style",nil)];
	[menuItem_writingDirection setTitle:AILocalizedString(@"Writing Direction",nil)];
	[menuItem_rightToLeft setTitle:AILocalizedString(@"Right to Left",nil)];
	
	//Window menu
	[menuItem_minimize setTitle:AILocalizedString(@"Minimize",nil)];
	[menuItem_bringAllToFront setTitle:AILocalizedString(@"Bring All to Front",nil)];

	//Help menu
	[menuItem_adiumHelp setTitle:AILocalizedString(@"Adium Help",nil)];
	[menuItem_reportABug setTitle:AILocalizedString(@"Report a Bug",nil)];
	[menuItem_sendFeedback setTitle:AILocalizedString(@"Send Feedback",nil)];
	[menuItem_adiumForums setTitle:AILocalizedString(@"Adium Forums",nil)];
}

@end

