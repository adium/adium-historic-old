//
//  ESGaimMeanwhileAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimMeanwhileAccountViewController.h"
#import "ESGaimMeanwhileAccount.h"

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
