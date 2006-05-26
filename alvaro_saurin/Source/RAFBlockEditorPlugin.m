//
//  RAFBlockEditorPlugin.m
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "RAFBlockEditorPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import "AIAccount.h"
#import "AIAccountController.h"

#define BLOCK_EDITOR AILocalizedString(@"Block List Editor...","Block List Editor menu item")

@implementation RAFBlockEditorPlugin

- (void)installPlugin
{
	//Install the Block menu items
	blockEditorMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_EDITOR
													  target:self
													  action:@selector(showEditor:)
											   keyEquivalent:@"b"];
	[blockEditorMenuItem setKeyEquivalentModifierMask:(NSShiftKeyMask | NSCommandKeyMask)];
	[[adium menuController] addMenuItem:blockEditorMenuItem toLocation:LOC_Contact_NegativeAction];
}

- (void)uninstallPlugin
{
	[blockEditorMenuItem release];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	BOOL retVal = NO;
	AIAccount <AIAccount_Privacy> *account;
	NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
	while((account = [enumerator nextObject]) && !retVal)
		if([[account statusObjectForKey:@"Online"] boolValue] &&
		   [account conformsToProtocol:@protocol(AIAccount_Privacy)])
			retVal = YES;
	return retVal;
}

- (IBAction)showEditor:(id)sender
{
	[RAFBlockEditorWindowController showWindow];
}
@end
