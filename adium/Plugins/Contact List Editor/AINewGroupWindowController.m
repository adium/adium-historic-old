//
//  AINewGroupWindowController.m
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 06 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AINewGroupWindowController.h"

#define ADD_GROUP_PROMPT_NIB	@"AddGroup"

@implementation AINewGroupWindowController

//Prompt for a new group.  Pass nil for a panel prompt.
+ (void)promptForNewGroupOnWindow:(NSWindow *)parentWindow
{
	AINewGroupWindowController	*newGroupWindow;
	
	newGroupWindow = [[self alloc] initWithWindowNibName:ADD_GROUP_PROMPT_NIB];
	
	if(parentWindow){
		[NSApp beginSheet:[newGroupWindow window]
		   modalForWindow:parentWindow
			modalDelegate:newGroupWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[newGroupWindow showWindow:nil];
	}
	
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[[self window] center];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
    return(YES);
}

//Stop automatic window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel
- (IBAction)cancel:(id)sender
{
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}

//Add the contact
- (IBAction)addGroup:(id)sender
{
	NSString		*UID = [textField_groupName stringValue];

	[[adium contactController] groupWithUID:UID];
	
//	textField_groupName
//	
//	
//	AIServiceType	*serviceType = [[popUp_contactType selectedItem] representedObject];
//	NSString		*serviceID = [serviceType identifier];
//	NSEnumerator	*enumerator = [addToAccounts objectEnumerator];
//	AIAccount		*account;
//	
//	
//	
//	while(account = [enumerator nextObject]){
//		//Ignore any accounts with a non-matching service
//		if([[[[account service] handleServiceType] identifier] compare:[serviceType identifier]] == 0){
//			AIListContact	*contact = [[adium contactController] contactWithService:serviceID accountUID:[account UID] UID:UID];
//			[[adium contactController] addGroup:[NSArray arrayWithObject:contact]
//										   toGroup:[[popUp_targetGroup selectedItem] representedObject]];
//		}
//	}
	
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}

@end
