//
//  ESAccountPasswordPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 23 2004.
//

#import "ESAccountPasswordPromptController.h"

#define ACCOUNT_PASSWORD_PROMPT_NIB		@"PasswordPrompt"

@interface ESAccountPasswordPromptController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;;
@end

static AIPasswordPromptController	*controller = nil;

@implementation ESAccountPasswordPromptController

+ (void)showPasswordPromptForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    if(!controller){
        controller = [[self alloc] initWithWindowNibName:ACCOUNT_PASSWORD_PROMPT_NIB forAccount:inAccount notifyingTarget:inTarget selector:inSelector];
    }else{
        //Beep and return failure if a prompt is already open
        NSBeep();        
        [inTarget performSelector:inSelector withObject:nil];
    }
	
    //bring the window front
    [controller showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    [super initWithWindowNibName:windowNibName notifyingTarget:inTarget selector:inSelector];
    
    account = [inAccount retain];
	
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
	    
    [checkBox_savePassword setState:[[account preferenceForKey:[self savedPasswordKey] 
														 group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	[super windowDidLoad];
}

- (BOOL)windowShouldClose:(id)sender
{
    controller = nil;
	
	return [super windowShouldClose:sender];
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
