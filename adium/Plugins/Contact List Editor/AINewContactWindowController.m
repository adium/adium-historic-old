//
//  AINewContactWindowController.m
//  Adium XCode
//
//  Created by Adam Iser on Sat Jan 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AINewContactWindowController.h"

#define ADD_CONTACT_PROMPT_NIB	@"AddContact"
@interface AINewContactWindowController (PRIVATE)
- (void)buildContactTypeMenu;
@end

@implementation AINewContactWindowController

+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow
{
	AINewContactWindowController	*newContactWindow;
	
	newContactWindow = [[self alloc] initWithWindowNibName:ADD_CONTACT_PROMPT_NIB];
	
    [NSApp beginSheet:[newContactWindow window]
	   modalForWindow:parentWindow
		modalDelegate:newContactWindow
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

//Build the menu of contact service types
- (void)buildContactTypeMenu
{
	NSEnumerator				*enumerator;
	id <AIServiceController>	service;
	
	//Empty the menu
	[popUp_contactType removeAllItems];
	
	//Add an item for each service
	enumerator = [[[adium accountController] availableServices] objectEnumerator];
	while(service = [enumerator nextObject]){
		AIServiceType 	*serviceType = [service handleServiceType];
		
		[[popUp_contactType menu] addItemWithTitle:[serviceType description]
											target:nil
											action:nil
									 keyEquivalent:@""
								 representedObject:serviceType];
	}
}

//Build the menu of available destination groups
//- (void)buildGroupMenu
//{
//	[[adium contactController] contactList];
//	
//	
//	
//	NSEnumerator				*enumerator;
//	id <AIServiceController>	service;
//	
//	//Empty the menu
//	[popUp_contactType removeAllItems];
//	
//	//Add an item for each service
//	enumerator = [[[adium accountController] availableServices] objectEnumerator];
//	while(service = [enumerator nextObject]){
//		AIServiceType 	*serviceType = [service handleServiceType];
//		
//		[[popUp_contactType menu] addItemWithTitle:[serviceType description]
//											target:nil
//											action:nil
//									 keyEquivalent:@""
//								 representedObject:service];
//	}
//}
//

//
- (IBAction)cancel:(id)sender
{
    [NSApp endSheet:[self window]];
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//
- (IBAction)addContact:(id)sender
{
	AIServiceType	*serviceType = [[popUp_contactType selectedItem] representedObject];
	NSString		*serviceID = [serviceType identifier];
	NSString		*UID = [textField_contactName stringValue];
	
	if(serviceID && UID){
		AIListContact	*contact = [[adium contactController] contactWithService:serviceID UID:UID];
		AIListGroup		*group = [[adium contactController] groupWithUID:@"New" createInGroup:nil];
			
		[[adium contactController] addContacts:[NSArray arrayWithObject:contact]
									   toGroup:group
									onAccounts:[[adium accountController] accountArray]];
	}
	
    [NSApp endSheet:[self window]];
}


- (id)initWithWindowNibName:(NSString *)windowNibName
{
    //init
    [super initWithWindowNibName:windowNibName];    
	
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[self buildContactTypeMenu];
	
    //Center the window
    [[self window] center];
}

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

- (BOOL)windowShouldClose:(id)sender
{
    return(YES);
}


@end
