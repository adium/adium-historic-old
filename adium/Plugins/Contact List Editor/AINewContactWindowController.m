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
- (void)buildGroupMenu;
- (void)_buildGroupMenu:(NSMenu *)menu forGroup:(AIListGroup *)group level:(int)level;
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
- (void)buildGroupMenu
{
	//Empty the menu
	[popUp_targetGroup removeAllItems];
	
	//Rebuild it
	[self _buildGroupMenu:[popUp_targetGroup menu]
				 forGroup:[[adium contactController] contactList]
					level:0];
}

- (void)_buildGroupMenu:(NSMenu *)menu forGroup:(AIListGroup *)group level:(int)level
{
	NSEnumerator	*enumerator = [group objectEnumerator];
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		if([object isKindOfClass:[AIListGroup class]]){
			NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:[object displayName]
																target:nil
																action:nil
														 keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:object];
			[menuItem setIndentationLevel:level];
			[menu addItem:menuItem];
			
			[self _buildGroupMenu:menu forGroup:object level:level+1];
		}
	}
}


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
			
		[[adium contactController] addContacts:[NSArray arrayWithObject:contact]
									   toGroup:[[popUp_targetGroup selectedItem] representedObject]
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
	[self buildGroupMenu];
	
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
