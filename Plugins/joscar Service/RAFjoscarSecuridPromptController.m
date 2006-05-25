//
//  RAFjoscarSecuridPromptController.m
//  Adium
//
//  Created by Augie Fackler on 3/21/06.
//

#import "RAFjoscarSecuridPromptController.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIStringUtilities.h>
#import <Adium/ESDebugAILog.h>

#define SECURID_NIB_NAME @"SecuridPrompt"

#define SECURID_REQUEST_TEXT AILocalizedString(@"Please enter your SecurID:", "SecurID prompt")
#define SECURID_NAME AILocalizedString(@"SecurID", "Name of the RSA SecurID product, if localized")
#define ACCOUNT_NAME AILocalizedString(@"Account",nil)
#define CANCEL AILocalizedString(@"Cancel",nil)
#define OKAY AILocalizedString(@"OK",nil)

typedef enum {
	AISecuridPromptCancel = 0,
	AISecuridPromptOK
} AISecuridPromptResponse;

@implementation RAFjoscarSecuridPromptController

+ (NSString *)getSecuridForAccount:(AIAccount *)account
{
	RAFjoscarSecuridPromptController *promptWindow = [[[RAFjoscarSecuridPromptController alloc] initWithAccount:account] autorelease];

	int result = [NSApp runModalForWindow:[promptWindow window]];

	return ((result == AISecuridPromptOK) ? [promptWindow getSecurid] : nil);
}

- (RAFjoscarSecuridPromptController *)initWithAccount:(AIAccount *)account
{
	if ((self = [super initWithWindowNibName:SECURID_NIB_NAME])) {
		accountUID = [[account formattedUID] retain];
		securidString = nil;
	}

	return self;
}

- (void)dealloc
{
	[securidString release];
	[accountUID release];
	[super dealloc];
}

- (void)windowDidLoad
{
	[securidTitle setStringValue:SECURID_REQUEST_TEXT];
	[accountTitle setStringValue:ACCOUNT_NAME];
	[cancelButton setStringValue:CANCEL];
	[okButton setStringValue:OKAY];
	[accountText setStringValue:accountUID];
	[securidView setStringValue:SECURID_NAME];

	[textField_securid setStringValue:@""];
}

- (IBAction)okButtonClicked:(id)sender
{
	securidString = [[textField_securid stringValue] retain];

	[NSApp stopModalWithCode:AISecuridPromptOK];
}

- (IBAction)cancelButtonClicked:(id)sender
{
	[NSApp stopModalWithCode:AISecuridPromptCancel];
}

- (NSString *)getSecurid
{
	return [[textField_securid retain] autorelease];
}

@end
