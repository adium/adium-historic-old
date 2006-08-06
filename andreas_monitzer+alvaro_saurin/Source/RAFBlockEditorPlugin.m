//
//  RAFBlockEditorPlugin.m
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "RAFBlockEditorPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountController.h>

#define PRIVACY_SETTINGS [AILocalizedString(@"Privacy Settings","Privacy Settings menu item") stringByAppendingEllipsis]

@implementation RAFBlockEditorPlugin

- (void)installPlugin
{
	//Install the Block menu items
	blockEditorMenuItem = [[NSMenuItem alloc] initWithTitle:PRIVACY_SETTINGS
													  target:self
													  action:@selector(showEditor:)
											   keyEquivalent:@"p"];
	[blockEditorMenuItem setKeyEquivalentModifierMask:(NSAlternateKeyMask | NSCommandKeyMask)];
	[[adium menuController] addMenuItem:blockEditorMenuItem toLocation:LOC_Adium_Preferences];
}

- (void)uninstallPlugin
{
	[blockEditorMenuItem release];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	BOOL		 retVal = NO;
	AIAccount	 *account;
	NSEnumerator *enumerator;

	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject]) && !retVal) {
		if([[account statusObjectForKey:@"Online"] boolValue] &&
		   [account conformsToProtocol:@protocol(AIAccount_Privacy)])
			retVal = YES;
	}

	return retVal;
}

- (IBAction)showEditor:(id)sender
{
	[RAFBlockEditorWindowController showWindow];
}
@end
