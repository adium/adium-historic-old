//
//  ESGaimMeanwhileAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//

#import "ESGaimMeanwhileAccountViewController.h"
#import "ESGaimMeanwhileAccount.h"

#define SAVE_WARNING AILocalizedString(@"Warning: The 'load and save' option is still experimental. Please back up your contact list with an official client before enabling.",nil)

@interface ESGaimMeanwhileAccountViewController (PRIVATE)
- (NSMenu *)_contactListMenu;
- (NSMenuItem *)_contactListMenuItemWithTitle:(NSString *)title tag:(int)tag;
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
	
	[popUp_contactList setMenu:[self _contactListMenu]];
	
	int contactListChoice = [[inAccount preferenceForKey:KEY_MEANWHILE_CONTACTLIST group:GROUP_ACCOUNT_STATUS] intValue];
	[popUp_contactList selectItemAtIndex:[popUp_contactList indexOfItemWithTag:contactListChoice]];
	
	if (contactListChoice == Meanwhile_CL_Load_And_Save){
		[textField_contactListWarning setStringValue:SAVE_WARNING];
	}else{
		[textField_contactListWarning setStringValue:@""];		
	}

}

- (NSMenu *)_contactListMenu
{
    NSMenu			*contactListMenu = [[NSMenu alloc] init];
	
    [contactListMenu addItem:[self _contactListMenuItemWithTitle:AILocalizedString(@"Local Only",nil) tag:Meanwhile_CL_None]];
	[contactListMenu addItem:[self _contactListMenuItemWithTitle:AILocalizedString(@"Load From Server",nil) tag:Meanwhile_CL_Load]];
	[contactListMenu addItem:[self _contactListMenuItemWithTitle:AILocalizedString(@"Load From and Save To Server",nil) tag:Meanwhile_CL_Load_And_Save]];

	return [contactListMenu autorelease];
}

- (NSMenuItem *)_contactListMenuItemWithTitle:(NSString *)title tag:(int)tag
{
	NSMenuItem		*menuItem;
    
    menuItem = [[NSMenuItem alloc] initWithTitle:title
										  target:self
										  action:@selector(changeCLType:)
								   keyEquivalent:@""];
    [menuItem setTag:tag];
	
	return [menuItem autorelease];
}

- (void)changeCLType:(id)sender
{
	int contactListChoice = [sender tag];
	
	[account setPreference:[NSNumber numberWithInt:contactListChoice]
					forKey:KEY_MEANWHILE_CONTACTLIST
					 group:GROUP_ACCOUNT_STATUS];
	
	if (contactListChoice == Meanwhile_CL_Load_And_Save){
		[textField_contactListWarning setStringValue:SAVE_WARNING];
	}else{
		[textField_contactListWarning setStringValue:@""];		
	}
}

#endif

@end
