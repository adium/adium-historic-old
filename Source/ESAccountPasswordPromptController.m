//
//  ESAccountPasswordPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESAccountPasswordPromptController.h"

#define ACCOUNT_PASSWORD_PROMPT_NIB		@"PasswordPrompt"

@interface ESAccountPasswordPromptController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;
@end

@implementation ESAccountPasswordPromptController

+ (void)showPasswordPromptForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	ESAccountPasswordPromptController *controller = [[[self alloc] initWithWindowNibName:ACCOUNT_PASSWORD_PROMPT_NIB 
																			  forAccount:inAccount 
																		 notifyingTarget:inTarget
																				selector:inSelector
																				 context:inContext] autorelease];
	
    //bring the window front
    [controller showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
    [super initWithWindowNibName:windowNibName notifyingTarget:inTarget selector:inSelector context:inContext];
    
    account = [inAccount retain];
	[self retain];
	
    return(self);
}

- (void)dealloc
{
    [account release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
    [textField_account setStringValue:[account formattedUID]];
	[textField_service setStringValue:[[account service] shortDescription]];
	
    [checkBox_savePassword setState:[[account preferenceForKey:[self savedPasswordKey] 
														 group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	[super windowDidLoad];
}

- (NSString *)savedPasswordKey
{
	return @"SavedPassword";
}

//Save a password; pass nil to forget the password
- (void)savePassword:(NSString *)password
{
	if (password){
		[[adium accountController] setPassword:password forAccount:account];	
	}else{
		[[adium accountController] forgetPasswordForAccount:account];	
	}
}


@end
