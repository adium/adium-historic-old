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
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIExceptionHandlingUtilities.h>

#import "AIHoveringPopUpButton.h"
#import "AIContactListImagePicker.h"
#import "AIContactListNameButton.h"

#define TOOLBAR_CONTACT_LIST				@"ContactList 1.0"				//Toolbar identifier

@interface AIStandardListWindowController (PRIVATE)
- (void)_configureToolbar;
- (void)updateStatusMenuSelection:(NSNotification *)notification;
- (void)updateImagePicker;
- (void)updateNameView;
- (void)repositionImagePickerToPosition:(ContactListImagePickerPosition)desiredImagePickerPosition;
@end

@implementation AIStandardListWindowController

/*
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)inNibName
{	
    if ((self = [super initWithWindowNibName:inNibName])) {
		previousAlpha = 0;
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

	[super dealloc];
}

/*
 * @brief Nib name
 */
+ (NSString *)nibName
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
	
	//Configure the state menu
	statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];

	//Update the selections in our state menu when the active state changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateStatusMenuSelection:)
									   name:AIStatusActiveStateChangedNotification
									 object:nil];
	//Update our state menus when the status icon set changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateStatusMenuSelection:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
	[self updateStatusMenuSelection:nil];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(listObjectAttributesChanged:)
									   name:ListObject_AttributesChanged
									 object:nil];
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
	
	//Set our minimum size here rather than in the nib to avoid conflicts with autosizing
	[[self window] setMinSize:NSMakeSize(135, 60)];

	[self _configureToolbar];
	[nameView setFont:[NSFont boldSystemFontOfSize:10]];	
}

/*!
 * @brief Window closing
 */
- (void)windowWillClose:(id)sender
{
	[[adium notificationCenter] removeObserver:self];
	[statusMenu release];
	
	[super windowWillClose:sender];
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
		
		if ([key isEqualToString:@"Active Display Name Account"] ||
			firstTime) {
			[self updateNameView];
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

- (void)listObjectAttributesChanged:(NSNotification *)inNotification
{
    AIListObject	*object = [inNotification object];

	if ([object isKindOfClass:[AIAccount class]] &&
		[[[inNotification userInfo] objectForKey:@"Keys"] containsObject:@"Display Name"]) {
		[self updateNameView];
	}
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
		
		newImagePickerFrame.origin.x = nameViewFrame.origin.x;
		
		/* I hate a magic number, but for some reason autosizing doesn't seem to work properly for the name view on first load
		 * so if we start off on the right and then move left, a calculated margin of NSMaxX(nameViewFrame) - NSMinX(imagePickerFrame)
		 * wouldn't work.
		 */
		newNameViewFrame.origin.x = (NSMaxX(newImagePickerFrame) + 9.0);
		newStatusMenuViewFrame.origin.x = newNameViewFrame.origin.x + (statusMenuViewFrame.origin.x - nameViewFrame.origin.x);

		[imagePicker setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];

	} else {
		//Image picker is on the left but we want it on the right		
		newNameViewFrame.origin.x = imagePickerFrame.origin.x;
		newStatusMenuViewFrame.origin.x = newNameViewFrame.origin.x + (statusMenuViewFrame.origin.x - nameViewFrame.origin.x);
		
		newImagePickerFrame.origin.x = ([[imagePicker superview] frame].size.width - NSMaxX(imagePickerFrame));

		[imagePicker setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
	}
	
	[statusMenuView setFrame:newStatusMenuViewFrame];
	[[statusMenuView superview] setNeedsDisplayInRect:statusMenuViewFrame];
	[statusMenuView setNeedsDisplay:YES];
	
	[nameView setFrame:newNameViewFrame];
	[[nameView superview] setNeedsDisplayInRect:nameViewFrame];
	[nameView setNeedsDisplay:YES];
	
	[imagePicker setFrame:newImagePickerFrame];
	[[imagePicker superview] setNeedsDisplayInRect:imagePickerFrame];
	[imagePicker setNeedsDisplay:YES];
	
	imagePickerPosition = desiredImagePickerPosition;	
}


#pragma mark User icon changing

/*
 * @brief Determine the account which will be modified by a change to the image picker
 *
 * @result The 'active' account for image purposes, or nil if the global icon is active
 */
+ (AIAccount *)activeAccountForIconsGettingOnlineAccounts:(NSMutableSet *)onlineAccounts ownIconAccounts:(NSMutableSet *)ownIconAccounts
{
	AIAdium		  *sharedAdium = [AIObject sharedAdiumInstance];
	AIAccount	  *account;
	AIAccount	  *activeAccount = nil;
	NSEnumerator  *enumerator;
	BOOL		  atLeastOneOwnIconAccount = NO;
	NSArray		  *accounts = [[sharedAdium accountController] accounts];

	if (!onlineAccounts) onlineAccounts = [NSMutableSet set];
	if (!ownIconAccounts) ownIconAccounts = [NSMutableSet set];
	
	//Figure out what accounts are online and what of those have their own custom icon
	enumerator = [accounts objectEnumerator];
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
		
		/* However, if all accounts are using their own icon, we should return one of them.
		 * Let's use the first one in the accounts list.
		 */
		if (!activeAccount && ([ownIconAccounts count] == [onlineAccounts count])) {
			enumerator = [accounts objectEnumerator];
			while ((account = [enumerator nextObject])) {
				if ([account online]) {
					activeAccount = account;
					break;
				}
			}
		}
	}

	return activeAccount;
}

- (void)updateImagePicker
{
	AIAccount *activeAccount = [[self class] activeAccountForIconsGettingOnlineAccounts:nil ownIconAccounts:nil];
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

/*
 * @brief The image picker changed images
 */
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)picker didChangeToImageData:(NSData *)imageData
{
	AIAccount	*activeAccount = [[self class] activeAccountForIconsGettingOnlineAccounts:nil
																		  ownIconAccounts:nil];

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

#pragma mark Status menu
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
- (void)updateStatusMenuSelection:(NSNotification *)notification
{
	AIStatus	*activeStatus = [[adium statusController] activeStatusState];
	NSString	*title = [activeStatus title];
	if (!title) NSLog(@"Warning: Title for %@ is (null)",activeStatus);
	
	[statusMenuView setTitle:(title ? title : @"")];
	[statusMenuView setImage:[activeStatus iconOfType:AIStatusIconList
											direction:AIIconFlipped]];
	
	[self updateImagePicker];
	[self updateNameView];
}

#pragma mark Name view

/*
 * @brief Determine the account which will be displayed / modified by the name view
 *
 * @result The 'active' account for display name purposes, or nil if the global display name is active
 */
+ (AIAccount *)activeAccountForDisplayNameGettingOnlineAccounts:(NSMutableSet *)onlineAccounts ownDisplayNameAccounts:(NSMutableSet *)ownDisplayNameAccounts
{
	AIAdium		  *sharedAdium = [AIObject sharedAdiumInstance];
	AIAccount	  *account;
	AIAccount	  *activeAccount = nil;
	NSEnumerator  *enumerator;
	BOOL		  atLeastOneOwnDisplayNameAccount = NO;
	NSArray		  *accounts = [[sharedAdium accountController] accounts];
	
	if (!onlineAccounts) onlineAccounts = [NSMutableSet set];
	if (!ownDisplayNameAccounts) ownDisplayNameAccounts = [NSMutableSet set];
	
	//Figure out what accounts are online and what of those have their own custom display name
	enumerator = [[[sharedAdium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account online]) {
			[onlineAccounts addObject:account];
			if ([[[account preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES] attributedString] length]) {
				[ownDisplayNameAccounts addObject:account];
				atLeastOneOwnDisplayNameAccount = YES;
			}
		}
	}
	
	//At least one account is using its own display name rather than the global preference
	if (atLeastOneOwnDisplayNameAccount) {
		NSString	*accountID = [[sharedAdium preferenceController] preferenceForKey:@"Active Display Name Account"
																				group:GROUP_ACCOUNT_STATUS];
		
		activeAccount = (accountID ? [[sharedAdium accountController] accountWithInternalObjectID:accountID] : nil);
		
		//If the activeAccount isn't in ownDisplayNameAccounts we don't want anything to do with it
		if (![ownDisplayNameAccounts containsObject:activeAccount]) activeAccount = nil;
		
		/* However, if all accounts are using their own display name, we should return one of them.
			* Let's use the first one in the accounts list.
			*/
		if (!activeAccount && ([ownDisplayNameAccounts count] == [onlineAccounts count])) {
			enumerator = [accounts objectEnumerator];
			while ((account = [enumerator nextObject])) {
				if ([account online]) {
					activeAccount = account;
					break;
				}
			}
		}
	}
	
	return activeAccount;
}

- (void)nameViewSelectedAccount:(id)sender
{
	[[adium preferenceController] setPreference:[[sender representedObject] internalObjectID]
										 forKey:@"Active Display Name Account"
										  group:GROUP_ACCOUNT_STATUS];
}

- (void)nameView:(AIContactListNameButton *)nameView didChangeToString:(NSString *)inName userInfo:(NSDictionary *)userInfo
{
	AIAccount			*activeAccount = [userInfo objectForKey:@"activeAccount"];
	NSAttributedString	*newDisplayName = ((inName && [inName length]) ?
										   [[NSAttributedString stringWithString:inName] dataRepresentation] :
										   nil);

	if (activeAccount) {
		[activeAccount setPreference:newDisplayName
							  forKey:KEY_ACCOUNT_DISPLAY_NAME
							   group:GROUP_ACCOUNT_STATUS];
	} else {
		[[adium preferenceController] setPreference:newDisplayName
											 forKey:KEY_ACCOUNT_DISPLAY_NAME
											  group:GROUP_ACCOUNT_STATUS];
	}
}

- (void)nameViewChangeName:(id)sender
{
	AIAccount	*activeAccount = [[self class] activeAccountForDisplayNameGettingOnlineAccounts:nil
																		  ownDisplayNameAccounts:nil];
	NSString	*startingString = nil;

	if (activeAccount) {
		startingString = [[[activeAccount preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
													 group:GROUP_ACCOUNT_STATUS] attributedString] string];		

	} else {
		startingString = [[[[adium preferenceController] preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
																	group:GROUP_ACCOUNT_STATUS] attributedString] string];
	}

	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	if (activeAccount) {
		[userInfo setObject:activeAccount
					 forKey:@"activeAccount"];
	}

	[nameView editNameStartingWithString:startingString
						 notifyingTarget:self
								selector:@selector(nameView:didChangeToString:userInfo:)
								userInfo:userInfo];
}

- (NSMenu *)nameViewMenuWithActiveAccount:(AIAccount *)activeAccount accountsUsingOwnName:(NSSet *)ownDisplayNameAccounts onlineAccounts:(NSSet *)onlineAccounts
{
	NSEnumerator *enumerator;
	AIAccount *account;
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Display Name For:", nil)
										  target:nil
										  action:nil
								   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	[menu addItem:menuItem];
	[menuItem release];
	
	enumerator = [ownDisplayNameAccounts objectEnumerator];
	while ((account = [enumerator nextObject])) {
		//Put a check before the account if it is the active account
		menuItem = [[NSMenuItem alloc] initWithTitle:[account formattedUID]
											  target:self
											  action:@selector(nameViewSelectedAccount:)
									   keyEquivalent:@""];
		[menuItem setRepresentedObject:account];
		
		if (activeAccount == account) {
			[menuItem setState:NSOnState];
		}
		[menuItem setIndentationLevel:1];
		[menu addItem:menuItem];
		
		[menuItem release];
	}
	
	//Show "All Other Accounts" if some accounts are using the global preference
	if ([ownDisplayNameAccounts count] != [onlineAccounts count]) {
		menuItem = [[NSMenuItem alloc] initWithTitle:ALL_OTHER_ACCOUNTS
											  target:self
											  action:@selector(nameViewSelectedAccount:)
									   keyEquivalent:@""];
		if (!activeAccount) {
			[menuItem setState:NSOnState];
		}
		[menuItem setIndentationLevel:1];
		[menu addItem:menuItem];
		[menuItem release];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Change Display Name", nil) stringByAppendingEllipsis]
										  target:self
										  action:@selector(nameViewChangeName:)
								   keyEquivalent:@""];
	[menu addItem:menuItem];
	[menuItem release];	
	
	return [menu autorelease];
}

- (void)updateNameView
{
	NSMutableSet *ownDisplayNameAccounts = [NSMutableSet set];
	NSMutableSet *onlineAccounts = [NSMutableSet set];
	AIAccount	 *activeAccount = [[self class] activeAccountForDisplayNameGettingOnlineAccounts:onlineAccounts
																		  ownDisplayNameAccounts:ownDisplayNameAccounts];
	NSString	 *alias = nil;

	if (activeAccount) {
		//There is a specific account active whose display name we should show
		alias = [activeAccount displayName];
	} else {
		/* There isn't an account active. We should show the global preference if possible.  Using it directly would mean
		 * that it displays exactly as typed by the user, whereas using it via an account's displayName means it is preprocessed
		 * for any substitutions, which looks better.
		*/
		NSMutableSet *onlineAccountsUsingGlobalPreference = [onlineAccounts mutableCopy];
		[onlineAccountsUsingGlobalPreference minusSet:ownDisplayNameAccounts];
		if ([onlineAccountsUsingGlobalPreference count]) {
			alias = [[onlineAccountsUsingGlobalPreference anyObject] displayName];

		} else {
			//No online accounts... look for an enabled account ('cause we still want to use displayName if possible)
			NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
			AIAccount		*account = nil;
			
			while ((account = [enumerator nextObject]) && ![account enabled]);
			
			alias = [account displayName];
		}

		[onlineAccountsUsingGlobalPreference release];
	}
	
	if ((!activeAccount && ![ownDisplayNameAccounts count]) || ([onlineAccounts count] == 1)) {
		//We're using the global preference, or we're the single online account has its own display name
		[nameView setHighlightOnHoverAndClick:NO];
		[nameView setTarget:self];
		[nameView setDoubleAction:@selector(nameViewChangeName:)];
		[nameView setMenu:nil];
	} else {
		//Multiple possibilities, so we rock with a menu
		[nameView setHighlightOnHoverAndClick:YES];
		[nameView setDoubleAction:NULL];
		[nameView setMenu:[self nameViewMenuWithActiveAccount:activeAccount 
										 accountsUsingOwnName:ownDisplayNameAccounts
											   onlineAccounts:onlineAccounts]];
	}

	/* If we don't have an alias to display as our text yet, grab from the global preferences. This can be the case
	 * in a no-accounts-enabled situation.
	 */
	if (!alias || ![alias length]) {
		alias = [[[[adium preferenceController] preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
														   group:GROUP_ACCOUNT_STATUS] attributedString] string];
		if (!alias || ![alias length]) {
			alias = @"Adium";
		}
	}

	[nameView setTitle:alias];
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
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:YES];

	/* Seemingly randomling, setToolbar: may throw:
	 * Exception:	NSInternalInconsistencyException
	 * Reason:		Uninitialized rectangle passed to [View initWithFrame:].
	 *
	 * With the same window positioning information as a user for whom this happens consistently, I can't reproduce. Let's
	 * fail to set the toolbar gracefully.
	 */
	AI_DURING
		[[self window] setToolbar:toolbar];
	AI_HANDLER
		NSLog(@"Warning: While setting the contact list's toolbar, exception %@ (%@) was thrown.",
			  [localException name],
			  [localException reason]);
	AI_ENDHANDLER
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *statusAndIconItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"StatusAndIcon"];
	[statusAndIconItem setMinSize:NSMakeSize(100, [view_statusAndImage bounds].size.height)];
	[statusAndIconItem setMaxSize:NSMakeSize(100000, [view_statusAndImage bounds].size.height)];
	[statusAndIconItem setView:view_statusAndImage];

	return [statusAndIconItem autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObject:@"StatusAndIcon"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObject:@"StatusAndIcon"];
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

void manualWindowMoveToPoint(NSWindow *inWindow, NSPoint targetPoint, AIRectEdgeMask windowSlidOffScreenEdgeMask, AIListController *contactListController)
{
	NSScreen *windowScreen = [inWindow screen];
	if(!windowScreen) windowScreen = [NSScreen mainScreen];
	BOOL	finishedX = NO, finishedY = NO;
	NSRect	frame = [inWindow frame];
	float yOff = (targetPoint.y + frame.size.height) - ([windowScreen frame].size.height - [NSMenuView menuBarHeight]);
	if(yOff > 0) targetPoint.y -= yOff;

	do
	{
		frame = [inWindow frame];
#define INCREMENT 15
		if (abs(targetPoint.x - frame.origin.x) <= INCREMENT) {
			//Our target point is within INCREMENT of the current point on the x axis
			
			if (windowSlidOffScreenEdgeMask != AINoEdges) {
				//If the window is sliding off screen, keep one pixel onscreen to avoid crashing
				if (targetPoint.x < frame.origin.x) {
					frame.origin.x = targetPoint.x + 1;
				} else if (targetPoint.x > frame.origin.x) {
					frame.origin.x = targetPoint.x - 1;
				}
				
			} else {
				//If the window is sliding on screen, go to the exact desired point
				frame.origin.x = targetPoint.x;
			}
			
			finishedX = YES;
			
		} else if (targetPoint.x < frame.origin.x) {
			frame.origin.x -= INCREMENT;
		} else if (targetPoint.x > frame.origin.x) {
			frame.origin.x += INCREMENT;		
		}
		
		if (abs(targetPoint.y - frame.origin.y) <= INCREMENT) {
			//Our target point is within INCREMENT of the current point on the y axis
			if (windowSlidOffScreenEdgeMask != AINoEdges) {
				//If the window is sliding off screen, keep one pixel onscreen to avoid crashing
				if (targetPoint.y < frame.origin.y) {
					frame.origin.y = targetPoint.y + 1;
				} else if (targetPoint.y > frame.origin.y) {
					frame.origin.y = targetPoint.y - 1;
				}
				
			} else {
				//If the window is sliding on screen, go to the exact desired point
				frame.origin.y = targetPoint.y;
				
			}
			
			finishedY = YES;
			
		} else if (targetPoint.y < frame.origin.y) {
			frame.origin.y -= INCREMENT;
		} else if (targetPoint.y > frame.origin.y) {
			frame.origin.y += INCREMENT;		
		}
		
		[inWindow setFrame:frame display:YES animate:NO];
	}
	while(!finishedX || !finishedY);
}

/*
 * @brief Slide the window to a given point
 *
 * windowSlidOffScreenEdgeMask must already be set to the resulting offscreen mask (or 0 if the window is sliding on screen)
 *
 * A standard window (titlebar window) will crash if told to setFrame completely offscreen,
 * so we implement our own animated movement.
 */
- (void)slideWindowToPoint:(NSPoint)inPoint
{
	NSWindow	*myWindow = [self window];

	if ((windowSlidOffScreenEdgeMask == AINoEdges) &&
		(previousAlpha > 0.0)) {
		//Before sliding onscreen, restore any previous alpha value
		[myWindow setAlphaValue:previousAlpha];
	}
	
	manualWindowMoveToPoint([self window],
							inPoint,
							windowSlidOffScreenEdgeMask,
							contactListController);
	
	if (windowSlidOffScreenEdgeMask == AINoEdges) {
		/* When the window is offscreen, there are no constraints on its size, for example it will grow downwards as much as
		 * it needs to to accomodate new rows.  Now that it's onscreen, there are constraints.
		 */
		[contactListController contactListDesiredSizeChanged];			
	} else {
		//After sliding off screen, go to an alpha value of 0 to hide our 1 px remaining on screen
		previousAlpha = [myWindow alphaValue];
		[myWindow setAlphaValue:0.0];
	}
}

@end
