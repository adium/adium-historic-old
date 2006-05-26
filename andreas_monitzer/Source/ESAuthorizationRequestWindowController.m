//
//  ESAuthorizationRequestWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 5/18/05.
//

#import "ESAuthorizationRequestWindowController.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESAuthorizationRequestWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict forAccount:(AIAccount *)inAccount;
@end

@implementation ESAuthorizationRequestWindowController

+ (ESAuthorizationRequestWindowController *)showAuthorizationRequestWithDict:(NSDictionary *)inInfoDict  forAccount:(AIAccount *)inAccount
{
	ESAuthorizationRequestWindowController	*controller;
	
	if ((controller = [[self alloc] initWithWindowNibName:@"AuthorizationRequestWindow"
												 withDict:inInfoDict
											   forAccount:inAccount])) {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
	}
	
	return controller;
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict forAccount:(AIAccount *)inAccount
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		infoDict = [inInfoDict retain];
		account = [inAccount retain];
	}
	
    return self;
}

- (void)dealloc
{
	[infoDict release]; infoDict = nil;
	[account release];

	[super dealloc];
}

- (void)windowDidLoad
{	
	NSString	*message;

	[super windowDidLoad];

	[textField_header setStringValue:AILocalizedString(@"Authorization Requested",nil)];
	
	if ([infoDict objectForKey:@"Reason"]) {
		message = [NSString stringWithFormat:
			AILocalizedString(@"The contact %@ wants to add %@ to his or her contact list for the following reason:\n%@",nil),
			[infoDict objectForKey:@"Remote Name"],
			[account formattedUID],
			[infoDict objectForKey:@"Reason"]];

	} else {
		message = [NSString stringWithFormat:
			AILocalizedString(@"The contact %@ wants to add %@ to his or her contact list.",nil),
			[infoDict objectForKey:@"Remote Name"],
			[account formattedUID]];
	}

	NSScrollView *scrollView_message = [textView_message enclosingScrollView];
	
	[textView_message setVerticallyResizable:YES];
	[textView_message setHorizontallyResizable:NO];
	[textView_message setDrawsBackground:NO];
	[textView_message setTextContainerInset:NSZeroSize];
	[scrollView_message setDrawsBackground:NO];
	
	[textView_message setString:(message ? message : @"")];
	
	//Resize the window frame to fit the error title
	[textView_message sizeToFit];
	float heightChange = [textView_message frame].size.height - [scrollView_message documentVisibleRect].size.height;

	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height += heightChange;
	windowFrame.origin.y -= heightChange;
	[[self window] setFrame:windowFrame display:YES animate:NO];
	
	[[self window] center];
}

- (IBAction)authorize:(id)sender
{
	//Do the authorization serverside
	[account authorizationWindowController:self
					 authorizationWithDict:infoDict
							  didAuthorize:YES];
	
	//Now handle the Add To Contact List checkbox
	AILog(@"Authorize: (%i) %@",[checkBox_addToList state],infoDict);

	if ([checkBox_addToList state] == NSOnState) {
		[[adium contactController] requestAddContactWithUID:[infoDict objectForKey:@"Remote Name"]
													service:[account service]];
	}
	
	[infoDict release]; infoDict = nil;
	
	[self closeWindow:nil];
}

- (IBAction)deny:(id)sender
{
	[account authorizationWindowController:self
					 authorizationWithDict:infoDict
							  didAuthorize:NO];	
	
	[infoDict release]; infoDict = nil;
}

@end
