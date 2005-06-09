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
	AIListContact	*contact;
	AIAccount		*account;
	NSString		*UID;
	
	//Get the service type and UID
	account = [[popUp_service selectedItem] representedObject];
	UID = [[account service] filterUID:[textField_handle impliedStringValue] removeIgnoredCharacters:YES];
	
	//Find the contact
	contact = [[adium contactController] contactWithService:[account service]
													account:account 
														UID:UID];
	
	return(contact);
}

- (IBAction)selectAccount:(id)sender
{
	AIAccount			*selectedAccount = [sender representedObject];
	[self _configureTextFieldForAccount:selectedAccount];
}

- (void)_configureTextFieldForAccount:(AIAccount *)account
{
	NSEnumerator		*enumerator;
    AIListContact		*contact;
	
	//Clear the completing strings
	[textField_handle setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while ((contact = [enumerator nextObject])) {
		if ([contact service] == [account service]) {
			NSString *UID = [contact UID];
			[textField_handle addCompletionString:[contact formattedUID] withImpliedCompletion:UID];
			[textField_handle addCompletionString:[contact displayName] withImpliedCompletion:UID];
			[textField_handle addCompletionString:UID];
		}
    }
	
}


// Private --------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    //init
    [super initWithWindowNibName:windowNibName];    
	
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];
	
	[textField_handle setMinStringLength:2];
	
    //Configure the handle type menu
    [popUp_service setMenu:[[adium accountController] menuOfAccountsWithTarget:self includeOffline:NO]];
	
    //Select the last used account / Available online account
	AIAccount   *preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																						   toContact:nil];
	int			serviceIndex = [popUp_service indexOfItemWithRepresentedObject:preferredAccount];
	
    if (serviceIndex < [popUp_service numberOfItems] && serviceIndex >= 0) {
		//Select the account
		[popUp_service selectItemAtIndex:serviceIndex];
		
		//Configure the autocompleting field
		[self _configureTextFieldForAccount:preferredAccount];
	}

    //Center the window
    [[self window] center];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[[self class] destroySharedInstance];
}

@end
