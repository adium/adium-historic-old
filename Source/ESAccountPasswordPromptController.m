/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccountController.h"
#import "ESAccountPasswordPromptController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>

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
    if((self = [super initWithWindowNibName:windowNibName notifyingTarget:inTarget selector:inSelector context:inContext])) {
		account = [inAccount retain];
		[self retain];
	}

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
