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

#import "AIStandardListWindowController.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import "AIToolbarController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIStatusMenu.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#import "AIContactListStatusMenuView.h"
#import "AIContactListImagePicker.h"
#import "AIContactListNameView.h"

#define TOOLBAR_CONTACT_LIST				@"ContactList"				//Toolbar identifier

@interface AIStandardListWindowController (PRIVATE)
- (void)_configureToolbar;
- (void)activeStateChanged:(NSNotification *)notification;
- (void)updateImagePicker;
- (void)repositionImagePickerToPosition:(ContactListImagePickerPosition)desiredImagePickerPosition;
@end

@implementation AIStandardListWindowController

/*
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init]))
	{
		toolbarItems = nil;
	}

	return self;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
	[toolbarItems release];
	
	[super dealloc];
}

/*
 * @brief Nib name
 */
- (NSString *)nibName
{
    return @"ContactListWindow";
}

/*
 * @brief Window loaded
 */
- (void)windowDidLoad
{
	//Our nib starts with the image picker on the left side
	imagePickerPosition = ContactListImagePickerOnLeft;

	[super windowDidLoad];
	
	[self _configureToolbar];
	[[self window] setTitle:AILocalizedString(@"Contacts","Contact List window title")];

	//Configure the state menu
	statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];

	//Update the selections in our state menu when the active state changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(activeStateChanged:)
									   name:AIStatusActiveStateChangedNotification
									 object:nil];
	[self activeStateChanged:nil];
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Window closing
 */
- (void)windowWillClose:(id)sender
{
	[statusMenu release];
	
	[super windowWillClose:sender];
}

/*!
 * @brief Add state menu items to our location
 *
 * Implemented as required by the StateMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
    NSMenu			*menu = [[NSMenu alloc] init];
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;

	//Add a menu item for each state
	while ((menuItem = [enumerator nextObject])) {
		[menu addItem:menuItem];
	}
	
	[statusMenuView setMenu:menu];
	[menu release];
}

/*
 * Update popup button to match selected menu item
 */
- (void)activeStateChanged:(NSNotification *)notification
{
	AIStatus	*activeStatus = [[adium statusController] activeStatusState];
	[statusMenuView setTitle:[activeStatus title]];
	[statusMenuView setImage:[activeStatus iconOfType:AIStatusIconList
											direction:AIIconFlipped]];

	[self updateImagePicker];
}

- (void)updateImagePicker
{
	AIAccount *activeAccount = [[self class] activeAccountGettingOnlineAccounts:nil ownIconAccounts:nil];
	NSImage	  *image;

	if (activeAccount) {
		image = [activeAccount userIcon];
	} else {
		NSData *data = [[adium preferenceController] preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS];
		if (!data) data = [[adium preferenceController] preferenceForKey:KEY_DEFAULT_USER_ICON group:GROUP_ACCOUNT_STATUS];

		image = [[[NSImage alloc] initWithData:data] autorelease];
	}

	[imagePicker setImage:image];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:GROUP_ACCOUNT_STATUS]) {
		if ([key isEqualToString:KEY_USER_ICON] ||
			[key isEqualToString:KEY_DEFAULT_USER_ICON] || 
			[key isEqualToString:KEY_USE_USER_ICON] ||
			[key isEqualToString:@"Active Icon Selection Account"] ||
			firstTime) {
			[self updateImagePicker];
		}
	}

	/*
	 * We move our image picker to mirror the contact list's own layout
	 */
	if ([group isEqualToString:PREF_GROUP_LIST_LAYOUT]) {
		LIST_POSITION					layoutUserIconPosition = [[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue];
		ContactListImagePickerPosition  desiredImagePickerPosition;

		//Determine where we want the image picker now
		switch (layoutUserIconPosition) {
			case LIST_POSITION_RIGHT:
			case LIST_POSITION_FAR_RIGHT:
			case LIST_POSITION_BADGE_RIGHT:
				desiredImagePickerPosition = ContactListImagePickerOnRight;
				break;
			case LIST_POSITION_NA:
			case LIST_POSITION_FAR_LEFT:
			case LIST_POSITION_LEFT:
			case LIST_POSITION_BADGE_LEFT:
			default:
				desiredImagePickerPosition = ContactListImagePickerOnLeft;
				break;				
		}

		//Only proceed if this new position is different from the old one
		if (desiredImagePickerPosition != imagePickerPosition) {
			[self repositionImagePickerToPosition:desiredImagePickerPosition];
		}
	}
	
	[super preferencesChangedForGroup:group
								  key:key
							   object:object
					   preferenceDict:prefDict
							firstTime:firstTime];
}

/*
 * @brief Reposition the image picker to a desireed position
 *
 * This shifts the status picker view and the name view in the opposite direction, maintaining the same relative spacing relationships
 */
- (void)repositionImagePickerToPosition:(ContactListImagePickerPosition)desiredImagePickerPosition
{
	NSRect statusMenuViewFrame = [statusMenuView frame];
	NSRect newStatusMenuViewFrame = statusMenuViewFrame;
	
	NSRect nameViewFrame = [nameView frame];
	NSRect newNameViewFrame = nameViewFrame;
	
	NSRect imagePickerFrame = [imagePicker frame];
	NSRect newImagePickerFrame = imagePickerFrame;
	
	if (desiredImagePickerPosition == ContactListImagePickerOnLeft) {
		//Image picker is on the right but we want it on the left
		float margin = (NSMinX(imagePickerFrame) - NSMaxX(statusMenuViewFrame));
		
		newImagePickerFrame.origin.x = statusMenuViewFrame.origin.x;
		newStatusMenuViewFrame.origin.x = (NSMaxX(newImagePickerFrame) + margin);
		newNameViewFrame.origin.x = newStatusMenuViewFrame.origin.x + (statusMenuViewFrame.origin.x - nameViewFrame.origin.x);
		
		[imagePicker setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];

	} else {
		//Image picker is on the left but we want it on the right
		float margin = (NSMinX(statusMenuViewFrame) - NSMaxX(imagePickerFrame));
		
		newStatusMenuViewFrame.origin.x = imagePickerFrame.origin.x;
		newNameViewFrame.origin.x = newStatusMenuViewFrame.origin.x + (statusMenuViewFrame.origin.x - nameViewFrame.origin.x);
		
		newImagePickerFrame.origin.x = (NSMaxX(newStatusMenuViewFrame) + margin);

		[imagePicker setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
	}
	
	NSView *myContentView = [[self window] contentView];
	
	[statusMenuView setFrame:newStatusMenuViewFrame];
	[myContentView setNeedsDisplayInRect:statusMenuViewFrame];
	[statusMenuView setNeedsDisplay:YES];
	
	[nameView setFrame:newNameViewFrame];
	[myContentView setNeedsDisplayInRect:nameViewFrame];
	[nameView setNeedsDisplay:YES];
	
	[imagePicker setFrame:newImagePickerFrame];
	[myContentView setNeedsDisplayInRect:imagePickerFrame];
	[imagePicker setNeedsDisplay:YES];
	
	imagePickerPosition = desiredImagePickerPosition;
}

/*
 * @brief Determine the account which will be modified by a change to the image picker
 *
 * @result The 'active' accnt for image purposes, or nil if the global icon is active
 */
+ (AIAccount *)activeAccountGettingOnlineAccounts:(NSMutableSet *)onlineAccounts ownIconAccounts:(NSMutableSet *)ownIconAccounts
{
	AIAdium		  *sharedAdium = [AIObject sharedAdiumInstance];
	AIAccount	  *account;
	AIAccount	  *activeAccount = nil;
	NSEnumerator  *enumerator;
	BOOL		  atLeastOneOwnIconAccount = NO;

	//Figure out what accounts are online and what of those have their own custom icon so we can display an appropriate set of choices
	enumerator = [[[sharedAdium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account online]) {
			[onlineAccounts addObject:account];
			if ([account preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES]) {
				[ownIconAccounts addObject:account];
				atLeastOneOwnIconAccount = YES;
			}
		}
	}
	
	//At least one account is using its own icon rather than the global preference
	if (atLeastOneOwnIconAccount) {
		NSString	*accountID = [[sharedAdium preferenceController] preferenceForKey:@"Active Icon Selection Account"
																		  group:GROUP_ACCOUNT_STATUS];
		
		activeAccount = (accountID ? [[sharedAdium accountController] accountWithInternalObjectID:accountID] : nil);
		
		//If the activeAccount isn't in ownIconAccounts we don't want anything to do with it
		if (![ownIconAccounts containsObject:activeAccount]) activeAccount = nil;
	}
	
	return activeAccount;
}

/*
 * @brief The image picker changed images
 */
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)picker didChangeToImageData:(NSData *)imageData
{
	AIAccount	*activeAccount = [AIStandardListWindowController activeAccountGettingOnlineAccounts:nil ownIconAccounts:nil];

	if (activeAccount) {
		[activeAccount setPreference:imageData
							  forKey:KEY_USER_ICON
							   group:GROUP_ACCOUNT_STATUS];

	} else {
		[[adium preferenceController] setPreference:imageData
											 forKey:KEY_USER_ICON
											  group:GROUP_ACCOUNT_STATUS];
	}
}

//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_CONTACT_LIST] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:NO];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	
    //
    toolbarItems = [[[adium toolbarController] toolbarItemsForToolbarTypes:[NSArray arrayWithObjects:@"General", @"ListObject", @"ContactList",nil]] retain];
	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return[NSArray arrayWithObjects:@"OfflineContacts", NSToolbarSeparatorItemIdentifier,
		@"ShowInfo", @"NewMessage", NSToolbarFlexibleSpaceItemIdentifier, @"AddContact", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

- (void)windowDidToggleToolbarShown:(NSWindow *)sender
{
	[contactListController contactListDesiredSizeChanged];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	return [contactListController _desiredWindowFrameUsingDesiredWidth:YES
														 desiredHeight:YES];
}

#pragma mark Dock-like hiding

- (AIRectEdgeMask)slidableEdgesAdjacentToWindow
{
	// no edges are slidable if the window has a border.
	// Attempting to use -[NSWindow setFrame:display:animate:] to slide a bordered window off screen will 
	// cause the application to crash.  So why is Dock-like hiding implemented in AIListWindowController instead of 
	// AIBorderlessWindowController?  This is because it would be a good thing (tm) if we could make it work
	// for bordered windows as well.  We should try implementing -[NSWindow constrainFrameRect:toScreen:].
	return 0;
}

@end
