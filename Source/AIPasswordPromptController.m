/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

// $Id$

#import "AIPasswordPromptController.h"

#define 	PASSWORD_PROMPT_NIB 		@"PasswordPrompt"
#define		KEY_PASSWORD_WINDOW_FRAME	@"Password Prompt Frame"

@interface AIPasswordPromptController (PRIVATE)
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation AIPasswordPromptController

- (id)initWithWindowNibName:(NSString *)windowNibName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
    [super initWithWindowNibName:windowNibName];
    
    target = [inTarget retain];
    selector = inSelector;

	context = [inContext retain];
	
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
    NSString	*password = [textField_password stringValue];
    BOOL	savePassword = [checkBox_savePassword state];

    //save password?
    if(savePassword && password && [password length]){
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

- (void)savePassword:(NSString *)password{ };

- (void)textDidChange:(NSNotification *)notification
{
    if([[textField_password stringValue] length] != 0){
        [textField_password setEnabled:YES];
    }else{
        [textField_password setEnabled:NO];
    }
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    [self autorelease];
    return(YES);
}

@end
