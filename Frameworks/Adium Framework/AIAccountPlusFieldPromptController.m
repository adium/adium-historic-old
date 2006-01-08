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

#import "AIAccount.h"
#import "AIAccountController.h"
#import "AIAccountPlusFieldPromptController.h"
#import "AIContactController.h"
#import "AIContentMessage.h"
#import "AIListContact.h"
#import "AIService.h"
#import <AIUtilities/AICompletingTextField.h>
#import <Adium/AIAccountMenu.h>

@interface AIAccountPlusFieldPromptController (PRIVATE)
- (void)_configureTextFieldForAccount:(AIAccount *)account;
@end

@implementation AIAccountPlusFieldPromptController

+ (id)sharedInstance {return nil;};
+ (id)createSharedInstance {return nil;};
+ (void)destroySharedInstance {};

- (IBAction)okay:(id)sender {};


+ (void)showPrompt
{
	AIAccountPlusFieldPromptController *sharedInstance = [self sharedInstance];
	
    if (!sharedInstance) {
        sharedInstance = [self createSharedInstance];
    }

    [[sharedInstance window] makeKeyAndOrderFront:nil];
}

+ (void)closeSharedInstance
{
	AIAccountPlusFieldPromptController *sharedInstance = [self sharedInstance];

    if (sharedInstance) {
        [sharedInstance closeWindow:nil];
    }
}

- (AIListContact *)contactFromTextField
{
	AIListContact	*contact = nil;
	NSString		*UID = nil;
	AIAccount		*account = [[popUp_service selectedItem] representedObject];;

	id impliedValue = [textField_handle impliedValue];
	if ([impliedValue isKindOfClass:[AIMetaContact class]]) {
		contact = impliedValue;

	} else if ([impliedValue isKindOfClass:[AIListContact class]]) {
		UID = [contact UID];

	} else  if ([impliedValue isKindOfClass:[NSString class]]) {
		UID = [[account service] filterUID:impliedValue removeIgnoredCharacters:YES];
	}
	
	if (!contact && UID) {

		//Find the contact
		contact = [[adium contactController] contactWithService:[account service]
														account:account 
															UID:UID];		
	}
	
	return contact;
}

- (void)_configureTextFieldForAccount:(AIAccount *)account
{
	NSEnumerator		*enumerator;
    AIListContact		*contact;
	
	//Clear the completing strings
	[textField_handle setCompletingStrings:nil];
	
	/* Configure the auto-complete view to autocomplete for contacts matching the selected account's service
	 * Don't include meta contacts which don't currently contain any valid contacts
	 */
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while ((contact = [enumerator nextObject])) {
		if ([contact service] == [account service] &&
			(![contact isKindOfClass:[AIMetaContact class]] || [[(AIMetaContact *)contact listContacts] count])) {
			NSString *UID = [contact UID];
			[textField_handle addCompletionString:[contact formattedUID] withImpliedCompletion:UID];
			[textField_handle addCompletionString:[contact displayName] withImpliedCompletion:contact];
			[textField_handle addCompletionString:UID];
		}
    }
	
}


// Private --------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    //init
    [super initWithWindowNibName:windowNibName];    
	
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	//Controls
	[button_cancel setLocalizedString:AILocalizedStringFromTable(@"Cancel", @"AdiumFramework", nil)];
	[textField_handle setMinStringLength:2];
	
	//Account menu
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO] retain];
	
	[self _configureTextFieldForAccount:[[popUp_service selectedItem] representedObject]];

    //Center the window
    [[self window] center];
}

//
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[accountMenu release];
	
	[[self class] destroySharedInstance];
}


//Account menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account menu
//Account menu delegate
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	[popUp_service setMenu:[inAccountMenu menu]];	
}	
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[self _configureTextFieldForAccount:inAccount];
}
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount {
	return [inAccount online];
}

//Select the last used account / Available online account
- (void)_selectLastUsedAccountInAccountMenu:(AIAccountMenu *)inAccountMenu
{
	AIAccount   *preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																						   toContact:nil];
	NSMenuItem	*menuItem = [inAccountMenu menuItemForAccount:preferredAccount];
	
	if (menuItem) {
		[popUp_service selectItem:menuItem];
		[self _configureTextFieldForAccount:preferredAccount];
	}
}	
	
@end
