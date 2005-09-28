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
#import "AIAccountSelectionView.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIChatController.h"
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountMenu.h>
#import <Adium/AIContactMenu.h>
#import <Adium/AIChat.h>

#define ACCOUNT_SELECTION_NIB	@"AccountSelectionView"

#define BOX_RECT	NSMakeRect(0, 0, 300, 28)
#define LABEL_RECT	NSMakeRect(17, 7, 56, 17)
#define POPUP_RECT	NSMakeRect(75, 1, 212, 26)

@interface AIAccountSelectionView (PRIVATE)
- (id)_init;
- (void)chatMetaContactChanged;
- (void)chatDestinationChanged:(NSNotification *)notification;
- (void)chatSourceChanged:(NSNotification *)notification;
- (AIMetaContact *)_chatMetaContact;
- (BOOL)_accountIsAvailable:(AIAccount *)inAccount;
- (void)_createAccountMenu;
- (void)_createContactMenu;
- (void)_destroyAccountMenu;
- (void)_destroyContactMenu;
- (BOOL)choicesAvailableForAccount;
- (BOOL)choicesAvailableForContact;
- (NSTextField *)_textFieldLabelWithValue:(NSString *)inValue frame:(NSRect)inFrame;
- (NSPopUpButton *)_popUpButtonWithFrame:(NSRect)inFrame;
- (NSView *)_boxWithFrame:(NSRect)inFrame;
- (void)_repositionMenusAndResize;
@end

@implementation AIAccountSelectionView

/*!
 * @brief InitWithCoder
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if((self = [super initWithCoder:aDecoder])) {
		[self _init];
	}
	return self;
}

/*!
 * @brief InitWithFrame
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect])) {
		[self _init];
	}
	return self;
}

/*!
 * @brief Common init
 */
- (id)_init
{
	adium = [AIObject sharedAdiumInstance];

	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	[self setChat:nil];

    [super dealloc];
}

/*!
 * @brief Set the chat associated with this selection view
 *
 * @param chat AIChat instance this view representents
 */
- (void)setChat:(AIChat *)inChat
{
	if(chat != inChat){
		if(chat){
			//Stop observing the existing chat
			[[adium notificationCenter] removeObserver:self name:Chat_SourceChanged object:chat];
			[[adium notificationCenter] removeObserver:self name:Chat_DestinationChanged object:chat];

			//Remove our menus
			[self _destroyAccountMenu];
			[self _destroyContactMenu];
			
			//Release it
			[chat release]; chat = nil;
		}

		if(inChat){
			//Retain the new chat
			chat = [inChat retain];
			
			//Observe changes to this chat's source and destination
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatSourceChanged:)
											   name:Chat_SourceChanged
											 object:chat];
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatDestinationChanged:)
											   name:Chat_DestinationChanged
											 object:chat];
			
			//Update source and destination menus
			[self chatMetaContactChanged];
		}			
	}
}

/*!
 * @brief Update our menus when the meta contact or the meta contact's content changes
 */
- (void)chatMetaContactChanged
{
	//Rebuild 'To' contact menu
	if([self choicesAvailableForContact]){
		[self _createContactMenu];
	}else{
		[self _destroyContactMenu];
	}

	//Update our 'From' account menu
	[self chatDestinationChanged:nil];
}

/*!
 * @brief Update our menus when the destination contact changes
 */
- (void)chatDestinationChanged:(NSNotification *)notification
{
	//Update selection in contact menu
	[popUp_contacts selectItemWithRepresentedObject:[chat listObject]];
	
	[self _destroyAccountMenu];
	//Rebuild 'From' account menu
	if([self choicesAvailableForAccount]){
		[self _createAccountMenu];
		[popUp_accounts selectItemWithRepresentedObject:[chat listObject]];
	}
	
	//Reposition our menus and resize as necessary
	[self _repositionMenusAndResize];
	
	//Update selection in account menu
	[self chatSourceChanged:nil];
}

/*!
 * @brief Update our menus when the source account changes
 */
- (void)chatSourceChanged:(NSNotification *)notification
{
	//Update selection in account menu
	[popUp_accounts selectItemWithRepresentedObject:[chat account]];
}

/*!
 * @brief Reposition our menus and resize the account selection view as necessary
 *
 * Invoke this method after the visibility of either menu has changed.
 */
- (void)_repositionMenusAndResize
{
	int		newHeight = 0;
	NSRect	oldFrame = [self frame];
	
	//Account menu is always at the bottom
	if(box_accounts){
		[box_accounts setFrameOrigin:NSMakePoint(0, 0)];
		newHeight += [box_accounts frame].size.height;
	}

	//Contact menu is at the bottom, unless the account menu is present in which case it moves up
	if(box_contacts){
		[box_contacts setFrameOrigin:NSMakePoint(0, (box_accounts ? [box_accounts frame].size.height : 0))];
		newHeight += [box_contacts frame].size.height;
	}

	//Resize our view to fit whichever menus are visible
	[self setFrameSize:NSMakeSize([self frame].size.width, newHeight)];
	[[self superview] setNeedsDisplayInRect:NSUnionRect(oldFrame,[self frame])];
	[[NSNotificationCenter defaultCenter] postNotificationName:AIViewFrameDidChangeNotification object:self];
}


//Account Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account Menu
/*
 * @brief Returns YES if a choice of source account is available
 */
- (BOOL)choicesAvailableForAccount
{
	NSEnumerator 	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;
	int				choices = 0;

	while ((account = [enumerator nextObject])) {
		if ([self _accountIsAvailable:account]) {
			if (++choices > 1) return YES;
		}
	}
	
	return NO;
}

/*
 * @brief Account Menu Delegate
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	[popUp_accounts setMenu:[inAccountMenu menu]];
}
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[[adium chatController] switchChat:chat toAccount:inAccount];
}
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount {
	return [self _accountIsAvailable:inAccount];
}

/*
 * @brief Check if an account is available for sending content
 *
 * An account is considered available if it's of the right service class and is currently online.
 * @param inAccount AIAccount instance to check
 * @return YES if the account is available
 */
- (BOOL)_accountIsAvailable:(AIAccount *)inAccount
{
	return ([[[[chat listObject] service] serviceClass] isEqualToString:[[inAccount service] serviceClass]] &&
		   [inAccount integerStatusObjectForKey:@"Online"]);
}

/*
 * @brief Create the account menu and add it to our view
 */
- (void)_createAccountMenu
{
	if (!popUp_accounts) {
		//Since the account box is only a few controls, we build it by hand rather than loading it from a nib
		box_accounts = [[self _boxWithFrame:BOX_RECT] retain];

		popUp_accounts = [[self _popUpButtonWithFrame:POPUP_RECT] retain];
		[box_accounts addSubview:popUp_accounts];
		
		label_accounts = [[self _textFieldLabelWithValue:@"From:" frame:LABEL_RECT] retain];
		[box_accounts addSubview:label_accounts];
		
		//Resize the contact box to fit our view and insert it
		[box_accounts setFrameSize:NSMakeSize([self frame].size.width, BOX_RECT.size.height)];
		[self addSubview:box_accounts];
		
		//Configure the contact menu
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountNoSubmenu showTitleVerbs:NO] retain];
	}
}

/*
 * @brief Destroy the account menu, removing it from our view
 */
- (void)_destroyAccountMenu
{
	if (popUp_accounts) {
		[box_accounts removeFromSuperview];
		[label_accounts release]; label_accounts = nil;
		[popUp_accounts release]; popUp_accounts = nil;
		[box_accounts release]; box_accounts = nil;
		[accountMenu release]; accountMenu = nil;
	}
}


//Contact Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Contact Menu
/*
 * @brief Returns YES if a choice of destination contact is available
 */
- (BOOL)choicesAvailableForContact{
	return [[[self _chatMetaContact] listContacts] count] > 1;
}

/*
 * @brief Contact menu delegate
 */
- (void)contactMenu:(AIContactMenu *)inContactMenu didRebuildMenuItems:(NSArray *)menuItems {
	[popUp_contacts setMenu:[inContactMenu menu]];
}
- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact {
	[[adium chatController] switchChat:chat toListContact:inContact usingContactAccount:YES];
}

/*
 * @brief Create the contact menu and add it to our view
 */
- (void)_createContactMenu
{
	if (!popUp_contacts) {
		//Since the contact box is only a few controls, we build it by hand rather than loading it from a nib
		box_contacts = [[self _boxWithFrame:BOX_RECT] retain];

		popUp_contacts = [[self _popUpButtonWithFrame:POPUP_RECT] retain];
		[box_contacts addSubview:popUp_contacts];
		
		label_contacts = [[self _textFieldLabelWithValue:@"To:" frame:LABEL_RECT] retain];
		[box_contacts addSubview:label_contacts];

		//Resize the contact box to fit our view and insert it
		[box_contacts setFrameSize:NSMakeSize([self frame].size.width, BOX_RECT.size.height)];
		[self addSubview:box_contacts];

		//Configure the contact menu
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self forContactsInObject:[self _chatMetaContact]] retain];
	}
}

/*
 * @brief Destroy the contact menu, remove it from our view
 */
- (void)_destroyContactMenu
{
	if(popUp_contacts){
		[box_contacts removeFromSuperview];
		[label_contacts release]; label_contacts = nil;
		[box_contacts release]; box_contacts = nil;
		[popUp_contacts release]; popUp_contacts = nil;
		[contactMenu release]; contactMenu = nil;
	}
}


//Misc -----------------------------------------------------------------------------------------------------------------
#pragma mark Misc
/*!
 * @brief Returns the meta contact containing our current destination contact (If one exists)
 */
- (AIMetaContact *)_chatMetaContact
{
	id 	containingObject = [[chat listObject] containingObject];
	return [containingObject isKindOfClass:[AIMetaContact class]] ? containingObject : nil;
}

/*!
 * @brief
 */
- (NSTextField *)_textFieldLabelWithValue:(NSString *)inValue frame:(NSRect)inFrame
{
	NSTextField *label = [[NSTextField alloc] initWithFrame:inFrame];

	[label setStringValue:inValue];
	[label setEditable:NO];
	[label setSelectable:NO];
	[label setBordered:NO];
	[label setDrawsBackground:NO];
	[label setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
	[label setAlignment:NSRightTextAlignment];

	return [label autorelease];
}

/*!
 * @brief
 */
- (NSPopUpButton *)_popUpButtonWithFrame:(NSRect)inFrame
{
	NSPopUpButton *popUp = [[NSPopUpButton alloc] initWithFrame:inFrame];

	[popUp setAutoresizingMask:(NSViewWidthSizable)];
	
	return [popUp autorelease];
}

/*!
 * @brief
 */
- (NSView *)_boxWithFrame:(NSRect)inFrame
{
	NSView	*box = [[NSView alloc] initWithFrame:inFrame];

	[box setAutoresizingMask:(NSViewWidthSizable)];
	
	return [box autorelease];
}

@end
