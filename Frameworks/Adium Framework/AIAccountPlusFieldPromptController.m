//
//  AIAccountPlusFieldPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/5/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIAccountPlusFieldPromptController.h"

@interface AIAccountPlusFieldPromptController (PRIVATE)
- (void)_configureTextFieldForAccount:(AIAccount *)account;
@end

@implementation AIAccountPlusFieldPromptController

+ (id)sharedInstance {return nil;};
+ (id)createSharedInstance {return nil;};
+ (void)destroySharedInstance {};

- (IBAction)okay:(id)sender {};


+ (void)showPrompt
{
	AIAccountPlusFieldPromptController *sharedInstance = [self sharedInstance];
	
    if(!sharedInstance){
        sharedInstance = [self createSharedInstance];
    }

    [[sharedInstance window] makeKeyAndOrderFront:nil];
}

+ (void)closeSharedInstance
{
	AIAccountPlusFieldPromptController *sharedInstance = [self sharedInstance];

    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

- (AIListContact *)contactFromTextField
{
	AIListContact	*contact;
	AIAccount		*account;
	NSString		*UID;
	
	//Get the service type and UID
	account = [[popUp_service selectedItem] representedObject];
	UID = [[account service] filterUID:[textField_handle impliedStringValue] removeIgnoredCharacters:YES];
	
	//Find the contact
	contact = [[adium contactController] contactWithService:[account service]
													account:account 
														UID:UID];
	
	return(contact);
}

- (IBAction)selectAccount:(id)sender
{
	AIAccount			*selectedAccount = [sender representedObject];
	[self _configureTextFieldForAccount:selectedAccount];
}

- (void)_configureTextFieldForAccount:(AIAccount *)account
{
	NSEnumerator		*enumerator;
    AIListContact		*contact;
	
	//Clear the completing strings
	[textField_handle setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while((contact = [enumerator nextObject])){
		if([contact service] == [account service]){
			NSString *UID = [contact UID];
			[textField_handle addCompletionString:[contact formattedUID] withImpliedCompletion:UID];
			[textField_handle addCompletionString:[contact displayName] withImpliedCompletion:UID];
			[textField_handle addCompletionString:UID];
		}
    }
	
}


// Private --------------------------------------------------------------------------------
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
	[textField_handle setMinStringLength:2];
	
    //Configure the handle type menu
    [popUp_service setMenu:[[adium accountController] menuOfAccountsWithTarget:self includeOffline:NO]];
	
    //Select the last used account / Available online account
	AIAccount   *preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																						   toContact:nil];
	int			serviceIndex = [popUp_service indexOfItemWithRepresentedObject:preferredAccount];
	
    if(serviceIndex < [popUp_service numberOfItems] && serviceIndex >= 0){
		//Select the account
		[popUp_service selectItemAtIndex:serviceIndex];
		
		//Configure the autocompleting field
		[self _configureTextFieldForAccount:preferredAccount];
	}
	
    //Center the window
    [[self window] center];
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (BOOL)windowShouldClose:(id)sender
{
	[[self class] destroySharedInstance];

    return(YES);
}

@end
