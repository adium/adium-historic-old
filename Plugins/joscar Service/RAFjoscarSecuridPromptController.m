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

@implementation RAFjoscarSecuridPromptController

+ (NSString *)getSecuridForAccount:(AIAccount *)account
{
	RAFjoscarSecuridPromptController *promptWindow = [[[RAFjoscarSecuridPromptController alloc] initWithAccount:account] autorelease];

	[NSApp runModalForWindow:[promptWindow window]];

	AILog(@"Ran %@ modally (window: %@)", promptWindow, [promptWindow window]);

	return [promptWindow getSecurid];
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
	[securid setStringValue:@""];
}

- (IBAction)okButtonClicked:(id)sender
{
	securidString = [[securid stringValue] retain];
	[[self window] close];
}

- (IBAction)cancelButtonClicked:(id)sender
{
	[[self window] close];
}

- (NSString *)getSecurid
{
	return [[securidString retain] autorelease];
}

@end
