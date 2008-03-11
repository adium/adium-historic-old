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

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#import <Adium/AIListGroup.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIListSmartGroup.h>

#import "AIStatusController.h"
#import "AIStandardListWindowController.h"

#import "AIHoveringPopUpButton.h"
#import "AIContactListImagePicker.h"
#import "AIContactListNameButton.h"
#import "AIContactController.h"
#import "AIContactHidingController.h"

#define PREF_GROUP_APPEARANCE		@"Appearance"

#define TOOLBAR_CONTACT_LIST				@"ContactList:1.0"				//Toolbar identifier

@interface AIStandardListWindowController (PRIVATE)
- (void)_configureToolbar;
- (void)updateStatusMenuSelection:(NSNotification *)notification;
- (void)updateImagePicker;
- (void)updateNameView;
- (void)repositionImagePickerToPosition:(ContactListImagePickerPosition)desiredImagePickerPosition;
@end

@implementation AIStandardListWindowController

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief Nib name
 */
+ (NSString *)nibName
{
    return @"ContactListWindow";
}

/*!
 * @brief Window loaded
 */
- (void)windowDidLoad
{
	//Our nib starts with the image picker on the left side
	imagePickerPosition = ContactListImagePickerOnLeft;
	
	[super windowDidLoad];
	
	[nameView setFont:[NSFont fontWithName:@"Lucida Grande" size:12]];
	
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
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateStatusMenuSelection:)
									   name:@"AIStatusFilteredStatusMessageChanged"
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
	
	
	filterBarIsVisible = NO;
	[searchField setDelegate:self];
	[[[searchField cell]cancelButtonCell]setTarget:self];
	[[[searchField cell]cancelButtonCell]setAction:@selector(hideFilterBar:)];
	
	[[NSNotificationCenter defaultCenter]addObserver:self
											selector:@selector(hideFilterBarFromWindowResignedMain:)
												name:NSWindowDidResignMainNotification
											  object:nil];
		
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

- (void)positionImagePickerIfNeeded
{
	LIST_POSITION					layoutUserIconPosition = [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION
																						 group:PREF_GROUP_LIST_LAYOUT] intValue];
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
	
	
	AIAccount *activeAccount = [[self class] activeAccountForIconsGettingOnlineAccounts:nil ownIconAccounts:nil];
	BOOL imagePickerIsVisible;
	
	if (activeAccount) {
		imagePickerIsVisible = ([activeAccount userIcon] != nil);
	} else {
		imagePickerIsVisible = [[[adium preferenceController] preferenceForKey:KEY_USE_USER_ICON group:GROUP_ACCOUNT_STATUS] boolValue];
	}
	
	if (!imagePickerIsVisible) {
		desiredImagePickerPosition = ((desiredImagePickerPosition == ContactListImagePickerOnLeft) ?
									  ContactListImagePickerHiddenOnLeft :
									  ContactListImagePickerHiddenOnRight);
	}
	
	//Only proceed if this new position is different from the old one
	if (desiredImagePickerPosition != imagePickerPosition) {
		[self repositionImagePickerToPosition:desiredImagePickerPosition];
	}
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
			[self positionImagePickerIfNeeded];
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
		[self positionImagePickerIfNeeded];
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

/*!
 * @brief Reposition the image picker to a desireed position
 *
 * This shifts the status picker view and the name view in the opposite direction, maintaining the same relative spacing relationships
 */
- (void)repositionImagePickerToPosition:(ContactListImagePickerPosition)desiredImagePickerPosition
{
	NSRect nameAndStatusMenuFrame = [view_nameAndStatusMenu frame];
	NSRect newNameAndStatusMenuFrame = nameAndStatusMenuFrame;
	
	NSRect imagePickerFrame = [imagePicker frame];
	NSRect newImagePickerFrame = imagePickerFrame;
	
	switch (desiredImagePickerPosition)
	{
		case ContactListImagePickerOnLeft:
		case ContactListImagePickerHiddenOnLeft:
		{
			if ((imagePickerPosition == ContactListImagePickerOnRight) ||
				(imagePickerPosition == ContactListImagePickerHiddenOnRight)) {
				//Image picker is on the right but we want it on the left
				newImagePickerFrame.origin.x = NSMinX(nameAndStatusMenuFrame);	
			}
			
			if (desiredImagePickerPosition == ContactListImagePickerOnLeft) {
				if ((imagePickerPosition == ContactListImagePickerHiddenOnLeft) ||
					(imagePickerPosition == ContactListImagePickerHiddenOnRight)) {
					//Image picker was hidden but now is visible; shrink the name/status menu
					newNameAndStatusMenuFrame.size.width -= NSWidth(newImagePickerFrame);
					[imagePicker setHidden:NO];
				}
				
				newNameAndStatusMenuFrame.origin.x = NSMaxX(newImagePickerFrame);
				
			} else /* if (desiredImagePickerPosition == ContactListImagePickerHiddenOnLeft) */ {
				if ((imagePickerPosition == ContactListImagePickerOnLeft) ||
					(imagePickerPosition == ContactListImagePickerOnRight)) {
					//Image picker was visible but now is hidden; expand the name/status menu
					newNameAndStatusMenuFrame.size.width += NSWidth(newImagePickerFrame);
					[imagePicker setHidden:YES];
				}
				
				newNameAndStatusMenuFrame.origin.x = NSMinX(newImagePickerFrame);
			}
			
			[imagePicker setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
			
			break;
		}
		case ContactListImagePickerOnRight:
		case ContactListImagePickerHiddenOnRight:
		{
			if (desiredImagePickerPosition == ContactListImagePickerOnRight) {
				if ((imagePickerPosition == ContactListImagePickerHiddenOnLeft) ||
					(imagePickerPosition == ContactListImagePickerHiddenOnRight)) {
					//Image picker was hidden but not is visible; shrink the name/status menu
					newNameAndStatusMenuFrame.size.width -= NSWidth(newImagePickerFrame);
					[imagePicker setHidden:NO];	
				}
				
			} else /* if (desiredImagePickerPosition == ContactListImagePickerHiddenOnLeft) */ {
				if ((imagePickerPosition == ContactListImagePickerOnLeft) ||
					(imagePickerPosition == ContactListImagePickerOnRight)) {
					//Image picker was visible but now is hidden; expand the name/status menu
					newNameAndStatusMenuFrame.size.width += NSWidth(newImagePickerFrame);
					[imagePicker setHidden:YES];
				}
			}
			
			if ((imagePickerPosition == ContactListImagePickerOnLeft) ||
				(imagePickerPosition == ContactListImagePickerHiddenOnLeft)) {
				/* Image picker is on the left but we want it on the right. Positioning is frame relative, not name-and-status-menu relative,
				 * so we can position it the same regardless of hidden status. */
				newImagePickerFrame.origin.x = (NSWidth([[imagePicker superview] frame]) - NSMaxX(imagePickerFrame));
				newNameAndStatusMenuFrame.origin.x = NSMinX(imagePickerFrame);
			}
			
			[imagePicker setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
			break;
		}
	}
	
	[view_nameAndStatusMenu setFrame:newNameAndStatusMenuFrame];
	[[nameView superview] setNeedsDisplayInRect:nameAndStatusMenuFrame];
	[view_nameAndStatusMenu setNeedsDisplay:YES];
	
	[imagePicker setFrame:newImagePickerFrame];
	[[imagePicker superview] setNeedsDisplayInRect:imagePickerFrame];
	[imagePicker setNeedsDisplay:YES];
	
	imagePickerPosition = desiredImagePickerPosition;	
}


#pragma mark User icon changing

/*!
 * @brief Determine the account which will be modified by a change to the image picker
 *
 * @result The 'active' account for image purposes, or nil if the global icon is active
 */
+ (AIAccount *)activeAccountForIconsGettingOnlineAccounts:(NSMutableSet *)onlineAccounts ownIconAccounts:(NSMutableSet *)ownIconAccounts
{
	NSObject<AIAdium>	*sharedAdium = [AIObject sharedAdiumInstance];
	AIAccount			*account;
	AIAccount			*activeAccount = nil;
	NSEnumerator		*enumerator;
	BOOL				atLeastOneOwnIconAccount = NO;
	NSArray				*accounts = [[sharedAdium accountController] accounts];
	
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

- (NSImage *)imageForImagePicker
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
	
	return image;
}

- (void)updateImagePicker
{
	[imagePicker setImage:[[self imageForImagePicker] imageByScalingToSize:[imagePicker frame].size]];
}

- (NSImage *)imageForImageViewWithImagePicker:(AIImageViewWithImagePicker *)picker
{
	return [self imageForImagePicker];
}

/*!
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
	/*
	 [statusMenuView setImage:[activeStatus iconOfType:AIStatusIconList
	 direction:AIIconFlipped]];
	 */
	[imageView_status setImage:[activeStatus iconOfType:AIStatusIconList
											  direction:AIIconNormal]];
	[statusMenuView setToolTip:[activeStatus statusMessageTooltipString]];
	
	[self updateImagePicker];
	[self updateNameView];
}

#pragma mark Name view

/*!
 * @brief Determine the account which will be displayed / modified by the name view
 *
 * @param onlineAccounts If non-nil, the NSMutableSet will have all online accounts
 * @param onlineAccounts If non-nil, the NSMutableSet will have all online accounts with a per-account display name set
 *
 * @result The 'active' account for display name purposes, or nil if the global display name is active
 */
+ (AIAccount *)activeAccountForDisplayNameGettingOnlineAccounts:(NSMutableSet *)onlineAccounts ownDisplayNameAccounts:(NSMutableSet *)ownDisplayNameAccounts
{
	NSObject<AIAdium>	*sharedAdium = [AIObject sharedAdiumInstance];
	AIAccount			*account;
	AIAccount			*activeAccount = nil;
	NSEnumerator		*enumerator;
	BOOL				atLeastOneOwnDisplayNameAccount = NO;
	NSArray				*accounts = [[sharedAdium accountController] accounts];
	
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

- (void)nameView:(AIContactListNameButton *)inNameView didChangeToString:(NSString *)inName userInfo:(NSDictionary *)userInfo
{
	AIAccount	*activeAccount = [userInfo objectForKey:@"activeAccount"];
	NSData		*newDisplayName = ((inName && [inName length]) ?
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
		[menuItem setImage:[AIServiceIcons serviceIconForObject:account type:AIServiceIconSmall direction:AIIconNormal]];
		
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
			/* No online accounts... look for an enabled account using the global preference
			 * 'cause we still want to use displayName if possible
			 */
			NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
			AIAccount		*account = nil;
			
			while ((account = [enumerator nextObject])) {
				if ([account enabled] && 
					![[[account preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME 
										   group:GROUP_ACCOUNT_STATUS
						   ignoreInheritedValues:YES] attributedString] length]) break;
			}
			
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
	[nameView setToolTip:alias];
}

#pragma mark Sliding

- (BOOL)keepListOnScreenWhenSliding
{
	return YES;
}

//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_CONTACT_LIST] autorelease];
	
	[toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setAllowsUserCustomization:NO];
	
	/* Seemingly randomling, setToolbar: may throw:
	 * Exception:	NSInternalInconsistencyException
	 * Reason:		Uninitialized rectangle passed to [View initWithFrame:].
	 *
	 * With the same window positioning information as a user for whom this happens consistently, I can't reproduce. Let's
	 * fail to set the toolbar gracefully.
	 */
	@try
	{
		[[self window] setToolbar:toolbar];
	}
	@catch(id exc)
	{
		NSLog(@"Warning: While setting the contact list's toolbar, exception %@ was thrown.", exc);
	}
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

#pragma mark Filtering
- (void)toggleFindPanel:(id)sender;
{
	[self toggleFilterBar:sender];
}
- (void)forwardKeyEventToFindPanel:(NSEvent *)theEvent;
{
	//if we were not searching something before, we need to show the filter bar first
	[self showFilterBar:nil];
	
	[[self window]makeFirstResponder:searchField];
	[[[self window] fieldEditor:YES forObject:searchField]keyDown:theEvent];
	
}
- (IBAction)showFilterBar:(id)sender;
{
	if (filterBarIsVisible || filterBarIsAnimating)
		return;
	
	NSSize filterBarSize = [filterBarView bounds].size;
	
	//contact list resizing
	//we need to decrease the height of the contact list to make room for the filter bar
	id viewToResize;
	if([contactListView enclosingScrollView])
		viewToResize = [contactListView enclosingScrollView];
	else
		viewToResize = contactListView;
	
	NSRect viewFrame = [viewToResize frame];
	
	
	NSRect endingViewFrame = viewFrame;
	endingViewFrame.size.height = viewFrame.size.height - filterBarSize.height;
	
	NSDictionary *viewToResizeAnimationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:viewToResize, NSViewAnimationTargetKey,
													 [NSValue valueWithRect:endingViewFrame], NSViewAnimationEndFrameKey, nil];
	
	
	
	//filter bar view resizing
	//start the filter bar at the top of the window
	NSRect startingFilterBarFrame = NSMakeRect(endingViewFrame.origin.x,
											   viewFrame.size.height,
											   endingViewFrame.size.width,
											   filterBarSize.height);
	
	//...and end with the filter bar on top of the contact list
	NSRect endingFilterBarFrame = NSMakeRect(endingViewFrame.origin.x, 
											 endingViewFrame.size.height,
											 endingViewFrame.size.width,
											 filterBarSize.height);
	
	//put the tiny filter bar in the window before we begin the animation
	[filterBarView setFrame:startingFilterBarFrame];
	[[[self window]contentView]addSubview:filterBarView];
	
	[[self window]makeFirstResponder:searchField]; 
	
	NSDictionary *filterBarAnimationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:filterBarView, NSViewAnimationTargetKey,
												  [NSValue valueWithRect:endingFilterBarFrame], NSViewAnimationEndFrameKey, nil];
	
	
	showFilterBarAnimation = [[NSViewAnimation alloc]initWithViewAnimations:[NSArray arrayWithObjects:viewToResizeAnimationDictionary,filterBarAnimationDictionary,nil]];
	[showFilterBarAnimation setDuration:0.25];
	[showFilterBarAnimation setDelegate:self];
	filterBarIsAnimating = YES;
	//disable vertical autoresizing just while the animation is running
	//this prevents display bugs that can occur when contacts are being shown/hidden that cause the frame to change while the filter bar is sliding
	[contactListController setAutoresizeVertically:NO];
	[showFilterBarAnimation startAnimation];
	
	//disable horizontal autoresizing while the filter bar is shown so the width does not change when longer contacts are eliminated as results
	[contactListController setAutoresizeHorizontally:NO];
	
	
	//contact list animation is a cool idea, but too glichy to work well when hiding/showing potentially hundreds of contacts
	[contactListView setEnableAnimation:NO];
	
	filterBarIsVisible = YES;
}

- (IBAction)hideFilterBar:(id)sender;
{
	if (!filterBarIsVisible || filterBarIsAnimating)
		return;
	
	//clear the search and show all contacts
	[searchField setStringValue:@""];
	[self filterContacts:searchField];
	
	NSSize filterBarSize = [filterBarView bounds].size;
	
	//contact list resizing
	//we need to increase the height of the contact list as we decrease the height of the filter bar
	id viewToResize;
	if([contactListView enclosingScrollView])
		viewToResize = [contactListView enclosingScrollView];
	else
		viewToResize = contactListView;
	
	NSRect viewFrame = [viewToResize frame];
	
	NSRect endingViewFrame = viewFrame;
	endingViewFrame.size.height = viewFrame.size.height + filterBarSize.height;
	
	NSDictionary *viewToResizeAnimationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:viewToResize, NSViewAnimationTargetKey,
													 [NSValue valueWithRect:endingViewFrame], NSViewAnimationEndFrameKey, nil];
	
	
	//filter bar resizing
	//end with the filter bar at the top of the window animationDidEnd: will remove it from the superview
	NSRect endingFilterBarFrame = NSMakeRect(endingViewFrame.origin.x,
											 endingViewFrame.size.height,
											 endingViewFrame.size.width,
											 filterBarSize.height);
	
	NSDictionary *filterBarAnimationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:filterBarView, NSViewAnimationTargetKey,
												  [NSValue valueWithRect:endingFilterBarFrame], NSViewAnimationEndFrameKey, nil];
	
	hideFilterBarAnimation = [[NSViewAnimation alloc]initWithViewAnimations:[NSArray arrayWithObjects:viewToResizeAnimationDictionary,filterBarAnimationDictionary,nil]];
	[hideFilterBarAnimation setDuration:0.25];
	filterBarIsVisible = NO;
	[hideFilterBarAnimation setDelegate:self];
	filterBarIsAnimating = YES;
	//disable vertical autoresizing just while the animation is running
	//this prevents display bugs that can occur when contacts are being shown/hidden that cause the frame to change while the filter bar is sliding
	[contactListController setAutoresizeVertically:NO];
	[hideFilterBarAnimation startAnimation];
	[contactListController setAutoresizeHorizontally:[[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE group:PREF_GROUP_APPEARANCE] boolValue]];
	[contactListView setEnableAnimation:YES];
}

- (void)animationDidEnd:(NSAnimation*)animation
{
	if (![animation isEqual:showFilterBarAnimation] && ![animation isEqual:hideFilterBarAnimation]) {
		[super animationDidEnd:animation];
		return;
	}
	
	if ([animation isEqual:hideFilterBarAnimation]) {
		[filterBarView removeFromSuperview];
	}
	
	[contactListController setAutoresizeVertically:[[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE group:PREF_GROUP_APPEARANCE] boolValue]];

	//resize the window for vertical autoresizing to reflect the addition/subtraction of the filter bar rect
	[contactListController contactListDesiredSizeChanged];
	
	filterBarIsAnimating = NO;
	[animation autorelease];
}

- (IBAction)toggleFilterBar:(id)sender;
{
	if(filterBarIsVisible) {
		[self hideFilterBar:sender];
	} else {
		[self showFilterBar:sender];
	}		
}
- (void)hideFilterBarFromWindowResignedMain:(NSNotification *)sender
{
	if ([[sender object]isEqual:[self window]]) {
		//if the filter bar was shown, but the user clicks out of the window, assume the user is done and hide the filter bar
		[self hideFilterBar:nil];
	}
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (control != searchField)
		return NO;
	
	if (command == @selector(insertNewline:))
	{
		int index = [contactListView indexOfFirstVisibleListContact];
		if (index != -1)
			[[adium chatController] openChatWithContact:[contactListView itemAtRow:index] onPreferredAccount:YES];
		[self hideFilterBar:nil];
		[[self window] makeFirstResponder:contactListView];
	}
	else if(command == @selector(moveDown:)) {
		//make the down key a shortcut for selecting the first contact
		[[self window] makeFirstResponder:contactListView];
		
		int index = [contactListView indexOfFirstVisibleListContact];
		[contactListView selectRowIndexes:((index != -1) ?
										   [NSIndexSet indexSetWithIndex:[contactListView indexOfFirstVisibleListContact]] :
										   [NSIndexSet indexSet])
					 byExtendingSelection:NO];
		
	}
	else if(command == @selector(cancelOperation:) && filterBarIsVisible) {
		[self hideFilterBar:nil];
		[[self window] makeFirstResponder:contactListView];
	}
	
	return NO;
}

- (IBAction)filterContacts:(id)sender;
{
	if (![sender isKindOfClass:[NSSearchField class]])
		return;
	
	[[[adium contactController]contactHidingController]setContactFilteringSearchString:[sender stringValue]
																	  refilterContacts:YES];
	
	int index = [contactListView indexOfFirstVisibleListContact];
	[contactListView selectRowIndexes:(index != -1 ?
									   [NSIndexSet indexSetWithIndex:[contactListView indexOfFirstVisibleListContact]] :
									   [NSIndexSet indexSet])
				 byExtendingSelection:NO];
}



@end
