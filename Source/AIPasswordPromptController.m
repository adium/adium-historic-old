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

// $Id$

#import "AIPasswordPromptController.h"
#import <AIUtilities/AITextFieldAdditions.h>

#define 	PASSWORD_PROMPT_NIB 		@"PasswordPrompt"
#define		KEY_PASSWORD_WINDOW_FRAME	@"Password Prompt Frame"

@implementation AIPasswordPromptController

- (id)initWithWindowNibName:(NSString *)windowNibName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
    if((self = [super initWithWindowNibName:windowNibName])) {
		target = [inTarget retain];
		selector = inSelector;

		context = [inContext retain];
	}

    return(self);
}

- (void)dealloc
{
    [target release];
	[context release];
	
    [super dealloc];
}

- (void)windowDidLoad
{
	[[self window] center];
}

- (NSString *)savedPasswordKey
{
	return nil;
}

- (IBAction)cancel:(id)sender
{
    //close up and notify our caller (pass nil to signify no password)
    [self closeWindow:nil]; 
    [target performSelector:selector withObject:nil withObject:context];
}

- (IBAction)okay:(id)sender
{
	NSString	*password = [textField_password secureStringValue];
	BOOL	savePassword = [checkBox_savePassword state];

	//save password?
	if(savePassword && password && [password length]) {
		[self savePassword:password];
	}

	//close up and notify our caller
	[self closeWindow:nil];    
	[target performSelector:selector withObject:password withObject:context];
}

- (IBAction)togglePasswordSaved:(id)sender
{
    if([sender state] == NSOffState){
        //Forget any saved passwords
		[self savePassword:nil];
    }
}

- (void)savePassword:(NSString *)password
{
	//abstract method. subclasses can do things here.
}

- (void)textDidChange:(NSNotification *)notification
{
	//if the password field is empty, disable the OK button.
	//otherwise, enable it.
	[button_OK setEnabled:([[textField_password secureStringValue] length] != 0)];
}

// called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
    [self autorelease];
}

@end
