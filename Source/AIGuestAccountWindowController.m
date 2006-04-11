//
//  AIGuestAccountWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/9/06.
//

#import "AIGuestAccountWindowController.h"
#import "AIEditAccountWindowController.h"
#import "AIAccountController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import "AIServiceMenu.h"
#import <AIUtilities/AIStringFormatter.h>
#import <AIUtilities/AITextFieldAdditions.h>

@interface AIGuestAccountWindowController (PRIVATE)
- (void)selectServiceType:(id)sender;
@end

static AIGuestAccountWindowController *sharedGuestAccountWindowController = nil;

@implementation AIGuestAccountWindowController
+ (void)showGuestAccountWindow
{
	//Create the window
	if (!sharedGuestAccountWindowController) {
		sharedGuestAccountWindowController = [[self alloc] initWithWindowNibName:@"GuestAccountWindow"];
	}

	[[sharedGuestAccountWindowController window] makeKeyAndOrderFront:nil];
}

- (void)awakeFromNib
{
	[[self window] setTitle:AILocalizedString(@"Connect Guest Account",nil)];
}

- (void)windowDidLoad
{
	[super windowDidLoad];

	[popUp_service setMenu:[AIServiceMenu menuOfServicesWithTarget:self
												activeServicesOnly:NO
												   longDescription:YES
															format:nil]];
	[self selectServiceType:nil];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[sharedGuestAccountWindowController autorelease]; sharedGuestAccountWindowController = nil;
}

- (AIService *)service
{
	return [[popUp_service selectedItem] representedObject];
}

- (NSString *)UID
{
	return [textField_name stringValue];
}

- (AIAccount *)account
{
	if (!account) {
		account = [[[adium accountController] createAccountWithService:[self service]
																   UID:[self UID]] retain];
	} else {
		if (([self service] != [account service]) ||
			(![[self UID] isEqualToString:[account UID]])) {
			[account release];

			account = [[adium accountController] createAccountWithService:[self service]
																	  UID:[self UID]];
		}
	}
	
	return account;
}

- (void)selectServiceType:(id)sender
{
	AIService *service = [self service];
	[label_name setStringValue:[[service userNameLabel] stringByAppendingString:@":"]];
	
	[textField_name setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[service allowedCharactersForAccountName]
													  length:[service allowedLengthForAccountName]
											   caseSensitive:[service caseSensitive]
												errorMessage:AILocalizedStringFromTable(@"The characters you're entering are not valid for an account name on this service.", @"AdiumFramework", nil)]];
	
}

- (IBAction)okay:(id)sender
{
	AIAccount	*theAccount = [self account];
	[theAccount setIsTemporary:YES];
	
	[[adium accountController] addAccount:theAccount];
	[theAccount setPasswordTemporarily:[textField_password secureStringValue]];

	//Connect the account
	[theAccount setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	
	[[self window] performClose:nil];
}

- (IBAction)displayAdvanced:(id)sender
{
	[AIEditAccountWindowController editAccount:[self account]
									  onWindow:[self window]
							   notifyingTarget:self];	
}

- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)inSuccess
{
	//If the AIEditAccountWindowController changes the account object, update to follow suit
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
	}
	
	//Make sure our UID is still accurate
	if (![[inAccount UID] isEqualToString:[self UID]]) {
		[textField_name setStringValue:[inAccount UID]];
	}
}

@end
