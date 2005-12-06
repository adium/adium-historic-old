//
//  AdiumSetupWizard.m
//  Adium
//
//  Created by Evan Schoenberg on 12/4/05.
//

#import "AdiumSetupWizard.h"
#import "AIAccountController.h"
#import "SetupWizardBackgroundView.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIServiceMenu.h>
#import <Adium/AIService.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AITextFieldAdditions.h>
#import <AIUtilities/AIStringFormatter.h>

#define ACCOUNT_SETUP_IDENTIFIER	@"account_setup"
#define WELCOME_IDENTIFIER			@"welcome"
#define DONE_IDENTIFIER				@"done"

/*!
 * @classs AdiumSetupWizard
 * @brief Class responsible for the first-run setup wizard
 */
@implementation AdiumSetupWizard

/*
 * @brief Run the wizard
 */
+ (void)runWizard
{
	AdiumSetupWizard *setupWizardWindowController;
	
	setupWizardWindowController = [[self alloc] initWithWindowNibName:@"SetupWizard"];
	
	//Configure and show window
	[setupWizardWindowController showWindow:nil];
	[[setupWizardWindowController window] orderFront:nil];
}

/*
 * @brief Localized some common items' titles
 */
- (void)localizeItems
{
	[button_goBack setLocalizedString:AILocalizedString(@"Go Back","'go back' button title")];
	[textField_passwordLabel setLocalizedString:AILocalizedStringFromTable(@"Password:", @"AdiumFramework", "Label for the password field in the account preferences")];
	[textField_serviceLabel	setLocalizedString:AILocalizedString(@"Service:",nil)];
	
	[button_alternate setLocalizedString:AILocalizedString(@"Add Another","button title for adding another account in the setup wizard")];
}

/*
 * @brief The window loaded
 */
- (void)windowDidLoad
{
	//Ensure the first tab view item is selected
	[tabView selectTabViewItemAtIndex:0];
	[self tabView:tabView willSelectTabViewItem:[tabView selectedTabViewItem]];

	//Configure our background view; it should display the image transparently where our tabView overlaps it
	[backgroundView setBackgroundImage:[NSImage imageNamed:@"AdiumyButler"
												  forClass:[self class]]];
	NSRect tabViewFrame = [tabView frame];
	NSRect backgroundViewFrame = [backgroundView frame];
	tabViewFrame.origin.x -= backgroundViewFrame.origin.x;
	tabViewFrame.origin.y -= backgroundViewFrame.origin.y;
	[backgroundView setTransparentRect:tabViewFrame];

	[self localizeItems];
	
	[super windowDidLoad];
}

/*
 * @brief A tab view item was completed; post-process any entered data
 */
- (BOOL)didCompleteTabViewItemWithIdentifier:(NSString *)identifier
{
	BOOL success = YES;

	if ([identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]) {
		NSString	*UID = [textField_username stringValue];

		if (UID && [UID length]) {
			AIService	*service = [[popUp_services selectedItem] representedObject];
			AIAccount	*account = [[adium accountController] createAccountWithService:service
																				   UID:UID];
			
			//Save the password
			NSString		*password = [textField_password secureStringValue];
			
			if (password && [password length] != 0) {
				[[adium accountController] setPassword:password forAccount:account];
			}
			
			//New accounts need to be added to our account list once they're configured
			[[adium accountController] addAccount:account];
			
			//Put new accounts online by default
			[account setPreference:[NSNumber numberWithBool:YES]
							forKey:@"Online"
							 group:GROUP_ACCOUNT_STATUS];
		} else {
			success = NO;
		}
	}
	
	return success;
}

/*
 * @brief The Continue button, which is also the Done button, was pressed
 */
- (IBAction)nextTab:(id)sender
{
	NSTabViewItem *currentTabViewItem = [tabView selectedTabViewItem];
	if ([self didCompleteTabViewItemWithIdentifier:[currentTabViewItem identifier]]) {
		if ([tabView indexOfTabViewItem:currentTabViewItem] == ([tabView numberOfTabViewItems] - 1)) {
			//Done
			[self  close];
			
		} else {
			//Go to the next tab view item
			[tabView selectNextTabViewItem:self];		
		}
	} else {
		NSBeep();
	}
}

/*
 * @brief The Back button was pressed
 */
- (IBAction)previousTab:(id)sender
{
	[tabView selectPreviousTabViewItem:self];
}

/*
 * @brief The alternate (third) button was pressed; its behavior will vary by tab view item
 */
- (IBAction)pressedAlternateButton:(id)sender
{
	NSTabViewItem	*currentTabViewItem = [tabView selectedTabViewItem];
	NSString		*identifier = [currentTabViewItem identifier];

	if ([identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]) {
		//Configure the account
		if ([self didCompleteTabViewItemWithIdentifier:identifier]) {
			//Reconfigure
			[self tabView:tabView willSelectTabViewItem:currentTabViewItem];
		} else {
			NSBeep();
		}
	}
}

/*
 * @brief Set up the Account Setup tab for a given service
 */
- (void)configureAccountSetupForService:(AIService *)service
{
	//UID Label
	[textField_usernameLabel setStringValue:[[service userNameLabel] stringByAppendingString:@":"]];

	//UID formatter and placeholder
	[textField_username setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[service allowedCharactersForAccountName]
													  length:[service allowedLengthForAccountName]
											   caseSensitive:[service caseSensitive]
												errorMessage:AILocalizedStringFromTable(@"The characters you're entering are not valid for an account name on this service.", @"AdiumFramework", nil)]];
	[[textField_username cell] setPlaceholderString:[service UIDPlaceholder]];
}

- (BOOL)showAlternateButtonForIdentifier:(NSString *)identifier
{
	return [identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER];	
}

/*
 * @brief The tab view is about to select a tab view item
 */
- (void)tabView:(NSTabView *)inTabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSString *identifier = [tabViewItem identifier];

	if ([identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]) {
		//Set the services menu if it hasn't already been set
		if (!setupAccountTabViewItem) {
			[popUp_services setMenu:[AIServiceMenu menuOfServicesWithTarget:self
														 activeServicesOnly:NO
															longDescription:YES
																	 format:nil]];
			
			[textField_addAccount setStringValue:AILocalizedString(@"Add an Instant Messaging Account",nil)];
			[textView_addAccountMessage setDrawsBackground:NO];
			[[textView_addAccountMessage enclosingScrollView] setDrawsBackground:NO];
#warning This text needs improvement...
			[textView_addAccountMessage setString:@"To chat with your friends and family, you must have an instant messaging account on the same service they do.  Specify a service, name, and password below; if you don't have an account yet, click <<here>> for more information.\n\nAdium supports as many accounts as you want to add; you can always add more in the Accounts pane of the Adium Preferences."];

			setupAccountTabViewItem = YES;
		}

		AIService *service = [[popUp_services selectedItem] representedObject];
		[textField_username setStringValue:@""];
		[textField_password setStringValue:@""];
		[self configureAccountSetupForService:service];
		
	} else if ([identifier isEqualToString:WELCOME_IDENTIFIER]) {
			[textView_welcomeMessage setDrawsBackground:NO];
		[[textView_welcomeMessage enclosingScrollView] setDrawsBackground:NO];
		[textView_welcomeMessage setString:@"<<<welcome message here>>>"];

		[textField_welcome setStringValue:AILocalizedString(@"Welcome to Adium!",nil)];
		
	} else if ([identifier isEqualToString:DONE_IDENTIFIER]) {
		[textView_doneMessage setDrawsBackground:NO];
		[[textView_doneMessage enclosingScrollView] setDrawsBackground:NO];
		[textView_doneMessage setString:@"<<<you're all done, woohoo, message here>>>"];

		[textField_done setStringValue:AILocalizedString(@"Congratulations!","Header line in the last pane of the Adium setup wizard")];
	}

	[button_alternate setHidden:![self showAlternateButtonForIdentifier:identifier]];

	//Set the done / continue button properly
	if ([tabView indexOfTabViewItem:tabViewItem] == ([tabView numberOfTabViewItems] - 1)) {
		[button_continue setLocalizedString:AILocalizedString(@"Done","'done' button title")];

	} else {
		[button_continue setLocalizedString:AILocalizedString(@"Continue","'done' button title")];
	}
}

/*
 * @brief The selected service in the account configuration tab view item was changed
 */
- (void)selectServiceType:(id)sender
{
	[self configureAccountSetupForService:[[popUp_services selectedItem] representedObject]];
}

@end
