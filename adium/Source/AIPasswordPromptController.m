/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIPasswordPromptController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define 	PASSWORD_PROMPT_NIB 		@"PasswordPrompt"
#define		KEY_PASSWORD_WINDOW_FRAME	@"Password Prompt Frame"

@interface AIPasswordPromptController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector owner:(id)inOwner;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation AIPasswordPromptController

AIPasswordPromptController	*controller = nil;
+ (void)showPasswordPromptForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector owner:(id)inOwner
{
    if(!controller){
        controller = [[self alloc] initWithWindowNibName:PASSWORD_PROMPT_NIB forAccount:inAccount notifyingTarget:inTarget selector:inSelector owner:inOwner];
    }else{
        //Beep and return failure if a prompt is already open
        NSBeep();        
        [inTarget performSelector:inSelector withObject:nil];
    }

    //bring the window front
    [controller showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName];
    
    account = [inAccount retain];
    target = [inTarget retain];
    selector = inSelector;
    owner = [inOwner retain];

    return(self);
}

- (void)dealloc
{
    [account release];
    [target release];

    [super dealloc];
}

- (void)windowDidLoad
{
    NSString	*savedFrame;
    
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PASSWORD_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

    //    
    [textField_account setStringValue:[account accountDescription]];
    [checkBox_savePassword setState:[[[account properties] objectForKey:@"SavedPassword"] boolValue]];
}

- (IBAction)cancel:(id)sender
{
    //close up and notify our caller (pass nil to signify no password)
    [self closeWindow:nil];    
    [target performSelector:selector withObject:nil];
}

- (IBAction)okay:(id)sender
{
    NSString	*password = [textField_password stringValue];
    BOOL	savePassword = [checkBox_savePassword state];

    //save password?
    if(savePassword){
        [AIKeychain putPasswordInKeychainForService:[NSString stringWithFormat:@"Adium.%@",[account accountID]] account:[account accountID] password:password];
    }

    //close up and notify our caller
    [self closeWindow:nil];    
    [target performSelector:selector withObject:password];
}

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
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_PASSWORD_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //
    [self autorelease];
    controller = nil;

    return(YES);
}

@end
