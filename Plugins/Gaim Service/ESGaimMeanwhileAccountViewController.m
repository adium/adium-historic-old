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

#import "ESGaimMeanwhileAccountViewController.h"
#import "ESGaimMeanwhileAccount.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIMenuAdditions.h>

#define SAVE_WARNING AILocalizedString(@"Warning: The 'load and save' option is still experimental. Please back up your contact list with an official client before enabling.",nil)

@interface ESGaimMeanwhileAccountViewController (PRIVATE)
- (NSMenu *)_contactListMenu;
- (NSMenuItem *)_contactListMenuItemWithTitle:(NSString *)title tag:(int)tag;
- (void)_updateContactListWarning;
@end

@implementation ESGaimMeanwhileAccountViewController

#ifndef MEANWHILE_NOT_AVAILABLE

- (NSString *)nibName{
    return(@"ESGaimMeanwhileAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	//Build the contact list mode menu
	[popUp_contactList setMenu:[self _contactListMenu]];
	
	//Select the correct list mode
	int contactListChoice = [[inAccount preferenceForKey:KEY_MEANWHILE_CONTACTLIST group:GROUP_ACCOUNT_STATUS] intValue];
	[popUp_contactList selectItemAtIndex:[popUp_contactList indexOfItemWithTag:contactListChoice]];
	[self _updateContactListWarning];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];

	//Contact list mode
	[account setPreference:[NSNumber numberWithInt:[[popUp_contactList selectedItem] tag]]
					forKey:KEY_MEANWHILE_CONTACTLIST
					 group:GROUP_ACCOUNT_STATUS];
}


//Contact list mode menu -----------------------------------------------------------------------------------------------
#pragma mark Contact list mode menu
//Show or hide the contact list warning depending on the contact list mode currently selected
- (void)_updateContactListWarning
{
	if([[popUp_contactList selectedItem] tag] == Meanwhile_CL_Load_And_Save){
		[textField_contactListWarning setStringValue:SAVE_WARNING];
	}else{
		[textField_contactListWarning setStringValue:@""];		
	}
}

//Returns the contact list popup menu
- (NSMenu *)_contactListMenu
{
    NSMenu			*contactListMenu = [[NSMenu alloc] init];
	
    [contactListMenu addItem:[self _contactListMenuItemWithTitle:AILocalizedString(@"Local Only",nil) tag:Meanwhile_CL_None]];
	[contactListMenu addItem:[self _contactListMenuItemWithTitle:AILocalizedString(@"Load From Server",nil) tag:Meanwhile_CL_Load]];
	[contactListMenu addItem:[self _contactListMenuItemWithTitle:AILocalizedString(@"Load From and Save To Server",nil) tag:Meanwhile_CL_Load_And_Save]];

	return [contactListMenu autorelease];
}

//Create a contact list popup menu item
- (NSMenuItem *)_contactListMenuItemWithTitle:(NSString *)title tag:(int)tag
{
	NSMenuItem		*menuItem;
    
    menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																	target:self
																	action:@selector(changeCLType:)
															 keyEquivalent:@""];
    [menuItem setTag:tag];
	
	return [menuItem autorelease];
}

//User selected a new contact list mode
- (void)changeCLType:(id)sender
{
	//Show or hide the warning depending on their selection
	[self _updateContactListWarning];
}

#endif

@end
